import Config

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Req

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.

# Configure Ollama client for production
# Use environment variables for security
config :paperform2web, :ollama_url, System.get_env("OLLAMA_URL") || "http://localhost:11434"

# Configure Ollama authentication for production
# Use environment variables for sensitive credentials
config :paperform2web, :ollama_auth, %{
  type: String.to_existing_atom(System.get_env("OLLAMA_AUTH_TYPE") || "none"),
  api_key: System.get_env("OLLAMA_API_KEY"),
  token: System.get_env("OLLAMA_BEARER_TOKEN"),
  username: System.get_env("OLLAMA_USERNAME"),
  password: System.get_env("OLLAMA_PASSWORD"),
  custom_header: System.get_env("OLLAMA_CUSTOM_HEADER")
}

# Configure upload directory for production
config :paperform2web, :upload_directory, System.get_env("UPLOAD_DIRECTORY") || "/app/uploads/"
