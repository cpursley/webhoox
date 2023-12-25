defmodule Webhoox.Webhook.StandardWebhook do
  @moduledoc """
  Struct modeling incoming Standard Webhooks compatible Events
  Read more here: https://standardwebhooks.com
  """
  @type t :: %__MODULE__{
          id: String.t(),
          timestamp: String.t(),
          payload: map()
        }

  defstruct [:id, :timestamp, :payload]
end
