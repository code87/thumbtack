defmodule Thumbtack.MixProject do
  use Mix.Project

  def project do
    [
      app: :thumbtack,
      version: "0.0.4",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      preferred_cli_env: preferred_cli_env(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: extra_applications(Mix.env())
    ]
  end

  defp extra_applications(:test), do: [:postgrex, :ecto_sql, :logger]
  defp extra_applications(_), do: [:logger, :inets, :ssl]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.12"},
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:postgrex, "~> 0.19"},
      {:vix, "~> 0.29"}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md",
        "guides/single_image_upload.md",
        "guides/multiple_image_uploads.md",
        "guides/image_transformations.md",
        "CHANGELOG.md",
        "LICENSE.md"
      ],
      groups_for_extras: [
        Guides: ~r/guides\/[^\/]+\.md/
      ],
      main: "readme"
    ]
  end

  defp preferred_cli_env do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: :test,
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.html": :test,
      "coveralls.post": :test
    ]
  end
end
