defmodule Paperform2web.DocumentProcessor do
  @moduledoc """
  Processes document images and PDFs using Ollama AI and converts them to standardized JSON format.
  """

  alias Paperform2web.OllamaClient
  alias Paperform2web.Documents
  alias Paperform2web.PdfProcessor
  require Logger

  def process_document_async(document_id, file_path, model \\ "llama2") do
    Task.start(fn -> 
      process_document_sync(document_id, file_path, model)
    end)
  end

  def process_document_sync(document_id, file_path, model) do
    Logger.info("Starting document processing for document #{document_id} with model #{model}")

    Documents.update_document_status(document_id, "processing", 10)

    # Check if the file is a PDF
    case determine_file_type(file_path) do
      :pdf ->
        process_pdf_document(document_id, file_path, model)
      :image ->
        process_image_document(document_id, file_path, model)
      {:error, error} ->
        Logger.error("Failed to determine file type for document #{document_id}: #{error}")
        Documents.update_document_status(document_id, "failed", 0, "Failed to determine file type: #{error}")
        {:error, error}
    end
  end

  defp process_pdf_document(document_id, file_path, model) do
    Logger.info("Processing PDF document #{document_id}")
    Documents.update_document_status(document_id, "processing", 20)

    case PdfProcessor.process_pdf(file_path) do
      {:ok, %{page_count: page_count, page_paths: page_paths, output_dir: output_dir}} ->
        Logger.info("PDF split into #{page_count} pages for document #{document_id}")
        Documents.update_document_status(document_id, "processing", 40)

        # Process each page individually
        page_results = process_pdf_pages(page_paths, model, document_id)

        # Cleanup temporary files
        PdfProcessor.cleanup_temp_files(output_dir)

        case combine_page_results(page_results) do
          {:ok, combined_data} ->
            Logger.info("PDF document #{document_id} processed successfully")
            Documents.update_document_with_results(document_id, combined_data, model, "PDF processed with #{page_count} pages")
            Documents.update_document_status(document_id, "completed", 100)
            {:ok, combined_data}
          {:error, error} ->
            Logger.error("Failed to combine page results for document #{document_id}: #{error}")
            Documents.update_document_status(document_id, "failed", 0, "Failed to combine page results: #{error}")
            {:error, error}
        end

      {:error, error} ->
        Logger.error("Failed to process PDF for document #{document_id}: #{error}")
        Documents.update_document_status(document_id, "failed", 0, "Failed to process PDF: #{error}")
        {:error, error}
    end
  end

  defp process_image_document(document_id, file_path, model) do
    case read_image_file(file_path) do
      {:ok, image_data} ->
        Documents.update_document_status(document_id, "processing", 30)

        case OllamaClient.process_document(image_data, model) do
          {:ok, {processed_data, raw_response}} ->
            Logger.info("Document #{document_id} processed successfully")
            Documents.update_document_with_results(document_id, processed_data, model, raw_response)
            Documents.update_document_status(document_id, "completed", 100)
            {:ok, processed_data}

          {:error, error} ->
            error_message = case error do
              %Jason.DecodeError{} -> "AI returned invalid JSON response"
              binary when is_binary(binary) -> binary
              other -> inspect(other)
            end
            Logger.error("Failed to process document #{document_id}: #{error_message}")
            Documents.update_document_status(document_id, "failed", 0, error_message)
            {:error, error_message}
        end

      {:error, error} ->
        Logger.error("Failed to read image file for document #{document_id}: #{error}")
        Documents.update_document_status(document_id, "failed", 0, "Failed to read image file: #{error}")
        {:error, error}
    end
  end

  defp process_pdf_pages(page_paths, model, document_id) do
    total_pages = length(page_paths)

    page_paths
    |> Enum.with_index(1)
    |> Enum.map(fn {page_info, index} ->
      Logger.info("Processing page #{index}/#{total_pages} for document #{document_id}")

      # Update progress with current page info
      progress = 40 + trunc((index / total_pages) * 50)
      page_status = "Processing page #{index} of #{total_pages}"
      Documents.update_document_status(document_id, "processing", progress, page_status)

      case read_image_file(page_info.file_path) do
        {:ok, image_data} ->
          case OllamaClient.process_document(image_data, model) do
            {:ok, {processed_data, _raw_response}} ->
              Logger.info("Completed processing page #{index}/#{total_pages} for document #{document_id}")
              completed_page_status = "Completed page #{index} of #{total_pages}"
              Documents.update_document_status(document_id, "processing", progress, completed_page_status)
              {:ok, %{page_number: page_info.page_number, data: processed_data}}
            {:error, error} ->
              error_message = case error do
                %Jason.DecodeError{} -> "AI returned invalid JSON response"
                binary when is_binary(binary) -> binary
                other -> inspect(other)
              end
              Logger.error("Failed to process page #{page_info.page_number}: #{error_message}")
              {:error, "Failed to process page #{page_info.page_number}: #{error_message}"}
          end
        {:error, error} ->
          {:error, "Failed to read page #{page_info.page_number}: #{error}"}
      end
    end)
  end

  defp combine_page_results(page_results) do
    # Check if all pages processed successfully
    case Enum.find(page_results, fn result -> match?({:error, _}, result) end) do
      {:error, error} ->
        {:error, error}
      nil ->
        # All pages processed successfully, combine them
        pages_data = page_results
        |> Enum.map(fn {:ok, page_result} -> page_result end)
        |> Enum.sort_by(& &1.page_number)

        combined_data = %{
          "document_type" => "pdf_multipage",
          "page_count" => length(pages_data),
          "pages" => Enum.map(pages_data, fn page ->
            Map.put(page.data, "page_number", page.page_number)
          end),
          "content" => combine_page_content(pages_data),
          "metadata" => %{
            "processing_type" => "pdf_split",
            "total_pages" => length(pages_data),
            "processed_at" => DateTime.utc_now() |> DateTime.to_iso8601()
          }
        }

        {:ok, combined_data}
    end
  end

  defp combine_page_content(pages_data) do
    all_sections = pages_data
    |> Enum.flat_map(fn page ->
      case page.data do
        %{"content" => %{"sections" => sections}} when is_list(sections) ->
          Enum.map(sections, fn section ->
            Map.put(section, "page_number", page.page_number)
          end)
        _ ->
          []
      end
    end)

    %{"sections" => all_sections}
  end

  defp determine_file_type(file_path) do
    case Path.extname(file_path) |> String.downcase() do
      ".pdf" -> :pdf
      ext when ext in [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff"] -> :image
      _ ->
        # Fallback: try to determine by file content
        case File.open(file_path, [:read, :binary], fn file ->
          IO.binread(file, 4)
        end) do
          {:ok, <<"%PDF">>} -> :pdf
          {:ok, _} -> :image  # Assume image if not PDF
          {:error, reason} -> {:error, "Cannot read file: #{reason}"}
        end
    end
  end

  def validate_processed_data(processed_data) do
    required_fields = ["document_type", "content", "metadata"]
    
    case validate_json_structure(processed_data, required_fields) do
      :ok -> 
        validate_content_structure(processed_data["content"])
      error -> 
        error
    end
  end

  defp validate_json_structure(data, required_fields) when is_map(data) do
    missing_fields = Enum.filter(required_fields, &(not Map.has_key?(data, &1)))
    
    case missing_fields do
      [] -> :ok
      fields -> {:error, "Missing required fields: #{Enum.join(fields, ", ")}"}
    end
  end
  
  defp validate_json_structure(_data, _required_fields) do
    {:error, "Processed data must be a JSON object"}
  end

  defp validate_content_structure(%{"sections" => sections}) when is_list(sections) do
    case validate_sections(sections) do
      [] -> :ok
      errors -> {:error, "Section validation errors: #{Enum.join(errors, ", ")}"}
    end
  end
  
  defp validate_content_structure(_content) do
    {:error, "Content must contain a 'sections' array"}
  end

  defp validate_sections(sections) do
    sections
    |> Enum.with_index()
    |> Enum.flat_map(fn {section, index} ->
      validate_section(section, index)
    end)
  end

  defp validate_section(section, index) do
    errors = []
    
    errors = if Map.has_key?(section, "type"), do: errors, else: ["Section #{index}: missing 'type' field" | errors]
    errors = if Map.has_key?(section, "content"), do: errors, else: ["Section #{index}: missing 'content' field" | errors]
    
    if Map.has_key?(section, "type") do
      valid_types = ["header", "paragraph", "list", "table", "form_field"]
      if section["type"] in valid_types do
        errors
      else
        ["Section #{index}: invalid type '#{section["type"]}'" | errors]
      end
    else
      errors
    end
  end

  defp read_image_file(file_path) do
    case File.read(file_path) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, "File read error: #{reason}"}
    end
  end

  def get_supported_formats do
    image_formats = ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/bmp", "image/tiff"]
    pdf_formats = PdfProcessor.get_supported_formats()
    image_formats ++ pdf_formats
  end

  def validate_file_format(content_type) do
    image_formats = ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/bmp", "image/tiff"]

    cond do
      content_type in image_formats -> :ok
      content_type in PdfProcessor.get_supported_formats() -> :ok
      true -> {:error, "Unsupported file format: #{content_type}. Supported formats: #{Enum.join(get_supported_formats(), ", ")}"}
    end
  end
end