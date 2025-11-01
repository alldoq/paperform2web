defmodule Paperform2webWeb.UserAuthController do
  use Paperform2webWeb, :controller

  alias Paperform2web.Accounts
  alias Paperform2web.Mailer
  alias Paperform2web.Emails.UserEmail

  @doc """
  Register a new user
  """
  def register(conn, %{"name" => name, "email" => email, "password" => password}) do
    case Accounts.register_user(%{name: name, email: email, password: password}) do
      {:ok, user} ->
        # Send confirmation email
        send_confirmation_email(user)

        conn
        |> put_status(:created)
        |> json(%{
          status: "success",
          message: "Registration successful. Please check your email to confirm your account."
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_changeset_errors(changeset)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          error: "Registration failed",
          errors: errors
        })
    end
  end

  @doc """
  Login a user
  """
  def login(conn, %{"email" => email, "password" => password} = params) do
    remember_me = Map.get(params, "remember_me", false)

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> maybe_set_remember_cookie(user.id, remember_me)
        |> json(%{
          status: "success",
          message: "Login successful",
          user: %{
            id: user.id,
            name: user.name,
            email: user.email
          }
        })

      {:error, :not_confirmed} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          status: "error",
          error: "Please confirm your email before logging in. Check your inbox for the confirmation link."
        })

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          status: "error",
          error: "Invalid email or password"
        })
    end
  end

  @doc """
  Logout a user
  """
  def logout(conn, _params) do
    conn
    |> clear_session()
    |> delete_resp_cookie("remember_token")
    |> json(%{
      status: "success",
      message: "Logged out successfully"
    })
  end

  @doc """
  Confirm user email
  """
  def confirm_email(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _user} ->
        # Redirect to frontend login page with success message
        redirect(conn, external: "http://localhost:3000/login?confirmed=true")

      {:error, :invalid_token} ->
        # Redirect to frontend with error
        redirect(conn, external: "http://localhost:3000/login?error=invalid_token")

      {:error, :already_confirmed} ->
        # Redirect to frontend with already confirmed message
        redirect(conn, external: "http://localhost:3000/login?error=already_confirmed")
    end
  end

  @doc """
  Get current user
  """
  def current_user(conn, _params) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          status: "error",
          error: "Not authenticated"
        })

      user_id ->
        case Accounts.get_user(user_id) do
          nil ->
            conn
            |> clear_session()
            |> put_status(:unauthorized)
            |> json(%{
              status: "error",
              error: "User not found"
            })

          user ->
            conn
            |> json(%{
              status: "success",
              user: %{
                id: user.id,
                name: user.name,
                email: user.email,
                confirmed: !is_nil(user.confirmed_at)
              }
            })
        end
    end
  end

  # Private helper functions

  defp send_confirmation_email(user) do
    # Get the base URL from config or use a default
    base_url = Application.get_env(:paperform2web, :base_url, "http://localhost:4000")
    confirmation_url = "#{base_url}/confirm/#{user.confirmation_token}"

    user
    |> UserEmail.confirmation_email(confirmation_url)
    |> Mailer.deliver()
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        # Convert value to string, handling lists specially
        value_string = case value do
          list when is_list(list) -> inspect(list)
          _ -> to_string(value)
        end
        String.replace(acc, "%{#{key}}", value_string)
      end)
    end)
  end

  defp maybe_set_remember_cookie(conn, user_id, true) do
    # Set a remember token cookie that lasts 60 days
    token = generate_remember_token(user_id)

    conn
    |> put_resp_cookie("remember_token", token,
         max_age: 60 * 60 * 24 * 60, # 60 days
         http_only: true,
         secure: Application.get_env(:paperform2web, :env) == :prod,
         same_site: "Lax"
       )
  end

  defp maybe_set_remember_cookie(conn, _user_id, _), do: conn

  defp generate_remember_token(user_id) do
    # Simple implementation - in production you'd want to store these tokens
    # and validate them on each request
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64()
    |> then(&"#{user_id}:#{&1}")
  end
end
