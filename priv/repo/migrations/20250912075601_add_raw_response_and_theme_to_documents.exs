defmodule Paperform2web.Repo.Migrations.AddRawResponseAndThemeToDocuments do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      add :raw_response, :text
      add :theme, :string, default: "default"
    end
  end
end
