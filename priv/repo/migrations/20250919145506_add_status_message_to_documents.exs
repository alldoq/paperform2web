defmodule Paperform2web.Repo.Migrations.AddStatusMessageToDocuments do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      add :status_message, :string
    end
  end
end
