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
end
