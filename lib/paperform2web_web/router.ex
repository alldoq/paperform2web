defmodule Paperform2webWeb.Router do
  use Paperform2webWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :api_protected do
    plug :accepts, ["json"]
    plug :fetch_session
    plug Paperform2webWeb.Plugs.RequireAuth
  end

  # Public confirmation route (outside /api scope)
  scope "/", Paperform2webWeb do
    get "/confirm/:token", UserAuthController, :confirm_email
  end

  # Public API routes (no authentication required)
  scope "/api", Paperform2webWeb do
    pipe_through :api

    # User authentication endpoints
    post "/auth/register", UserAuthController, :register
    post "/auth/login", UserAuthController, :login

    # Public document viewing (allows viewing uploaded documents without login)
    get "/documents/:id/status", DocumentController, :process_status
    get "/documents/:id/html", DocumentController, :html_output
    get "/documents/:id/form-data", DocumentController, :form_data

    # Shared form access (public endpoints)
    get "/share/:token", DocumentController, :view_shared_form
    get "/share/:token/data", DocumentController, :get_shared_form_data
    post "/share/:token/response", DocumentController, :submit_form_response
    get "/share/:token/analytics", DocumentController, :view_share_analytics
  end

  # Protected API routes (authentication required)
  scope "/api", Paperform2webWeb do
    pipe_through :api_protected

    # Upload endpoint (requires authentication)
    post "/upload", DocumentController, :upload

    resources "/documents", DocumentController, only: [:index, :show, :delete, :update] do
      patch "/theme", DocumentController, :update_theme
      patch "/form_structure", DocumentController, :update_form_structure
      post "/reorder-fields", DocumentController, :reorder_fields
      patch "/title", DocumentController, :update_title
      post "/share", DocumentController, :create_share
      get "/shares", DocumentController, :list_shares
      get "/analytics", DocumentController, :view_document_analytics
      get "/responses", DocumentController, :list_document_responses
      post "/test-submission", DocumentController, :test_submission
    end

    # Templates endpoint
    get "/templates", DocumentController, :list_templates

    # Ollama authentication and health check endpoints
    get "/auth/status", AuthController, :auth_status
    get "/auth/test", AuthController, :test_connection
    get "/models", AuthController, :list_models

    # User authenticated endpoints
    post "/auth/logout", UserAuthController, :logout
    get "/auth/me", UserAuthController, :current_user
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:paperform2web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: Paperform2webWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
