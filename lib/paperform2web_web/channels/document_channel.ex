defmodule Paperform2webWeb.DocumentChannel do
  use Paperform2webWeb, :channel

  alias Paperform2web.Documents
  require Logger

  @impl true
  def join("document:" <> document_id, payload, socket) do
    if authorized?(payload) do
      # Verify the document exists
      case Documents.get_document(document_id) do
        %Documents.Document{} = document ->
          socket = assign(socket, :document_id, document_id)
          send(self(), :after_join)
          {:ok, %{status: "joined", document: format_document(document)}, socket}
        nil ->
          {:error, %{reason: "Document not found"}}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    document_id = socket.assigns.document_id

    case Documents.get_document(document_id) do
      %Documents.Document{} = document ->
        push(socket, "document_status", format_document(document))
      nil ->
        push(socket, "error", %{reason: "Document not found"})
    end

    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # Handle document status requests
  @impl true
  def handle_in("get_status", _payload, socket) do
    document_id = socket.assigns.document_id

    case Documents.get_document(document_id) do
      %Documents.Document{} = document ->
        {:reply, {:ok, format_document(document)}, socket}
      nil ->
        {:reply, {:error, %{reason: "Document not found"}}, socket}
    end
  end

  # Broadcast document updates to all subscribers
  def broadcast_document_update(document_id, document) do
    formatted_doc = format_document(document)
    Logger.info("📡 Broadcasting document update for #{document_id}: status=#{formatted_doc.status}, progress=#{formatted_doc.progress}, message=#{formatted_doc.status_message}")

    Paperform2webWeb.Endpoint.broadcast(
      "document:#{document_id}",
      "document_updated",
      formatted_doc
    )
  end

  # Broadcast status updates specifically
  def broadcast_status_update(document_id, status, progress, error_message \\ nil) do
    Paperform2webWeb.Endpoint.broadcast(
      "document:#{document_id}",
      "status_updated",
      %{
        status: status,
        progress: progress,
        error_message: error_message,
        updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    )
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    # For now, allow all connections
    # In production, you might want to verify user authentication
    true
  end

  defp format_document(document) do
    %{
      id: document.id,
      filename: document.filename,
      status: document.status,
      progress: document.progress || 0,
      error_message: document.error_message,
      status_message: document.status_message,
      model_used: document.model_used,
      theme: document.theme,
      inserted_at: document.inserted_at,
      updated_at: document.updated_at,
      processed_data: document.processed_data
    }
  end
end