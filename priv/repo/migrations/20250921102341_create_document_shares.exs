defmodule Paperform2web.Repo.Migrations.CreateDocumentShares do
  use Ecto.Migration

  def change do
    create table(:document_shares, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :document_id, references(:documents, type: :binary_id, on_delete: :delete_all), null: false
      add :share_token, :string, null: false
      add :recipient_email, :string, null: false
      add :recipient_name, :string
      add :subject, :string
      add :message, :text
      add :status, :string, default: "pending", null: false
      add :expires_at, :utc_datetime
      add :sent_at, :utc_datetime
      add :opened_at, :utc_datetime
      add :first_response_at, :utc_datetime
      add :last_response_at, :utc_datetime
      add :total_opens, :integer, default: 0
      add :unique_opens, :integer, default: 0
      add :response_count, :integer, default: 0
      add :is_completed, :boolean, default: false
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:document_shares, [:share_token])
    create index(:document_shares, [:document_id])
    create index(:document_shares, [:recipient_email])
    create index(:document_shares, [:status])
    create index(:document_shares, [:expires_at])
    create index(:document_shares, [:sent_at])
  end
end
