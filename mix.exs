defmodule FakeHTTP.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_fake_http,
      version: "0.1.0",
      description: "A scriptable HTTP server for testing",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "FakeHTTP",
      source_url: "https://github.com/ishikawa/ex_fake_http",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {FakeHTTP.Application, []},
      extra_applications: [:logger]
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ishikawa/ex_fake_http"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1.2"},
      {:ace, "~> 0.18.1"},
      {:raxx, "~> 0.17.0"},
      {:httpoison, "~> 1.5", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false}
    ]
  end
end
