defmodule Thumbtack.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
    end

    create unique_index(:users, [:email])
  end
end
