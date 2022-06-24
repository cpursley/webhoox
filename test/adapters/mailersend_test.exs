defmodule Webhoox.Adapter.MailersendTest do
  use ExUnit.Case
  use Plug.Test

  alias Webhoox.Adapter

  @signature "9917b9f1e436aee6c9781cee37072adcae1b7fabbdf9f3b9758fc3275190089e"
  @signing_secret "signing_secret"

  @mailersend_activity_params %{
    "created_at" => "2020-11-27T10:08:08.298647Z",
    "data" => %{
      "created_at" => "2020-11-27T10:08:06.258000Z",
      "email" => %{
        "created_at" => "2020-11-27T10:08:03.923000Z",
        "from" => "test@mailersend.com",
        "id" => "5fc0d003e7a5e7035446aa32",
        "message" => %{
          "created_at" => "2020-11-27T10:08:03.017000Z",
          "id" => "5fc0d003f718c90162341852",
          "object" => "message"
        },
        "object" => "email",
        "recipient" => %{
          "created_at" => "2020-09-21T11:00:38.184000Z",
          "email" => "test@mailersend.com",
          "id" => "5f6887d6fd913a6523283fd2",
          "object" => "recipient"
        },
        "status" => "sent",
        "subject" => "Test email",
        "tags" => nil
      },
      "id" => "5fc0d006b42c3e16e1774882",
      "morph" => nil,
      "object" => "activity",
      "template_id" => "7nxe3yjmeq28vp0k",
      "type" => "sent"
    },
    "domain_id" => "yv69oxl5kl785kw2",
    "type" => "activity.sent",
    "url" => "https://your-domain.com/webhook",
    "webhook_id" => "2351ndgwr4zqx8ko"
  }

  defp setup_webhook(mailersend_params) do
    conn(:post, "/_incoming", mailersend_params)
    |> put_req_header("signature", @signature)
    |> Plug.Conn.assign(:raw_body, Jason.encode!(mailersend_params))
  end

  describe "'standard' webhook" do
    test "processes valid webhook" do
      conn = setup_webhook(@mailersend_activity_params)

      {:ok, _conn} =
        Adapter.Mailersend.handle_webhook(conn, TestProcessor, signing_secret: @signing_secret)

      assert_receive {:webhook, %Webhoox.Data.Email{}}
    end

    test "normalizes email" do
      assert %Webhoox.Data.Email{
               message_id: "5fc0d003f718c90162341852",
               event: "sent",
               sender: "test@mailersend.com",
               to: [{"", "test@mailersend.com"}],
               from: {"", "test@mailersend.com"},
               subject: "Test email",
               timestamp: "2020-11-27T10:08:06.258000Z",
               raw_params: @mailersend_activity_params
             } == Adapter.Mailersend.normalize_params(@mailersend_activity_params)
    end
  end
end
