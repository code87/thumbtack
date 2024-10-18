defmodule Thumbtack.Repo.Migrations.CreateAlbums do
  use Ecto.Migration

  def change do
    create table(:albums) do
      add :title, :string, null: false
    end

    create unique_index(:albums, [:title])
  end
end
