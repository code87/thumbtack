defmodule Thumbtack.Repo do
  use Ecto.Repo,
    otp_app: :thumbtack,
    adapter: Ecto.Adapters.Postgres
end
