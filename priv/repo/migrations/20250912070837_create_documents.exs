defmodule Paperform2web.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string, null: false
      add :file_path, :string, null: false
      add :content_type, :string, null: false
      add :status, :string, default: "uploaded", null: false
      add :progress, :integer, default: 0, null: false
      add :model_used, :string
      add :processed_data, :map
      add :error_message, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:documents, [:file_path])
    create index(:documents, [:status])
    create index(:documents, [:inserted_at])
  end
end
