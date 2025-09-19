defmodule Paperform2webWeb.DocumentJSON do
  alias Paperform2web.Documents.Document

  @doc """
  Renders a list of documents.
  """
  def index(%{documents: documents}) do
    %{data: for(document <- documents, do: data(document))}
  end

  @doc """
  Renders a single document.
  """
  def show(%{document: document}) do
    %{data: data(document)}
  end

  @doc """
  Renders processing status for a document.
  """
  def process_status(%{document: document}) do
    %{
      id: document.id,
      status: document.status,
      progress: document.progress,
      error_message: document.error_message,
      updated_at: document.updated_at
    }
  end

  defp data(%Document{} = document) do
    %{
      id: document.id,
      filename: document.filename,
      file_path: document.file_path,
      status: document.status,
      progress: document.progress,
      model_used: document.model_used,
      processed_data: document.processed_data,
      error_message: document.error_message,
      inserted_at: document.inserted_at,
      updated_at: document.updated_at
    }
  end
end