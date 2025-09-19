defmodule Paperform2web.Repo.Migrations.CreateTemplates do
  use Ecto.Migration

  def change do
    create table(:templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :css_content, :text
      add :is_active, :boolean, default: true
      add :sort_order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:templates, [:slug])
    create index(:templates, [:is_active])
    create index(:templates, [:sort_order])

    # Add template_id to documents table
    alter table(:documents) do
      add :template_id, references(:templates, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:documents, [:template_id])
  end
end
