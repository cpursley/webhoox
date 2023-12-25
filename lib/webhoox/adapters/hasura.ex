defmodule Webhoox.Adapter.Hasura do
  @moduledoc """
  Webhoox Adapter for Hasura Events and Actions
  """
  @behaviour Webhoox.Adapter

  import Plug.Conn
  import Webhoox.Response
  alias Webhoox.Data.Hasura

  def handle_webhook(conn = %Plug.Conn{body_params: params}, handler, opts) do
    api_key = Keyword.fetch!(opts, :api_key)

    if authorized_request?(conn, api_key) do
      authorized_request(conn, params, handler)
    else
      unauthorized_request(conn)
    end
  end

  defp authorized_request?(conn, api_key) do
    with [secret] <- get_req_header(conn, "api-key") do
      api_key == secret
    else
      _ ->
        false
    end
  end

  defp authorized_request(conn, params, handler) do
    response =
      params
      |> normalize_params()
      |> handler.process()

    case response do
      {_, %Hasura.Action{} = resp} ->
        {:ok, conn, resp}

      {_, %Hasura.Event{} = resp} ->
        {:ok, conn, resp}

      {:ok, resp} ->
        {:ok, conn, resp}

      {:error, :bad_request} ->
        bad_request(conn)

      _ ->
        bad_request(conn)
    end
  end

  @doc """
  Handles a Hasura webhook:
    - Action: https://hasura.io/docs/latest/graphql/core/actions/action-handlers/#http-handler
    - Event: https://hasura.io/docs/latest/graphql/core/event-triggers/payload.html#json-payload
  """
  def normalize_params(%{
        "action" => %{"name" => name},
        "input" => input,
        "session_variables" => session_variables
      }) do
    %Hasura.Action{
      name: name,
      input: input,
      session_variables: session_variables
    }
  end

  def normalize_params(%{
        "created_at" => created_at,
        "event" => %{
          "data" => data,
          "op" => operation,
          "session_variables" => session_variables
        },
        "id" => id,
        "table" => table,
        "trigger" => %{"name" => name}
      }) do
    %Hasura.Event{
      id: id,
      name: name,
      table: table,
      data: data,
      operation: operation,
      session_variables: session_variables,
      created_at: created_at
    }
  end

  def normalize_params(_), do: nil
end
