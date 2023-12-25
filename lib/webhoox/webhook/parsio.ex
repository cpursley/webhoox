defmodule Webhoox.Webhook.Parsio do
  @moduledoc """
  Struct modeling incoming Parsio parsed email
  """
  @type t :: %__MODULE__{
          event: String.t(),
          mailbox_id: String.t(),
          doc_id: String.t(),
          filename: String.t(),
          template_id: String.t(),
          parsed: map()
        }
  defstruct [:event, :mailbox_id, :doc_id, :filename, :template_id, :parsed]
end
