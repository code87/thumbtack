defmodule Thumbtack.Repo.Migrations.CreateUserPhotos do
  use Ecto.Migration

  def change do
    create table("user_photos", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users), null: false
    end

    create unique_index(:user_photos, [:user_id])
  end
end
