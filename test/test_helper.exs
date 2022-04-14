ExUnit.start()

defmodule TestProcessor do
  @behaviour Webhoox.Handler

  def process(email) do
    send(self(), {:email, email})
  end
end
