defmodule Paperform2web.DataMigration do
  @moduledoc """
  One-time data migration to fix field types that were incorrectly saved as form_input
  """

  alias Paperform2web.{Repo, Documents.Document}
  import Ecto.Query

  def fix_field_types do
    IO.puts("🔧 Starting field type migration...")

    documents = Repo.all(from d in Document, where: d.status == "completed")

    IO.puts("Found #{length(documents)} completed documents")

    Enum.each(documents, fn document ->
      IO.puts("\n📄 Processing document: #{document.filename}")
      fix_document_field_types(document)
    end)

    IO.puts("\n✅ Migration complete!")
  end

  defp fix_document_field_types(document) do
    sections = get_in(document.processed_data, ["content", "sections"]) || []

    if length(sections) == 0 do
      IO.puts("  No sections found, skipping")
    else

    IO.puts("  Original sections: #{length(sections)}")

    # Analyze and fix section types
    fixed_sections = analyze_and_fix_sections(sections)

    changes_made = Enum.zip(sections, fixed_sections)
    |> Enum.filter(fn {old, new} -> old["type"] != new["type"] end)
    |> length()

    if changes_made > 0 do
      IO.puts("  Fixed #{changes_made} section types")

      # Update the document
      updated_processed_data = put_in(
        document.processed_data,
        ["content", "sections"],
        fixed_sections
      )

      case Repo.update(Ecto.Changeset.change(document, processed_data: updated_processed_data)) do
        {:ok, _} ->
          IO.puts("  ✅ Document updated successfully")
        {:error, changeset} ->
          IO.puts("  ❌ Failed to update: #{inspect(changeset.errors)}")
      end
    else
      IO.puts("  No changes needed")
    end
    end
  end

  defp analyze_and_fix_sections(sections) do
    Enum.with_index(sections)
    |> Enum.map(fn {section, index} ->
      next_section = Enum.at(sections, index + 1)
      determine_correct_type(section, next_section, index)
    end)
  end

  defp determine_correct_type(section, next_section, _index) do
    content = section["content"] || ""
    current_type = section["type"]

    # Only fix sections that are currently form_input
    if current_type != "form_input" do
      section
    else

    # Determine what the type should actually be
    correct_type = cond do
      # Check if it's a heading (section header)
      is_heading?(content) ->
        "form_title"

      # Check if it's a label followed by an input
      is_label_with_input?(content, next_section) ->
        "form_label"

      # Check if it has metadata indicating it's actually an input
      has_input_metadata?(section) ->
        "form_input"

      # Empty content is likely an input field
      String.trim(content) == "" ->
        "form_input"

      # Default: if it has content but no clear input indicators, it's a label
      true ->
        "form_label"
    end

    if correct_type != current_type do
      IO.puts("    Changing #{inspect(String.slice(content, 0, 50))} from #{current_type} to #{correct_type}")
      Map.put(section, "type", correct_type)
    else
      section
    end
    end
  end

  # Detect if content looks like a heading
  defp is_heading?(content) do
    content = String.trim(content)

    cond do
      # All uppercase and longer than a few chars (section headers)
      String.length(content) > 10 and content == String.upcase(content) ->
        true

      # Starts with single letter followed by period (like "A. DANE...")
      Regex.match?(~r/^[A-Z]\.\s+[A-Z]/, content) ->
        true

      # Contains "SECTION" or other heading keywords
      String.contains?(content, ["SECTION", "PART", "CZĘŚĆ", "DZIAŁ"]) ->
        true

      true ->
        false
    end
  end

  # Detect if this is a label followed by an input field
  defp is_label_with_input?(content, next_section) do
    content = String.trim(content)

    # If this has content and the next section is empty, this is likely a label
    if content != "" and next_section do
      next_content = String.trim(next_section["content"] || "")
      next_content == ""
    else
      false
    end
  end

  # Check if section has metadata indicating it's an actual input
  defp has_input_metadata?(section) do
    metadata = section["metadata"] || %{}

    # Has a field_name (actual form field)
    has_field_name = Map.has_key?(metadata, "field_name") and
                     metadata["field_name"] != nil and
                     metadata["field_name"] != ""

    # Has an input_type
    has_input_type = Map.has_key?(metadata, "input_type")

    has_field_name or has_input_type
  end

  @doc """
  Migrates all multi-page documents to add page_number to their sections.
  This fixes documents that were processed before pagination support was added.

  Run this in IEx:
    iex> Paperform2web.DataMigration.migrate_page_numbers()
  """
  def migrate_page_numbers do
    IO.puts("🔄 Starting page number migration...")

    # Find all completed multi-page documents
    query = from d in Document,
      where: d.status == "completed",
      where: fragment("?->>'page_count' IS NOT NULL", d.processed_data),
      where: fragment("CAST(?->>'page_count' AS INTEGER) > 1", d.processed_data)

    documents = Repo.all(query)
    IO.puts("Found #{length(documents)} multi-page documents")

    # Migrate each document
    results = Enum.map(documents, fn doc ->
      migrate_document_page_numbers(doc)
    end)

    success_count = Enum.count(results, fn {status, _} -> status == :ok end)
    error_count = Enum.count(results, fn {status, _} -> status == :error end)

    IO.puts("\n✅ Migration complete!")
    IO.puts("  ✓ Successfully migrated: #{success_count}")
    IO.puts("  ✗ Errors: #{error_count}")

    {:ok, %{success: success_count, errors: error_count}}
  end

  defp migrate_document_page_numbers(%Document{} = document) do
    IO.puts("\n📄 Migrating: #{document.filename}")

    processed_data = document.processed_data
    pages = processed_data["pages"] || []
    sections = get_in(processed_data, ["content", "sections"]) || []

    # Check if migration is needed
    needs_migration = length(pages) > 1 and
                     Enum.any?(sections, fn section ->
                       !Map.has_key?(section, "page_number")
                     end)

    if needs_migration do
      # Reconstruct sections from pages with page numbers
      migrated_sections = Enum.flat_map(pages, fn page ->
        page_num = page["page_number"]
        page_sections = get_in(page, ["content", "sections"]) || []

        Enum.map(page_sections, fn section ->
          Map.put(section, "page_number", page_num)
        end)
      end)

      # Also update the pages array with page numbers in their sections
      updated_pages = Enum.map(pages, fn page ->
        page_num = page["page_number"]
        page_sections = get_in(page, ["content", "sections"]) || []

        # Add page_number to sections within this page
        sections_with_page_num = Enum.map(page_sections, fn section ->
          Map.put(section, "page_number", page_num)
        end)

        put_in(page, ["content", "sections"], sections_with_page_num)
      end)

      # Update processed_data
      updated_processed_data = processed_data
        |> put_in(["content", "sections"], migrated_sections)
        |> Map.put("pages", updated_pages)

      # Save to database
      changeset = Ecto.Changeset.change(document, processed_data: updated_processed_data)

      case Repo.update(changeset) do
        {:ok, _updated_doc} ->
          IO.puts("  ✓ Migrated #{length(migrated_sections)} sections across #{length(pages)} pages")
          {:ok, document.id}

        {:error, changeset} ->
          IO.puts("  ✗ Error: #{inspect(changeset.errors)}")
          {:error, changeset.errors}
      end
    else
      IO.puts("  → Already migrated or single page, skipping")
      {:ok, :skipped}
    end
  rescue
    e ->
      IO.puts("  ✗ Exception: #{inspect(e)}")
      {:error, e}
  end
end
