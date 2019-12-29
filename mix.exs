defmodule FakeHTTP.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_fake_http,
      version: "0.3.2",
      description: "A scriptable HTTP server for testing",
      elixir: "~> 1.8",
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
      mod: {FakeHTTP, []},
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
      {:poison, ">= 3.0.0", optional: true},
      # {:ace, "~> 0.18.1"},
      {:ace, github: "ishikawa/Ace", branch: "work/fix-and-add-function-spec"},
      {:raxx, "~> 1.1.0"},
      {:raxx_logger, "~> 0.2.0"},
      {:raxx_view, "~> 0.1.0"},
      {:httpoison, "~> 1.5", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false}
    ]
  end
end
