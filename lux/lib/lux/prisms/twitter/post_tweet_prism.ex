defmodule Lux.Prisms.Twitter.PostTweetPrism do
  @moduledoc """
  Prism for posting a tweet or a reply to X (Twitter).
  """

  use Lux.Prism,
    name: "Post Tweet",
    description: "Posts a new tweet or a reply to X (Twitter)",
    input_schema: %{
      type: :object,
      properties: %{
        text: %{
          type: :string,
          description: "The content of the tweet",
          maxLength: 280
        },
        reply_to_tweet_id: %{
          type: :string,
          description: "The ID of the tweet to reply to (optional)"
        }
      },
      required: ["text"]
    }

  alias Lux.Integrations.Twitter.Client

  def handler(input, _ctx) do
    payload = %{text: input[:text]}
    
    payload = if id = input[:reply_to_tweet_id] do
      Map.put(payload, :reply, %{in_reply_to_tweet_id: id})
    else
      payload
    end

    Client.request(:post, "/tweets", %{json: payload})
  end
end
