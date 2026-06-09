defmodule Lux.Prisms.Twitter.AutoReplyPrism do
  @moduledoc """
  Prism that checks for new mentions and replies to them using an LLM.
  """

  use Lux.Prism,
    name: "Twitter Auto Reply",
    description: "Checks mentions and auto-replies to them"

  alias Lux.Lenses.Twitter.MentionsLens, as: Mentions
  alias Lux.Lenses.Twitter.GetUserLens, as: GetUser
  alias Lux.Prisms.Twitter.PostTweetPrism, as: PostTweet

  require Logger

  def handler(_input, agent) do
    # 1. Fetch mentions
    with {:ok, mentions} <- Mentions.focus(),
         {:ok, user} <- GetUser.focus() do
      
      # 2. Iterate and reply
      results = Enum.map(mentions, fn mention ->
        # We should ideally check memory here to avoid double-replying.
        # For now we'll log it.
        Logger.info("Processing mention from #{mention.author_id}: #{mention.text}")
        
        reply_text = generate_reply(agent, mention, user)
        
        case PostTweet.run(%{
          text: reply_text,
          reply_to_tweet_id: mention.id
        }) do
          {:ok, response} -> {:ok, response}
          {:error, reason} -> 
            Logger.error("Failed to reply to #{mention.id}: #{inspect(reason)}")
            {:error, reason}
        end
      end)
      
      {:ok, %{processed_count: length(results)}}
    else
      {:error, reason} -> 
        Logger.error("AutoReply failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp generate_reply(agent, mention, user) do
    # Use the agent's LLM to generate a reply
    prompt = """
    You are an AI agent on Twitter. Your handle is @#{user["username"]}.
    Someone mentioned you in a tweet:
    "#{mention.text}"
    
    Your goal is: #{agent.goal}
    
    Write a short, engaging, and helpful reply (max 250 chars to be safe).
    Do not include hashtags unless they are very relevant.
    Maintain a professional yet conversational tone.
    """
    
    case Lux.Agent.chat(agent, prompt) do
      {:ok, reply} -> reply
      _ -> "Thanks for reaching out! How can I help you today?"
    end
  end
end
