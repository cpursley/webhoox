# Webhoox

Webhoox makes it easy to deal with inbound webhooks by using an adapter-based approach, saving you time.

This library started off as a fork of Maarten's awesome [receivex](https://github.com/maartenvanvliet/receivex) email-focused library.

## Adapters

- [Mailgun](./lib/webhoox/adapters/mailgun.ex)
- [Mandrill](./lib/webhoox/adapters/mandrill.ex)
- [Hasura](./lib/webhoox/adapters/hasura.ex)

You can implement your own adapter by following the existing adapters as an example. Pull requests for new adapters welcome!

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `webhoox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:webhoox, "~> 0.1.1"}
  ]
end
```

## Configuration

Example configuration for Mandrill with the Plug router:

```elixir
# Your router.ex file
forward("_incoming", to: Webhoox, init_opts: [
  adapter: Webhoox.Adapter.Mandrill,
  adapter_opts: [
    secret: "i8PTcm8glMgsfaWf75bS1FQ",
    url: "http://example.com"
  ],
  handler: Example.Processor]
)
```

Example Processor:

```elixir
  defmodule Example.Processor do
    @behaviour Webhoox.Handler

    def process(%Webhoox.Data.Email{} = mail) do
      # Do stuff with the webhook event data here
      IO.inspect(mail)
    end
  end
```

Documentation can be found at [https://hexdocs.pm/webhoox](https://hexdocs.pm/webhoox).

