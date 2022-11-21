defmodule Webhoox.Adapter.Parsio do
  @moduledoc """
  Parsio.io Adapter
  - https://help.parsio.io/data-export-integrations/send-data-to-webhook-1#secure-your-webhooks-optional
  """
  import Webhoox.{Authentication, Response}
  alias Webhoox.Data.Parsio

  @behaviour Webhoox.Adapter

  def handle_webhook(conn = %Plug.Conn{body_params: params}, handler, opts) do
    signing_secret = Keyword.fetch!(opts, :signing_secret)

    case valid_signature?(conn, signing_secret, "parsio-signature") do
      true ->
        authorized_request(conn, params, handler)

      _ ->
        unauthorized_request(conn)
    end
  end

  defp authorized_request(conn, params, handler) do
    response =
      params
      |> normalize_params()
      |> handler.process()

    case response do
      {_, %Parsio{} = resp} ->
        {:ok, conn, resp}

      {:ok, resp} ->
        {:ok, conn, resp}

      {:error, :bad_request} ->
        bad_request(conn)

      _ ->
        bad_request(conn)
    end
  end

  # @doc """
  # Handles a Parsio webhook:
  # """
  def normalize_params(%{
        "doc_id" => doc_id,
        "event" => event = "doc.parsed",
        "mailbox_id" => mailbox_id,
        "payload" => %{
          "filename" => filename,
          "template_id" => template_id,
          "parsed" => parsed
        }
      }) do
    %Parsio{
      event: event,
      mailbox_id: mailbox_id,
      doc_id: doc_id,
      filename: filename,
      template_id: template_id,
      parsed: parsed
    }
  end

  def normalize_params(_), do: nil
end
