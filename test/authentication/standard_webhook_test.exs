defmodule Webhoox.Authentication.StandardWebhookTest do
  use ExUnit.Case
  use Plug.Test

  alias Webhoox.Authentication.StandardWebhook, as: Authentication

  @id "msg_p5jXN8AQM9LWM0D4loKWxJek"
  @timestamp :os.system_time(:second)
  @tolerance 5 * 60
  @payload %{"event_type" => "ping"}
  @secret_prefix "whsec_"
  @secret "MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw"
  @encoded_secret @secret_prefix <> Base.encode64(@secret)

  describe "sign/4" do
    test "raises error when message id is not a String" do
      assert_raise ArgumentError, "Message id must be a string", fn ->
        Authentication.sign(123, @timestamp, @payload, @secret)
      end
    end

    test "raises error when message timestamp is not an Integer" do
      assert_raise ArgumentError, "Message timestamp must be an integer", fn ->
        Authentication.sign(@id, to_string(@timestamp), @payload, @secret)
      end
    end

    test "raises error when message timestamp is too old" do
      assert_raise ArgumentError, "Message timestamp too old", fn ->
        timestamp = :os.system_time(:second) - @tolerance - 5000
        Authentication.sign(@id, timestamp, @payload, @secret)
      end
    end

    test "raises error when message timestamp is too new" do
      assert_raise ArgumentError, "Message timestamp too new", fn ->
        timestamp = :os.system_time(:second) + @tolerance + 5000
        Authentication.sign(@id, timestamp, @payload, @secret)
      end
    end

    test "raises error when message payload is not a Map" do
      assert_raise ArgumentError, "Message payload must be a map", fn ->
        Authentication.sign(@id, @timestamp, [], @secret)
      end
    end

    test "raises error when secret is not a String" do
      assert_raise ArgumentError, "Secret must be a string", fn ->
        Authentication.sign(@id, @timestamp, @payload, [])
      end
    end

    test "returns valid signature when unencoded secret" do
      [signature_identifier, signature] =
        Authentication.sign(@id, @timestamp, @payload, @secret) |> String.split(",")

      {:ok, decoded_signature} = Base.decode64(signature)

      assert "v1" == signature_identifier
      assert is_binary(decoded_signature)
    end

    test "returns valid signature when encoded secret" do
      [signature_identifier, signature] =
        Authentication.sign(@id, @timestamp, @payload, @encoded_secret) |> String.split(",")

      {:ok, decoded_signature} = Base.decode64(signature)

      assert "v1" == signature_identifier
      assert is_binary(decoded_signature)
    end
  end

  describe "verify/2" do
    setup do
      signature = Authentication.sign(@id, @timestamp, @payload, @secret)

      {:ok, signature: signature}
    end

    test "return true when valid signature", %{signature: signature} do
      conn = setup_webhook(signature)

      assert Authentication.verify(conn, @payload, @secret)
    end

    test "raises error when missing all required headers" do
      connection = conn(:post, "/_incoming", @payload)

      assert_raise ArgumentError,
                   "Missing required headers: webhook-id, webhook-timestamp, webhook-signature",
                   fn ->
                     Authentication.verify(connection, @payload, @secret)
                   end
    end

    test "raises error when missing webhook-id header", %{signature: signature} do
      connection =
        conn(:post, "/_incoming", @payload)
        |> put_req_header("webhook-timestamp", to_string(@timestamp))
        |> put_req_header("webhook-signature", signature)

      assert_raise ArgumentError, "Missing required headers: webhook-id", fn ->
        Authentication.verify(connection, @payload, @secret)
      end
    end

    test "raises error when missing webhook-timestamp header", %{signature: signature} do
      connection =
        conn(:post, "/_incoming", @payload)
        |> put_req_header("webhook-id", @id)
        |> put_req_header("webhook-signature", signature)

      assert_raise ArgumentError, "Missing required headers: webhook-timestamp", fn ->
        Authentication.verify(connection, @payload, @secret)
      end
    end

    test "raises error when missing webhook-signature header" do
      connection =
        conn(:post, "/_incoming", @payload)
        |> put_req_header("webhook-id", @id)
        |> put_req_header("webhook-timestamp", to_string(@timestamp))

      assert_raise ArgumentError, "Missing required headers: webhook-signature", fn ->
        Authentication.verify(connection, @payload, @secret)
      end
    end
  end

  defp setup_webhook(signature) do
    conn(:post, "/_incoming", @payload)
    |> put_req_header("webhook-id", @id)
    |> put_req_header("webhook-timestamp", to_string(@timestamp))
    |> put_req_header("webhook-signature", signature)
  end
end
