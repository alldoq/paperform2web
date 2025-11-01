defmodule Paperform2webWeb.Plugs.RequireAuth do
  @moduledoc """
  Plug to ensure the user is authenticated before accessing a resource.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Paperform2web.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          status: "error",
          error: "Authentication required"
        })
        |> halt()

      user_id ->
        case Accounts.get_user(user_id) do
          nil ->
            # User in session doesn't exist - clear session and deny access
            conn
            |> clear_session()
            |> put_status(:unauthorized)
            |> json(%{
              status: "error",
              error: "Invalid session"
            })
            |> halt()

          user ->
            # User is authenticated - add to conn.assigns for controller access
            assign(conn, :current_user, user)
        end
    end
  end

  @doc """
  Helper function to get the current user from conn.assigns
  """
  def current_user(conn) do
    Map.get(conn.assigns, :current_user)
  end
end
