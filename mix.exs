defmodule Mastery.MixProject do
  use Mix.Project

  def project do
    [
      app: :mastery,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:eex]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:eex, :logger],
      mod: {Mastery.Application, []}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:mastery_persistence, path: "./mastery_persistence"}
    ]
  end
end
