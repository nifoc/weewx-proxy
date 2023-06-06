defmodule WeewxProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :weewx_proxy,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {WeewxProxy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:tortoise311, "~> 0.11"},
      {:httpoison, "~> 2.1"},
      {:jason, "~> 1.4"},
      {:tz, "~> 0.26"},
      {:typed_struct, "~> 0.3.0", runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false}
    ]
  end
end
