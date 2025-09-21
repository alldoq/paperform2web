defmodule Paperform2web.Documents.Document do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "documents" do
    field :filename, :string
    field :file_path, :string
    field :content_type, :string
    field :status, :string, default: "uploaded"
    field :progress, :integer, default: 0
    field :model_used, :string
    field :processed_data, :map
    field :raw_response, :string
    field :theme, :string, default: "default"
    field :error_message, :string
    field :status_message, :string
    
    belongs_to :template, Paperform2web.Templates.Template
    has_many :document_shares, Paperform2web.Documents.DocumentShare

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [
      :filename,
      :file_path,
      :content_type,
      :status,
      :progress,
      :model_used,
      :processed_data,
      :raw_response,
      :theme,
      :template_id,
      :error_message,
      :status_message
    ])
    |> validate_required([:filename, :file_path, :content_type])
    |> validate_inclusion(:status, ["uploaded", "processing", "completed", "failed"])
    |> validate_number(:progress, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint(:file_path)
  end
end