defmodule Paperform2web.Templates.Template do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "templates" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :css_content, :string
    field :is_active, :boolean, default: true
    field :sort_order, :integer, default: 0

    has_many :documents, Paperform2web.Documents.Document, foreign_key: :template_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [:name, :slug, :description, :css_content, :is_active, :sort_order])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:slug, min: 1, max: 50)
    |> validate_format(:slug, ~r/^[a-z0-9_-]+$/, message: "must contain only lowercase letters, numbers, hyphens, and underscores")
  end
end