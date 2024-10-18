import Config

# Print only warnings and errors during test
config :logger, level: :warning

config :thumbtack,
  ecto_repos: [Thumbtack.Repo]

database_url =
  System.get_env("THUMBTACK_DATABASE_URL") || "ecto://postgres:postgres@localhost/thumbtack_test"

config :thumbtack, Thumbtack.Repo,
  url: database_url,
  pool: Ecto.Adapters.SQL.Sandbox

config :thumbtack,
  repo: Thumbtack.Repo,
  storage: Thumbtack.Storage.Local