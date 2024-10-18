defmodule Thumbtack.Repo.Migrations.CreateAlbumPhotos do
  use Ecto.Migration

  def change do
    create table("album_photos", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :album_id, references(:albums), null: false
      add :index_number, :integer, null: false, default: 0
    end

    create unique_index(:album_photos, [:album_id, :index_number])
  end
end
