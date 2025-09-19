defmodule Paperform2web.Documents do
  @moduledoc """
  The Documents context.
  """

  import Ecto.Query, warn: false
  alias Paperform2web.Repo
  alias Paperform2web.Documents.Document
  alias Paperform2web.DocumentProcessor
  alias Paperform2web.HtmlGenerator
  alias Paperform2web.Templates

  @doc """
  Returns the list of documents.
  """
  def list_documents do
    Repo.all(Document)
  end

  @doc """
  Gets a single document.
  """
  def get_document!(id), do: Repo.get!(Document, id)

  @doc """
  Gets a single document, returns nil if not found.
  """
  def get_document(id), do: Repo.get(Document, id)

  @doc """
  Creates a document and starts processing.
  """
  def create_document(file_params, model \\ "llama2", template_slug \\ "default") do
    # Get template by slug, fallback to default
    template = Templates.get_template_by_slug(template_slug) || Templates.get_default_template()
    
    case validate_and_save_file(file_params) do
      {:ok, file_path, filename, content_type} ->
        case DocumentProcessor.validate_file_format(content_type) do
          :ok ->
            attrs = %{
              filename: filename,
              file_path: file_path,
              content_type: content_type,
              model_used: model,
              template_id: template && template.id,
              theme: template_slug, # Keep theme for backward compatibility
              status: "uploaded",
              progress: 0
            }
            
            case create_document_record(attrs) do
              {:ok, document} ->
                DocumentProcessor.process_document_async(document.id, file_path, model)
                {:ok, document}
              {:error, changeset} ->
                File.rm(file_path)
                {:error, changeset}
            end
            
          {:error, reason} ->
            File.rm(file_path)
            {:error, reason}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Updates a document status and progress.
  """
  def update_document_status(document_id, status, progress, error_message \\ nil) do
    document = get_document!(document_id)
    attrs = %{status: status, progress: progress}
    attrs = if error_message, do: Map.put(attrs, :error_message, error_message), else: attrs

    case update_document(document, attrs) do
      {:ok, updated_document} ->
        # Broadcast status update via WebSocket
        broadcast_document_update(updated_document)
        {:ok, updated_document}
      error ->
        error
    end
  end

  @doc """
  Updates a document with processing results.
  """
  def update_document_with_results(document_id, processed_data, model, raw_response \\ nil) do
    document = get_document!(document_id)
    attrs = %{
      processed_data: processed_data,
      raw_response: raw_response,
      model_used: model,
      status: "completed",
      progress: 100
    }
    
    update_document(document, attrs)
  end

  @doc """
  Updates a document.
  """
  def update_document(%Document{} = document, attrs) do
    document
    |> Document.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a document's theme.
  """
  def update_document_theme(%Document{} = document, theme) do
    update_document(document, %{theme: theme})
  end

  @doc """
  Updates a document's title.
  """
  def update_document_title(%Document{} = document, title) do
    # Update the title in processed_data as well as document title field
    updated_processed_data = if document.processed_data do
      Map.put(document.processed_data, "title", title)
    else
      %{"title" => title}
    end
    
    attrs = %{
      processed_data: updated_processed_data
    }
    
    update_document(document, attrs)
  end

  @doc """
  Updates a document's form structure and regenerates processed data.
  """
  def update_form_structure(%Document{} = document, form_fields) do
    # Convert form fields to document sections format
    sections = Enum.with_index(form_fields, fn field, index ->
      %{
        "type" => determine_section_type(field["fieldType"]),
        "content" => field["label"],
        "metadata" => build_field_metadata(field),
        "formatting" => %{
          "alignment" => "left",
          "font_size" => "medium",
          "bold" => false,
          "italic" => false,
          "width" => field["width"] || "full"
        },
        "position" => %{"x" => 0, "y" => index * 50, "width" => 400, "height" => 30}
      }
    end)

    # Update processed_data with new form structure
    updated_processed_data = Map.merge(
      document.processed_data || %{},
      %{
        "content" => %{
          "sections" => sections
        },
        "metadata" => Map.merge(
          get_in(document.processed_data, ["metadata"]) || %{},
          %{
            "last_form_update" => DateTime.utc_now() |> DateTime.to_iso8601(),
            "form_fields_count" => length(form_fields)
          }
        )
      }
    )

    update_document(document, %{processed_data: updated_processed_data})
  end

  defp determine_section_type(field_type) do
    case field_type do
      "checkbox" -> "checkbox"
      "select" -> "select"
      "textarea" -> "textarea"
      "email" -> "email"
      "date" -> "date"
      _ -> "text"
    end
  end

  defp build_field_metadata(field) do
    base_metadata = %{}
    
    case field["fieldType"] do
      "select" -> 
        Map.put(base_metadata, "options", field["options"] || ["Option 1", "Option 2", "Option 3"])
      "checkbox" ->
        Map.put(base_metadata, "checked", false)
      _ -> 
        base_metadata
    end
  end

  @doc """
  Deletes a document and its associated file.
  """
  def delete_document(%Document{} = document) do
    if File.exists?(document.file_path) do
      File.rm(document.file_path)
    end
    
    Repo.delete(document)
  end

  @doc """
  Generates HTML from a processed document.
  """
  def generate_html(%Document{processed_data: nil}), do: "<p>Document not yet processed</p>"
  def generate_html(%Document{processed_data: processed_data, template_id: template_id, theme: theme, status: "completed"} = document) do
    # Always use theme-based CSS generation, ignore template database for now
    effective_theme = theme || "default"
    
    options = %{
      template: nil, # Force use of theme-based CSS
      theme: effective_theme
    }
    
    case HtmlGenerator.generate_html(processed_data, options) do
      {:ok, html} -> html
      {:error, _reason} -> "<p>Error generating HTML from processed data</p>"
    end
  end
  def generate_html(_document), do: "<p>Document processing not completed</p>"

  @doc """
  Generates HTML from a processed document with additional options.
  """
  def generate_html_with_options(%Document{processed_data: nil}, _options), do: "<p>Document not yet processed</p>"
  def generate_html_with_options(%Document{processed_data: processed_data, template_id: template_id, theme: theme, status: "completed"} = document, additional_options) do
    # Always use theme-based CSS generation, ignore template database for now
    # Use theme from additional_options if provided, otherwise fall back to document theme
    effective_theme = Map.get(additional_options, :theme, theme || "default")

    options = Map.merge(%{
      template: nil, # Force use of theme-based CSS
      theme: effective_theme
    }, additional_options)
    
    case HtmlGenerator.generate_html(processed_data, options) do
      {:ok, html} -> html
      {:error, _reason} -> "<p>Error generating HTML from processed data</p>"
    end
  end
  def generate_html_with_options(_document, _options), do: "<p>Document processing not completed</p>"

  defp create_document_record(attrs) do
    %Document{}
    |> Document.changeset(attrs)
    |> Repo.insert()
  end

  defp validate_and_save_file(%{"path" => temp_path, "filename" => filename} = _file_params) do
    content_type = get_content_type(filename)
    upload_dir = ensure_upload_directory()
    
    file_id = Ecto.UUID.generate()
    extension = Path.extname(filename)
    stored_filename = "#{file_id}#{extension}"
    destination_path = Path.join(upload_dir, stored_filename)
    
    case File.cp(temp_path, destination_path) do
      :ok ->
        {:ok, destination_path, filename, content_type}
      {:error, reason} ->
        {:error, "Failed to save file: #{reason}"}
    end
  end

  defp validate_and_save_file(_invalid_params) do
    {:error, "Invalid file parameters"}
  end

  defp ensure_upload_directory do
    upload_dir = Application.get_env(:paperform2web, :upload_directory, "uploads/")
    File.mkdir_p!(upload_dir)
    upload_dir
  end

  defp get_content_type(filename) do
    case Path.extname(filename) |> String.downcase() do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".bmp" -> "image/bmp"
      ".tiff" -> "image/tiff"
      ".tif" -> "image/tiff"
      ".pdf" -> "application/pdf"
      _ -> "application/octet-stream"
    end
  end

  defp broadcast_document_update(document) do
    # Use DocumentChannel to broadcast updates
    alias Paperform2webWeb.DocumentChannel
    DocumentChannel.broadcast_document_update(document.id, document)
  end
end