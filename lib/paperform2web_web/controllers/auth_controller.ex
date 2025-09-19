defmodule Paperform2webWeb.AuthController do
  use Paperform2webWeb, :controller

  alias Paperform2web.OllamaClient

  @doc """
  Test Ollama connection and authentication
  """
  def test_connection(conn, _params) do
    case OllamaClient.validate_auth_config() do
      {:ok, message} ->
        case OllamaClient.test_connection() do
          {:ok, response} ->
            conn
            |> put_status(:ok)
            |> json(%{
              status: "success",
              auth_message: message,
              connection_test: "successful",
              ollama_response: response
            })
          
          {:error, error} ->
            conn
            |> put_status(:service_unavailable)
            |> json(%{
              status: "error",
              auth_message: message,
              connection_test: "failed",
              error: error
            })
        end
      
      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          auth_message: error,
          connection_test: "not_attempted"
        })
    end
  end

  @doc """
  Get current authentication configuration status (without sensitive data)
  """
  def auth_status(conn, _params) do
    case OllamaClient.validate_auth_config() do
      {:ok, message} ->
        conn
        |> json(%{
          status: "configured",
          message: message,
          auth_type: get_auth_type_display()
        })
      
      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          message: error,
          auth_type: get_auth_type_display()
        })
    end
  end

  @doc """
  List available Ollama models (tests authentication)
  """
  def list_models(conn, _params) do
    case OllamaClient.list_models() do
      {:ok, models} ->
        conn
        |> json(%{
          status: "success",
          models: models,
          count: length(models)
        })
      
      {:error, error} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{
          status: "error",
          message: error,
          hint: "Check your Ollama server connection and authentication settings"
        })
    end
  end

  defp get_auth_type_display do
    config = Application.get_env(:paperform2web, :ollama_auth, %{})
    auth_type = Map.get(config, :type, :none)
    
    case auth_type do
      :none -> "No authentication"
      :api_key -> "API Key authentication"
      :bearer -> "Bearer token authentication"  
      :basic -> "Basic authentication"
      _ -> "Unknown authentication type"
    end
  end
end