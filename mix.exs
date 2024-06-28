defmodule Flake.MixProject do
  use Mix.Project

  def project do
    [
      app: :flake,
      name: "Flake",
      description: "Generate 64-bit unique, timestamp sortable, identifiers.",
      source_url: "https://github.com/goodgamechat/flake",
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Flake.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      name: "flake",
      licenses: ["GPL-3.0-or-later"],
      links: %{"Github" => "https://github.com/goodgamechat/flake"}
    ]
  end
end
