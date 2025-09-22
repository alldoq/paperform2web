defmodule Paperform2web.HtmlGenerator.ContentGeneration do
  @moduledoc """
  Content generation functionality for HTML documents.
  Handles regular content sections like headers, paragraphs, lists, and tables.
  """

  @doc """
  Generates content based on sections with proper mode handling.
  """
  def generate_content(content, editing_mode \\ false, form_generator \\ nil, radio_grouper \\ nil, editable_generator \\ nil)

  def generate_content(%{"sections" => sections}, editing_mode, form_generator, radio_grouper, editable_generator) when is_list(sections) do
    sections_html = if editing_mode do
      # Group sections by field_name for radio buttons to create fieldsets
      grouped_sections = if radio_grouper, do: radio_grouper.(sections), else: sections
      grouped_sections
      |> Enum.with_index()
      |> Enum.map_join("\n", fn {section_group, index} ->
        if is_list(section_group) do
          # This is a group of radio buttons - render as fieldset
          if form_generator, do: form_generator.(:radio_fieldset, section_group, index), else: ""
        else
          # This is a single section
          if editable_generator, do: editable_generator.(section_group, index), else: ""
        end
      end)
    else
      # Also group radio sections in preview mode
      grouped_sections = if radio_grouper, do: radio_grouper.(sections), else: sections
      grouped_sections
      |> Enum.with_index()
      |> Enum.map_join("\n", fn {section_group, index} ->
        if is_list(section_group) do
          if form_generator, do: form_generator.(:radio_group, section_group, index), else: ""
        else
          if form_generator, do: form_generator.(:section, section_group, index), else: ""
        end
      end)
    end

    """
    <main class="document-content">
        #{sections_html}
        #{if editing_mode, do: generate_add_field_button(), else: ""}
    </main>
    """
  end

  def generate_content(_, _editing_mode, _form_generator, _radio_grouper, _editable_generator), do: "<main class=\"document-content\"><p>No content available</p></main>"

  @doc """
  Generates document header with optional editing mode.
  """
  def generate_header(data, editing_mode \\ false, html_escaper \\ &escape_html/1) do
    title = data["title"] || "Document"

    if editing_mode do
      """
      <header class="document-header">
          <h1 class="document-title editable-title" contenteditable="true" data-original-title="#{html_escaper.(title)}">#{html_escaper.(title)}</h1>
      </header>
      """
    else
      """
      <header class="document-header">
          <h1 class="document-title">#{html_escaper.(title)}</h1>
      </header>
      """
    end
  end

  @doc """
  Generates a regular content section (not form-related).
  """
  def generate_section(section, css_builder \\ nil, style_builder \\ nil, html_escaper \\ &escape_html/1) do
    type = section["type"] || "paragraph"
    content = section["content"] || ""
    formatting = section["formatting"] || %{}
    position = section["position"] || %{}

    css_classes = if css_builder, do: css_builder.(type, formatting), else: build_css_classes(type, formatting)
    inline_styles = if style_builder, do: style_builder.(formatting, position), else: build_inline_styles(formatting, position)

    case type do
      "header" ->
        level = determine_header_level(formatting)
        "<h#{level} class=\"#{css_classes}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</h#{level}>"

      "paragraph" ->
        "<p class=\"#{css_classes}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</p>"

      "list" ->
        generate_list(content, css_classes, inline_styles, html_escaper)

      "table" ->
        generate_table(content, css_classes, inline_styles, html_escaper)

      # New form-specific types - these would be handled by form generation
      "form_title" ->
        "<h1 class=\"form-title #{css_classes}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</h1>"

      "form_section" ->
        "<h2 class=\"form-section #{css_classes}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</h2>"

      "form_label" ->
        # Check if this label is associated with a specific field
        field_name = get_in(section, ["metadata", "field_name"])
        if field_name do
          # This is a label for a specific input field
          "<label for=\"#{field_name}\" class=\"form-label #{css_classes}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</label>"
        else
          # This is standalone descriptive text (like a question)
          "<div class=\"form-question #{css_classes}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</div>"
        end

      _ ->
        "<div class=\"#{css_classes}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</div>"
    end
  end

  @doc """
  Generates HTML list from content.
  """
  def generate_list(content, css_classes, inline_styles, html_escaper \\ &escape_html/1) do
    items = String.split(content, "\n") |> Enum.reject(&(&1 == ""))
    items_html = Enum.map_join(items, "", fn item ->
      "<li>#{html_escaper.(String.trim(item))}</li>"
    end)

    "<ul class=\"#{css_classes}\" style=\"#{inline_styles}\">#{items_html}</ul>"
  end

  @doc """
  Generates HTML table from content.
  """
  def generate_table(content, css_classes, inline_styles, html_escaper \\ &escape_html/1) do
    rows = String.split(content, "\n") |> Enum.reject(&(&1 == ""))

    case rows do
      [header | data_rows] ->
        header_cells = String.split(header, "|") |> Enum.map(&String.trim/1)
        header_html = Enum.map_join(header_cells, "", fn cell ->
          "<th>#{html_escaper.(cell)}</th>"
        end)

        rows_html = Enum.map_join(data_rows, "", fn row ->
          cells = String.split(row, "|") |> Enum.map(&String.trim/1)
          cells_html = Enum.map_join(cells, "", fn cell ->
            "<td>#{html_escaper.(cell)}</td>"
          end)
          "<tr>#{cells_html}</tr>"
        end)

        """
        <table class="#{css_classes}" style="#{inline_styles}">
            <thead><tr>#{header_html}</tr></thead>
            <tbody>#{rows_html}</tbody>
        </table>
        """

      _ ->
        "<div class=\"table-error\">Invalid table format</div>"
    end
  end

  @doc """
  Generates metadata section for documents.
  """
  def generate_metadata_section(metadata, options) when is_map(options) do
    if Map.get(options, :show_metadata, true) and metadata && metadata != %{} do
      """
      <section class="document-metadata">
          <h3>Document Information</h3>
          <div class="metadata-grid">
              #{generate_metadata_items(metadata)}
          </div>
      </section>
      """
    else
      ""
    end
  end

  def generate_metadata_section(_, _), do: ""

  # Private helper functions

  defp generate_metadata_items(metadata) do
    metadata
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> Enum.map_join("", fn {key, value} ->
      display_key = key |> String.replace("_", " ") |> String.capitalize()
      """
      <div class="metadata-item">
          <strong>#{escape_html(display_key)}:</strong>
          <span>#{escape_html(to_string(value))}</span>
      </div>
      """
    end)
  end

  defp build_css_classes(type, formatting) do
    classes = ["section", "section-#{type}"]

    classes = if formatting["bold"], do: ["bold" | classes], else: classes
    classes = if formatting["italic"], do: ["italic" | classes], else: classes

    font_size = formatting["font_size"]
    classes = if font_size, do: ["font-#{font_size}" | classes], else: classes

    alignment = formatting["alignment"]
    classes = if alignment, do: ["align-#{alignment}" | classes], else: classes

    Enum.join(classes, " ")
  end

  defp build_inline_styles(_formatting, _position) do
    # Remove absolute positioning to prevent overlapping elements
    # Let CSS handle the layout using normal document flow
    ""
  end

  defp determine_header_level(formatting) do
    case formatting["font_size"] do
      "large" -> 1
      "medium" -> 2
      "small" -> 3
      _ -> 2
    end
  end

  @doc """
  Gets language from document data.
  """
  def get_language(data) do
    get_in(data, ["metadata", "language"]) || "en"
  end

  @doc """
  Escapes HTML content to prevent XSS attacks.
  """
  def escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  def escape_html(text), do: to_string(text) |> escape_html()

  @doc """
  Generates the add field button for editing mode.
  """
  def generate_add_field_button do
    """
    <div class="add-field-container">
        <button id="add-field-button" class="add-field-btn">
            <span class="add-field-icon">➕</span>
            <span class="add-field-text">Add New Field</span>
        </button>
    </div>
    """
  end
end