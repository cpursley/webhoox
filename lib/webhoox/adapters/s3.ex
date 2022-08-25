defmodule Webhoox.Adapter.S3 do
  @moduledoc """
  Webhoox Adapter for s3 compatible Events
  """
  @behaviour Webhoox.Adapter

  import Plug.Conn
  import Webhoox.Response
  alias Webhoox.Data.S3

  def handle_webhook(conn = %Plug.Conn{body_params: params}, handler, api_key: api_key) do
    if authorized_request?(conn, api_key) do
      authorized_request(conn, params, handler)
    else
      unauthorized_request(conn)
    end
  end

  defp authorized_request?(conn, api_key) do
    with ["Bearer " <> secret] <- get_req_header(conn, "authorization") do
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
      {_, %S3{} = resp} ->
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
  Handles an s3 compatible webhook:
    - https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-how-to-event-types-and-destinations.html
    - https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-content-structure.html
    - https://docs.min.io/docs/minio-bucket-notification-guide.html
  """

  def normalize_params(%{
        "EventName" => event,
        "Key" => key,
        "Records" => records
      }) do
    %S3{
      event: event,
      key: key,
      records: records
    }
  end

  def normalize_params(%{
        "Records" =>
          [
            %{
              "eventName" => event,
              "s3" => %{
                "object" => %{
                  "key" => key
                }
              }
            }
          ] = records
      }) do
    %S3{
      event: event,
      key: key,
      records: records
    }
  end

  def normalize_params(_), do: nil
end
