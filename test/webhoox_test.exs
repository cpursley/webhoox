defmodule WebhooxTest do
  use ExUnit.Case
  use Plug.Test

  defmodule TestAdapter do
    @behaviour Webhoox.Adapter

    @impl true
    def handle_webhook(conn, handler, _opts) do
      case conn.body_params do
        %{"invalid" => "true"} ->
          {:error, conn}

        %{"error_response" => "true"} ->
          error_response = %{
            code: :bad_request,
            body: %{message: "Bad Request"}
          }

          {:error, conn, error_response}

        %{"ok_response" => "true"} ->
          response = %{
            code: :ok,
            body: %{hello: "World"}
          }

          {:ok, conn, response}

        _ ->
          email = normalize_params(conn.body_params)

          handler.process(email)
          {:ok, conn}
      end
    end

    @impl true
    def normalize_params(payload) do
      %Webhoox.Data.Email{
        from: {nil, payload["from"]},
        subject: nil,
        to: nil,
        html: nil,
        text: payload["subject"]
      }
    end
  end

  @opts Webhoox.init(
          adapter: TestAdapter,
          adapter_opts: [],
          handler: TestProcessor
        )

  test "sends mail to processor" do
    conn =
      conn(:post, "/_incoming", "subject=Hello+World&from=test%40example.com")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Plug.Parsers.call(conn, Plug.Parsers.init(parsers: [:urlencoded, :multipart]))
    conn = Webhoox.call(conn, @opts)
    assert 200 == conn.status
    assert conn.halted

    assert_receive {:webhook,
                    %Webhoox.Data.Email{
                      from: {nil, "test@example.com"},
                      html: nil,
                      sender: nil,
                      subject: nil,
                      text: "Hello World",
                      to: nil
                    }}
  end

  describe "webhook responses" do
    test "returns user-provided response" do
      conn =
        conn(:post, "/_incoming", "ok_response=true")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      conn = Plug.Parsers.call(conn, Plug.Parsers.init(parsers: [:urlencoded, :multipart]))
      conn = Webhoox.call(conn, @opts)

      assert conn.status == 200
      assert conn.resp_body == "{\"code\":\"ok\",\"body\":{\"hello\":\"World\"}}"
      assert conn.halted
    end

    test "returns standard error response" do
      conn =
        conn(:post, "/_incoming", "invalid=true&subject=Hello+World&from=test%40example.com")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      conn = Plug.Parsers.call(conn, Plug.Parsers.init(parsers: [:urlencoded, :multipart]))
      conn = Webhoox.call(conn, @opts)

      assert conn.status == 403
      assert conn.resp_body == "bad signature"
      assert conn.halted

      refute_receive {:webhook, _}
    end

    test "returns user-provided error response" do
      conn =
        conn(:post, "/_incoming", "error_response=true")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      conn = Plug.Parsers.call(conn, Plug.Parsers.init(parsers: [:urlencoded, :multipart]))
      conn = Webhoox.call(conn, @opts)

      assert conn.status == 400
      assert conn.resp_body == "{\"message\":\"Bad Request\"}"
      assert conn.halted

      refute_receive {:webhook, _}
    end
  end
end
