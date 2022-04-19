ExUnit.start()

defmodule TestProcessor do
  @behaviour Webhoox.Handler

  def process(webhook) do
    send(self(), {:webhook, webhook})
  end
end
