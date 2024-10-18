import Config

config :thumbtack,
  ecto_repos: [Thumbtack.Repo]

database_url =
  System.get_env("THUMBTACK_DATABASE_URL") || "ecto://postgres:postgres@localhost/thumbtack_dev"

config :thumbtack, Thumbtack.Repo,
  url: database_url,
  pool: Ecto.Adapters.SQL

config :thumbtack,
  repo: Thumbtack.Repo,
  storage: Thumbtack.Storage.Local
