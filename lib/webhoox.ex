defmodule Webhoox do
  @moduledoc """
  Package that makes it easy to deal with inbound webhooks.


  ## Installation

  If [available in Hex](https://hex.pm/docs/publish), the package can be installed
  by adding `webhoox` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
  [
    {:webhoox, "~> 0.1.3"}
  ]
  end
  ```


  Example configuration for Mandrill with the Plug router
  ```elixir
  forward("_incoming",
    to: Webhoox,
    init_opts: [
      adapter: Webhoox.Adapter.Mandrill,
      adapter_opts: [
        secret: "i8PTcm8glMgsfaWf75bS1FQ",
        url: "http://example.com"
      ],
      handler: Example.Processor
    ]
  )
  ```

  Example configuration for Mandrill with the Phoenix router
  ```elixir
  forward("_incoming", Webhoox,
    adapter: Webhoox.Adapter.Mandrill,
    adapter_opts: [
      secret: "i8PTcm8glMgsfaWf75bS1FQ",
      url: "http://example.com"
    ],
    handler: Example.Processor
  )
  ```

  Example configuration for Mailgun with the Plug router
  ```elixir
  forward("_incoming",
    to: Webhoox,
    init_opts: [
      adapter: Webhoox.Adapter.Mailgun,
      adapter_opts: [
        api_key: "some-key"
      ],
      handler: Example.Processor
    ]
  )
  ```

  Example configuration for custom adapter
  ```elixir
  forward("_incoming", Webhoox,
    adapter: Your.Custom.Adapter,
    adapter_opts: [some_option: "some-option"],
    handler: Your.Processor
  )
  ```

  Example processor
  ```elixir
  defmodule Example.Processor do
    @behaviour Webhoox.Handler

    def process(%Webhoox.Data.Email{} = email) do
      IO.inspect(email)
    end
  end

  ```

  """

  import Plug.Conn
  @behaviour Plug

  @impl true
  def init(opts) do
    handler = Keyword.fetch!(opts, :handler)
    adapter = Keyword.fetch!(opts, :adapter)
    adapter_opts = Keyword.fetch!(opts, :adapter_opts)

    {adapter, adapter_opts, handler}
  end

  @impl true
  def call(conn, opts) do
    {adapter, adapter_opts, handler} = opts

    case adapter.handle_webhook(conn, handler, adapter_opts) do
      {:ok, conn} ->
        conn
        |> send_resp(:ok, "ok")
        |> halt()

      {:ok, conn, resp} ->
        conn
        |> send_resp(:ok, Jason.encode!(resp))
        |> halt()

      {:error, conn} ->
        conn
        |> send_resp(:forbidden, "bad signature")
        |> halt()

      {:error, conn, error_resp} ->
        conn
        |> send_resp(error_resp.code, Jason.encode!(error_resp.body))
        |> halt()
    end
  end
end
