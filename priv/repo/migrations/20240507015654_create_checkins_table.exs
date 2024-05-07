defmodule Subathon.Repo.Migrations.CreateCheckinsTable do
  use Ecto.Migration

  def change do
    create table(:check_ins) do
      add :profile_id, references(:profiles, on_delete: :delete_all), null: false
      add :date_nz, :date, null: false
      timestamps(updated_at: false)
    end

    create unique_index(:check_ins, [:profile_id, :date_nz])
  end
end
