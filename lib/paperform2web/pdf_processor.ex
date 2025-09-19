defmodule Paperform2web.PdfProcessor do
  @moduledoc """
  Handles PDF processing, including splitting PDFs into individual pages as images.
  """

  require Logger

  @max_pages 5
  @supported_formats ["application/pdf"]

  def process_pdf(file_path, output_dir \\ nil) do
    output_dir = output_dir || create_temp_dir()

    with :ok <- validate_pdf(file_path),
         {:ok, page_count} <- get_page_count(file_path),
         :ok <- validate_page_count(page_count),
         {:ok, page_paths} <- split_pdf_to_images(file_path, output_dir, page_count) do
      {:ok, %{
        page_count: page_count,
        page_paths: page_paths,
        output_dir: output_dir
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_file_format(content_type) do
    if content_type in @supported_formats do
      :ok
    else
      {:error, "Unsupported file format: #{content_type}. Only PDF files are supported."}
    end
  end

  def get_supported_formats, do: @supported_formats

  defp validate_pdf(file_path) do
    case File.exists?(file_path) do
      true -> :ok
      false -> {:error, "PDF file not found: #{file_path}"}
    end
  end

  defp get_page_count(file_path) do
    case Porcelain.exec("pdfinfo", [file_path]) do
      %{out: output, status: 0} ->
        case Regex.run(~r/Pages:\s+(\d+)/, output) do
          [_, page_count_str] ->
            {:ok, String.to_integer(page_count_str)}
          nil ->
            {:error, "Could not determine page count from PDF"}
        end
      %{err: error, status: _} ->
        {:error, "Failed to get PDF info: #{error}"}
    end
  end

  defp validate_page_count(page_count) do
    cond do
      page_count <= 0 ->
        {:error, "PDF appears to be empty"}
      page_count > @max_pages ->
        {:error, "PDF has too many pages (#{page_count}). Maximum allowed is #{@max_pages} pages."}
      true ->
        :ok
    end
  end

  defp split_pdf_to_images(file_path, output_dir, page_count) do
    Logger.info("Splitting PDF #{file_path} into #{page_count} pages")

    # Use pdftoppm to convert PDF pages to PNG images
    # Format: page-001.png, page-002.png, etc.
    output_prefix = Path.join(output_dir, "page")

    case Porcelain.exec("pdftoppm", [
      "-png",
      "-r", "150", # 150 DPI for good quality
      file_path,
      output_prefix
    ]) do
      %{status: 0} ->
        # Collect all generated page files
        page_paths = collect_page_files(output_dir, page_count)
        {:ok, page_paths}
      %{err: error, status: _} ->
        {:error, "Failed to convert PDF to images: #{error}"}
    end
  end

  defp collect_page_files(output_dir, page_count) do
    1..page_count
    |> Enum.map(fn page_num ->
      # pdftoppm creates files with format: page-001.png, page-002.png, etc.
      page_file = "page-#{String.pad_leading(Integer.to_string(page_num), 3, "0")}.png"
      page_path = Path.join(output_dir, page_file)

      case File.exists?(page_path) do
        true ->
          {:ok, %{
            page_number: page_num,
            file_path: page_path,
            filename: page_file
          }}
        false ->
          {:error, "Generated page file not found: #{page_path}"}
      end
    end)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, page_info}, {:ok, acc} -> {:cont, {:ok, [page_info | acc]}}
      {:error, reason}, _ -> {:halt, {:error, reason}}
    end)
    |> case do
      {:ok, pages} -> Enum.reverse(pages)
      error -> error
    end
  end

  defp create_temp_dir do
    {:ok, temp_dir} = Temp.mkdir("pdf_processing")
    temp_dir
  end

  def cleanup_temp_files(output_dir) do
    case File.rm_rf(output_dir) do
      {:ok, _} ->
        Logger.info("Cleaned up temporary PDF processing files in #{output_dir}")
        :ok
      {:error, reason} ->
        Logger.warning("Failed to clean up temporary files in #{output_dir}: #{reason}")
        {:error, reason}
    end
  end

  def is_pdf_file?(filename) when is_binary(filename) do
    filename
    |> String.downcase()
    |> String.ends_with?(".pdf")
  end

  def is_pdf_file?(_), do: false
end