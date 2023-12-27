defmodule Webhoox.Adapter.StandardWebhook do
  @moduledoc """
  Standard Webhook Adapter
  Read more here: https://standardwebhooks.com
  """
  import Plug.Conn
  import Webhoox.Utility.Response

  alias Webhoox.Authentication.StandardWebhook, as: Authentication

  @behaviour Webhoox.Adapter

  def handle_webhook(conn = %Plug.Conn{body_params: params}, handler, opts) do
    secret = Keyword.fetch!(opts, :secret)

    if Authentication.verify(conn, params, secret) do
      authorized_request(conn, params, handler)
    else
      unauthorized_request(conn)
    end
  end

  defp authorized_request(conn, params, handler) do
    response =
      params
      |> normalize_params(conn)
      |> handler.process()

    case response do
      {_, %Webhoox.Webhook.StandardWebhook{} = resp} ->
        {:ok, conn, resp}

      {:ok, resp} ->
        {:ok, conn, resp}

      {:error, :bad_request} ->
        bad_request(conn)

      _ ->
        bad_request(conn)
    end
  end

  def normalize_params(payload, conn) do
    [id] = get_req_header(conn, "webhook-id")
    [timestamp] = get_req_header(conn, "webhook-timestamp")

    %Webhoox.Webhook.StandardWebhook{
      id: id,
      timestamp: String.to_integer(timestamp),
      payload: payload
    }
  end
end
