defmodule Paperform2web.Documents.ResponseAnalytics do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "response_analytics" do
    field :field_key, :string
    field :field_type, :string
    field :field_label, :string
    field :response_value, :string
    field :response_count, :integer, default: 1
    field :completion_rate, :float
    field :avg_time_to_complete_seconds, :float
    field :analytics_data, :map

    belongs_to :document_share, Paperform2web.Documents.DocumentShare

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(response_analytics, attrs) do
    response_analytics
    |> cast(attrs, [
      :field_key,
      :field_type,
      :field_label,
      :response_value,
      :response_count,
      :completion_rate,
      :avg_time_to_complete_seconds,
      :analytics_data,
      :document_share_id
    ])
    |> validate_required([:field_key, :field_type, :document_share_id])
    |> validate_inclusion(:field_type, [
      "text", "textarea", "email", "phone", "number", "date", "time", "datetime",
      "select", "radio", "checkbox", "file", "signature", "rating", "scale",
      "matrix", "address", "payment", "calculated"
    ])
    |> validate_number(:response_count, greater_than_or_equal_to: 0)
    |> validate_number(:completion_rate, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_number(:avg_time_to_complete_seconds, greater_than_or_equal_to: 0.0)
    |> unique_constraint([:document_share_id, :field_key, :response_value])
  end
end