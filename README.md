# Webhoox

Webhoox makes it easy to deal with inbound webhooks by using an adapter-based approach, saving you time.

This library started off as a fork of Maarten's awesome [receivex](https://github.com/maartenvanvliet/receivex) email-focused library.

## Adapters

- [MailerSend](./lib/webhoox/adapters/mailersend.ex)
- [Mailgun](./lib/webhoox/adapters/mailgun.ex)
- [Mandrill](./lib/webhoox/adapters/mandrill.ex)
- [Hasura](./lib/webhoox/adapters/hasura.ex)
- [s3](./lib/webhoox/adapters/s3.ex)
- [Parsio](./lib/webhoox/adapters/parsio.ex)

You can implement your own adapter by following the existing adapters as an example. Pull requests for new adapters welcome!

## Installation

[Available in Hex](https://hex.pm/packages/webhoox), the package can be installed
by adding `webhoox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:webhoox, "~> 0.1.8"}
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

    def process(%Webhoox.Data.Email{} = email) do
      # You probably want to handle processing of the event asynchronously
      # and go ahead and return a 200 as not to block the sending server
      
      {:ok, "200 OK"}
    end
  end
```

Documentation can be found at [https://hex.pm/packages/webhoox](https://hex.pm/packages/webhoox).

