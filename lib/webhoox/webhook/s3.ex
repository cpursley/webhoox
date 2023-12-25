defmodule Webhoox.Webhook.S3 do
  @moduledoc """
  Struct modeling incoming s3 compatible Events
  """
  @type t :: %__MODULE__{
          event: String.t(),
          key: String.t(),
          records: map()
        }
  defstruct [:event, :key, :records]
end
