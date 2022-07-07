defmodule Webhoox.Adapter.MailersendTest do
  use ExUnit.Case
  use Plug.Test

  alias Webhoox.Adapter

  @activity_signature "9917b9f1e436aee6c9781cee37072adcae1b7fabbdf9f3b9758fc3275190089e"
  @inbound_signature "77b1f73586bbb597bdccd68e52c5aad5130986e46773fa2358acdfd8847431a2"
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

  @mailersend_inbound_params %{
    "created_at" => "2022-07-07T12:37:08.523580Z",
    "data" => %{
      "attachments" => [],
      "created_at" => "2022-07-07T12:37:08.160000Z",
      "date" => "Thu, 7 Jul 2022 08:36:54 -0400",
      "dkim_check" => true,
      "from" => %{
        "email" => "test@mailersend.com",
        "name" => "Test Mailersend",
        "raw" => "Test Mailersend <test@mailersend.com>"
      },
      "headers" => %{
        "Content-Type" => "multipart/alternative;",
        "Date" => "Thu, 7 Jul 2022 08:36:54 -0400",
        "From" => "Test Mailersend <test@mailersend.com>",
        "MIME-Version" => "1.0",
        "Message-ID" => "<ZALEQ8gac99LoU9aE-=xZM1+7g6GmFrtqJv54Xfz+vcYLqx9DrA@mail.gmail.com>",
        "Received" => [],
        "Subject" => "Test email",
        "To" => "0s86ovobd7pg2i6ebese@inbound.mailersend.net",
        "X-Envelope-From" => "<test@mailersend.com>"
      },
      "html" =>
        "<div><span style=font-family:Roboto,RobotoDraft,Helvetica,Arial,sans-serif;font-size:14px>Hello!</span><br></div>",
      "id" => "52c5d374f807dd7eec0886a1",
      "object" => "message",
      "raw" => "",
      "recipients" => %{
        "rcptTo" => [%{"email" => "0s86ovobd7pg2i6ebese@inbound.mailersend.net"}],
        "to" => %{
          "data" => [
            %{
              "email" => "0s86ovobd7pg2i6ebese@inbound.mailersend.net",
              "name" => ""
            }
          ],
          "raw" => "0s86ovobd7pg2i6ebese@inbound.mailersend.net"
        }
      },
      "sender" => %{"email" => "test@mailersend.com"},
      "spf_check" => %{"code" => "+", "value" => "pass"},
      "subject" => "Test email",
      "text" => "Hello!"
    },
    "inbound_id" => "ex2p0247k3lzdrn8",
    "type" => "inbound.message",
    "url" => "https://your-domain.com/webhook"
  }

  defp setup_webhook(mailersend_params, signature) do
    conn(:post, "/_incoming", mailersend_params)
    |> put_req_header("signature", signature)
    |> Plug.Conn.assign(:raw_body, Jason.encode!(mailersend_params))
  end

  describe "'activity' webhook" do
    test "processes valid webhook" do
      conn = setup_webhook(@mailersend_activity_params, @activity_signature)

      {:ok, _conn} =
        Adapter.Mailersend.handle_webhook(conn, TestProcessor, signing_secret: @signing_secret)

      assert_receive {:webhook, %Webhoox.Data.Email{}}
    end

    test "normalizes email" do
      assert %Webhoox.Data.Email{
               message_id: "5fc0d003f718c90162341852",
               event: "activity.sent",
               sender: "test@mailersend.com",
               to: [{"", "test@mailersend.com"}],
               from: {"", "test@mailersend.com"},
               subject: "Test email",
               timestamp: "2020-11-27T10:08:08.298647Z",
               raw_params: @mailersend_activity_params
             } == Adapter.Mailersend.normalize_params(@mailersend_activity_params)
    end
  end

  describe "'inbound' webhook" do
    test "processes valid webhook" do
      conn = setup_webhook(@mailersend_inbound_params, @inbound_signature)

      {:ok, _conn} =
        Adapter.Mailersend.handle_webhook(conn, TestProcessor, signing_secret: @signing_secret)

      assert_receive {:webhook, %Webhoox.Data.Email{}}
    end

    test "normalizes email" do
      assert %Webhoox.Data.Email{
               message_id: "52c5d374f807dd7eec0886a1",
               event: "inbound.message",
               sender: "test@mailersend.com",
               to: [{"", "0s86ovobd7pg2i6ebese@inbound.mailersend.net"}],
               from: {"", "test@mailersend.com"},
               subject: "Test email",
               html:
                 "<div><span style=font-family:Roboto,RobotoDraft,Helvetica,Arial,sans-serif;font-size:14px>Hello!</span><br></div>",
               text: "Hello!",
               timestamp: "2022-07-07T12:37:08.523580Z",
               raw_params: @mailersend_inbound_params
             } == Adapter.Mailersend.normalize_params(@mailersend_inbound_params)
    end
  end
end
