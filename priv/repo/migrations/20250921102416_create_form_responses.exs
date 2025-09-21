defmodule Paperform2web.Repo.Migrations.CreateFormResponses do
  use Ecto.Migration

  def change do
    create table(:form_responses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :document_share_id, references(:document_shares, type: :binary_id, on_delete: :delete_all), null: false
      add :session_id, :string, null: false
      add :form_data, :map, null: false
      add :page_number, :integer, default: 1
      add :is_partial, :boolean, default: true
      add :is_completed, :boolean, default: false
      add :ip_address, :string
      add :user_agent, :text
      add :completion_time_seconds, :integer
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end

    create index(:form_responses, [:document_share_id])
    create index(:form_responses, [:session_id])
    create index(:form_responses, [:is_completed])
    create index(:form_responses, [:inserted_at])
    create unique_index(:form_responses, [:document_share_id, :session_id, :page_number])
  end
end
