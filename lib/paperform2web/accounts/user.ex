defmodule Paperform2web.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :confirmed_at, :utc_datetime
    field :confirmation_token, :string
    field :confirmation_sent_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for registration
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email, :password])
    |> validate_email()
    |> validate_password()
    |> unique_constraint(:email)
  end

  @doc """
  Changeset for email confirmation
  """
  def confirm_changeset(user) do
    change(user, %{
      confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second),
      confirmation_token: nil
    })
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email address")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Paperform2web.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> maybe_hash_password()
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Verifies the password
  """
  def verify_password(user, password) do
    Bcrypt.verify_pass(password, user.password_hash)
  end
end
