defmodule Paperform2webWeb.DocumentController do
  use Paperform2webWeb, :controller

  alias Paperform2web.Documents
  alias Paperform2web.Documents.Document
  alias Paperform2web.Templates

  action_fallback Paperform2webWeb.FallbackController

  def upload(conn, %{"file" => %Plug.Upload{} = upload, "model" => model, "theme" => theme}) do
    file_params = %{
      "path" => upload.path,
      "filename" => upload.filename
    }
    with {:ok, %Document{} = document} <- Documents.create_document(file_params, model, theme) do
      conn
      |> put_status(:created)
      |> render(:show, document: document)
    end
  end

  def upload(conn, %{"file" => %Plug.Upload{} = upload, "model" => model}) do
    file_params = %{
      "path" => upload.path,
      "filename" => upload.filename
    }
    with {:ok, %Document{} = document} <- Documents.create_document(file_params, model, "default") do
      conn
      |> put_status(:created)
      |> render(:show, document: document)
    end
  end

  def upload(conn, %{"file" => %Plug.Upload{} = upload}) do
    upload(conn, %{"file" => upload, "model" => "llama2", "theme" => "default"})
  end

  def show(conn, %{"id" => id}) do
    document = Documents.get_document!(id)
    render(conn, :show, document: document)
  end

  def index(conn, _params) do
    documents = Documents.list_documents()
    render(conn, :index, documents: documents)
  end

  def process_status(conn, %{"document_id" => id}) do
    document = Documents.get_document!(id)
    render(conn, :process_status, document: document)
  end

  def html_output(conn, %{"document_id" => id} = params) do
    document = Documents.get_document!(id)
    editing_mode = Map.get(params, "editing", "false") == "true"
    theme = Map.get(params, "theme", document.theme || "default")

    case document.status do
      "completed" ->
        html_content = Documents.generate_html_with_options(document, %{
          editing: editing_mode,
          document_id: id,
          theme: theme
        })
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, html_content)

      _ ->
        conn
        |> put_status(:accepted)
        |> json(%{message: "Document is still processing", status: document.status})
    end
  end

  def update_theme(conn, %{"document_id" => id, "theme" => theme}) do
    document = Documents.get_document!(id)
    
    case Documents.update_document_theme(document, theme) do
      {:ok, updated_document} ->
        conn
        |> render(:show, document: updated_document)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset})
    end
  end

  def list_templates(conn, _params) do
    templates = Templates.list_active_templates()
    conn
    |> json(%{data: templates})
  end

  def update_form_structure(conn, %{"document_id" => id, "form_fields" => form_fields}) do
    document = Documents.get_document!(id)
    
    case Documents.update_form_structure(document, form_fields) do
      {:ok, updated_document} ->
        conn
        |> render(:show, document: updated_document)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset})
    end
  end

  def update_title(conn, %{"document_id" => id, "title" => title}) do
    document = Documents.get_document!(id)

    case Documents.update_document_title(document, title) do
      {:ok, updated_document} ->
        conn
        |> render(:show, document: updated_document)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset})
    end
  end

  def update(conn, %{"id" => id} = params) do
    document = Documents.get_document!(id)

    # Handle different update scenarios based on what data is provided
    cond do
      # If both title and form_data are provided (from editing mode)
      Map.has_key?(params, "title") and Map.has_key?(params, "form_data") ->
        with {:ok, updated_document} <- Documents.update_document_title(document, params["title"]),
             {:ok, final_document} <- Documents.update_form_structure(updated_document, params["form_data"]) do
          conn
          |> render(:show, document: final_document)
        else
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: changeset})
        end

      # If only title is provided
      Map.has_key?(params, "title") ->
        case Documents.update_document_title(document, params["title"]) do
          {:ok, updated_document} ->
            conn
            |> render(:show, document: updated_document)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: changeset})
        end

      # If only form_data is provided
      Map.has_key?(params, "form_data") ->
        case Documents.update_form_structure(document, params["form_data"]) do
          {:ok, updated_document} ->
            conn
            |> render(:show, document: updated_document)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: changeset})
        end

      # If neither title nor form_data is provided, return error
      true ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "No valid update data provided"})
    end
  end

  def delete(conn, %{"id" => id}) do
    document = Documents.get_document!(id)

    case Documents.delete_document(document) do
      {:ok, _deleted_document} ->
        conn
        |> send_resp(:no_content, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset})
    end
  end

  ## Sharing Functions

  def create_share(conn, %{"document_id" => id} = params) do
    document = Documents.get_document!(id)

    share_params = %{
      "recipient_email" => params["recipient_email"],
      "recipient_name" => Map.get(params, "recipient_name"),
      "subject" => params["subject"],
      "message" => Map.get(params, "message"),
      "expires_at" => parse_expires_at(Map.get(params, "expires_at"))
    }

    case Documents.create_document_share(document, share_params) do
      {:ok, share} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            id: share.id,
            share_token: share.share_token,
            recipient_email: share.recipient_email,
            recipient_name: share.recipient_name,
            subject: share.subject,
            status: share.status,
            expires_at: share.expires_at,
            inserted_at: share.inserted_at
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to create share", details: changeset_errors_to_map(changeset)})
    end
  end

  def list_shares(conn, %{"document_id" => id}) do
    shares = Documents.list_document_shares(id)

    conn
    |> json(%{
      data: Enum.map(shares, fn share ->
        %{
          id: share.id,
          share_token: share.share_token,
          recipient_email: share.recipient_email,
          recipient_name: share.recipient_name,
          subject: share.subject,
          status: share.status,
          total_opens: share.total_opens,
          response_count: share.response_count,
          is_completed: share.is_completed,
          expires_at: share.expires_at,
          sent_at: share.sent_at,
          opened_at: share.opened_at,
          first_response_at: share.first_response_at,
          last_response_at: share.last_response_at,
          inserted_at: share.inserted_at
        }
      end)
    })
  end

  def view_shared_form(conn, %{"token" => token}) do
    case Documents.get_document_share_by_token(token) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Share not found"})

      share ->
        # Check if share has expired
        if share.expires_at && DateTime.compare(DateTime.utc_now(), share.expires_at) == :gt do
          conn
          |> put_status(:gone)
          |> json(%{error: "This share has expired"})
        else
          # Record the form open
          Documents.record_form_open(token)

          # Return the form HTML
          document = share.document

          if document.status == "completed" do
            html_content = Documents.generate_html_with_options(document, %{
              editing: false,
              shared: true,
              share_token: token
            })

            conn
            |> put_resp_content_type("text/html")
            |> send_resp(200, html_content)
          else
            conn
            |> put_status(:accepted)
            |> json(%{error: "Document is still processing", status: document.status})
          end
        end
    end
  end

  def submit_form_response(conn, %{"token" => token} = params) do
    response_data = Map.get(params, "response_data", %{})
    session_id = Map.get(params, "session_id")

    case Documents.submit_form_response(token, response_data, session_id) do
      {:ok, response} ->
        conn
        |> json(%{
          data: %{
            id: response.id,
            session_id: response.session_id,
            is_completed: response.is_completed,
            inserted_at: response.inserted_at
          },
          message: "Response submitted successfully"
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Share not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to submit response", details: changeset.errors})
    end
  end

  def view_share_analytics(conn, %{"token" => token}) do
    case Documents.get_share_analytics(token) do
      {:ok, analytics_data} ->
        conn
        |> json(%{
          data: %{
            share: %{
              id: analytics_data.share.id,
              recipient_email: analytics_data.share.recipient_email,
              total_opens: analytics_data.share.total_opens,
              response_count: analytics_data.share.response_count,
              is_completed: analytics_data.share.is_completed,
              sent_at: analytics_data.share.sent_at,
              first_response_at: analytics_data.share.first_response_at,
              last_response_at: analytics_data.share.last_response_at
            },
            analytics: Enum.map(analytics_data.analytics, fn item ->
              %{
                field_key: item.field_key,
                field_type: item.field_type,
                field_label: item.field_label,
                response_value: item.response_value,
                response_count: item.response_count,
                completion_rate: item.completion_rate
              }
            end),
            summary: %{
              total_responses: analytics_data.total_responses,
              completed_responses: analytics_data.completed_responses,
              completion_rate: if(analytics_data.total_responses > 0,
                do: analytics_data.completed_responses / analytics_data.total_responses,
                else: 0
              )
            }
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Share not found"})
    end
  end

  ## Private Helper Functions

  defp parse_expires_at(nil), do: nil
  defp parse_expires_at(""), do: nil
  defp parse_expires_at(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string <> "Z") do
      {:ok, datetime, _} -> datetime
      _ -> nil
    end
  end
  defp parse_expires_at(_), do: nil

  def test_submission(conn, %{"document_id" => id} = params) do
    document = Documents.get_document!(id)
    form_data = Map.get(params, "form_data", %{})

    # Log the test submission for development purposes
    require Logger
    Logger.info("📝 Test form submission for document #{id}")
    Logger.info("Form data: #{inspect(form_data, pretty: true)}")

    # Create a mock submission record for testing
    test_submission = %{
      id: Ecto.UUID.generate(),
      document_id: id,
      form_data: form_data,
      is_completed: Map.get(params, "is_completed", false),
      submitted_at: DateTime.utc_now(),
      submission_type: "test"
    }

    conn
    |> json(%{
      data: %{
        id: test_submission.id,
        is_completed: test_submission.is_completed,
        submitted_at: test_submission.submitted_at,
        field_count: map_size(form_data)
      },
      message: "Test submission received successfully"
    })
  end

  defp changeset_errors_to_map(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
