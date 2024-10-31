Thumbtack.Repo.start_link()

ExUnit.start()

ExUnit.after_suite(fn _ ->
  Thumbtack.storage().storage_path()
  # |> File.rm_rf()
end)

Ecto.Adapters.SQL.Sandbox.mode(Thumbtack.Repo, :manual)
