ExUnit.start()

defmodule TestHelper do
  use ExUnit.Case
  import Plug.Conn
  import Plug.Test

  def setup_webhook(params, signature, header) do
    conn(:post, "/_incoming", params)
    |> put_req_header(header, signature)
    |> Plug.Conn.assign(:raw_body, Jason.encode!(params))
  end
end

defmodule TestProcessor do
  @behaviour Webhoox.Handler

  def process(webhook) do
    send(self(), {:webhook, webhook})
  end
end
