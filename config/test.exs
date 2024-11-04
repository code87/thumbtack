import Config

# Print only warnings and errors during test
config :logger, level: :warning

# Use fake httpc implementation during test
config :thumbtack, httpc: Thumbtack.FakeHttpc

config :thumbtack,
  ecto_repos: [Thumbtack.Repo]

database_url =
  System.get_env("THUMBTACK_DATABASE_URL") ||
    "ecto://postgres:postgres@localhost/thumbtack_test"

config :thumbtack, Thumbtack.Repo,
  url: database_url,
  pool: Ecto.Adapters.SQL.Sandbox

config :thumbtack,
  repo: Thumbtack.Repo,
  storage: Thumbtack.Storage.Local

config :thumbtack, Thumbtack.Storage.Local,
  root_url: "http://localhost:4000/uploads",
  storage_path: "tmp/uploads"
