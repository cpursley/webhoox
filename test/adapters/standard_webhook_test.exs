defmodule Webhoox.Adapter.StandardWebhookTest do
  use ExUnit.Case
  use Plug.Test

  alias Webhoox.Adapter.StandardWebhook, as: Adapter
  alias Webhoox.Authentication.StandardWebhook, as: Authentication
  alias Webhoox.Webhook.StandardWebhook, as: StandardWebhook

  @id "msg_p5jXN8AQM9LWM0D4loKWxJek"
  @timestamp :os.system_time(:second)
  @payload %{"event_type" => "ping"}
  @secret "MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw"

  describe "Authorization" do
    test "authorized webhook" do
      signature = Authentication.sign(@id, @timestamp, @payload, @secret)
      conn = setup_webhook(signature)

      {:ok, _conn, response = %StandardWebhook{}} =
        Adapter.handle_webhook(conn, TestProcessor, secret: @secret)

      assert_receive {:webhook, %StandardWebhook{}}
      assert response == %StandardWebhook{id: @id, timestamp: @timestamp, payload: @payload}
    end

    test "unauthorized webhook" do
      conn = setup_webhook("signature")

      {:error, _conn, resp} =
        Adapter.handle_webhook(conn, TestProcessor, secret: "incorrect secret")

      refute_receive {:webhook, %StandardWebhook{}}
      assert resp == %{body: %{code: "401", message: "Unauthorized"}, code: :unauthorized}
    end
  end

  defp setup_webhook(signature) do
    conn(:post, "/_incoming", @payload)
    |> put_req_header("webhook-id", @id)
    |> put_req_header("webhook-timestamp", to_string(@timestamp))
    |> put_req_header("webhook-signature", signature)
  end
end
