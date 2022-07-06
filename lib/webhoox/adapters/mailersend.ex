defmodule Webhoox.Adapter.Mailersend do
  @moduledoc """
  Mailersend Adapter
  Note: Must set up custom parser to set raw_body:
  - https://stackoverflow.com/questions/41510957/read-the-raw-body-from-a-plug-connection-after-parsers-in-elixir
  - https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader
  """
  import Plug.Conn
  import Webhoox.Parser

  @behaviour Webhoox.Adapter

  def handle_webhook(conn, handler, opts) do
    signing_secret = Keyword.fetch!(opts, :signing_secret)

    case valid_signature?(conn, signing_secret) do
      true ->
        conn.body_params
        |> normalize_params()
        |> handler.process()

        {:ok, conn}

      _ ->
        {:error, conn}
    end
  end

  defp valid_signature?(conn, signing_secret) do
    [signature] = get_req_header(conn, "signature")
    body = conn.assigns[:raw_body]

    :crypto.mac(:hmac, :sha256, signing_secret, body)
    |> Base.encode16(case: :lower)
    |> Plug.Crypto.secure_compare(signature)
  end

  @doc """
  Handle Mailersend v1 webhook type
  """
  def normalize_params(
        email = %{
          "created_at" => timestamp,
          "data" => %{
            "email" => %{
              "from" => sender,
              "message" => %{
                "id" => message_id
              },
              "recipient" => %{
                "email" => to
              },
              "subject" => subject
            }
          },
          "type" => event
        }
      ) do
    %Webhoox.Data.Email{
      message_id: message_id,
      event: event,
      sender: sender,
      to: parse_recipients(to),
      from: parse_address(sender),
      subject: subject,
      timestamp: parse_timestamp(timestamp),
      raw_params: email
    }
  end

  def normalize_params(_), do: nil
end
