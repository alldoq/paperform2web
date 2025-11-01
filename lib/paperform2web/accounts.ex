defmodule Paperform2web.Accounts do
  @moduledoc """
  The Accounts context for user management and authentication.
  """

  alias Paperform2web.Repo
  alias Paperform2web.Accounts.User

  @doc """
  Registers a new user and generates a confirmation token.
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> put_confirmation_token()
    |> Repo.insert()
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by id.
  """
  def get_user(id) when is_binary(id) do
    Repo.get(User, id)
  end

  @doc """
  Authenticates a user by email and password.
  Returns {:ok, user} if credentials are valid and user is confirmed.
  """
  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    cond do
      user && User.verify_password(user, password) ->
        if user.confirmed_at do
          {:ok, user}
        else
          {:error, :not_confirmed}
        end

      user ->
        # Run dummy check to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      true ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Confirms a user's email using the confirmation token.
  """
  def confirm_user(token) do
    case get_user_by_confirmation_token(token) do
      nil ->
        {:error, :invalid_token}

      user ->
        if user.confirmed_at do
          {:error, :already_confirmed}
        else
          user
          |> User.confirm_changeset()
          |> Repo.update()
        end
    end
  end

  @doc """
  Gets a user by confirmation token.
  """
  def get_user_by_confirmation_token(token) when is_binary(token) do
    Repo.get_by(User, confirmation_token: token)
  end

  # Private functions

  defp put_confirmation_token(changeset) do
    if changeset.valid? do
      token = generate_token()
      changeset
      |> Ecto.Changeset.put_change(:confirmation_token, token)
      |> Ecto.Changeset.put_change(:confirmation_sent_at, DateTime.utc_now() |> DateTime.truncate(:second))
    else
      changeset
    end
  end

  defp generate_token do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64()
    |> binary_part(0, 32)
  end
end
