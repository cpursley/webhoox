defmodule Webhoox.Authentication.StandardWebhook do
  @moduledoc false
  import Plug.Conn

  @secret_prefix "whsec_"
  @signature_identifier "v1"
  @tolerance 5 * 60
  @now :os.system_time(:second)

  def verify(conn, payload, secret) do
    required_headers?(conn)

    [id] = get_req_header(conn, "webhook-id")
    [timestamp] = get_req_header(conn, "webhook-timestamp")
    signatures = get_req_header(conn, "webhook-signature")

    signed_signature =
      sign(id, String.to_integer(timestamp), payload, secret)
      |> split_signature_from_identifier()

    verify_signatures(signatures, signed_signature)
  end

  defp required_headers?(%{req_headers: req_headers}) do
    required_headers = ["webhook-id", "webhook-timestamp", "webhook-signature"]
    filtered_headers = filter_headers(req_headers, required_headers)

    unless missing_headers?(filtered_headers, required_headers) do
      missing_headers = join_missing_headers(filtered_headers, required_headers)

      raise ArgumentError, message: "Missing required headers: #{missing_headers}"
    end
  end

  defp filter_headers(req_headers, required_headers) do
    req_headers
    |> Enum.map(fn {header, _value} -> header end)
    |> Enum.filter(&Enum.member?(required_headers, &1))
  end

  defp missing_headers?(headers, required_headers) do
    required_headers
    |> Enum.all?(&Enum.member?(headers, &1))
  end

  defp join_missing_headers(headers, required_headers) do
    required_headers
    |> Enum.reject(&Enum.member?(headers, &1))
    |> Enum.join(", ")
  end

  defp verify_signatures([], _signed_signature), do: false

  defp verify_signatures(signatures, signature) when signature >= 1 do
    signatures
    |> Enum.map(&split_signature_from_identifier/1)
    |> Enum.any?(&Plug.Crypto.secure_compare(&1, signature))
  end

  defp split_signature_from_identifier(signature) do
    signature
    |> String.split(",")
    |> List.last()
  end

  def sign(id, _timestamp, _payload, _secret) when not is_binary(id) do
    raise ArgumentError, message: "Message id must be a string"
  end

  def sign(_id, timestamp, _payload, _secret) when not is_integer(timestamp) do
    raise ArgumentError, message: "Message timestamp must be an integer"
  end

  def sign(_id, timestamp, _payload, _secret)
      when is_integer(timestamp) and timestamp < @now - @tolerance do
    raise ArgumentError, message: "Message timestamp too old"
  end

  def sign(_id, timestamp, _payload, _secret)
      when is_integer(timestamp) and timestamp > @now + @tolerance do
    raise ArgumentError, message: "Message timestamp too new"
  end

  def sign(_id, _timestamp, payload, _secret) when not is_map(payload) do
    raise ArgumentError, message: "Message payload must be a map"
  end

  def sign(_id, _timestamp, _payload, secret) when not is_binary(secret) do
    raise ArgumentError, message: "Secret must be a string"
  end

  def sign(id, timestamp, payload, @secret_prefix <> secret) do
    decoded_secret = Base.decode64!(secret)

    sign_with_version(id, timestamp, payload, decoded_secret)
  end

  def sign(id, timestamp, payload, secret) do
    sign_with_version(id, timestamp, payload, secret)
  end

  defp sign_with_version(id, timestamp, payload, secret) do
    signature =
      to_sign(id, timestamp, payload)
      |> sign_and_encode(secret)

    "#{@signature_identifier},#{signature}"
  end

  defp to_sign(id, timestamp, payload) do
    encoded_payload = Jason.encode!(payload)

    "#{id}.#{timestamp}.#{encoded_payload}"
  end

  defp sign_and_encode(to_sign, secret) do
    :crypto.mac(:hmac, :sha256, secret, to_sign)
    |> Base.encode64()
    |> String.trim()
  end
end
