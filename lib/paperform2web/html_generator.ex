defmodule Paperform2web.HtmlGenerator do
  @moduledoc """
  Converts processed document JSON data into HTML web pages.
  This module orchestrates various specialized modules for HTML generation.
  """

  # Import the extracted modules
  alias Paperform2web.HtmlGenerator.CssThemes
  alias Paperform2web.HtmlGenerator.Javascript
  alias Paperform2web.HtmlGenerator.Pagination
  alias Paperform2web.HtmlGenerator.FormGeneration
  alias Paperform2web.HtmlGenerator.ContentGeneration
  alias Paperform2web.HtmlGenerator.Toolbar

  def generate_html(processed_data, options \\ %{}) do
    case validate_data(processed_data) do
      :ok ->
        html = build_html_document(processed_data, options)
        {:ok, html}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_data(data) when is_map(data) do
    required_keys = ["document_type", "content", "metadata"]
    case Enum.all?(required_keys, &Map.has_key?(data, &1)) do
      true -> :ok
      false -> {:error, "Missing required data fields"}
    end
  end

  defp validate_data(_), do: {:error, "Invalid data format"}

  defp build_html_document(data, options) do
    title = data["title"] || "Processed Document"
    template = Map.get(options, :template)
    theme = Map.get(options, :theme, "default")
    editing_mode = Map.get(options, :editing, false)
    document_id = Map.get(options, :document_id)

    # Use template CSS if available, otherwise fallback to theme
    css_content = if template && template.css_content do
      template.css_content
    else
      CssThemes.generate_css(theme)
    end

    # Add toolbar CSS for both editing and preview modes since both use toolbars
    editing_css = Toolbar.generate_editing_css()

    # Check if this is a multi-page PDF document
    is_pdf_multipage = data["document_type"] == "pdf_multipage" and data["pages"]

    content_html = if is_pdf_multipage do
      Pagination.generate_pdf_paginated_content(data, editing_mode, &generate_content_with_modules/2)
    else
      generate_content_with_modules(data["content"], editing_mode)
    end

    """
    <!DOCTYPE html>
    <html lang="#{ContentGeneration.get_language(data)}">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{ContentGeneration.escape_html(title)}</title>
        #{css_content}
        #{editing_css}
        #{if is_pdf_multipage, do: Pagination.generate_pagination_css(), else: ""}
    </head>
    <body class="document-#{data["document_type"]}#{if editing_mode, do: " editing-mode", else: " preview-mode"}#{if is_pdf_multipage, do: " pdf-paginated", else: ""}">
        #{Toolbar.generate_toolbar(editing_mode, document_id)}
        <div class="container">
            #{ContentGeneration.generate_header(data, editing_mode, &ContentGeneration.escape_html/1)}
            #{if editing_mode, do: content_html, else: FormGeneration.generate_form_wrapper(content_html, document_id, options)}
            #{ContentGeneration.generate_metadata_section(data["metadata"], options)}
        </div>
        #{Javascript.generate_javascript(editing_mode, document_id)}
        #{if is_pdf_multipage, do: Pagination.generate_pagination_javascript(data["pages"]), else: ""}
    </body>
    </html>
    """
  end

  # Bridge function to connect modules
  defp generate_content_with_modules(content, editing_mode) do
    ContentGeneration.generate_content(
      content,
      editing_mode,
      &form_generation_bridge/3,
      &FormGeneration.group_radio_sections/1,
      &generate_editable_section_bridge/2
    )
  end

  # Bridge functions for module communication
  defp form_generation_bridge(:section, section, index) do
    FormGeneration.generate_form_section(section, index, &build_css_classes/2, &build_inline_styles/2, &ContentGeneration.escape_html/1)
  end

  defp form_generation_bridge(:radio_group, section_group, index) do
    generate_form_radio_group(section_group, index)
  end

  defp form_generation_bridge(:radio_fieldset, section_group, index) do
    FormGeneration.generate_radio_fieldset(section_group, index)
  end

  defp generate_editable_section_bridge(section, index) do
    generate_editable_section(section, index)
  end

  # Still need these functions that haven't been fully extracted yet
  defp generate_form_radio_group(radio_sections, index) do
    if is_list(radio_sections) and length(radio_sections) > 1 do
      # This is a group of radio sections
      [first_section | radio_inputs] = radio_sections

      # Use the first section (usually a label) as the group label
      group_label = first_section["content"] || "Radio Group"
      field_name = get_in(List.first(radio_inputs), ["metadata", "field_name"]) || "radio_group_#{index}"

      # Debug logging to help track radio button grouping
      if Application.get_env(:paperform2web, :debug_radio_buttons, false) do
        IO.puts("[Radio Group] Creating radio group with field_name: #{field_name}, label: #{group_label}, sections: #{length(radio_inputs)}")
      end

      # Create a copy of each radio section with the proper field_name to ensure they all share the same name
      radio_buttons = Enum.map_join(radio_inputs, "", fn section ->
        # Ensure the section has the correct field_name for the radio group
        section_with_field_name = put_in(section, ["metadata", "field_name"], field_name)
        FormGeneration.generate_form_input(section["content"], "", "", section_with_field_name, &ContentGeneration.escape_html/1)
      end)

      """
      <div class="form-field radio-field">
        <span class="radio-group-label">#{ContentGeneration.escape_html(group_label)}</span>
        <div class="radio-options">
          #{radio_buttons}
        </div>
      </div>
      """
    else
      # Single section, treat as regular form section
      section = if is_list(radio_sections), do: List.first(radio_sections), else: radio_sections
      FormGeneration.generate_form_section(section, index, &build_css_classes/2, &build_inline_styles/2, &ContentGeneration.escape_html/1)
    end
  end

  defp generate_editable_section(section, index) do
    type = section["type"] || "text"
    _content = section["content"] || ""
    formatting = section["formatting"] || %{}
    _position = section["position"] || %{}

    _css_classes = build_css_classes(type, formatting)
    field_name = get_in(section, ["metadata", "field_name"]) || "field_#{index}"
    field_id = "editable_#{field_name}_#{index}"

    # Generate the editable wrapper with drag and drop functionality
    """
    <div class="editable-field-wrapper" data-field-type="#{type}" draggable="true" id="#{field_id}">
      <div class="drag-handle" title="Drag to reorder"></div>
      <div class="field-controls">
        <button class="field-control-btn edit-btn" onclick="editField('#{field_id}')" title="Edit field">✏️</button>
        <button class="field-control-btn delete-btn" onclick="deleteField('#{field_id}')" title="Delete field">🗑️</button>
      </div>
      #{FormGeneration.generate_form_section(section, index, &build_css_classes/2, &build_inline_styles/2, &ContentGeneration.escape_html/1)}
    </div>
    """
  end

  # Helper functions that are still needed
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
end