defmodule Webhoox.Webhook.Hasura.Action do
  @moduledoc """
  Struct modeling incoming Hasura Action
  """
  @type t :: %__MODULE__{
          name: String.t(),
          input: map(),
          request_query: String.t(),
          session_variables: map()
        }
  defstruct [:name, :input, :request_query, :session_variables]
end

defmodule Webhoox.Webhook.Hasura.Event do
  @moduledoc """
  Struct modeling incoming Hasura Event
  """
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          table: map(),
          data: map(),
          operation: String.t(),
          session_variables: map(),
          created_at: DateTime.t()
        }
  defstruct [:id, :name, :table, :data, :operation, :session_variables, :created_at]
end
