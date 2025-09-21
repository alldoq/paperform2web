defmodule Paperform2web.Documents.DocumentShare do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "document_shares" do
    field :share_token, :string
    field :recipient_email, :string
    field :recipient_name, :string
    field :subject, :string
    field :message, :string
    field :status, :string, default: "pending"
    field :expires_at, :utc_datetime
    field :sent_at, :utc_datetime
    field :opened_at, :utc_datetime
    field :first_response_at, :utc_datetime
    field :last_response_at, :utc_datetime
    field :total_opens, :integer, default: 0
    field :unique_opens, :integer, default: 0
    field :response_count, :integer, default: 0
    field :is_completed, :boolean, default: false
    field :metadata, :map

    belongs_to :document, Paperform2web.Documents.Document
    has_many :form_responses, Paperform2web.Documents.FormResponse
    has_many :response_analytics, Paperform2web.Documents.ResponseAnalytics

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document_share, attrs) do
    document_share
    |> cast(attrs, [
      :share_token,
      :recipient_email,
      :recipient_name,
      :subject,
      :message,
      :status,
      :expires_at,
      :sent_at,
      :opened_at,
      :first_response_at,
      :last_response_at,
      :total_opens,
      :unique_opens,
      :response_count,
      :is_completed,
      :metadata,
      :document_id
    ])
    |> put_share_token()
    |> validate_required([:share_token, :recipient_email, :document_id])
    |> validate_email(:recipient_email)
    |> validate_inclusion(:status, ["pending", "sent", "opened", "responded", "completed", "expired", "failed"])
    |> unique_constraint(:share_token)
  end

  defp validate_email(changeset, field) do
    validate_format(changeset, field, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must have the @ sign and no spaces")
  end

  defp put_share_token(changeset) do
    case get_field(changeset, :share_token) do
      nil -> put_change(changeset, :share_token, generate_share_token())
      _ -> changeset
    end
  end

  defp generate_share_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end