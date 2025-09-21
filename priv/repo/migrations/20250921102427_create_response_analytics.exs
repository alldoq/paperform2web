defmodule Paperform2web.Repo.Migrations.CreateResponseAnalytics do
  use Ecto.Migration

  def change do
    create table(:response_analytics, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :document_share_id, references(:document_shares, type: :binary_id, on_delete: :delete_all), null: false
      add :field_key, :string, null: false
      add :field_type, :string, null: false
      add :field_label, :string
      add :response_value, :text
      add :response_count, :integer, default: 1
      add :completion_rate, :float
      add :avg_time_to_complete_seconds, :float
      add :analytics_data, :map

      timestamps(type: :utc_datetime)
    end

    create index(:response_analytics, [:document_share_id])
    create index(:response_analytics, [:field_key])
    create index(:response_analytics, [:field_type])
    create unique_index(:response_analytics, [:document_share_id, :field_key, :response_value])
  end
end
