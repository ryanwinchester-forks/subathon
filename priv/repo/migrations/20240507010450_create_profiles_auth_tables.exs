defmodule Subathon.Repo.Migrations.CreateProfilesAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:profiles) do
      add :twitch_id, :string, null: false
      add :twitch_username, :citext, null: false
      add :pfp_url, :string, null: false
      timestamps()
    end

    create unique_index(:profiles, [:twitch_id])
    create unique_index(:profiles, [:twitch_username])

    create table(:profiles_tokens) do
      add :profile_id, references(:profiles, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      timestamps(updated_at: false)
    end

    create index(:profiles_tokens, [:profile_id])
    create unique_index(:profiles_tokens, [:context, :token])
  end
end
