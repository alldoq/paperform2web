defmodule Paperform2webWeb.Router do
  use Paperform2webWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Paperform2webWeb do
    pipe_through :api
    
    resources "/documents", DocumentController, only: [:index, :show, :delete] do
      get "/status", DocumentController, :process_status
      get "/html", DocumentController, :html_output
      patch "/theme", DocumentController, :update_theme
      patch "/form_structure", DocumentController, :update_form_structure
      patch "/title", DocumentController, :update_title
      post "/share", DocumentController, :create_share
      get "/shares", DocumentController, :list_shares
      post "/test-submission", DocumentController, :test_submission
    end
    
    post "/upload", DocumentController, :upload
    
    # Templates endpoint
    get "/templates", DocumentController, :list_templates
    
    # Shared form access (public endpoints)
    get "/share/:token", DocumentController, :view_shared_form
    post "/share/:token/response", DocumentController, :submit_form_response
    get "/share/:token/analytics", DocumentController, :view_share_analytics

    # Authentication and health check endpoints
    get "/auth/status", AuthController, :auth_status
    get "/auth/test", AuthController, :test_connection
    get "/models", AuthController, :list_models
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
