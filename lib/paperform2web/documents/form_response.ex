defmodule Paperform2web.Documents.FormResponse do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "form_responses" do
    field :session_id, :string
    field :form_data, :map
    field :page_number, :integer, default: 1
    field :is_partial, :boolean, default: true
    field :is_completed, :boolean, default: false
    field :ip_address, :string
    field :user_agent, :string
    field :completion_time_seconds, :integer
    field :metadata, :map

    belongs_to :document_share, Paperform2web.Documents.DocumentShare

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(form_response, attrs) do
    form_response
    |> cast(attrs, [
      :session_id,
      :form_data,
      :page_number,
      :is_partial,
      :is_completed,
      :ip_address,
      :user_agent,
      :completion_time_seconds,
      :metadata,
      :document_share_id
    ])
    |> validate_required([:session_id, :form_data, :document_share_id])
    |> validate_number(:page_number, greater_than: 0)
    |> validate_number(:completion_time_seconds, greater_than_or_equal_to: 0)
    |> unique_constraint([:document_share_id, :session_id, :page_number])
    |> put_session_id()
  end

  defp put_session_id(changeset) do
    case get_field(changeset, :session_id) do
      nil -> put_change(changeset, :session_id, generate_session_id())
      _ -> changeset
    end
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end