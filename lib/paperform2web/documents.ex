defmodule Paperform2web.Documents do
  @moduledoc """
  The Documents context.
  """

  import Ecto.Query, warn: false
  alias Paperform2web.Repo
  alias Paperform2web.Documents.Document
  alias Paperform2web.Documents.DocumentShare
  alias Paperform2web.Documents.FormResponse
  alias Paperform2web.Documents.ResponseAnalytics
  alias Paperform2web.DocumentProcessor
  alias Paperform2web.HtmlGenerator
  alias Paperform2web.Templates
  alias Paperform2web.Mailer
  alias Paperform2web.Emails.ShareEmail
  require Logger

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
  def update_document_status(document_id, status, progress, status_message \\ nil) do
    document = get_document!(document_id)
    attrs = %{status: status, progress: progress}
    attrs = if status_message, do: Map.put(attrs, :status_message, status_message), else: attrs

    # Always update the document, but only broadcast on meaningful changes
    case update_document(document, attrs) do
      {:ok, updated_document} ->
        # Only broadcast if there's a meaningful change
        should_broadcast = document.status != status ||
                          abs((document.progress || 0) - progress) >= 5 || # Broadcast every 5% progress for page updates
                          document.status_message != status_message || # Always broadcast status message changes
                          status in ["completed", "failed"] # Always broadcast completion states

        Logger.info("📊 Document update check for #{document_id}: old_status=#{document.status}, new_status=#{status}, old_progress=#{document.progress}, new_progress=#{progress}, old_message=#{document.status_message}, new_message=#{status_message}, should_broadcast=#{should_broadcast}")

        if should_broadcast do
          broadcast_document_update(updated_document)
        end
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
    # Debug logging
    IO.puts("=== UPDATE_FORM_STRUCTURE DEBUG ===")
    IO.puts("Form fields received: #{inspect(form_fields)}")

    # Get existing sections
    existing_sections = get_in(document.processed_data, ["content", "sections"]) || []
    IO.puts("Existing sections count: #{length(existing_sections)}")

    # Convert form fields to document sections format
    # First, ensure all field IDs are unique
    unique_form_fields = ensure_unique_field_ids(form_fields)

    IO.puts("🔧 BACKEND DEBUG: Final unique field IDs: #{Enum.map(unique_form_fields, &(&1["id"])) |> inspect()}")

    new_form_sections = Enum.with_index(unique_form_fields, fn field, index ->
      # Handle both old and new data structure formats
      field_type = get_field_type(field)
      field_content = get_field_content(field)
      field_metadata = get_field_metadata(field)
      field_id = field["id"] || field["form_field_id"] || "field_#{index}"

      # Debug logging for radio fields
      if field_type == "radio" do
        IO.puts("📻 BACKEND PROCESSING RADIO FIELD:")
        IO.puts("  Field: #{inspect(field)}")
        IO.puts("  Type: #{field_type}")
        IO.puts("  Content: #{field_content}")
        IO.puts("  Metadata: #{inspect(field_metadata)}")
      end

      %{
        "type" => "form_input",  # Always use form_input for user-added fields
        "content" => field_content,
        "metadata" => Map.merge(field_metadata, %{
          "input_type" => field_type,
          "field_name" => get_in(field, ["metadata", "field_name"]) || field["fieldName"] || sanitize_field_name(field_content),
          "required" => get_in(field, ["metadata", "required"]) || field["required"] || false
        }),
        "formatting" => %{
          "alignment" => "left",
          "font_size" => "medium",
          "bold" => false,
          "italic" => false,
          "width" => field["width"] || "full"
        },
        "position" => %{"x" => 0, "y" => index * 50, "width" => 400, "height" => 30},
        "form_field_id" => field_id  # Mark as user-added form field
      }
    end)

    IO.puts("🔧 NEW FORM SECTIONS CREATED:")
    Enum.each(new_form_sections, fn section ->
      IO.puts("  Section type: #{section["type"]}, form_field_id: #{section["form_field_id"]}")
    end)

    # PROPER FIX: Only remove form sections that have form_field_id (user-added fields)
    # Keep original AI-processed form structure (labels, titles, etc.)

    # CORRECT APPROACH: Create a complete new sections array based on frontend ordering
    # This rebuilds the entire form structure in the order specified by the frontend

    # Create a mapping of field IDs to their new form sections
    new_sections_by_id = Enum.reduce(new_form_sections, %{}, fn section, acc ->
      field_id = section["form_field_id"]
      Map.put(acc, field_id, section)
    end)

    # Create a mapping to track which frontend fields we've processed
    frontend_field_ids = MapSet.new(Enum.map(unique_form_fields, fn field -> field["id"] end))

    # Build the final sections array respecting frontend order
    ordered_form_sections = Enum.map(unique_form_fields, fn field ->
      field_id = field["id"]
      Map.get(new_sections_by_id, field_id)
    end)
    |> Enum.filter(fn section -> section != nil end)

    # Keep only non-form sections that don't conflict with our ordered fields
    preserved_sections = Enum.filter(existing_sections, fn section ->
      !Map.has_key?(section, "form_field_id")
    end)

    # Final structure: preserved content + ordered form sections
    combined_sections = preserved_sections ++ ordered_form_sections

    IO.puts("Preserved sections count: #{length(preserved_sections)}")
    IO.puts("Ordered form sections count: #{length(ordered_form_sections)}")
    IO.puts("Frontend ordered field IDs: #{inspect(Enum.map(unique_form_fields, &(&1["id"])))}")

    IO.puts("=== ORDERED FORM STRUCTURE DEBUG ===")
    IO.puts("Total sections: #{length(combined_sections)}")
    IO.puts("Preserved sections: #{length(preserved_sections)}")
    IO.puts("Ordered form sections: #{length(ordered_form_sections)}")
    IO.puts("Final section order:")
    combined_sections
    |> Enum.take(15)
    |> Enum.with_index()
    |> Enum.each(fn {section, idx} ->
      section_type = section["type"]
      form_field_id = Map.get(section, "form_field_id", "N/A")
      content_preview = String.slice(section["content"] || "", 0, 40)
      IO.puts("  #{idx}: #{section_type} | #{form_field_id} | #{content_preview}...")
    end)
    IO.puts("=== END DEBUG ===")

    # Print a sample of new form sections for debugging
    if length(new_form_sections) > 0 do
      IO.puts("Sample new form section: #{inspect(Enum.at(new_form_sections, 0))}")
    end

    # Update processed_data with merged sections
    # For PDF documents, also update the first page's sections
    updated_processed_data = Map.merge(
      document.processed_data || %{},
      %{
        "content" => %{
          "sections" => combined_sections
        },
        "metadata" => Map.merge(
          get_in(document.processed_data, ["metadata"]) || %{},
          %{
            "last_form_update" => DateTime.utc_now() |> DateTime.to_iso8601(),
            "form_fields_count" => length(form_fields),
            "total_sections_count" => length(combined_sections)
          }
        )
      }
    )

    # For PDF multipage documents, also update the first page's sections
    final_processed_data = if updated_processed_data["document_type"] == "pdf_multipage" and
                             updated_processed_data["pages"] do
      pages = updated_processed_data["pages"]
      updated_first_page = if length(pages) > 0 do
        first_page = Enum.at(pages, 0)
        Map.put(first_page, "content", %{"sections" => combined_sections})
      end

      updated_pages = if updated_first_page do
        List.replace_at(pages, 0, updated_first_page)
      else
        pages
      end

      Map.put(updated_processed_data, "pages", updated_pages)
    else
      updated_processed_data
    end

    update_document(document, %{processed_data: final_processed_data})
  end

  @doc """
  Reorders fields in a document without creating new fields.
  Only updates the order/index of existing form fields.
  """
  def reorder_fields(%Document{} = document, field_order) do
    IO.puts("=== REORDER_FIELDS DEBUG ===")
    IO.puts("Field order received: #{inspect(field_order)}")

    # Get existing sections
    existing_sections = get_in(document.processed_data, ["content", "sections"]) || []
    IO.puts("Existing sections count: #{length(existing_sections)}")

    # Separate form fields from other content sections
    {form_sections, other_sections} = Enum.split_with(existing_sections, fn section ->
      Map.has_key?(section, "form_field_id")
    end)

    IO.puts("Form sections count: #{length(form_sections)}")
    IO.puts("Other sections count: #{length(other_sections)}")

    # Create a map of form sections by their ID for quick lookup
    form_sections_map = Enum.reduce(form_sections, %{}, fn section, acc ->
      field_id = section["form_field_id"]
      Map.put(acc, field_id, section)
    end)

    # Reorder form sections according to the provided field_order
    reordered_form_sections = Enum.map(field_order, fn %{"id" => field_id, "index" => new_index} ->
      case Map.get(form_sections_map, field_id) do
        nil ->
          IO.puts("Warning: Field ID #{field_id} not found in existing sections")
          nil
        section ->
          # Update the position y coordinate based on new index
          updated_position = Map.put(section["position"] || %{}, "y", new_index * 50)
          Map.put(section, "position", updated_position)
      end
    end)
    |> Enum.filter(& &1 != nil)  # Remove any nil entries

    IO.puts("Reordered form sections count: #{length(reordered_form_sections)}")

    # Combine other sections with reordered form sections
    combined_sections = other_sections ++ reordered_form_sections

    # Update the document structure
    updated_processed_data =
      document.processed_data
      |> put_in(["content", "sections"], combined_sections)

    # Also update pages if they exist (for multi-page documents)
    final_processed_data = if Map.has_key?(updated_processed_data, "pages") do
      pages = updated_processed_data["pages"] || []
      updated_first_page = if length(pages) > 0 do
        first_page = Enum.at(pages, 0)
        Map.put(first_page, "content", %{"sections" => combined_sections})
      end

      updated_pages = if updated_first_page do
        [updated_first_page | Enum.drop(pages, 1)]
      else
        pages
      end

      Map.put(updated_processed_data, "pages", updated_pages)
    else
      updated_processed_data
    end

    IO.puts("=== END REORDER DEBUG ===")

    update_document(document, %{processed_data: final_processed_data})
  end

  defp determine_section_type(field_type) do
    case field_type do
      "checkbox" -> "checkbox"
      "radio" -> "radio"
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
      "radio" ->
        Map.put(base_metadata, "options", field["options"] || ["Option 1", "Option 2", "Option 3"])
      "checkbox" ->
        Map.put(base_metadata, "checked", false)
      _ ->
        base_metadata
    end
  end

  # Helper functions to extract field data from different structures
  defp get_field_type(field) do
    # Try different possible locations for field type
    get_in(field, ["metadata", "input_type"]) ||  # New structure from JS
    field["fieldType"] ||                         # Old structure
    field["type"] ||                              # Alternative
    "text"                                        # Default fallback
  end

  defp get_field_content(field) do
    # Try different possible locations for field content/label
    field["content"] ||                           # New structure from JS
    field["label"] ||                             # Old structure
    field["title"] ||                             # Alternative
    "Untitled Field"                              # Default fallback
  end

  defp get_field_metadata(field) do
    # Extract existing metadata or create empty map
    existing_metadata = field["metadata"] || %{}

    # Add options for select/radio fields if not already present
    field_type = get_field_type(field)
    case field_type do
      "select" ->
        # Check for options in metadata first, then fallback to field level, then default
        options = existing_metadata["options"] || field["options"] || ["Option 1", "Option 2", "Option 3"]
        Map.put(existing_metadata, "options", options)
      "radio" ->
        # Check for options in metadata first, then fallback to field level, then default
        options = existing_metadata["options"] || field["options"] || ["Option 1", "Option 2", "Option 3"]
        Map.put(existing_metadata, "options", options)
      "checkbox" ->
        Map.put_new(existing_metadata, "checked", false)
      _ ->
        existing_metadata
    end
  end

  defp sanitize_field_name(content) do
    content
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/, "_")
    |> String.replace(~r/_+/, "_")
    |> String.trim("_")
    |> case do
      "" -> "field"
      name -> name
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

  defp ensure_unique_field_ids(form_fields) do
    {result, _} = Enum.reduce(form_fields, {[], MapSet.new()}, fn field, {acc_fields, used_ids} ->
      original_id = field["id"]
      unique_id = find_unique_id(original_id, used_ids)

      if original_id != unique_id do
        IO.puts("🔧 BACKEND DEBUG: Changed duplicate ID '#{original_id}' to '#{unique_id}'")
      end

      updated_field = Map.put(field, "id", unique_id)
      {[updated_field | acc_fields], MapSet.put(used_ids, unique_id)}
    end)

    Enum.reverse(result)
  end

  defp find_unique_id(original_id, used_ids) do
    find_unique_id(original_id, used_ids, 0)
  end

  defp find_unique_id(original_id, used_ids, counter) do
    candidate_id = if counter == 0 do
      original_id
    else
      "#{original_id}_#{counter}"
    end

    if MapSet.member?(used_ids, candidate_id) do
      find_unique_id(original_id, used_ids, counter + 1)
    else
      candidate_id
    end
  end

  defp broadcast_document_update(document) do
    # Use DocumentChannel to broadcast updates
    alias Paperform2webWeb.DocumentChannel
    DocumentChannel.broadcast_document_update(document.id, document)
  end

  ## Document Sharing Functions

  @doc """
  Creates a document share and sends an email invitation.
  """
  def create_document_share(document, attrs) do
    %DocumentShare{}
    |> DocumentShare.changeset(Map.put(attrs, "document_id", document.id))
    |> Repo.insert()
    |> case do
      {:ok, share} ->
        # Send email invitation
        send_share_email(share, document)
        {:ok, share}
      error ->
        error
    end
  end

  @doc """
  Gets a document share by token.
  """
  def get_document_share_by_token(token) do
    Repo.get_by(DocumentShare, share_token: token)
    |> Repo.preload(:document)
  end

  @doc """
  Lists all shares for a document.
  """
  def list_document_shares(document_id) do
    from(s in DocumentShare,
      where: s.document_id == ^document_id,
      order_by: [desc: s.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Records that a shared form was opened.
  """
  def record_form_open(share_token) do
    case get_document_share_by_token(share_token) do
      nil ->
        {:error, :not_found}

      share ->
        now = DateTime.utc_now()

        updates = %{
          status: "opened",
          total_opens: share.total_opens + 1
        }

        # Set first open time if not already set
        updates = if is_nil(share.opened_at) do
          Map.put(updates, :opened_at, now)
        else
          updates
        end

        share
        |> DocumentShare.changeset(updates)
        |> Repo.update()
    end
  end

  @doc """
  Submits a form response.
  """
  def submit_form_response(share_token, response_data, session_id \\ nil) do
    case get_document_share_by_token(share_token) do
      nil ->
        {:error, :not_found}

      share ->
        session_id = session_id || generate_session_id()

        attrs = %{
          "document_share_id" => share.id,
          "session_id" => session_id,
          "form_data" => response_data,
          "is_completed" => Map.get(response_data, "is_completed", false),
          "completion_time_seconds" => Map.get(response_data, "completion_time_seconds")
        }

        case create_form_response(attrs) do
          {:ok, response} ->
            # Update share statistics
            update_share_statistics(share, response)

            # Update analytics
            update_response_analytics(share, response_data)

            {:ok, response}
          error ->
            error
        end
    end
  end

  @doc """
  Creates a form response.
  """
  def create_form_response(attrs) do
    %FormResponse{}
    |> FormResponse.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets share analytics data.
  """
  def get_share_analytics(share_token) do
    case get_document_share_by_token(share_token) do
      nil ->
        {:error, :not_found}

      share ->
        analytics = from(a in ResponseAnalytics,
          where: a.document_share_id == ^share.id,
          order_by: [asc: a.field_key]
        )
        |> Repo.all()

        responses = from(r in FormResponse,
          where: r.document_share_id == ^share.id,
          order_by: [desc: r.inserted_at]
        )
        |> Repo.all()

        {:ok, %{
          share: share,
          analytics: analytics,
          responses: responses,
          total_responses: length(responses),
          completed_responses: Enum.count(responses, & &1.is_completed)
        }}
    end
  end

  ## Private Helper Functions

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  defp send_share_email(share, document) do
    # Create and send email using Swoosh
    email = ShareEmail.form_invitation(share, document)

    case Mailer.deliver(email) do
      {:ok, _result} ->
        Logger.info("📧 Email sent successfully to #{share.recipient_email}")

        # Update share status to sent
        share
        |> DocumentShare.changeset(%{status: "sent", sent_at: DateTime.utc_now()})
        |> Repo.update()

      {:error, reason} ->
        Logger.error("📧 Failed to send email to #{share.recipient_email}: #{inspect(reason)}")

        # Update share status to failed
        share
        |> DocumentShare.changeset(%{status: "failed"})
        |> Repo.update()
    end
  end

  defp update_share_statistics(share, response) do
    now = DateTime.utc_now()

    updates = %{
      response_count: share.response_count + 1
    }

    # Set first response time if not already set
    updates = if is_nil(share.first_response_at) do
      Map.put(updates, :first_response_at, now)
    else
      updates
    end

    # Always update last response time
    updates = Map.put(updates, :last_response_at, now)

    # Update completion status
    updates = if response.is_completed do
      Map.put(updates, :is_completed, true)
    else
      updates
    end

    share
    |> DocumentShare.changeset(updates)
    |> Repo.update()
  end

  defp update_response_analytics(share, response_data) do
    # Extract field responses and update analytics
    form_data = Map.get(response_data, "form_data", %{})

    Enum.each(form_data, fn {field_key, field_data} ->
      field_type = Map.get(field_data, "type", "text")
      field_label = Map.get(field_data, "label", field_key)
      response_value = to_string(Map.get(field_data, "value", ""))

      # Upsert analytics record
      attrs = %{
        "document_share_id" => share.id,
        "field_key" => field_key,
        "field_type" => field_type,
        "field_label" => field_label,
        "response_value" => response_value,
        "response_count" => 1
      }

      case Repo.get_by(ResponseAnalytics,
        document_share_id: share.id,
        field_key: field_key,
        response_value: response_value
      ) do
        nil ->
          %ResponseAnalytics{}
          |> ResponseAnalytics.changeset(attrs)
          |> Repo.insert()

        existing ->
          existing
          |> ResponseAnalytics.changeset(%{"response_count" => existing.response_count + 1})
          |> Repo.update()
      end
    end)
  end
end