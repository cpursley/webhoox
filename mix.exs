defmodule Webhoox.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :webhoox,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Webhoox",
      description: "Handle incoming webhooks via adapters",
      package: [
        maintainers: ["Chase Pursley"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/cpursley/webhoox"},
        files: ~w(LICENSE README.md lib mix.exs)
      ],
      source_url: "https://github.com/cpursley/webhoox",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.14.2"},
      {:jason, "~> 1.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.30.4", only: :dev},
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false}
    ]
  end
end
