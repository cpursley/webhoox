# Webhoox

Webhoox makes it easy to deal with inbound webhooks by using an adapter-based approach, saving you time.

This library started off as a fork of [receivex](https://github.com/maartenvanvliet/receivex) which is focused on common email webhooks. Webhoox takes Maarten's awesome work and makes it generic.

## Adapters

TODO: Move adapters out of core library

Right now [Mailgun](./lib/webhoox/adapters/mailgun.ex) and [Mandrill](./lib/webhoox/adapters/mandrill.ex) webhooks are supported out of the box.

You can implement your own adapter by following the existing adapters as an example.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `webhoox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:webhoox, "~> 0.1.0"}
  ]
end
```


Example configuration for Mandrill with the Plug router
```elixir
forward("_incoming", to: Webhoox, init_opts: [
  adapter: Webhoox.Adapter.Mandrill,
  adapter_opts: [
    secret: "i8PTcm8glMgsfaWf75bS1FQ",
    url: "http://example.com"
  ],
  handler: Example.Processor]
)
```

Example configuration for Mandrill with the Phoenix router
```elixir
forward("_incoming", Webhoox, [
  adapter: Webhoox.Adapter.Mandrill,
  adapter_opts: [
    secret: "i8PTcm8glMgsfaWf75bS1FQ",
    url: "http://example.com"
  ],
  handler: Example.Processor]
)
```

Example configuration for Mailgun with the Plug router
```elixir
forward("_incoming", to: Webhoox, init_opts: [
  adapter: Webhoox.Adapter.Mailgun,
  adapter_opts: [
    api_key: "some-key"
  ],
  handler: Example.Processor]
)
```

Example processor
```elixir
  defmodule Example.Processor do
    @behaviour Webhoox.Handler

    def process(%Webhoox.Email{} = mail) do
      IO.inspect(mail)
    end
  end

```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/webhoox](https://hexdocs.pm/webhoox).

