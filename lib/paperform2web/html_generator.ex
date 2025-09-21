defmodule Paperform2web.HtmlGenerator do
  @moduledoc """
  Converts processed document JSON data into HTML web pages.
  """

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
      generate_css(theme)
    end

    # Add toolbar CSS for both editing and preview modes since both use toolbars
    editing_css = generate_editing_css()

    # Check if this is a multi-page PDF document
    is_pdf_multipage = data["document_type"] == "pdf_multipage" and data["pages"]

    content_html = if is_pdf_multipage do
      generate_pdf_paginated_content(data, editing_mode)
    else
      generate_content(data["content"], editing_mode)
    end

    """
    <!DOCTYPE html>
    <html lang="#{get_language(data)}">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{escape_html(title)}</title>
        #{css_content}
        #{editing_css}
        #{if is_pdf_multipage, do: generate_pagination_css(), else: ""}
    </head>
    <body class="document-#{data["document_type"]}#{if editing_mode, do: " editing-mode", else: " preview-mode"}#{if is_pdf_multipage, do: " pdf-paginated", else: ""}">
        #{if editing_mode, do: generate_editing_toolbar(document_id), else: generate_preview_toolbar(document_id)}
        <div class="container">
            #{generate_header(data, editing_mode)}
            #{if editing_mode, do: content_html, else: generate_form_wrapper(content_html, document_id, options)}
            #{generate_metadata_section(data["metadata"], options)}
        </div>
        #{generate_javascript(editing_mode, document_id)}
        #{if is_pdf_multipage, do: generate_pagination_javascript(data["pages"]), else: ""}
    </body>
    </html>
    """
  end

  defp generate_header(data, editing_mode \\ false) do
    title = data["title"] || "Document"

    if editing_mode do
      """
      <header class="document-header">
          <h1 class="document-title editable-title" contenteditable="true" data-original-title="#{escape_html(title)}">#{escape_html(title)}</h1>
      </header>
      """
    else
      """
      <header class="document-header">
          <h1 class="document-title">#{escape_html(title)}</h1>
      </header>
      """
    end
  end

  # Function header with default value
  defp generate_content(content, editing_mode \\ false)

  defp generate_content(%{"sections" => sections}, editing_mode) when is_list(sections) do
    sections_html = if editing_mode do
      # Group sections by field_name for radio buttons to create fieldsets
      grouped_sections = group_radio_sections(sections)
      grouped_sections
      |> Enum.with_index()
      |> Enum.map_join("\n", fn {section_group, index} ->
        if is_list(section_group) do
          # This is a group of radio buttons - render as fieldset
          generate_radio_fieldset(section_group, index)
        else
          # This is a single section
          generate_editable_section(section_group, index)
        end
      end)
    else
      # Also group radio sections in preview mode
      grouped_sections = group_radio_sections(sections)
      grouped_sections
      |> Enum.with_index()
      |> Enum.map_join("\n", fn {section_group, index} ->
        if is_list(section_group) do
          generate_form_radio_group(section_group, index)
        else
          generate_form_section(section_group, index)
        end
      end)
    end

    """
    <main class="document-content#{if editing_mode, do: " editable-content", else: ""}">
        #{sections_html}
        #{if editing_mode, do: generate_add_field_button(), else: ""}
    </main>
    """
  end

  defp generate_content(_, _editing_mode), do: "<main class=\"document-content\"><p>No content available</p></main>"

  # Generate paginated content for PDF documents
  defp generate_pdf_paginated_content(data, editing_mode) do
    pages = data["pages"] || []
    total_pages = length(pages)

    pages_html = pages
    |> Enum.with_index()
    |> Enum.map_join("\n", fn {page_data, index} ->
      page_number = index + 1
      is_first_page = page_number == 1

      """
      <div class="pdf-page" id="page-#{page_number}" style="#{if not is_first_page, do: "display: none;", else: ""}">
        <div class="page-header">
          <h2 class="page-title">Page #{page_number} of #{total_pages}</h2>
        </div>
        #{generate_content(page_data["content"], editing_mode)}
      </div>
      """
    end)

    """
    <main class="document-content pdf-paginated-content">
        #{pages_html}
        <div class="pagination-controls">
          <button id="prev-page" class="page-btn" onclick="previousPage()" disabled>← Previous</button>
          <span id="page-info" class="page-info">Page 1 of #{total_pages}</span>
          <button id="next-page" class="page-btn" onclick="nextPage()">Next →</button>
        </div>
    </main>
    """
  end

  # Generate CSS for pagination
  defp generate_pagination_css() do
    """
    <style>
        .pdf-paginated-content {
            position: relative;
            min-height: 70vh;
        }

        .pdf-page {
            transition: opacity 0.3s ease-in-out;
        }

        .page-header {
            border-bottom: 2px solid #e5e7eb;
            margin-bottom: 2rem;
            padding-bottom: 1rem;
        }

        .page-title {
            color: #374151;
            font-size: 1.5rem;
            font-weight: 600;
            margin: 0;
        }

        .pagination-controls {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 1rem;
            margin-top: 3rem;
            padding: 2rem 0;
            border-top: 1px solid #e5e7eb;
        }

        .page-btn {
            background: #3b82f6;
            color: white;
            border: none;
            padding: 0.75rem 1.5rem;
            border-radius: 0.5rem;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
            font-size: 0.875rem;
        }

        .page-btn:hover:not(:disabled) {
            background: #2563eb;
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
        }

        .page-btn:disabled {
            background: #9ca3af;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }

        .page-info {
            font-weight: 500;
            color: #374151;
            font-size: 0.875rem;
            min-width: 100px;
            text-align: center;
        }

        .pdf-paginated .container {
            max-width: none;
            width: 100%;
        }
    </style>
    """
  end

  # Generate JavaScript for pagination
  defp generate_pagination_javascript(pages) do
    total_pages = length(pages)

    """
    <script>
        let currentPage = 1;
        const totalPages = #{total_pages};

        function showPage(pageNumber) {
            // Hide all pages
            for (let i = 1; i <= totalPages; i++) {
                const page = document.getElementById('page-' + i);
                if (page) {
                    page.style.display = 'none';
                }
            }

            // Show the requested page
            const targetPage = document.getElementById('page-' + pageNumber);
            if (targetPage) {
                targetPage.style.display = 'block';
            }

            // Update controls
            updatePaginationControls();

            // Scroll to top
            window.scrollTo({top: 0, behavior: 'smooth'});
        }

        function nextPage() {
            if (currentPage < totalPages) {
                currentPage++;
                showPage(currentPage);
            }
        }

        function previousPage() {
            if (currentPage > 1) {
                currentPage--;
                showPage(currentPage);
            }
        }

        function updatePaginationControls() {
            const prevBtn = document.getElementById('prev-page');
            const nextBtn = document.getElementById('next-page');
            const pageInfo = document.getElementById('page-info');

            if (prevBtn) prevBtn.disabled = currentPage <= 1;
            if (nextBtn) nextBtn.disabled = currentPage >= totalPages;
            if (pageInfo) pageInfo.textContent = `Page ${currentPage} of ${totalPages}`;
        }

        // Keyboard navigation
        document.addEventListener('keydown', function(e) {
            if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
                e.preventDefault();
                nextPage();
            } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
                e.preventDefault();
                previousPage();
            }
        });

        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            updatePaginationControls();
        });
    </script>
    """
  end

  # Group radio button sections with the same field_name together
  defp group_radio_sections(sections) do
    IO.puts("=== GROUPING RADIO SECTIONS ===")
    IO.inspect(sections, label: "Original sections")

    # First pass: find radio groups and their associated labels
    grouped_sections = group_radio_and_labels(sections)

    IO.puts("=== GROUPING RESULT ===")
    IO.inspect(grouped_sections, label: "Final grouped result")

    grouped_sections
  end

  # Enhanced grouping logic that handles form_label + radio patterns
  defp group_radio_and_labels(sections) do
    sections
    |> Enum.with_index()
    |> Enum.reduce({[], MapSet.new()}, fn {section, index}, {result, processed} ->
      if MapSet.member?(processed, index) do
        {result, processed}
      else
        {grouped_section, new_processed} = process_section_for_radio_grouping(section, index, sections, processed)

        # Only add non-nil results
        new_result = if grouped_section != nil do
          result ++ [grouped_section]
        else
          result
        end

        {new_result, new_processed}
      end
    end)
    |> elem(0)
  end

  defp process_section_for_radio_grouping(section, index, all_sections, processed) do
    section_type = section["type"]

    cond do
      # Check if this is a form_label that might be followed by radio buttons
      section_type == "form_label" ->
        following_radios = find_following_radio_buttons(all_sections, index + 1)

        if length(following_radios) > 0 do
          # Found radio buttons following this label - group them together
          radio_indices = Enum.map(following_radios, fn {_, idx} -> idx end)
          new_processed = Enum.reduce([index | radio_indices], processed, &MapSet.put(&2, &1))

          # Create group with label first, then radio buttons
          radio_sections = Enum.map(following_radios, fn {radio_section, _} -> radio_section end)
          group = [section | radio_sections]

          {group, new_processed}
        else
          # No following radio buttons, treat as individual section
          {section, MapSet.put(processed, index)}
        end

      # Check if this is a radio button that might be part of a group
      section_type == "form_input" && get_in(section, ["metadata", "input_type"]) == "radio" ->
        field_name = get_in(section, ["metadata", "field_name"])
        radio_siblings = find_radio_siblings_with_same_field(all_sections, field_name)

        if length(radio_siblings) > 1 do
          # Multiple radio buttons with same field name
          first_radio_index = radio_siblings |> Enum.map(fn {_, idx} -> idx end) |> Enum.min()

          if index == first_radio_index do
            # This is the first radio button in the group
            radio_indices = Enum.map(radio_siblings, fn {_, idx} -> idx end)
            new_processed = Enum.reduce(radio_indices, processed, &MapSet.put(&2, &1))

            radio_sections = Enum.map(radio_siblings, fn {radio_section, _} -> radio_section end)
            {radio_sections, new_processed}
          else
            # This radio button will be processed when we encounter the first one
            {nil, MapSet.put(processed, index)}
          end
        else
          # Single radio button
          {section, MapSet.put(processed, index)}
        end

      # All other section types
      true ->
        {section, MapSet.put(processed, index)}
    end
  end

  # Find radio buttons immediately following a label
  defp find_following_radio_buttons(sections, start_index) do
    sections
    |> Enum.drop(start_index)
    |> Enum.take_while(fn section ->
      section["type"] == "form_input" && get_in(section, ["metadata", "input_type"]) == "radio"
    end)
    |> Enum.with_index(start_index)
  end

  # Find all radio buttons with the same field name
  defp find_radio_siblings_with_same_field(sections, field_name) do
    sections
    |> Enum.with_index()
    |> Enum.filter(fn {section, _} ->
      section["type"] == "form_input" &&
      get_in(section, ["metadata", "input_type"]) == "radio" &&
      get_in(section, ["metadata", "field_name"]) == field_name
    end)
  end

  # Merge grouped radio buttons and individual sections while preserving original order
  defp merge_sections_and_groups(original_sections, radio_groups, other_sections) do
    # Create a map of field_name -> group for radio groups
    radio_group_map =
      radio_groups
      |> Enum.map(fn group ->
        field_name = get_in(List.first(group), ["metadata", "field_name"])
        {field_name, group}
      end)
      |> Map.new()

    # Go through original sections and replace radio sections with groups
    {result, _used_groups} =
      Enum.reduce(original_sections, {[], MapSet.new()}, fn section, {acc, used} ->
        section_type = section["type"]
        section_field_name = get_in(section, ["metadata", "field_name"])

        if (section_type == "form_input" && get_in(section, ["metadata", "input_type"]) == "radio") ||
           (section_type == "form_input" && get_in(section, ["metadata", "input_type"]) == "checkbox") ||
           section_type == "radio" do
          if MapSet.member?(used, section_field_name) do
            # Already included this radio group, skip
            {acc, used}
          else
            # First radio of this group, include the entire group
            group = Map.get(radio_group_map, section_field_name, [section])
            {acc ++ [group], MapSet.put(used, section_field_name)}
          end
        else
          # Not a radio button, include as is
          {acc ++ [section], used}
        end
      end)

    result
  end

  defp generate_form_radio_group(radio_sections, index) do
    # This function is for preview mode
    {labels, radio_inputs} = Enum.split_with(radio_sections, fn s -> s["type"] == "form_label" end)

    question_text = case labels do
      [label | _] -> label["content"]
      _ -> "Radio Group"
    end

    field_name = get_in(List.first(radio_inputs), ["metadata", "field_name"]) || "radio_group_#{index}"

    radio_buttons_html = Enum.map_join(radio_inputs, "\n", fn section ->
      generate_form_input(section["content"], "", "", section)
    end)

    """
    <div class="form-field radio-field">
      <span class="radio-group-label">#{escape_html(question_text)}</span>
      <div class="radio-options">
        #{radio_buttons_html}
      </div>
    </div>
    """
  end

  # Generate a fieldset for a group of radio buttons
  defp generate_radio_fieldset(radio_sections, index) do
    # Separate form_label from radio inputs
    {labels, radio_inputs} =
      radio_sections
      |> Enum.split_with(fn section -> section["type"] == "form_label" end)

    # Get question text from form_label if available
    question_text =
      case labels do
        [label | _] -> label["content"]
        _ ->
          # Fallback: try to get from first radio input's field_name
          first_radio = List.first(radio_inputs)
          if first_radio do
            field_name = get_in(first_radio, ["metadata", "field_name"]) || "field_group_#{index}"
            String.replace(field_name, "_", " ") |> String.capitalize()
          else
            "Radio Group #{index + 1}"
          end
      end

    # Get field_name from first radio input
    first_radio = List.first(radio_inputs)
    field_name = get_in(first_radio, ["metadata", "field_name"]) || "field_group_#{index}"

    # Generate individual radio buttons only from radio inputs
    radio_buttons =
      radio_inputs
      |> Enum.with_index()
      |> Enum.map_join("\n", fn {section, radio_index} ->
        content = section["content"] || ""
        field_value = get_in(section, ["metadata", "field_value"]) || escape_html(content)
        radio_id = "#{field_name}_#{radio_index}"

        """
        <div class="radio-option">
          <input type="radio" id="#{radio_id}" name="#{field_name}" value="#{escape_html(field_value)}" />
          <label class="editable-label" contenteditable="true" data-field="#{field_name}_#{radio_index}" for="#{radio_id}">#{escape_html(content)}</label>
        </div>
        """
      end)

    """
    <div class="editable-field-wrapper radio-fieldset" data-index="#{index}" data-type="radio-group" data-field-name="#{field_name}" draggable="true">
        <div class="drag-handle"></div>
        <div class="field-controls">
            <button class="control-btn type-btn" title="Change field type">⚙</button>
            <button class="control-btn remove-btn" title="Remove field group">×</button>
        </div>
        <fieldset class="radio-group-fieldset">
            <legend class="editable-label" contenteditable="true" data-field="#{field_name}_question">#{escape_html(question_text)}</legend>
            #{radio_buttons}
        </fieldset>
    </div>
    """
  end

  defp generate_form_section(section, index) do
    type = section["type"] || "text"
    content = section["content"] || ""
    formatting = section["formatting"] || %{}
    position = section["position"] || %{}

    css_classes = build_css_classes(type, formatting)
    inline_styles = build_inline_styles(formatting, position)
    field_name = get_in(section, ["metadata", "field_name"]) || "field_#{index}"

    # Remove width functionality - all fields are full width
    width_class = ""

    # Debug: let's see what we're getting
    IO.inspect(section, label: "Section in generate_form_section")

    # Handle new AI-detected form elements
    case type do
      "form_input" ->
        if get_in(section, ["metadata", "input_type"]) do
          generate_form_input(content, "#{css_classes}#{width_class}", inline_styles, section)
        else
          # Fallback to legacy type-based generation
          generate_legacy_form_section(type, content, css_classes, inline_styles, width_class, field_name, section, index)
        end

      "form_label" ->
        # Check if this label is associated with a specific field
        label_field_name = get_in(section, ["metadata", "field_name"])
        if label_field_name do
          # This is a label for a specific input field
          "<label for=\"#{label_field_name}\" class=\"form-label #{css_classes}#{width_class}\" style=\"#{inline_styles}\">#{escape_html(content)}</label>"
        else
          # This is standalone descriptive text (like a question)
          "<div class=\"form-question #{css_classes}#{width_class}\" style=\"#{inline_styles}\">#{escape_html(content)}</div>"
        end

      "form_title" ->
        "<h1 class=\"form-title #{css_classes}#{width_class}\" style=\"#{inline_styles}\">#{escape_html(content)}</h1>"

      "form_section" ->
        "<h2 class=\"form-section #{css_classes}#{width_class}\" style=\"#{inline_styles}\">#{escape_html(content)}</h2>"

      # Check if this is a user-added field that was restored without proper type metadata
      # Also handle radio button fields created in edit mode
      "radio" ->
        # Handle radio button fields created in edit mode - these contain multiple options
        options = get_in(section, ["metadata", "options"]) || []
        if length(options) > 0 do
          # Generate radio group with the provided options
          radio_buttons = Enum.with_index(options, fn option, idx ->
            radio_id = "#{field_name}_#{idx}"
            """
            <div class="radio-option">
              <input type="radio" id="#{radio_id}" name="#{field_name}" value="#{escape_html(option)}" />
              <label for="#{radio_id}">#{escape_html(option)}</label>
            </div>
            """
          end) |> Enum.join("")

          """
          <div class="form-field radio-field">
            <span class="radio-group-label">#{escape_html(content)}</span>
            <div class="radio-options">
              #{radio_buttons}
            </div>
          </div>
          """
        else
          # Fallback to form_input generation for radio without options
          generate_form_input(content, "#{css_classes}#{width_class}", inline_styles, section)
        end

      _ ->
        cond do
          # Check for form_field_id (indicates user-added field)
          Map.has_key?(section, "form_field_id") ->
            generate_form_input(content, "#{css_classes}#{width_class}", inline_styles, section)

          # Check if field_name starts with user_field_ (restored user field)
          String.starts_with?(field_name, "user_field_") ->
            generate_form_input(content, "#{css_classes}#{width_class}", inline_styles, section)

          # Check if it's a form_input type (AI-detected form field)
          type == "form_input" ->
            generate_form_input(content, "#{css_classes}#{width_class}", inline_styles, section)

          # Fallback to legacy type-based generation
          true ->
            generate_legacy_form_section(type, content, css_classes, inline_styles, width_class, field_name, section, index)
        end
    end
  end

  defp generate_legacy_form_section(type, content, css_classes, inline_styles, width_class, field_name, section, _index) do
    case type do
      "text" ->
        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <input type="text" id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" />
        </div>
        """

      "textarea" ->
        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <textarea id="#{field_name}" name="#{field_name}" rows="3" placeholder="#{escape_html(content)}"></textarea>
        </div>
        """

      "checkbox" ->
        """
        <div class="form-field#{width_class} checkbox-field #{css_classes}" style="#{inline_styles}">
            <input type="checkbox" id="#{field_name}" name="#{field_name}" />
            <label for="#{field_name}">#{escape_html(content)}</label>
        </div>
        """

      "select" ->
        options = get_in(section, ["metadata", "options"]) || ["Option 1", "Option 2", "Option 3"]
        options_html = Enum.map_join(options, "", fn option ->
          "<option value=\"#{escape_html(option)}\">#{escape_html(option)}</option>"
        end)

        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <select id="#{field_name}" name="#{field_name}">#{options_html}</select>
        </div>
        """

      "email" ->
        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <input type="email" id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" />
        </div>
        """

      "date" ->
        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <input type="date" id="#{field_name}" name="#{field_name}" />
        </div>
        """

      # Handle legacy types and convert them to proper form fields
      "form_field" ->
        generate_form_field(content, css_classes <> width_class, inline_styles, section)

      "form_input" ->
        generate_form_input(content, css_classes <> width_class, inline_styles, section)

      _ ->
        # Default to text input for any other type
        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <input type="text" id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" />
        </div>
        """
    end
  end

  defp generate_section(section) do
    type = section["type"] || "paragraph"
    content = section["content"] || ""
    formatting = section["formatting"] || %{}
    position = section["position"] || %{}

    css_classes = build_css_classes(type, formatting)
    inline_styles = build_inline_styles(formatting, position)

    case type do
      "header" ->
        level = determine_header_level(formatting)
        "<h#{level} class=\"#{css_classes}\" style=\"#{inline_styles}\">#{escape_html(content)}</h#{level}>"

      "paragraph" ->
        "<p class=\"#{css_classes}\" style=\"#{inline_styles}\">#{escape_html(content)}</p>"

      "list" ->
        generate_list(content, css_classes, inline_styles)

      "table" ->
        generate_table(content, css_classes, inline_styles)

      # Legacy support
      "form_field" ->
        generate_form_field(content, css_classes, inline_styles, section)

      # New form-specific types
      "form_title" ->
        "<h1 class=\"form-title #{css_classes}\" style=\"#{inline_styles}\">#{escape_html(content)}</h1>"

      "form_section" ->
        "<h2 class=\"form-section #{css_classes}\" style=\"#{inline_styles}\">#{escape_html(content)}</h2>"

      "form_label" ->
        # Check if this label is associated with a specific field
        field_name = get_in(section, ["metadata", "field_name"])
        if field_name do
          # This is a label for a specific input field
          "<label for=\"#{field_name}\" class=\"form-label #{css_classes}\" style=\"#{inline_styles}\">#{escape_html(content)}</label>"
        else
          # This is standalone descriptive text (like a question)
          "<div class=\"form-question #{css_classes}\" style=\"#{inline_styles}\">#{escape_html(content)}</div>"
        end

      "form_input" ->
        generate_form_input(content, css_classes, inline_styles, section)

      "form_group" ->
        "<div class=\"form-group #{css_classes}\" style=\"#{inline_styles}\">#{generate_form_group_content(section)}</div>"

      _ ->
        "<div class=\"#{css_classes}\" style=\"#{inline_styles}\">#{escape_html(content)}</div>"
    end
  end

  defp generate_list(content, css_classes, inline_styles) do
    items = String.split(content, "\n") |> Enum.reject(&(&1 == ""))
    items_html = Enum.map_join(items, "", fn item ->
      "<li>#{escape_html(String.trim(item))}</li>"
    end)

    "<ul class=\"#{css_classes}\" style=\"#{inline_styles}\">#{items_html}</ul>"
  end

  defp generate_table(content, css_classes, inline_styles) do
    rows = String.split(content, "\n") |> Enum.reject(&(&1 == ""))

    case rows do
      [header | data_rows] ->
        header_cells = String.split(header, "|") |> Enum.map(&String.trim/1)
        header_html = Enum.map_join(header_cells, "", fn cell ->
          "<th>#{escape_html(cell)}</th>"
        end)

        rows_html = Enum.map_join(data_rows, "", fn row ->
          cells = String.split(row, "|") |> Enum.map(&String.trim/1)
          cells_html = Enum.map_join(cells, "", fn cell ->
            "<td>#{escape_html(cell)}</td>"
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

  defp generate_form_input(content, css_classes, inline_styles, section) do
    input_type =
      get_in(section, ["metadata", "input_type"]) ||
      get_in(section, ["metadata", "field_type"]) ||
      infer_field_type(content)
    field_name = get_in(section, ["metadata", "field_name"]) || sanitize_field_name(content)
    field_value = get_in(section, ["metadata", "field_value"]) || ""
    placeholder = get_in(section, ["metadata", "placeholder"]) || extract_placeholder(content)
    required = get_in(section, ["metadata", "required"]) || false
    options = get_in(section, ["metadata", "options"]) || []

    required_attr = if required, do: " required", else: ""

    case input_type do
      "checkbox" ->
        # Create unique checkbox ID
        checkbox_id = "#{field_name}_#{:erlang.phash2(content)}"
        checked = if String.contains?(String.downcase(content), "checked") or field_value == "true", do: " checked", else: ""
        value = if field_value != "", do: field_value, else: "on"
        """
        <div class="form-field checkbox-field #{css_classes}" style="#{inline_styles}">
            <input type="checkbox" id="#{checkbox_id}" name="#{field_name}" value="#{escape_html(value)}"#{checked}#{required_attr}>
            <label for="#{checkbox_id}">#{escape_html(content)}</label>
        </div>
        """

      "radio" ->
        # Create unique ID but use same name for radio group
        radio_id = "#{field_name}_#{sanitize_field_name(field_value != "" && field_value || content)}"
        value = if field_value != "", do: field_value, else: sanitize_field_name(content)
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <input type="radio" id="#{radio_id}" name="#{field_name}" value="#{escape_html(value)}"#{required_attr}>
            <label for="#{radio_id}">#{escape_html(content)}</label>
        </div>
        """

      "textarea" ->
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <textarea id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(placeholder)}" rows="4"#{required_attr}>#{escape_html(field_value)}</textarea>
        </div>
        """

      "select" ->
        options_html = if Enum.empty?(options) do
          "<option value=\"\">Select an option</option>"
        else
          Enum.map_join(options, "", fn option ->
            selected = if option == field_value, do: " selected", else: ""
            "<option value=\"#{escape_html(option)}\"#{selected}>#{escape_html(option)}</option>"
          end)
        end
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <select id="#{field_name}" name="#{field_name}"#{required_attr}>#{options_html}</select>
        </div>
        """

      input_type when input_type in ["date", "time", "datetime-local", "email", "tel", "url", "number", "password"] ->
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <input type="#{input_type}" id="#{field_name}" name="#{field_name}" value="#{escape_html(field_value)}" placeholder="#{escape_html(placeholder)}"#{required_attr}>
        </div>
        """

      "text" ->
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <input type="text" id="#{field_name}" name="#{field_name}" value="#{escape_html(field_value)}" placeholder="#{escape_html(placeholder)}"#{required_attr}>
        </div>
        """

      _ ->
        # Force create a text input even for unknown types - NO STATIC CONTENT
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <input type="text" id="#{field_name}" name="#{field_name}" value="#{escape_html(field_value || content)}" placeholder="Enter value"#{required_attr}>
        </div>
        """
    end
  end

  defp generate_form_group_content(section) do
    # For form groups, just return the content as-is
    escape_html(section["content"] || "")
  end

  defp extract_placeholder(content) do
    # Extract meaningful placeholder from content, removing formatting symbols
    content
    |> String.replace(~r/_+/, "")
    |> String.replace(~r/\[.*?\]/, "")
    |> String.replace(~r/□|☐/, "")
    |> String.trim()
    |> case do
      "" -> "Enter value"
      text -> "Enter " <> String.downcase(text)
    end
  end

  # Legacy function for backward compatibility
  defp generate_form_field(content, css_classes, inline_styles, section) do
    field_type = get_in(section, ["metadata", "field_type"]) || infer_field_type(content)
    field_name = get_in(section, ["metadata", "field_name"]) || sanitize_field_name(content)
    field_value = get_in(section, ["metadata", "field_value"]) || ""

    case field_type do
      "checkbox" ->
        checked = if String.contains?(String.downcase(content), "checked") or field_value == "true", do: "checked", else: ""
        """
        <div class="form-field checkbox-field #{css_classes}" style="#{inline_styles}">
            <input type="checkbox" id="#{field_name}" name="#{field_name}" #{checked}>
            <label for="#{field_name}">#{escape_html(content)}</label>
        </div>
        """

      "radio" ->
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <input type="radio" id="#{field_name}" name="#{field_name}" value="#{escape_html(field_value)}">
            <label for="#{field_name}">#{escape_html(content)}</label>
        </div>
        """

      "textarea" ->
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <textarea id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" rows="4">#{escape_html(field_value)}</textarea>
        </div>
        """

      "select" ->
        options = get_in(section, ["metadata", "options"]) || []
        options_html = Enum.map_join(options, "", fn option ->
          selected = if option == field_value, do: " selected", else: ""
          "<option value=\"#{escape_html(option)}\"#{selected}>#{escape_html(option)}</option>"
        end)
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <select id="#{field_name}" name="#{field_name}">#{options_html}</select>
        </div>
        """

      field_type when field_type in ["date", "time", "datetime-local", "email", "tel", "url", "number", "password"] ->
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <input type="#{field_type}" id="#{field_name}" name="#{field_name}" value="#{escape_html(field_value)}" placeholder="#{escape_html(content)}">
        </div>
        """

      "text" ->
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{escape_html(content)}</label>
            <input type="text" id="#{field_name}" name="#{field_name}" value="#{escape_html(field_value)}" placeholder="#{escape_html(content)}">
        </div>
        """

      _ ->
        # Fallback for unknown types - just display as text
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label>#{escape_html(content)}</label>
            <div class="field-value">#{escape_html(field_value)}</div>
        </div>
        """
    end
  end

  defp generate_metadata_section(metadata, options) when is_map(options) do
    show_metadata = Map.get(options, :show_metadata, false)

    if show_metadata do
      confidence = if metadata, do: metadata["confidence"] || 0, else: 0
      language = if metadata, do: metadata["language"] || "Unknown", else: "Unknown"
      notes = if metadata, do: metadata["processing_notes"] || "", else: ""

      """
      <footer class="document-metadata">
          <h3>Document Information</h3>
          <div class="metadata-grid">
              <div class="metadata-item">
                  <strong>Language:</strong> #{escape_html(language)}
              </div>
              <div class="metadata-item">
                  <strong>Confidence:</strong> #{Float.round(confidence * 100, 1)}%
              </div>
              #{if notes != "", do: "<div class=\"metadata-item\"><strong>Notes:</strong> #{escape_html(notes)}</div>", else: ""}
          </div>
      </footer>
      """
    else
      ""
    end
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

  defp get_language(data) do
    get_in(data, ["metadata", "language"]) || "en"
  end

  defp infer_field_type(content) do
    content_lower = String.downcase(content)

    cond do
      String.contains?(content_lower, "email") -> "email"
      String.contains?(content_lower, "phone") or String.contains?(content_lower, "tel") -> "tel"
      String.contains?(content_lower, "date") and not String.contains?(content_lower, "time") -> "date"
      String.contains?(content_lower, "time") and not String.contains?(content_lower, "date") -> "time"
      String.contains?(content_lower, "datetime") -> "datetime-local"
      String.contains?(content_lower, "password") -> "password"
      String.contains?(content_lower, "number") or String.contains?(content_lower, "amount") -> "number"
      String.contains?(content_lower, "url") or String.contains?(content_lower, "website") -> "url"
      String.contains?(content_lower, "address") or String.contains?(content_lower, "comment") or String.contains?(content_lower, "description") -> "textarea"
      true -> "text"
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

  defp escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  defp escape_html(text), do: to_string(text) |> escape_html()

  defp generate_css(theme) do
    base_css = case theme do
      "minimal" -> minimal_css()
      "dark" -> dark_css()
      "modern" -> modern_css()
      "classic" -> classic_css()
      "colorful" -> colorful_css()
      "newspaper" -> newspaper_css()
      "elegant" -> elegant_css()
      _ -> default_css()
    end

    # Add 80% width container rule and radio button styling for all themes
    full_width_css = """
    <style>
        .container {
            max-width: none !important;
            width: 80% !important;
            margin: 0 auto;
            padding: 1rem;
        }

        /* Radio button field styling */
        .radio-field {
            margin-bottom: 1.5rem;
        }
        .radio-group-label {
            display: block;
            font-weight: 600;
            margin-bottom: 0.75rem;
            color: #374151;
        }
        .radio-options {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }
        .radio-options label {
            display: flex;
            align-items: center;
            font-weight: normal;
            cursor: pointer;
            padding: 0.5rem 0;
        }
        .radio-options input[type="radio"] {
            margin-right: 0.75rem;
            transform: scale(1.2);
        }
    </style>
    """

    base_css <> full_width_css
  end


  defp default_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; background: #f4f4f4; }
        .container { max-width: 800px; margin: 0 auto; background: white; box-shadow: 0 0 20px rgba(0,0,0,0.1); min-height: 100vh; }
        .document-header { background: #2c3e50; color: white; padding: 2rem; text-align: center; }
        .document-title { font-size: 2rem; margin-bottom: 0.5rem; }
        .document-type-badge { background: #3498db; padding: 0.5rem 1rem; border-radius: 20px; display: inline-block; font-size: 0.9rem; }
        .document-content { padding: 2rem; }
        .section { margin-bottom: 1.5rem; }
        .section-header { color: #2c3e50; margin-bottom: 1rem; }
        .section-paragraph { margin-bottom: 1rem; }
        .section-list { margin-left: 1.5rem; }
        .section-table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
        .section-table th, .section-table td { border: 1px solid #ddd; padding: 0.75rem; text-align: left; }
        .section-table th { background: #f8f9fa; font-weight: bold; }
        .form-field { margin-bottom: 1rem; }
        .form-field label { display: block; margin-bottom: 0.5rem; font-weight: bold; }
        .form-question { margin-bottom: 0.75rem; font-weight: bold; color: #333; font-size: 1rem; }
        .form-field input[type="text"], .form-field input[type="email"], .form-field input[type="tel"], .form-field input[type="date"], .form-field input[type="number"], .form-field textarea, .form-field select { padding: 0.5rem; border: 1px solid #ddd; border-radius: 4px; width: 100%; }
        .form-field select { background: white; background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 0.5rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 2.5rem; appearance: none; }
        .form-field select:focus { border-color: #3498db; outline: none; box-shadow: 0 0 0 2px rgba(52, 152, 219, 0.2); }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; transform: scale(1.2); }
        .form-field.checkbox-field { display: flex; align-items: flex-start; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: normal; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 2px; flex-shrink: 0; }
        .bold { font-weight: bold; }
        .italic { font-style: italic; }
        .font-large { font-size: 1.5rem; }
        .font-medium { font-size: 1.2rem; }
        .font-small { font-size: 0.9rem; }
        .align-center { text-align: center; }
        .align-right { text-align: right; }
        .align-left { text-align: left; }
        .document-metadata { background: #ecf0f1; padding: 1.5rem; border-top: 1px solid #bdc3c7; }
        .metadata-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-top: 1rem; }
        .metadata-item { background: white; padding: 1rem; border-radius: 6px; }
    </style>
    """
  end

  defp minimal_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Georgia, serif; line-height: 1.8; color: #222; background: white; }
        .container { max-width: 700px; margin: 0 auto; padding: 2rem; }
        .document-header { border-bottom: 2px solid #eee; padding-bottom: 1rem; margin-bottom: 2rem; }
        .document-title { font-size: 1.8rem; margin-bottom: 0.5rem; }
        .document-content { }
        .section { margin-bottom: 1.5rem; }
        .form-field { margin-bottom: 1rem; }
        .form-field label { display: block; margin-bottom: 0.5rem; font-weight: 500; }
        .form-question { margin-bottom: 0.75rem; font-weight: 600; color: #2c3e50; font-size: 1rem; }
        .form-field input[type="text"], .form-field input[type="email"], .form-field input[type="tel"], .form-field input[type="date"], .form-field input[type="number"], .form-field textarea, .form-field select { padding: 0.5rem; border: 1px solid #ddd; border-radius: 0; width: 100%; font-family: inherit; }
        .form-field select { background: white; background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 0.5rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 2.5rem; appearance: none; }
        .form-field select:focus, .form-field input:focus, .form-field textarea:focus { border-color: #333; outline: none; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; transform: scale(1.2); }
        .form-field.checkbox-field { display: flex; align-items: flex-start; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: normal; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 2px; flex-shrink: 0; }
        .bold { font-weight: bold; }
        .italic { font-style: italic; }
    </style>
    """
  end

  defp dark_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #e0e0e0; background: #1a1a1a; }
        .container { max-width: 800px; margin: 0 auto; background: #2d2d2d; box-shadow: 0 0 20px rgba(0,0,0,0.5); min-height: 100vh; }
        .document-header { background: #1e3a5f; color: white; padding: 2rem; text-align: center; }
        .document-title { font-size: 2rem; margin-bottom: 0.5rem; }
        .document-type-badge { background: #4a90e2; padding: 0.5rem 1rem; border-radius: 20px; display: inline-block; font-size: 0.9rem; }
        .document-content { padding: 2rem; }
        .section { margin-bottom: 1.5rem; }
        .section-table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
        .section-table th, .section-table td { border: 1px solid #555; padding: 0.75rem; text-align: left; }
        .section-table th { background: #3a3a3a; font-weight: bold; }
        .form-field input[type="text"], .form-field input[type="email"], .form-field input[type="tel"], .form-field input[type="date"], .form-field input[type="number"], .form-field textarea, .form-field select { padding: 0.5rem; border: 1px solid #555; border-radius: 4px; width: 100%; background: #3a3a3a; color: #e0e0e0; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%23e0e0e0' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 0.5rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 2.5rem; appearance: none; }
        .form-field select:focus { border-color: #64b5f6; outline: none; box-shadow: 0 0 0 2px rgba(100, 181, 246, 0.3); }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; transform: scale(1.2); accent-color: #4a90e2; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: normal; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 2px; flex-shrink: 0; }
        .bold { font-weight: bold; }
        .italic { font-style: italic; }
    </style>
    """
  end

  defp modern_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.6; color: #1f2937; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { max-width: 900px; margin: 2rem auto; background: white; border-radius: 20px; box-shadow: 0 25px 50px rgba(0,0,0,0.15); overflow: hidden; }
        .document-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 3rem 2rem; text-align: center; position: relative; }
        .document-header::after { content: ''; position: absolute; bottom: 0; left: 0; right: 0; height: 4px; background: linear-gradient(90deg, #ff6b6b, #4ecdc4, #45b7d1, #96ceb4, #feca57); }
        .document-title { font-size: 2.5rem; font-weight: 700; margin: 0; text-shadow: 0 2px 4px rgba(0,0,0,0.2); }
        .document-content { padding: 3rem; }
        .section { margin-bottom: 2rem; }
        .form-section { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; margin: 2rem -1rem 2rem -1rem; padding: 1rem 2rem; border-radius: 15px; font-weight: 600; }
        .form-label { color: #4a5568; font-weight: 600; margin-bottom: 0.5rem; display: block; }
        .form-question { margin-bottom: 1rem; font-weight: 600; color: #2d3748; font-size: 1.1rem; }
        .form-field input, .form-field textarea, .form-field select { background: #f7fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 1rem; width: 100%; transition: all 0.3s ease; font-size: 1rem; font-family: inherit; }
        .form-field input:focus, .form-field textarea:focus, .form-field select:focus { border-color: #667eea; box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1); outline: none; background: white; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%234a5568' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 1rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 3rem; appearance: none; }
        .form-field { margin-bottom: 1.5rem; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.75rem; transform: scale(1.3); accent-color: #667eea; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; background: #f7fafc; padding: 1rem; border-radius: 12px; border: 2px solid #e2e8f0; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: normal; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 3px; flex-shrink: 0; }
        .bold { font-weight: 700; }
        .italic { font-style: italic; }
    </style>
    """
  end

  defp classic_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Times New Roman', Times, serif; line-height: 1.7; color: #2c3e50; background: #f8f9fa; }
        .container { max-width: 750px; margin: 2rem auto; background: white; border: 3px double #8b4513; padding: 0; }
        .document-header { background: #8b4513; color: #f4e4c1; padding: 2rem; text-align: center; border-bottom: 3px double #654321; }
        .document-title { font-size: 2.2rem; font-weight: normal; letter-spacing: 2px; text-transform: uppercase; }
        .document-content { padding: 2.5rem; background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="white"/><rect width="1" height="100" fill="%23e8e8e8" x="25"/><rect width="1" height="100" fill="%23e8e8e8" x="50"/><rect width="1" height="100" fill="%23e8e8e8" x="75"/></svg>'); }
        .section { margin-bottom: 2rem; }
        .form-section { border-left: 4px solid #8b4513; padding-left: 1rem; margin: 2rem 0 1.5rem 0; font-weight: bold; font-size: 1.1rem; text-transform: uppercase; letter-spacing: 1px; }
        .form-label { font-weight: bold; margin-bottom: 0.3rem; display: block; color: #5d4037; }
        .form-question { margin-bottom: 0.8rem; font-weight: bold; color: #3e2723; font-size: 1rem; }
        .form-field input, .form-field textarea, .form-field select { border: 2px solid #8b4513; background: #fefefe; padding: 0.7rem; width: 100%; font-family: inherit; border-radius: 0; }
        .form-field input:focus, .form-field textarea:focus, .form-field select:focus { outline: 2px solid #d2691e; outline-offset: 2px; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%238b4513' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 0.7rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 2.5rem; appearance: none; }
        .form-field { margin-bottom: 1.2rem; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; transform: scale(1.2); accent-color: #8b4513; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: normal; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 2px; flex-shrink: 0; }
        .bold { font-weight: bold; }
        .italic { font-style: italic; }
    </style>
    """
  end

  defp colorful_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Comic Sans MS', cursive, sans-serif; line-height: 1.6; color: #2c3e50; background: linear-gradient(45deg, #ff9a9e 0%, #fecfef 50%, #fecfef 100%); }
        .container { max-width: 850px; margin: 1rem auto; background: white; border-radius: 25px; overflow: hidden; box-shadow: 0 20px 40px rgba(0,0,0,0.1); border: 5px solid transparent; background-clip: padding-box; }
        .container::before { content: ''; position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: linear-gradient(45deg, #ff6b6b, #4ecdc4, #45b7d1, #96ceb4, #feca57, #ff9ff3); border-radius: 25px; padding: 5px; mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0); -webkit-mask-composite: destination-out; }
        .document-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2.5rem; text-align: center; }
        .document-title { font-size: 2.3rem; font-weight: bold; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); animation: rainbow 3s linear infinite; }
        @keyframes rainbow { 0% { filter: hue-rotate(0deg); } 100% { filter: hue-rotate(360deg); } }
        .document-content { padding: 2.5rem; background: linear-gradient(135deg, #fff9e6 0%, #f0f8ff 100%); }
        .section { margin-bottom: 2rem; }
        .form-section { background: linear-gradient(135deg, #ff6b6b, #4ecdc4); color: white; padding: 1rem 1.5rem; border-radius: 20px; margin: 2rem 0 1.5rem 0; font-weight: bold; text-shadow: 1px 1px 2px rgba(0,0,0,0.2); }
        .form-label { color: #e91e63; font-weight: bold; margin-bottom: 0.5rem; display: block; text-shadow: 1px 1px 2px rgba(0,0,0,0.1); }
        .form-field input, .form-field textarea, .form-field select { background: linear-gradient(135deg, #fff 0%, #f8f9ff 100%); border: 3px solid #ff6b6b; border-radius: 15px; padding: 1rem; width: 100%; font-size: 1rem; transition: all 0.3s ease; font-family: inherit; }
        .form-field input:focus, .form-field textarea:focus, .form-field select:focus { border-color: #4ecdc4; transform: scale(1.02); box-shadow: 0 5px 15px rgba(78, 205, 196, 0.3); outline: none; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%23ff6b6b' stroke-linecap='round' stroke-linejoin='round' stroke-width='2.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 1rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 3rem; appearance: none; }
        .form-field { margin-bottom: 1.5rem; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.75rem; transform: scale(1.4); accent-color: #ff6b6b; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; background: linear-gradient(135deg, #fff 0%, #f8f9ff 100%); padding: 1rem; border-radius: 15px; border: 3px solid #ff6b6b; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: bold; color: #e91e63; flex: 1; text-shadow: 1px 1px 2px rgba(0,0,0,0.1); }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 3px; flex-shrink: 0; }
        .bold { font-weight: bold; color: #e91e63; }
        .italic { font-style: italic; color: #9c27b0; }
    </style>
    """
  end

  defp newspaper_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Times New Roman', Times, serif; line-height: 1.5; color: #000; background: #f5f5dc; }
        .container { max-width: 800px; margin: 1rem auto; background: white; border: 2px solid #000; }
        .document-header { background: #000; color: white; padding: 1rem; text-align: center; border-bottom: 4px double #000; }
        .document-title { font-size: 2rem; font-weight: bold; letter-spacing: 3px; text-transform: uppercase; font-family: 'Old English Text MT', serif; }
        .document-content { padding: 2rem; column-count: 2; column-gap: 2rem; column-rule: 1px solid #ccc; }
        .section { margin-bottom: 1.5rem; break-inside: avoid; }
        .form-section { column-span: all; background: #000; color: white; padding: 0.5rem 1rem; margin: 1.5rem 0; font-weight: bold; text-align: center; letter-spacing: 2px; text-transform: uppercase; border-top: 2px solid #000; border-bottom: 2px solid #000; }
        .form-label { font-weight: bold; margin-bottom: 0.3rem; display: block; text-transform: uppercase; font-size: 0.9rem; letter-spacing: 1px; }
        .form-field input, .form-field textarea, .form-field select { border: none; border-bottom: 2px solid #000; background: transparent; padding: 0.5rem 0; width: 100%; font-family: inherit; }
        .form-field input:focus, .form-field textarea:focus, .form-field select:focus { outline: none; border-bottom-color: #666; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%23000' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 0.5rem center; background-repeat: no-repeat; background-size: 1.2em 1.2em; padding-right: 2rem; appearance: none; }
        .form-field { margin-bottom: 1rem; column-span: all; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.5rem; transform: scale(1.1); accent-color: #000; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; column-span: all; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: bold; text-transform: uppercase; font-size: 0.9rem; letter-spacing: 1px; flex: 1; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 2px; flex-shrink: 0; }
        .bold { font-weight: bold; text-transform: uppercase; }
        .italic { font-style: italic; }
        @media (max-width: 768px) { .document-content { column-count: 1; } }
    </style>
    """
  end

  defp elegant_css do
    """
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Playfair Display', 'Georgia', serif; line-height: 1.7; color: #2c3e50; background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); }
        .container { max-width: 900px; margin: 3rem auto; background: white; border-radius: 2px; box-shadow: 0 0 50px rgba(0,0,0,0.1); position: relative; }
        .container::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 8px; background: linear-gradient(90deg, #d4af37, #ffd700, #d4af37); }
        .document-header { background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%); color: #ecf0f1; padding: 4rem 3rem 3rem 3rem; text-align: center; position: relative; }
        .document-header::after { content: ''; position: absolute; bottom: -10px; left: 50%; transform: translateX(-50%); width: 100px; height: 4px; background: #d4af37; }
        .document-title { font-size: 2.8rem; font-weight: 300; letter-spacing: 3px; text-shadow: 0 2px 4px rgba(0,0,0,0.3); }
        .document-content { padding: 4rem 3rem; }
        .section { margin-bottom: 2.5rem; }
        .form-section { color: #2c3e50; font-size: 1.3rem; font-weight: 300; margin: 3rem 0 2rem 0; padding-bottom: 0.5rem; border-bottom: 2px solid #d4af37; letter-spacing: 1px; }
        .form-label { color: #5d6d7e; font-weight: 400; margin-bottom: 0.8rem; display: block; font-size: 1.1rem; }
        .form-field input, .form-field textarea, .form-field select { background: #fcfcfc; border: 1px solid #d5d8dc; padding: 1.2rem; width: 100%; font-family: 'Source Sans Pro', sans-serif; font-size: 1rem; transition: all 0.3s ease; }
        .form-field input:focus, .form-field textarea:focus, .form-field select:focus { border-color: #d4af37; box-shadow: 0 0 10px rgba(212, 175, 55, 0.2); outline: none; background: white; }
        .form-field select { background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%235d6d7e' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e"); background-position: right 1.2rem center; background-repeat: no-repeat; background-size: 1.5em 1.5em; padding-right: 3rem; appearance: none; }
        .form-field { margin-bottom: 2rem; }
        .form-field input[type="checkbox"], .form-field input[type="radio"] { width: auto; margin-right: 0.8rem; transform: scale(1.2); accent-color: #d4af37; }
        .form-field.checkbox-field { display: flex; align-items: flex-start; }
        .form-field.checkbox-field label { margin-bottom: 0; font-weight: 400; flex: 1; font-size: 1.1rem; }
        .form-field.checkbox-field input[type="checkbox"] { margin-top: 3px; flex-shrink: 0; }
        .bold { font-weight: 600; }
        .italic { font-style: italic; color: #7f8c8d; }
    </style>
    """
  end

  defp generate_javascript(editing_mode \\ false, document_id \\ nil) do
    if editing_mode && document_id do
      generate_editing_javascript(document_id)
    else
      generate_standard_javascript(document_id)
    end
  end

  defp generate_standard_javascript(document_id \\ nil) do
    """
    <script>
        // Preview mode JavaScript
        let isEditingMode = false;
        window.documentId = #{if document_id, do: "'#{document_id}'", else: "null"};

        document.addEventListener('DOMContentLoaded', function() {
            // Add click handlers for form fields if needed
            const formFields = document.querySelectorAll('.form-field input[type="text"]');
            formFields.forEach(field => {
                field.addEventListener('focus', function() {
                    this.style.borderColor = '#3498db';
                });
                field.addEventListener('blur', function() {
                    this.style.borderColor = '#ddd';
                });
            });

            // Initialize theme selector for preview mode
            initializeThemeSelector();

            // Initialize edit mode button
            initializeEditButton();

            // Initialize share button
            initializeShareButton();

            // Initialize form submission
            initializeFormSubmission();
        });

        function initializeThemeSelector() {
            const themeSelect = document.getElementById('theme-select');
            if (!themeSelect) return;

            // Set current theme from URL
            const urlParams = new URLSearchParams(window.location.search);
            const currentTheme = urlParams.get('theme') || 'default';
            themeSelect.value = currentTheme;

            // Add change event listener
            themeSelect.addEventListener('change', function(e) {
                changeTheme(e.target.value);
            });
        }

        function changeTheme(newTheme) {
            // In preview mode, update URL and refresh
            const url = new URL(window.location);
            if (newTheme === 'default') {
                url.searchParams.delete('theme');
            } else {
                url.searchParams.set('theme', newTheme);
            }
            window.location.href = url.toString();
        }

        function initializeEditButton() {
            const editBtn = document.getElementById('switch-to-edit');
            if (!editBtn) return;

            editBtn.addEventListener('click', function() {
                // Switch to edit mode by adding editing parameter
                const url = new URL(window.location);
                url.searchParams.set('editing', 'true');
                window.location.href = url.toString();
            });
        }

        function initializeShareButton() {
            const shareBtn = document.getElementById('share-form');
            if (!shareBtn) return;

            shareBtn.addEventListener('click', function() {
                openShareDialog();
            });
        }

        function openShareDialog() {
            if (!window.documentId) {
                alert('Document ID not available');
                return;
            }

            // Create share modal HTML
            const modalHtml = `
                <div id="share-modal" class="share-modal-overlay">
                    <div class="share-modal">
                        <div class="share-modal-header">
                            <h3>Share Form</h3>
                            <button class="share-close-btn" onclick="closeShareDialog()">&times;</button>
                        </div>
                        <div class="share-modal-body">
                            <form id="share-form">
                                <div class="form-group">
                                    <label for="recipient-email">Recipient Email *</label>
                                    <input type="email" id="recipient-email" required placeholder="Enter email address">
                                </div>
                                <div class="form-group">
                                    <label for="recipient-name">Recipient Name</label>
                                    <input type="text" id="recipient-name" placeholder="Enter recipient name">
                                </div>
                                <div class="form-group">
                                    <label for="email-subject">Email Subject *</label>
                                    <input type="text" id="email-subject" required value="You've been invited to fill out a form">
                                </div>
                                <div class="form-group">
                                    <label for="email-message">Personal Message</label>
                                    <textarea id="email-message" rows="4" placeholder="Add a personal message..."></textarea>
                                </div>
                                <div class="form-group">
                                    <label for="expires-at">Expiration Date</label>
                                    <input type="datetime-local" id="expires-at">
                                    <small>Leave blank for no expiration</small>
                                </div>
                                <div id="share-error" class="error-message" style="display:none;"></div>
                                <div id="share-success" class="success-message" style="display:none;"></div>
                            </form>
                        </div>
                        <div class="share-modal-footer">
                            <button type="button" onclick="closeShareDialog()" class="btn btn-secondary">Cancel</button>
                            <button type="button" onclick="submitShare()" class="btn btn-primary" id="share-submit-btn">
                                Send Form
                            </button>
                        </div>
                    </div>
                </div>
            `;

            // Add modal to page
            document.body.insertAdjacentHTML('beforeend', modalHtml);

            // Add modal styles
            addShareModalStyles();
        }

        function closeShareDialog() {
            const modal = document.getElementById('share-modal');
            if (modal) {
                modal.remove();
            }
        }

        function submitShare() {
            const form = document.getElementById('share-form');
            const submitBtn = document.getElementById('share-submit-btn');
            const errorDiv = document.getElementById('share-error');
            const successDiv = document.getElementById('share-success');

            // Get form values
            const recipientEmail = document.getElementById('recipient-email').value;
            const recipientName = document.getElementById('recipient-name').value;
            const subject = document.getElementById('email-subject').value;
            const message = document.getElementById('email-message').value;
            const expiresAt = document.getElementById('expires-at').value;

            // Validation
            if (!recipientEmail || !subject) {
                showError('Please fill in all required fields');
                return;
            }

            // Show loading state
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<span class="loading-spinner"></span> Sending...';

            // Prepare data
            const shareData = {
                recipient_email: recipientEmail,
                recipient_name: recipientName,
                subject: subject,
                message: message,
                expires_at: expiresAt || null
            };

            // Send request
            fetch(\`/api/documents/\${window.documentId}/share\`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(shareData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.error) {
                    throw new Error(data.error);
                }
                showSuccess('Form shared successfully! The recipient will receive an email shortly.');
                setTimeout(() => {
                    closeShareDialog();
                }, 2000);
            })
            .catch(error => {
                showError(error.message || 'Failed to share form. Please try again.');
            })
            .finally(() => {
                submitBtn.disabled = false;
                submitBtn.innerHTML = 'Send Form';
            });

            function showError(message) {
                errorDiv.textContent = message;
                errorDiv.style.display = 'block';
                successDiv.style.display = 'none';
            }

            function showSuccess(message) {
                successDiv.textContent = message;
                successDiv.style.display = 'block';
                errorDiv.style.display = 'none';
            }
        }

        function addShareModalStyles() {
            if (document.getElementById('share-modal-styles')) return;

            const styles = \`
                <style id="share-modal-styles">
                    .share-modal-overlay {
                        position: fixed;
                        top: 0;
                        left: 0;
                        width: 100%;
                        height: 100%;
                        background-color: rgba(0, 0, 0, 0.5);
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        z-index: 1000;
                    }
                    .share-modal {
                        background: white;
                        border-radius: 12px;
                        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
                        width: 90%;
                        max-width: 500px;
                        max-height: 90vh;
                        overflow-y: auto;
                    }
                    .share-modal-header {
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        padding: 1.5rem;
                        border-bottom: 1px solid #e5e7eb;
                    }
                    .share-modal-header h3 {
                        margin: 0;
                        font-size: 1.25rem;
                        font-weight: 600;
                        color: #111827;
                    }
                    .share-close-btn {
                        background: none;
                        border: none;
                        font-size: 1.5rem;
                        cursor: pointer;
                        color: #6b7280;
                        padding: 0.25rem;
                        border-radius: 0.375rem;
                    }
                    .share-close-btn:hover {
                        background-color: #f3f4f6;
                        color: #111827;
                    }
                    .share-modal-body {
                        padding: 1.5rem;
                    }
                    .form-group {
                        margin-bottom: 1rem;
                    }
                    .form-group label {
                        display: block;
                        margin-bottom: 0.5rem;
                        font-weight: 500;
                        color: #374151;
                    }
                    .form-group input,
                    .form-group textarea {
                        width: 100%;
                        padding: 0.75rem;
                        border: 1px solid #d1d5db;
                        border-radius: 0.375rem;
                        font-size: 0.875rem;
                        box-sizing: border-box;
                    }
                    .form-group input:focus,
                    .form-group textarea:focus {
                        outline: none;
                        border-color: #3b82f6;
                        box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
                    }
                    .form-group small {
                        display: block;
                        margin-top: 0.25rem;
                        color: #6b7280;
                        font-size: 0.75rem;
                    }
                    .share-modal-footer {
                        display: flex;
                        justify-content: flex-end;
                        gap: 0.75rem;
                        padding: 1.5rem;
                        border-top: 1px solid #e5e7eb;
                        background-color: #f9fafb;
                    }
                    .error-message {
                        background-color: #fef2f2;
                        border: 1px solid #fecaca;
                        color: #dc2626;
                        padding: 0.75rem;
                        border-radius: 0.375rem;
                        margin-top: 1rem;
                    }
                    .success-message {
                        background-color: #f0fdf4;
                        border: 1px solid #bbf7d0;
                        color: #166534;
                        padding: 0.75rem;
                        border-radius: 0.375rem;
                        margin-top: 1rem;
                    }
                    .loading-spinner {
                        display: inline-block;
                        width: 1rem;
                        height: 1rem;
                        border: 2px solid #ffffff;
                        border-top: 2px solid transparent;
                        border-radius: 50%;
                        animation: spin 1s linear infinite;
                    }
                    @keyframes spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                </style>
            \`;
            document.head.insertAdjacentHTML('beforeend', styles);
        }

        function initializeFormSubmission() {
            const submitBtn = document.getElementById('submit-form');
            if (!submitBtn) return;

            submitBtn.addEventListener('click', function() {
                submitForm();
            });
        }

        function submitForm() {
            const form = document.getElementById('document-form');
            const submitBtn = document.getElementById('submit-form');
            const statusDiv = document.getElementById('form-status');

            if (!form) {
                showFormStatus('error', 'Form not found');
                return;
            }

            // Collect form data
            const formData = collectFormData(form);

            // Check if this is a shared form or regular preview
            const shareToken = form.dataset.shareToken;
            const documentId = form.dataset.documentId;

            // Show loading state
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<span class="loading-spinner"></span> Submitting...';
            showFormStatus('loading', 'Submitting your response...');

            // Determine endpoint
            let endpoint, payload;
            if (shareToken) {
                // Shared form submission
                endpoint = \`/api/share/\${shareToken}/response\`;
                payload = {
                    response_data: {
                        form_data: formData,
                        is_completed: true,
                        completion_time_seconds: calculateCompletionTime()
                    }
                };
            } else {
                // Test submission for preview mode
                endpoint = \`/api/documents/\${documentId}/test-submission\`;
                payload = {
                    form_data: formData,
                    is_completed: true
                };
            }

            // Submit form
            fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(payload)
            })
            .then(response => response.json())
            .then(data => {
                if (data.error) {
                    throw new Error(data.error);
                }
                showFormStatus('success', 'Form submitted successfully! Thank you for your response.');

                // Disable form fields to prevent resubmission
                disableFormFields(form);
            })
            .catch(error => {
                console.error('Form submission error:', error);
                showFormStatus('error', error.message || 'Failed to submit form. Please try again.');
            })
            .finally(() => {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '📝 Submit Form';
            });
        }

        function collectFormData(form) {
            const formData = {};
            const formFields = form.querySelectorAll('input, textarea, select');

            formFields.forEach(field => {
                if (!field.name || field.name === '') return;

                const fieldType = field.type || field.tagName.toLowerCase();
                const fieldValue = getFieldValue(field);

                if (fieldValue !== null) {
                    // Store field data with metadata
                    formData[field.name] = {
                        type: fieldType,
                        value: fieldValue,
                        label: getFieldLabel(field),
                        required: field.hasAttribute('required')
                    };
                }
            });

            return formData;
        }

        function getFieldValue(field) {
            const fieldType = field.type || field.tagName.toLowerCase();

            switch (fieldType) {
                case 'checkbox':
                    return field.checked ? (field.value || 'true') : null;
                case 'radio':
                    return field.checked ? field.value : null;
                case 'select':
                case 'select-one':
                    return field.value || null;
                case 'select-multiple':
                    const selectedOptions = Array.from(field.selectedOptions);
                    return selectedOptions.length > 0 ? selectedOptions.map(opt => opt.value) : null;
                default:
                    return field.value.trim() || null;
            }
        }

        function getFieldLabel(field) {
            // Try to find associated label
            const label = document.querySelector(\`label[for="\${field.id}"]\`);
            if (label) {
                return label.textContent.trim();
            }

            // Try to find parent label
            const parentLabel = field.closest('label');
            if (parentLabel) {
                return parentLabel.textContent.replace(field.value, '').trim();
            }

            // Fallback to field name
            return field.name || field.placeholder || 'Unknown field';
        }

        function showFormStatus(type, message) {
            const statusDiv = document.getElementById('form-status');
            if (!statusDiv) return;

            statusDiv.className = \`form-status \${type}\`;
            statusDiv.textContent = message;
            statusDiv.style.display = 'block';
        }

        function disableFormFields(form) {
            const formFields = form.querySelectorAll('input, textarea, select');
            formFields.forEach(field => {
                field.disabled = true;
            });
        }

        function calculateCompletionTime() {
            // Simple completion time calculation
            // In a real app, you'd track when the user started filling the form
            return Math.floor(Math.random() * 300) + 60; // Random 1-6 minutes for demo
        }

    </script>
    """
  end

  defp generate_form_wrapper(content_html, document_id, options) do
    is_shared = Map.get(options, :shared, false)
    share_token = Map.get(options, :share_token)

    if is_shared and share_token do
      # For shared forms, use the share token endpoint
      """
      <form id="document-form" data-share-token="#{share_token}">
          #{content_html}
          <div class="form-submit-section">
              <button type="button" id="submit-form" class="btn btn-primary btn-large">
                  📝 Submit Form
              </button>
              <div id="form-status" class="form-status" style="display:none;"></div>
          </div>
      </form>
      """
    else
      # For regular preview, create a test submission
      """
      <form id="document-form" data-document-id="#{document_id}">
          #{content_html}
          <div class="form-submit-section">
              <button type="button" id="submit-form" class="btn btn-primary btn-large">
                  📝 Submit Form (Test)
              </button>
              <div id="form-status" class="form-status" style="display:none;"></div>
          </div>
      </form>
      """
    end
  end

  defp generate_style_selector do
    """
    <div class="style-selector">
        <label for="theme-select" class="style-label">Theme:</label>
        <select id="theme-select" class="style-select">
            <option value="default">Professional</option>
            <option value="minimal">Minimal</option>
            <option value="dark">Dark Mode</option>
            <option value="modern">Modern</option>
            <option value="classic">Classic</option>
            <option value="colorful">Colorful</option>
            <option value="newspaper">Newspaper</option>
            <option value="elegant">Elegant</option>
        </select>
    </div>
    """
  end

  defp generate_preview_toolbar(document_id) do
    """
    <div class="preview-toolbar">
        <div class="toolbar-content">
            <h3>Form Preview</h3>
            <div class="toolbar-actions">
                <button id="share-form" class="btn btn-primary">Share Form</button>
                <button id="switch-to-edit" class="btn btn-secondary">Edit</button>
                #{generate_style_selector()}
            </div>
        </div>
    </div>
    """
  end

  defp generate_editing_toolbar(document_id) do
    """
    <div class="editing-toolbar">
        <div class="toolbar-content">
            <h3>Form Editor</h3>
            <div class="toolbar-actions">
                <button id="toggle-edit" class="btn btn-secondary">Switch to Preview</button>
                <button id="save-changes" class="btn btn-primary">Save Changes</button>
                <button id="reset-form" class="btn btn-secondary">Reset</button>
                <button id="add-field" class="btn btn-secondary">Add Field</button>
                #{generate_style_selector()}
            </div>
        </div>
    </div>
    """
  end

  defp generate_editing_css do
    """
    <style>
        /* Toolbar Styles for both Edit and Preview modes */
        .editing-toolbar,
        .preview-toolbar {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            background: #ffffff;
            border-bottom: 1px solid #e5e7eb;
            color: #374151;
            padding: 1rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            z-index: 1000;
        }

        /* Body spacing for toolbar modes */
        .editing-mode,
        .preview-mode {
            padding-top: 5rem;
        }

        .toolbar-content {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .toolbar-actions {
            display: flex;
            gap: 0.5rem;
        }

        .btn {
            padding: 0.6rem 1.2rem;
            border: 1px solid transparent;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.875rem;
            font-weight: 500;
            transition: all 0.2s ease;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }

        .btn-primary {
            background: #3b82f6;
            color: white;
            border-color: #3b82f6;
        }
        .btn-primary:hover {
            background: #2563eb;
            border-color: #2563eb;
        }

        .btn-secondary {
            background: #f9fafb;
            color: #374151;
            border-color: #d1d5db;
        }
        .btn-secondary:hover {
            background: #f3f4f6;
            border-color: #9ca3af;
        }

        /* Style Selector */
        .style-selector {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-left: 1rem;
        }

        .style-label {
            font-size: 0.875rem;
            font-weight: 500;
            color: #374151;
            margin: 0;
        }

        .style-select {
            padding: 0.6rem 1.2rem;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            background: #f9fafb;
            font-size: 0.875rem;
            font-weight: 500;
            color: #374151;
            min-width: 140px;
            cursor: pointer;
            transition: all 0.2s ease;
            appearance: none;
            background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%23374151' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e");
            background-position: right 0.75rem center;
            background-repeat: no-repeat;
            background-size: 1.25em 1.25em;
            padding-right: 2.5rem;
        }

        .style-select:hover {
            background: #f3f4f6;
            border-color: #9ca3af;
        }

        .style-select:focus {
            background: #f3f4f6;
            outline: 0;
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
        }

        .style-select option {
            background: white;
            color: #374151;
            padding: 0.5rem;
        }


        .btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 6px rgba(0,0,0,0.15);
            filter: brightness(1.1);
        }

        .btn:active {
            transform: translateY(0);
            box-shadow: 0 1px 3px rgba(0,0,0,0.2);
        }

        .editing-mode .container { margin-top: 80px; }

        .editable-field-wrapper {
            position: relative;
            margin-bottom: 1.5rem;
            padding: 1rem;
            border: 2px dashed transparent;
            border-radius: 8px;
            transition: all 0.2s ease;
        }


        .editable-field-wrapper:hover {
            border-color: #3498db;
            background: rgba(52, 152, 219, 0.05);
        }

        .editable-field-wrapper.dragging {
            transform: rotate(2deg);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
            z-index: 100;
        }

        .drag-handle {
            position: absolute;
            left: -10px;
            top: 50%;
            transform: translateY(-50%);
            width: 20px;
            height: 40px;
            background: #3498db;
            border-radius: 4px;
            cursor: grab;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            opacity: 0;
            transition: opacity 0.2s ease;
        }

        .editable-field-wrapper:hover .drag-handle {
            opacity: 1;
        }

        .drag-handle:active { cursor: grabbing; }

        .drag-handle::before {
            content: "⋮⋮";
            font-size: 12px;
            line-height: 1;
            letter-spacing: -2px;
        }

        .field-controls {
            position: absolute;
            top: -10px;
            right: -10px;
            display: flex;
            gap: 0.25rem;
            opacity: 0;
            transition: opacity 0.2s ease;
            z-index: 50;
        }

        .editable-field-wrapper:hover .field-controls {
            opacity: 1;
        }


        .control-btn {
            width: 28px;
            height: 28px;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            cursor: pointer;
            font-size: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: white;
            color: #6b7280;
            transition: all 0.15s ease;
            box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        }

        .remove-btn {
            background: #f8f9fa;
            color: #6c757d;
            border-color: #dee2e6;
        }
        .remove-btn:hover {
            background: #e9ecef;
            color: #495057;
            border-color: #adb5bd;
        }

        .type-btn {
            background: #f8f9fa;
            color: #6c757d;
            border-color: #dee2e6;
        }
        .type-btn:hover {
            background: #e9ecef;
            color: #495057;
            border-color: #adb5bd;
        }

        .editable-label {
            background: rgba(241, 196, 15, 0.2);
            padding: 2px 4px;
            border-radius: 3px;
            cursor: text;
            transition: background-color 0.2s ease;
        }

        .editable-label:hover {
            background: rgba(241, 196, 15, 0.3);
        }

        .editable-label:focus {
            outline: 2px solid #f1c40f;
            background: rgba(241, 196, 15, 0.4);
        }

        .add-field-zone {
            border: 2px dashed #bdc3c7;
            border-radius: 8px;
            padding: 2rem;
            text-align: center;
            margin-top: 2rem;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .add-field-zone:hover {
            border-color: #3498db;
            background: rgba(52, 152, 219, 0.05);
        }

        .drop-zone {
            border: 2px dashed #3498db;
            background: rgba(52, 152, 219, 0.1);
            border-radius: 8px;
            padding: 1rem;
            margin: 0.5rem 0;
            text-align: center;
            opacity: 0;
            transition: all 0.2s ease;
        }

        .drop-zone.active {
            opacity: 1;
        }

        #save-status {
            position: fixed;
            top: 90px;
            right: 20px;
            padding: 0.5rem 1rem;
            border-radius: 4px;
            font-size: 0.9rem;
            opacity: 0;
            transition: opacity 0.3s ease;
            z-index: 999;
        }

        #save-status.success {
            background: #27ae60;
            color: white;
            opacity: 1;
        }

        #save-status.error {
            background: #e74c3c;
            color: white;
            opacity: 1;
        }

        /* Field Edit Dialog */
        .field-edit-modal {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: transparent;
            z-index: 2000;
            opacity: 0;
            visibility: hidden;
            transition: all 0.3s ease;
            pointer-events: none;
        }

        .field-edit-modal.active {
            opacity: 1;
            visibility: visible;
            pointer-events: auto;
        }

        .field-edit-dialog {
            position: fixed;
            right: 20px;
            top: 120px;
            background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
            border-radius: 16px;
            padding: 0;
            width: 340px;
            max-height: calc(100vh - 140px);
            overflow: hidden;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15), 0 8px 20px rgba(0, 0, 0, 0.08);
            transform: translateX(100%);
            transition: transform 0.4s cubic-bezier(0.4, 0, 0.2, 1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(20px);
            z-index: 2001;
        }

        .field-edit-modal.active .field-edit-dialog {
            transform: translateX(0);
        }

        .field-edit-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 1.5rem 1.5rem 1rem 1.5rem;
            margin-bottom: 0;
            background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
            border-radius: 16px 16px 0 0;
            position: relative;
        }

        .field-edit-header::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 1px;
            background: linear-gradient(90deg, transparent 0%, rgba(255, 255, 255, 0.3) 50%, transparent 100%);
        }

        .field-edit-title {
            font-size: 1.1rem;
            font-weight: 600;
            color: white;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .field-edit-title::before {
            content: '🎨';
            font-size: 1rem;
        }

        .field-edit-content {
            padding: 1.5rem;
            overflow-y: auto;
            max-height: calc(100vh - 220px);
        }

        .field-edit-close {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            font-size: 1.2rem;
            color: white;
            cursor: pointer;
            padding: 0.5rem;
            border-radius: 8px;
            transition: all 0.2s ease;
            width: 32px;
            height: 32px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .field-edit-close:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: scale(1.1);
        }

        .field-edit-form {
            display: flex;
            flex-direction: column;
            gap: 1.5rem;
        }

        .field-group {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }

        .field-group label {
            font-weight: 600;
            color: #34495e;
            font-size: 0.9rem;
        }

        .field-group input,
        .field-group select,
        .field-group textarea {
            padding: 0.75rem;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            font-size: 1rem;
            transition: border-color 0.2s ease;
        }

        .field-group input:focus,
        .field-group select:focus,
        .field-group textarea:focus {
            outline: none;
            border-color: #3498db;
            box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
        }

        .field-options-container {
            border: 2px solid #e9ecef;
            border-radius: 8px;
            padding: 1rem;
            background: #f8f9fa;
        }

        .field-options-list {
            list-style: none;
            padding: 0;
            margin: 0;
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }

        .field-option-item {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .field-option-input {
            flex: 1;
            padding: 0.5rem;
            border: 1px solid #ddd;
            border-radius: 4px;
        }

        .remove-option-btn {
            background: #fef2f2;
            color: #dc2626;
            border: 1px solid #fecaca;
            border-radius: 4px;
            padding: 0.5rem;
            cursor: pointer;
            font-size: 0.8rem;
            transition: all 0.15s ease;
        }

        .remove-option-btn:hover {
            background: #fecaca;
            color: #b91c1c;
            border-color: #f87171;
        }

        .add-option-btn {
            background: #f0fdf4;
            color: #059669;
            border: 1px solid #bbf7d0;
            border-radius: 4px;
            padding: 0.5rem 1rem;
            cursor: pointer;
            font-size: 0.9rem;
            margin-top: 0.5rem;
            transition: all 0.15s ease;
        }

        .add-option-btn:hover {
            background: #dcfce7;
            color: #047857;
            border-color: #86efac;
        }

        .field-edit-actions {
            display: flex;
            gap: 1rem;
            justify-content: flex-end;
            padding-top: 1rem;
            border-top: 2px solid #f0f0f0;
        }

        .field-edit-btn {
            padding: 0.75rem 1.5rem;
            border: 1px solid transparent;
            border-radius: 6px;
            font-size: 0.875rem;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }

        .field-edit-btn.cancel {
            background: #f9fafb;
            color: #374151;
            border-color: #d1d5db;
        }

        .field-edit-btn.cancel:hover {
            background: #f3f4f6;
            border-color: #9ca3af;
        }

        .field-edit-btn.save {
            background: #059669;
            color: white;
            border-color: #059669;
        }

        .field-edit-btn.save:hover {
            background: #047857;
            border-color: #047857;
            transform: translateY(-1px);
            box-shadow: 0 2px 6px rgba(0,0,0,0.15);
        }

        /* Add Field Dialog */
        .add-field-modal {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: transparent;
            z-index: 2000;
            opacity: 0;
            visibility: hidden;
            transition: all 0.3s ease;
            pointer-events: none;
        }

        .add-field-modal.active {
            opacity: 1;
            visibility: visible;
            pointer-events: auto;
        }

        .add-field-dialog {
            position: fixed;
            left: 20px;
            top: 120px;
            background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
            border-radius: 16px;
            padding: 0;
            width: 340px;
            max-height: calc(100vh - 140px);
            overflow: hidden;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15), 0 8px 20px rgba(0, 0, 0, 0.08);
            transform: translateX(-100%);
            transition: transform 0.4s cubic-bezier(0.4, 0, 0.2, 1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(20px);
            z-index: 2001;
        }

        .add-field-modal.active .add-field-dialog {
            transform: translateX(0);
        }

        .add-field-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 1.5rem 1.5rem 1rem 1.5rem;
            margin-bottom: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 16px 16px 0 0;
            position: relative;
        }

        .add-field-header::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 1px;
            background: linear-gradient(90deg, transparent 0%, rgba(255, 255, 255, 0.3) 50%, transparent 100%);
        }

        .add-field-title {
            font-size: 1.1rem;
            font-weight: 600;
            color: white;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .add-field-title::before {
            content: '✨';
            font-size: 1rem;
        }

        .add-field-content {
            padding: 1.5rem;
            overflow-y: auto;
            max-height: calc(100vh - 220px);
        }

        .field-type-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 0.75rem;
            margin-bottom: 1.5rem;
        }

        .field-type-option {
            border: 2px solid #f1f5f9;
            border-radius: 12px;
            padding: 1rem 0.75rem;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
            position: relative;
            overflow: hidden;
        }


        .field-type-option:hover {
            border-color: #3b82f6;
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.1);
            transform: translateY(-1px);
        }

        .field-type-option.selected {
            border-color: #3b82f6;
            background: #eff6ff;
            color: #1e40af;
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
            transform: translateY(-2px);
        }

        .field-type-option.selected .field-type-name {
            color: #1e40af;
        }

        /* Form Elements */
        .field-group {
            margin-bottom: 1.5rem;
        }

        .field-group label {
            display: block;
            font-size: 0.875rem;
            font-weight: 600;
            color: #374151;
            margin-bottom: 0.5rem;
        }

        .field-group input[type="text"],
        .field-group textarea,
        .field-group select {
            width: 100%;
            padding: 0.75rem 1rem;
            border: 2px solid #f1f5f9;
            border-radius: 10px;
            background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
            font-size: 0.875rem;
            transition: all 0.3s ease;
            outline: none;
        }

        .field-group input[type="text"]:focus,
        .field-group textarea:focus,
        .field-group select:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
            background: white;
        }

        .field-group input[type="text"]:hover,
        .field-group textarea:hover,
        .field-group select:hover {
            border-color: #e2e8f0;
        }

        /* Action Buttons */
        .field-edit-actions {
            display: flex;
            gap: 0.75rem;
            padding-top: 1rem;
            border-top: 1px solid #f1f5f9;
            margin-top: 1.5rem;
        }

        .field-edit-btn {
            flex: 1;
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 10px;
            font-size: 0.875rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }


        .field-edit-btn.cancel {
            background: #f3f4f6;
            color: #374151;
            border: 1px solid #d1d5db;
        }

        .field-edit-btn.cancel:hover {
            background: #e5e7eb;
            border-color: #9ca3af;
            transform: translateY(-1px);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        .field-edit-btn.save {
            background: #3b82f6;
            color: white;
            border: 1px solid #3b82f6;
        }

        .field-edit-btn.save:hover {
            background: #2563eb;
            border-color: #2563eb;
            transform: translateY(-1px);
            box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
        }

        .field-type-icon {
            font-size: 2rem;
            margin-bottom: 0.5rem;
            display: block;
        }

        .field-type-name {
            font-weight: 600;
            color: #374151;
            font-size: 0.9rem;
        }

        /* Drop Zones for field insertion */
        .field-drop-zone {
            height: 12px;
            background: rgba(59, 130, 246, 0.05);
            border: 1px dashed rgba(59, 130, 246, 0.3);
            border-radius: 4px;
            margin: 0.75rem 0;
            transition: all 0.2s ease;
            opacity: 0.6;
            position: relative;
            cursor: pointer;
        }

        .field-drop-zone::before {
            content: "Click to insert field here";
            position: absolute;
            left: 50%;
            top: 50%;
            transform: translate(-50%, -50%);
            background: rgba(255, 255, 255, 0.9);
            color: #6b7280;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 11px;
            white-space: nowrap;
            opacity: 0;
            transition: opacity 0.2s ease;
            border: 1px solid rgba(59, 130, 246, 0.2);
        }

        .field-drop-zone:hover {
            opacity: 1;
            background: rgba(59, 130, 246, 0.1);
            border-color: #3b82f6;
            height: 24px;
        }

        .field-drop-zone:hover::before {
            opacity: 1;
        }

        .field-drop-zone.active {
            opacity: 1;
            height: 40px;
            background: rgba(59, 130, 246, 0.1);
            border-color: #3b82f6;
        }

        .field-drop-zone.active::before {
            opacity: 1;
        }

        .field-drop-zone.drag-over {
            background: rgba(59, 130, 246, 0.2);
            border-color: #1d4ed8;
        }

        /* Editable title styling */
        .editable-title {
            position: relative;
            border: 2px solid transparent;
            border-radius: 8px;
            padding: 0.5rem;
            transition: all 0.2s ease;
            outline: none;
        }

        .editable-title:hover {
            border-color: rgba(59, 130, 246, 0.3);
            background-color: rgba(59, 130, 246, 0.05);
        }

        .editable-title:focus {
            border-color: #3b82f6;
            background-color: rgba(59, 130, 246, 0.1);
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
        }

        .editable-title::before {
            content: "Click to edit title";
            position: absolute;
            top: -30px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            white-space: nowrap;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.2s ease;
            z-index: 1000;
        }

        .editable-title:hover::before {
            opacity: 1;
        }

        .editable-title:focus::before {
            opacity: 0;
        }

        /* Updated add field button styling */
        .add-field-zone {
            background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
            border: 2px dashed #cbd5e1;
            border-radius: 12px;
            padding: 2rem;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
            margin: 2rem 0;
        }

        .add-field-zone:hover {
            background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%);
            border-color: #3b82f6;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }

        .add-field-zone h3 {
            color: #475569;
            font-size: 1.1rem;
            margin: 0 0 0.5rem 0;
        }

        .add-field-zone p {
            color: #64748b;
            margin: 0;
            font-size: 0.9rem;
        }

        /* Two-Column Visual Layout for Editing */
        .column-layout-container {
            background: #f8fafc;
            border: 2px dashed #cbd5e1;
            border-radius: 12px;
            padding: 1rem;
            margin: 1rem 0;
            min-height: 200px;
            position: relative;
        }

        .column-layout-header {
            text-align: center;
            margin-bottom: 1rem;
            font-size: 0.9rem;
            color: #6b7280;
            font-weight: 500;
        }

        .two-column-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1.5rem;
            min-height: 150px;
        }

        .column-drop-zone {
            border: 2px dashed #e5e7eb;
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.5);
            padding: 1rem;
            position: relative;
            transition: all 0.2s ease;
            min-height: 100px;
        }

        .column-drop-zone::before {
            content: attr(data-column-label);
            position: absolute;
            top: 8px;
            left: 12px;
            font-size: 11px;
            color: #9ca3af;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .column-drop-zone.drag-over {
            border-color: #3b82f6;
            background: rgba(59, 130, 246, 0.1);
        }

        .column-drop-zone.has-fields {
            border-style: solid;
            border-color: #d1d5db;
            background: white;
        }

        .column-field {
            margin-bottom: 0.75rem;
            position: relative;
        }

        .column-field:last-child {
            margin-bottom: 0;
        }

        .column-add-field {
            border: 2px dashed #cbd5e1;
            border-radius: 6px;
            padding: 1rem;
            text-align: center;
            cursor: pointer;
            transition: all 0.2s ease;
            background: rgba(255, 255, 255, 0.5);
            margin-top: 0.75rem;
            color: #6b7280;
            font-size: 14px;
        }

        .column-add-field:hover {
            border-color: #3b82f6;
            background: rgba(59, 130, 246, 0.05);
            color: #3b82f6;
            transform: translateY(-1px);
        }

        .column-add-field .add-field-icon {
            display: block;
            font-size: 18px;
            margin-bottom: 4px;
        }

        .column-add-field .add-field-text {
            font-size: 12px;
            font-weight: 500;
        }

        /* Hide add field buttons when column has no fields */
        .column-drop-zone:not(.has-fields) .column-add-field {
            border-style: solid;
            border-color: #e5e7eb;
            background: rgba(255, 255, 255, 0.8);
        }

        .column-toggle-btn {
            position: absolute;
            top: 10px;
            right: 10px;
            background: rgba(59, 130, 246, 0.9);
            color: white;
            border: none;
            border-radius: 6px;
            padding: 6px 12px;
            font-size: 11px;
            cursor: pointer;
            transition: all 0.2s ease;
            z-index: 100;
            font-weight: 500;
        }

        .column-toggle-btn:hover {
            background: #2563eb;
            transform: scale(1.05);
        }

        /* Hide regular field layout when column layout is active */
        .editable-content.column-layout-active > .editable-field-wrapper {
            display: none !important;
        }

        .editable-content.column-layout-active > .field-drop-zone {
            display: none !important;
        }

        .editable-content.column-layout-active > .add-field-zone {
            display: none !important;
        }

        .editable-content.column-layout-active .field-drop-zone {
            display: none !important;
        }

        .editable-content.column-layout-active .drop-zone {
            display: none !important;
        }

        /* Radio fieldset styling */
        .radio-fieldset {
            border: 2px solid #e2e8f0;
            border-radius: 8px;
            padding: 1rem;
            margin: 0.5rem 0;
        }

        .radio-group-fieldset {
            border: 1px solid #d1d5db;
            border-radius: 6px;
            padding: 1rem;
            margin: 0;
            background: #f9fafb;
        }

        .radio-group-fieldset legend {
            font-weight: 600;
            color: #374151;
            padding: 0 0.5rem;
            margin-bottom: 0.75rem;
        }

        .radio-option {
            display: flex;
            align-items: center;
            margin: 0.5rem 0;
            gap: 0.5rem;
        }

        .radio-option input[type="radio"] {
            margin: 0;
            transform: scale(1.2);
        }

        .radio-option label {
            margin: 0;
            font-weight: normal;
            flex: 1;
        }

        /* Form Submission Styles */
        .form-submit-section {
            margin-top: 2rem;
            padding: 1.5rem;
            border-top: 2px solid #e5e7eb;
            text-align: center;
        }

        .btn-large {
            padding: 1rem 2rem;
            font-size: 1.1rem;
            font-weight: 600;
            min-width: 200px;
        }

        .form-status {
            margin-top: 1rem;
            padding: 1rem;
            border-radius: 8px;
            font-weight: 500;
        }

        .form-status.success {
            background: #f0fdf4;
            border: 1px solid #bbf7d0;
            color: #166534;
        }

        .form-status.error {
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #dc2626;
        }

        .form-status.loading {
            background: #eff6ff;
            border: 1px solid #bfdbfe;
            color: #1d4ed8;
        }

        .loading-spinner {
            display: inline-block;
            width: 1rem;
            height: 1rem;
            border: 2px solid #ffffff;
            border-top: 2px solid transparent;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-right: 0.5rem;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

    </style>
    """
  end

  defp generate_editable_section(section, index) do
    type = section["type"] || "paragraph"
    content = section["content"] || ""
    formatting = section["formatting"] || %{}
    field_name = get_in(section, ["metadata", "field_name"]) || "field_#{index}"

    # Check if this is a user-added field and ensure proper prefix
    data_index = if Map.has_key?(section, "form_field_id") do
      form_field_id = section["form_field_id"]
      # Ensure user fields have the user_field_ prefix for JavaScript detection
      if String.starts_with?(form_field_id, "user_field_") do
        form_field_id
      else
        "user_field_#{form_field_id}"
      end
    else
      "ai_field_#{index}"  # Use different prefix for AI-processed fields
    end

    # Debug logging to track data_index generation
    IO.puts("🔧 HTML Generation Debug: section #{index}, type: #{type}, form_field_id present: #{Map.has_key?(section, "form_field_id")}, data_index: #{data_index}")

    # Check if field should be half-width
    width_class = case get_in(formatting, ["width"]) do
      "half" -> " half-width"
      _ -> ""
    end

    # Handle new AI-detected form elements first
    form_element = case type do
      "form_input" ->
        if get_in(section, ["metadata", "input_type"]) do
          generate_editable_form_input(content, section, field_name)
        else
          # Fallback to legacy generation
          generate_legacy_editable_element(type, content, field_name, section)
        end

      "form_label" ->
        # Check if this label has an associated input field - if so, skip rendering it
        # because it will be included in the form_input rendering
        label_field_name = get_in(section, ["metadata", "field_name"])
        if label_field_name do
          # This label is associated with a form input - don't render it separately
          # Return empty string to avoid duplication
          ""
        else
          # This is standalone descriptive text (like a question)
          "<div class=\"form-question editable-label\" contenteditable=\"true\" data-field=\"#{field_name}\">#{escape_html(content)}</div>"
        end

      "form_title" ->
        "<h1 class=\"form-title editable-label\" contenteditable=\"true\" data-field=\"#{field_name}\">#{escape_html(content)}</h1>"

      "form_section" ->
        "<h2 class=\"form-section editable-label\" contenteditable=\"true\" data-field=\"#{field_name}\">#{escape_html(content)}</h2>"

      _ ->
        # Fallback to legacy generation for old types
        generate_legacy_editable_element(type, content, field_name, section)
    end

    """
    <div class="editable-field-wrapper form-field#{width_class}" data-index="#{data_index}" data-type="#{type}" draggable="true">
        <div class="drag-handle"></div>
        <div class="field-controls">
            <button class="control-btn type-btn" title="Change field type">⚙</button>
            <button class="control-btn remove-btn" title="Remove field">×</button>
        </div>
        #{form_element}
    </div>
    """
  end

  defp generate_editable_form_input(content, section, field_name) do
    input_type = get_in(section, ["metadata", "input_type"])

    case input_type do
      "checkbox" ->
        """
        <div class="checkbox-field">
          <input type="checkbox" id="#{field_name}" name="#{field_name}" />
          <label class="editable-label" contenteditable="true" data-field="#{field_name}" for="#{field_name}">#{escape_html(content)}</label>
        </div>
        """

      "radio" ->
        # Match preview mode - create individual radio button like preview mode does
        field_value = get_in(section, ["metadata", "field_value"]) || escape_html(content)
        radio_id = "#{field_name}_#{sanitize_field_name(field_value)}"

        """
        <div class="form-field">
          <input type="radio" id="#{radio_id}" name="#{field_name}" value="#{escape_html(field_value)}" />
          <label class="editable-label" contenteditable="true" data-field="#{field_name}" for="#{radio_id}">#{escape_html(content)}</label>
        </div>
        """

      "select" ->
        options = get_in(section, ["metadata", "options"]) || ["Option 1", "Option 2", "Option 3"]
        options_html = Enum.map_join(options, "", fn option ->
          "<option value=\"#{escape_html(option)}\">#{escape_html(option)}</option>"
        end)

        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <select id="#{field_name}" name="#{field_name}">#{options_html}</select>
        """

      "date" ->
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <input type="date" id="#{field_name}" name="#{field_name}" />
        """

      "email" ->
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <input type="email" id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" />
        """

      "textarea" ->
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <textarea id="#{field_name}" name="#{field_name}" rows="3" placeholder="#{escape_html(content)}"></textarea>
        """

      "tel" ->
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <input type="tel" id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" />
        """

      "number" ->
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <input type="number" id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" />
        """

      _ ->
        # Default to text input
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <input type="text" id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" />
        """
    end
  end

  defp generate_legacy_editable_element(type, content, field_name, section) do
    case type do
      "text" ->
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <input type="text" id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" />
        """

      "textarea" ->
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <textarea id="#{field_name}" name="#{field_name}" rows="3" placeholder="#{escape_html(content)}"></textarea>
        """

      "checkbox" ->
        """
        <div class="checkbox-field">
          <input type="checkbox" id="#{field_name}" name="#{field_name}" />
          <label class="editable-label" contenteditable="true" data-field="#{field_name}" for="#{field_name}">#{escape_html(content)}</label>
        </div>
        """

      "select" ->
        options = get_in(section, ["metadata", "options"]) || ["Option 1", "Option 2", "Option 3"]
        options_html = Enum.map_join(options, "", fn option ->
          "<option value=\"#{escape_html(option)}\">#{escape_html(option)}</option>"
        end)

        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <select id="#{field_name}" name="#{field_name}">#{options_html}</select>
        """

      "email" ->
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <input type="email" id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" />
        """

      "date" ->
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <input type="date" id="#{field_name}" name="#{field_name}" />
        """

      "radio" ->
        # Handle radio button with multiple options for user-added fields
        options = get_in(section, ["metadata", "options"]) || ["Option 1", "Option 2", "Option 3"]
        radio_buttons = Enum.with_index(options, fn option, idx ->
          radio_id = "#{field_name}_#{idx}"
          """
          <div class="radio-option">
            <input type="radio" id="#{radio_id}" name="#{field_name}" value="#{escape_html(option)}" />
            <label class="editable-label" contenteditable="true" data-field="#{field_name}_#{idx}" for="#{radio_id}">#{escape_html(option)}</label>
          </div>
          """
        end) |> Enum.join("")

        """
        <div class="form-field radio-group">
          <div class="form-question editable-label" contenteditable="true" data-field="#{field_name}_question">#{escape_html(content)}</div>
          <div class="radio-options">
            #{radio_buttons}
          </div>
        </div>
        """

      _ ->
        """
        <label class="editable-label" contenteditable="true" data-field="#{field_name}">#{escape_html(content)}</label>
        <input type="text" id="#{field_name}" name="#{field_name}" placeholder="#{escape_html(content)}" />
        """
    end
  end

  defp generate_add_field_button do
    """
    <div class="add-field-zone" id="add-field-zone">
        <h3>➕ Add New Field</h3>
        <p>Click here to add a new form field</p>
    </div>
    """
  end


  defp generate_editing_javascript(document_id) do
    """
    <script>
        // Form editing functionality
        let isEditingMode = true;
        let draggedElement = null;
        let formData = [];

        document.addEventListener('DOMContentLoaded', function() {
            initializeFormEditor();
        });

        function initializeFormEditor() {
            // Ensure clean state at startup
            isColumnLayoutActive = false;
            window.targetColumn = null;
            window.insertionIndex = null;

            // Initialize drag and drop
            initializeDragDrop();

            // Initialize toolbar buttons
            initializeToolbarButtons();

            // Initialize label editing
            initializeLabelEditing();

            // Initialize field controls
            initializeFieldControls();

            // Initialize title editing
            initializeTitleEditing();

            // Load initial form data
            loadFormData();

            // Show save status element
            const statusDiv = document.createElement('div');
            statusDiv.id = 'save-status';
            document.body.appendChild(statusDiv);

            // Create field edit modal
            createFieldEditModal();

            // Create add field modal
            createAddFieldModal();

            // Initialize dialog position update function
            window.updateDialogPosition = function() {
                const toolbar = document.querySelector('.editing-toolbar');
                const toolbarHeight = toolbar ? toolbar.offsetHeight : 80;

                // Simple approach: always position dialogs just below the toolbar
                const fixedTop = toolbarHeight + 20;

                // Update add field dialog position (left side)
                const addDialog = document.querySelector('.add-field-dialog');
                if (addDialog && addDialog.closest('.add-field-modal.active')) {
                    addDialog.style.position = 'fixed';
                    addDialog.style.top = fixedTop + 'px';
                    addDialog.style.left = '20px';
                    addDialog.style.maxHeight = 'calc(100vh - ' + (toolbarHeight + 40) + 'px)';
                }

                // Update edit field dialog position (right side)
                const editDialog = document.querySelector('.field-edit-dialog');
                if (editDialog && editDialog.closest('.field-edit-modal.active')) {
                    editDialog.style.position = 'fixed';
                    editDialog.style.top = fixedTop + 'px';
                    editDialog.style.right = '20px';
                    editDialog.style.maxHeight = 'calc(100vh - ' + (toolbarHeight + 40) + 'px)';
                }
            };

            // Clean up any existing drop zones and initialize fresh
            cleanupAllDropZones();
            initializeDropZones();

            // Define updateDocumentContentClass function
            window.updateDocumentContentClass = function() {
                const documentContent = document.querySelector('.document-content');
                if (documentContent) {
                    documentContent.classList.add('editable-content');
                }
            };

            // Initial document content class update
            updateDocumentContentClass();
        }

        function initializeDragDrop() {
            const fields = document.querySelectorAll('.editable-field-wrapper');

            fields.forEach((field, index) => {
                field.addEventListener('dragstart', handleDragStart);
                field.addEventListener('dragend', handleDragEnd);
                field.addEventListener('dragover', handleDragOver);
                field.addEventListener('drop', handleDrop);
            });
        }

        function handleDragStart(e) {
            draggedElement = e.target;
            e.target.classList.add('dragging');
            e.dataTransfer.effectAllowed = 'move';
        }

        function handleDragEnd(e) {
            e.target.classList.remove('dragging');
            if (!isColumnLayoutActive) {
                document.querySelectorAll('.drop-zone').forEach(zone => zone.remove());
            }
        }

        function handleDragOver(e) {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';

            // Show drop zones only if not in column layout
            if (!isColumnLayoutActive && !document.querySelector('.drop-zone')) {
                createDropZones();
            }
        }

        function handleDrop(e) {
            e.preventDefault();
            if (draggedElement && draggedElement !== e.target) {
                const container = document.querySelector('.editable-content');
                const targetField = e.target.closest('.editable-field-wrapper');

                if (targetField && targetField !== draggedElement) {
                    // Insert before the target
                    container.insertBefore(draggedElement, targetField);

                    // Update field positions and indices after reordering
                    updateFieldPositions();
                    updateFormData();
                }
            }
        }

        function updateFieldPositions() {
            // Get all user-added fields (those with user_field_ data-index)
            const userFields = document.querySelectorAll('.editable-field-wrapper[data-index^="user_field_"]');

            userFields.forEach((field, index) => {
                // Update the position metadata for visual positioning
                const yPosition = index * 50; // 50px spacing between fields
                field.style.order = index; // CSS order for flex layouts

                // Update any position-related attributes if needed
                field.setAttribute('data-position', index);
            });

            // Show position update feedback
            const saveStatus = document.getElementById('save-status');
            if (saveStatus && userFields.length > 1) {
                saveStatus.textContent = 'Field positions updated';
                saveStatus.className = 'info';
                saveStatus.style.opacity = '1';
                setTimeout(() => {
                    saveStatus.style.opacity = '0';
                }, 2000);
            }
        }

        function createDropZones() {
            if (isColumnLayoutActive) return;
            const fields = document.querySelectorAll('.editable-field-wrapper');
            fields.forEach(field => {
                const dropZone = document.createElement('div');
                dropZone.className = 'drop-zone active';
                dropZone.innerHTML = 'Drop here to reorder';
                field.parentNode.insertBefore(dropZone, field);
            });
        }

        function initializeToolbarButtons() {
            // Toggle edit mode (switch to preview)
            const toggleEditBtn = document.getElementById('toggle-edit');
            if (toggleEditBtn) {
                toggleEditBtn.addEventListener('click', togglePreviewMode);
            }

            // Initialize theme selector
            initializeThemeSelector();


            // Save changes
            const saveBtn = document.getElementById('save-changes');
            if (saveBtn) {
                saveBtn.addEventListener('click', saveFormChanges);
            }

            // Reset form
            const resetBtn = document.getElementById('reset-form');
            if (resetBtn) {
                resetBtn.addEventListener('click', resetForm);
            }

            // Add field
            const addFieldBtn = document.getElementById('add-field');
            if (addFieldBtn) {
                addFieldBtn.addEventListener('click', addNewField);
            }

            const addFieldZone = document.getElementById('add-field-zone');
            if (addFieldZone) {
                addFieldZone.addEventListener('click', addNewField);
            }
        }

        function initializeLabelEditing() {
            document.addEventListener('blur', function(e) {
                if (e.target.classList.contains('editable-label')) {
                    const fieldName = e.target.getAttribute('data-field');
                    const newText = e.target.textContent.trim() || 'Untitled Field';
                    e.target.textContent = newText;
                    updateFormData();
                }
            }, true);

            document.addEventListener('keydown', function(e) {
                if (e.target.classList.contains('editable-label') && e.key === 'Enter') {
                    e.preventDefault();
                    e.target.blur();
                }
            });
        }

        function initializeTitleEditing() {
            const titleElement = document.querySelector('.editable-title');
            if (!titleElement) return;

            // Store original title
            const originalTitle = titleElement.getAttribute('data-original-title');

            // Handle focus event - select all text
            titleElement.addEventListener('focus', function() {
                // Select all text when focused
                const range = document.createRange();
                range.selectNodeContents(this);
                const selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(range);
            });

            // Handle blur event - save changes
            titleElement.addEventListener('blur', function() {
                const newTitle = this.textContent.trim() || 'Document';
                this.textContent = newTitle;

                // Only save if title actually changed
                if (newTitle !== originalTitle) {
                    saveTitleChange(newTitle);
                    this.setAttribute('data-original-title', newTitle);
                }
            });

            // Handle Enter key - save and blur
            titleElement.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    this.blur();
                } else if (e.key === 'Escape') {
                    // Revert to original title
                    this.textContent = originalTitle;
                    this.blur();
                }
            });

            // Prevent line breaks
            titleElement.addEventListener('paste', function(e) {
                e.preventDefault();
                const text = (e.clipboardData || window.clipboardData).getData('text/plain');
                const cleanText = text.replace(/\\n/g, ' ').replace(/\\r/g, '');
                document.execCommand('insertText', false, cleanText);
            });
        }

        async function saveTitleChange(newTitle) {
            const saveStatus = document.getElementById('save-status');
            saveStatus.textContent = 'Saving title...';
            saveStatus.className = '';
            saveStatus.style.opacity = '1';

            try {
                const response = await fetch(`/api/documents/#{document_id}/title`, {
                    method: 'PATCH',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        title: newTitle
                    })
                });

                if (response.ok) {
                    saveStatus.textContent = '✓ Title saved successfully!';
                    saveStatus.className = 'success';
                    setTimeout(() => {
                        saveStatus.style.opacity = '0';
                    }, 3000);

                    // Update page title as well
                    document.title = newTitle;
                } else {
                    throw new Error('Failed to save title');
                }
            } catch (error) {
                console.error('Save title error:', error);
                saveStatus.textContent = '✗ Failed to save title';
                saveStatus.className = 'error';
                setTimeout(() => {
                    saveStatus.style.opacity = '0';
                }, 5000);
            }
        }

        function initializeFieldControls() {
            document.addEventListener('click', function(e) {
                if (e.target.classList.contains('remove-btn')) {
                    removeField(e.target.closest('.editable-field-wrapper'));
                } else if (e.target.classList.contains('type-btn')) {
                    changeFieldType(e.target.closest('.editable-field-wrapper'));
                }
            });
        }

        function removeField(fieldWrapper) {
            if (confirm('Are you sure you want to remove this field?')) {
                fieldWrapper.remove();
                updateFormData();

                // Refresh drop zones after removal (only if not in column mode)
                if (!isColumnLayoutActive) {
                    addDropZonesBetweenFields();
                }
            }
        }

        function changeFieldType(fieldWrapper) {
            openFieldEditDialog(fieldWrapper);
        }

        function createFieldEditModal() {
            const modalHTML = \`
                <div id="field-edit-modal" class="field-edit-modal">
                    <div class="field-edit-dialog">
                        <div class="field-edit-header">
                            <h3 class="field-edit-title">Edit Field</h3>
                            <button class="field-edit-close" onclick="closeFieldEditDialog()">×</button>
                        </div>

                        <div class="field-edit-content">
                            <form class="field-edit-form" onsubmit="saveFieldChanges(event)">
                            <div class="field-group">
                                <label for="field-label">Field Label</label>
                                <input type="text" id="field-label" name="label" required>
                            </div>

                            <div class="field-group">
                                <label for="field-type">Field Type</label>
                                <select id="field-type" name="type" onchange="handleFieldTypeChange()">
                                    <option value="text">Text Input</option>
                                    <option value="textarea">Textarea</option>
                                    <option value="email">Email</option>
                                    <option value="date">Date</option>
                                    <option value="select">Dropdown</option>
                                    <option value="checkbox">Checkbox</option>
                                </select>
                            </div>

                            <div class="field-group" id="field-placeholder-group">
                                <label for="field-placeholder">Placeholder Text</label>
                                <input type="text" id="field-placeholder" name="placeholder">
                            </div>

                            <div class="field-group" id="field-required-group">
                                <label>
                                    <input type="checkbox" id="field-required" name="required"> Required Field
                                </label>
                            </div>

                            <div class="field-group" id="field-options-group" style="display: none;">
                                <label id="field-options-label">Options</label>
                                <div class="field-options-container">
                                    <ul id="field-options-list" class="field-options-list"></ul>
                                    <button type="button" class="add-option-btn" onclick="addOption()">+ Add Option</button>
                                </div>
                            </div>

                                <div class="field-edit-actions">
                                    <button type="button" class="field-edit-btn cancel" onclick="closeFieldEditDialog()">Cancel</button>
                                    <button type="submit" class="field-edit-btn save">Save Changes</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            \`;

            document.body.insertAdjacentHTML('beforeend', modalHTML);
        }

        function openFieldEditDialog(fieldWrapper) {
            window.currentEditingField = fieldWrapper;
            const modal = document.getElementById('field-edit-modal');
            const label = fieldWrapper.querySelector('.editable-label')?.textContent || 'Field';
            const type = fieldWrapper.getAttribute('data-type') || 'text';

            // Populate form
            document.getElementById('field-label').value = label;
            document.getElementById('field-type').value = type;

            // Handle type-specific fields
            handleFieldTypeChange();

            // Update dialog position to ensure it's properly positioned
            updateDialogPosition();

            // Show modal
            modal.classList.add('active');
        }

        function closeFieldEditDialog() {
            const modal = document.getElementById('field-edit-modal');
            modal.classList.remove('active');
            window.currentEditingField = null;
        }

        function handleFieldTypeChange() {
            const type = document.getElementById('field-type').value;
            const placeholderGroup = document.getElementById('field-placeholder-group');
            const optionsGroup = document.getElementById('field-options-group');
            const requiredGroup = document.getElementById('field-required-group');

            // Show/hide fields based on type
            if (type === 'select') {
                placeholderGroup.style.display = 'none';
                optionsGroup.style.display = 'block';
                document.getElementById('field-options-label').textContent = 'Dropdown Options';
                populateOptions();
            } else if (type === 'radio') {
                placeholderGroup.style.display = 'none';
                optionsGroup.style.display = 'block';
                document.getElementById('field-options-label').textContent = 'Radio Button Options';
                populateOptions();
            } else if (type === 'checkbox') {
                placeholderGroup.style.display = 'none';
                optionsGroup.style.display = 'none';
            } else {
                placeholderGroup.style.display = 'block';
                optionsGroup.style.display = 'none';
            }
        }

        function populateOptions() {
            const optionsList = document.getElementById('field-options-list');
            optionsList.innerHTML = '';

            // Add default options or existing ones
            const defaultOptions = ['Option 1', 'Option 2', 'Option 3'];
            defaultOptions.forEach(option => {
                addOptionToList(option);
            });
        }

        function addOption() {
            addOptionToList('New Option');
        }

        function addOptionToList(value = '') {
            const optionsList = document.getElementById('field-options-list');
            const optionItem = document.createElement('li');
            optionItem.className = 'field-option-item';
            optionItem.innerHTML = \`
                <input type="text" class="field-option-input" value="\${value}" placeholder="Option text">
                <button type="button" class="remove-option-btn" onclick="removeOption(this)">×</button>
            \`;
            optionsList.appendChild(optionItem);
        }

        function removeOption(button) {
            button.parentElement.remove();
        }

        function handleAddFieldTypeChange() {
            const selectedType = document.querySelector('.field-type-option.selected');
            const fieldType = selectedType ? selectedType.getAttribute('data-type') : 'text';
            const optionsGroup = document.getElementById('add-field-options-group');

            // Show/hide options section based on field type
            if (fieldType === 'radio' || fieldType === 'select') {
                optionsGroup.style.display = 'block';
                document.getElementById('add-field-options-label').textContent =
                    fieldType === 'radio' ? 'Radio Button Options' : 'Dropdown Options';
                populateAddFieldOptions();
            } else {
                optionsGroup.style.display = 'none';
            }
        }

        function populateAddFieldOptions() {
            const optionsList = document.getElementById('add-field-options-list');
            optionsList.innerHTML = '';

            // Add default options
            const defaultOptions = ['Option 1', 'Option 2', 'Option 3'];
            defaultOptions.forEach(option => {
                addNewFieldOptionToList(option);
            });
        }

        function addNewFieldOption() {
            addNewFieldOptionToList('New Option');
        }

        function addNewFieldOptionToList(value = '') {
            const optionsList = document.getElementById('add-field-options-list');
            const optionItem = document.createElement('li');
            optionItem.className = 'field-option-item';
            optionItem.innerHTML = \`
                <input type="text" class="field-option-input" value="\${value}" placeholder="Option text">
                <button type="button" class="remove-option-btn" onclick="removeNewFieldOption(this)">×</button>
            \`;
            optionsList.appendChild(optionItem);
        }

        function removeNewFieldOption(button) {
            button.parentElement.remove();
        }

        function saveFieldChanges(event) {
            event.preventDefault();

            if (!window.currentEditingField) return;

            const label = document.getElementById('field-label').value.trim();
            const type = document.getElementById('field-type').value;

            if (!label) {
                alert('Field label is required');
                return;
            }

            // Update field label
            const labelElement = window.currentEditingField.querySelector('.editable-label');
            if (labelElement) {
                labelElement.textContent = label;
            }

            // Update field type
            window.currentEditingField.setAttribute('data-type', type);

            // Regenerate field HTML based on new type
            regenerateFieldHTML(window.currentEditingField, label, type);

            // Update form data
            updateFormData();

            // Close dialog
            closeFieldEditDialog();

            // Show success message
            const saveStatus = document.getElementById('save-status');
            saveStatus.textContent = '✓ Field updated successfully!';
            saveStatus.className = 'success';
            saveStatus.style.opacity = '1';
            setTimeout(() => {
                saveStatus.style.opacity = '0';
            }, 2000);
        }

        function regenerateFieldHTML(fieldWrapper, label, type) {
            const fieldName = fieldWrapper.getAttribute('data-index') || 'field_new';
            const isHalfWidth = fieldWrapper.classList.contains('half-width');

            let newHTML = '';

            switch(type) {
                case 'textarea':
                    newHTML = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <textarea id="\${fieldName}" name="\${fieldName}" rows="3" placeholder="\${label}"></textarea>
                    \`;
                    break;
                case 'checkbox':
                    newHTML = \`
                        <div class="checkbox-field">
                            <input type="checkbox" id="\${fieldName}" name="\${fieldName}" />
                            <label class="editable-label" contenteditable="true" data-field="\${fieldName}" for="\${fieldName}">\${label}</label>
                        </div>
                    \`;
                    break;
                case 'radio':
                    const radioOptions = Array.from(document.querySelectorAll('.field-option-input'))
                        .map(input => input.value.trim())
                        .filter(value => value)
                        .map(option => \`<label><input type="radio" name="\${fieldName}" value="\${option}" /> \${option}</label>\`)
                        .join('');

                    const defaultRadioOptions = radioOptions || \`
                        <label><input type="radio" name="\${fieldName}" value="option1" /> Option 1</label>
                        <label><input type="radio" name="\${fieldName}" value="option2" /> Option 2</label>
                        <label><input type="radio" name="\${fieldName}" value="option3" /> Option 3</label>
                    \`;

                    newHTML = \`
                        <div class="radio-field">
                            <span class="editable-label radio-group-label" contenteditable="true" data-field="\${fieldName}">\${label}</span>
                            <div class="radio-options">
                                \${defaultRadioOptions}
                            </div>
                        </div>
                    \`;
                    break;
                case 'select':
                    const options = Array.from(document.querySelectorAll('.field-option-input'))
                        .map(input => input.value.trim())
                        .filter(value => value)
                        .map(option => \`<option value="\${option}">\${option}</option>\`)
                        .join('');

                    newHTML = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <select id="\${fieldName}" name="\${fieldName}">\${options}</select>
                    \`;
                    break;
                case 'email':
                    newHTML = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <input type="email" id="\${fieldName}" name="\${fieldName}" placeholder="\${label}" />
                    \`;
                    break;
                case 'date':
                    newHTML = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <input type="date" id="\${fieldName}" name="\${fieldName}" />
                    \`;
                    break;
                default:
                    newHTML = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <input type="text" id="\${fieldName}" name="\${fieldName}" placeholder="\${label}" />
                    \`;
            }

            // Find the form content area and replace it
            const existingContent = fieldWrapper.querySelector('.editable-label')?.parentElement || fieldWrapper;
            const controlsElement = fieldWrapper.querySelector('.field-controls');
            const dragHandle = fieldWrapper.querySelector('.drag-handle');

            // Clear and rebuild field content
            fieldWrapper.innerHTML = '';
            if (dragHandle) fieldWrapper.appendChild(dragHandle);
            if (controlsElement) fieldWrapper.appendChild(controlsElement);
            fieldWrapper.insertAdjacentHTML('beforeend', newHTML);

            // Restore width class if needed
            if (isHalfWidth) {
                fieldWrapper.classList.add('half-width');
            }
        }


        function addNewField() {
            window.insertionIndex = null; // Insert at end
            openAddFieldDialog();
        }

        function editField(fieldWrapper) {
            // Get current field data
            const dataIndex = fieldWrapper.getAttribute('data-index');
            const currentType = fieldWrapper.getAttribute('data-type');
            const labelElement = fieldWrapper.querySelector('.editable-label');
            const currentLabel = labelElement ? labelElement.textContent.trim() : 'Field';
            const isHalfWidth = fieldWrapper.classList.contains('half-width');

            // Get current options if it's a select or radio field
            let currentOptions = [];
            if (currentType === 'radio' || currentType === 'select') {
                const optionElements = fieldWrapper.querySelectorAll('option, .radio-option label');
                currentOptions = Array.from(optionElements).map(opt => opt.textContent.trim()).filter(text => text);
            }

            // Set up edit mode
            window.editingFieldWrapper = fieldWrapper;
            window.editingFieldIndex = dataIndex;

            openEditFieldDialog(currentType, currentLabel, currentOptions, isHalfWidth);
        }

        function createAddFieldModal() {
            const modalHTML = \`
                <div id="add-field-modal" class="add-field-modal">
                    <div class="add-field-dialog">
                        <div class="add-field-header">
                            <h3 class="add-field-title">Add New Field</h3>
                            <button class="field-edit-close" onclick="closeAddFieldDialog()">×</button>
                        </div>

                        <div class="add-field-content">
                            <div class="field-group">
                            <label>Field Label</label>
                            <input type="text" id="new-field-label" placeholder="Enter field label" value="New Field">
                        </div>

                        <div class="field-group">
                            <label>Choose Field Type</label>
                            <div class="field-type-grid">
                                <div class="field-type-option selected" data-type="text">
                                    <span class="field-type-icon">T</span>
                                    <div class="field-type-name">Text Input</div>
                                </div>
                                <div class="field-type-option" data-type="textarea">
                                    <span class="field-type-icon">¶</span>
                                    <div class="field-type-name">Textarea</div>
                                </div>
                                <div class="field-type-option" data-type="email">
                                    <span class="field-type-icon">@</span>
                                    <div class="field-type-name">Email</div>
                                </div>
                                <div class="field-type-option" data-type="date">
                                    <span class="field-type-icon">D</span>
                                    <div class="field-type-name">Date</div>
                                </div>
                                <div class="field-type-option" data-type="select">
                                    <span class="field-type-icon">▼</span>
                                    <div class="field-type-name">Dropdown</div>
                                </div>
                                <div class="field-type-option" data-type="checkbox">
                                    <span class="field-type-icon">☑</span>
                                    <div class="field-type-name">Checkbox</div>
                                </div>
                                <div class="field-type-option" data-type="radio">
                                    <span class="field-type-icon">○</span>
                                    <div class="field-type-name">Radio Button</div>
                                </div>
                            </div>
                        </div>

                        <div class="field-group" id="add-field-options-group" style="display: none;">
                            <label id="add-field-options-label">Options</label>
                            <div class="field-options-container">
                                <ul id="add-field-options-list" class="field-options-list"></ul>
                                <button type="button" class="add-option-btn" onclick="addNewFieldOption()">+ Add Option</button>
                            </div>
                        </div>

                            <div class="field-edit-actions">
                                <button type="button" class="field-edit-btn cancel" onclick="closeAddFieldDialog()">Cancel</button>
                                <button type="button" class="field-edit-btn save" onclick="createNewField()">Add Field</button>
                            </div>
                        </div>
                    </div>
                </div>
            \`;

            document.body.insertAdjacentHTML('beforeend', modalHTML);

            // Add click handlers for field type selection
            document.querySelectorAll('.field-type-option').forEach(option => {
                option.addEventListener('click', function() {
                    document.querySelectorAll('.field-type-option').forEach(opt => opt.classList.remove('selected'));
                    this.classList.add('selected');
                    // Show/hide options based on selected type
                    handleAddFieldTypeChange();
                });
            });
        }

        function openAddFieldDialog() {
            const modal = document.getElementById('add-field-modal');
            modal.classList.add('active');

            // Update dialog position to ensure it's properly positioned
            updateDialogPosition();

            // Focus on label input
            setTimeout(() => {
                const labelInput = document.getElementById('new-field-label');
                labelInput.focus();
                labelInput.select();

                // Add Enter key support
                labelInput.onkeydown = function(e) {
                    if (e.key === 'Enter') {
                        createNewField();
                    } else if (e.key === 'Escape') {
                        closeAddFieldDialog();
                    }
                };
            }, 100);
        }

        function closeAddFieldDialog() {
            const modal = document.getElementById('add-field-modal');
            modal.classList.remove('active');
            window.insertionIndex = null;
        }

        function openEditFieldDialog(currentType, currentLabel, currentOptions, isHalfWidth) {
            // Create edit modal if it doesn't exist
            if (!document.getElementById('edit-field-modal')) {
                createEditFieldModal();
            }

            const modal = document.getElementById('edit-field-modal');

            // Populate current values
            document.getElementById('edit-field-label').value = currentLabel;

            // Set current field type
            document.querySelectorAll('.edit-field-type-option').forEach(option => {
                option.classList.remove('selected');
                if (option.dataset.type === currentType) {
                    option.classList.add('selected');
                }
            });

            // Populate options if it's a select or radio field
            const optionsList = document.getElementById('edit-field-options-list');
            optionsList.innerHTML = '';
            if ((currentType === 'radio' || currentType === 'select') && currentOptions.length > 0) {
                currentOptions.forEach(option => {
                    addEditFieldOptionToList(option);
                });
            }

            // Show/hide options section
            handleEditFieldTypeChange();

            modal.classList.add('active');
        }

        function closeEditFieldDialog() {
            const modal = document.getElementById('edit-field-modal');
            if (modal) {
                modal.classList.remove('active');
            }
            window.editingFieldWrapper = null;
            window.editingFieldIndex = null;
        }

        function createEditFieldModal() {
            const modalHTML = \`
                <div id="edit-field-modal" class="field-edit-modal">
                    <div class="field-edit-dialog">
                        <div class="add-field-header">
                            <h3 class="add-field-title">⚙️ Edit Field</h3>
                            <button class="field-edit-close" onclick="closeEditFieldDialog()">×</button>
                        </div>
                        <div class="add-field-content">
                            <div class="field-group">
                                <label>Field Label</label>
                                <input type="text" id="edit-field-label" placeholder="Enter field label" value="">
                            </div>

                            <div class="field-group">
                                <label>Choose Field Type</label>
                                <div class="field-type-grid">
                                    <div class="field-type-option edit-field-type-option" data-type="text">
                                        <span class="field-type-icon">T</span>
                                        <div class="field-type-name">Text Input</div>
                                    </div>
                                    <div class="field-type-option edit-field-type-option" data-type="textarea">
                                        <span class="field-type-icon">¶</span>
                                        <div class="field-type-name">Textarea</div>
                                    </div>
                                    <div class="field-type-option edit-field-type-option" data-type="email">
                                        <span class="field-type-icon">@</span>
                                        <div class="field-type-name">Email</div>
                                    </div>
                                    <div class="field-type-option edit-field-type-option" data-type="date">
                                        <span class="field-type-icon">D</span>
                                        <div class="field-type-name">Date</div>
                                    </div>
                                    <div class="field-type-option edit-field-type-option" data-type="select">
                                        <span class="field-type-icon">▼</span>
                                        <div class="field-type-name">Dropdown</div>
                                    </div>
                                    <div class="field-type-option edit-field-type-option" data-type="checkbox">
                                        <span class="field-type-icon">☑</span>
                                        <div class="field-type-name">Checkbox</div>
                                    </div>
                                    <div class="field-type-option edit-field-type-option" data-type="radio">
                                        <span class="field-type-icon">○</span>
                                        <div class="field-type-name">Radio Button</div>
                                    </div>
                                </div>
                            </div>
                            <div class="field-group" id="edit-field-options-group" style="display: none;">
                                <label id="edit-field-options-label">Options</label>
                                <ul id="edit-field-options-list"></ul>
                                <button type="button" class="add-option-btn" onclick="addEditFieldOption()">+ Add Option</button>
                            </div>


                            <div class="field-edit-actions">
                                <button type="button" class="field-edit-btn cancel" onclick="closeEditFieldDialog()">Cancel</button>
                                <button type="button" class="field-edit-btn save" onclick="updateField()">Update Field</button>
                            </div>
                        </div>
                    </div>
                </div>
            \`;

            document.body.insertAdjacentHTML('beforeend', modalHTML);

            // Add click handlers for field type selection
            document.querySelectorAll('.edit-field-type-option').forEach(option => {
                option.addEventListener('click', function() {
                    document.querySelectorAll('.edit-field-type-option').forEach(opt => opt.classList.remove('selected'));
                    this.classList.add('selected');
                    handleEditFieldTypeChange();
                });
            });
        }

        function handleEditFieldTypeChange() {
            const selectedType = document.querySelector('.edit-field-type-option.selected');
            const optionsGroup = document.getElementById('edit-field-options-group');

            if (selectedType && (selectedType.dataset.type === 'select' || selectedType.dataset.type === 'radio')) {
                optionsGroup.style.display = 'block';
                // Add default options if none exist
                const optionsList = document.getElementById('edit-field-options-list');
                if (optionsList.children.length === 0) {
                    const defaultOptions = ['Option 1', 'Option 2', 'Option 3'];
                    defaultOptions.forEach(option => {
                        addEditFieldOptionToList(option);
                    });
                }
            } else {
                optionsGroup.style.display = 'none';
            }
        }

        function addEditFieldOption() {
            addEditFieldOptionToList('New Option');
        }

        function addEditFieldOptionToList(value = '') {
            const optionsList = document.getElementById('edit-field-options-list');
            const optionItem = document.createElement('li');
            optionItem.className = 'option-item';
            optionItem.innerHTML = \`
                <input type="text" class="option-input" value="\${value}" placeholder="Option text">
                <button class="remove-option" onclick="this.parentElement.remove()">×</button>
            \`;
            optionsList.appendChild(optionItem);
        }

        async function updateField() {
            const fieldWrapper = window.editingFieldWrapper;
            if (!fieldWrapper) return;

            const fieldLabel = document.getElementById('edit-field-label').value.trim() || 'Field';
            const selectedType = document.querySelector('.edit-field-type-option.selected');
            const fieldType = selectedType ? selectedType.dataset.type : 'text';

            // Get options for select/radio fields
            let options = [];
            if (fieldType === 'select' || fieldType === 'radio') {
                const optionInputs = document.querySelectorAll('#edit-field-options-list .option-input');
                options = Array.from(optionInputs).map(input => input.value.trim()).filter(val => val);
            }

            // Update the field's DOM structure
            updateFieldDOM(fieldWrapper, fieldType, fieldLabel, options);

            // Update formData and save to database
            console.log('🔧 EDIT DEBUG - Field data-index before update:', fieldWrapper.getAttribute('data-index'));
            console.log('🔧 EDIT DEBUG - Field classes before update:', fieldWrapper.className);
            updateFormData();
            console.log('🔧 EDIT DEBUG - FormData after update:', formData);
            console.log('🔧 EDIT DEBUG - Found user fields:', document.querySelectorAll('.editable-field-wrapper[data-index^="user_field_"]').length);
            console.log('🔧 EDIT DEBUG - All editable fields:', document.querySelectorAll('.editable-field-wrapper').length);
            console.log('🔧 EDIT DEBUG - Field data-index after update:', fieldWrapper.getAttribute('data-index'));
            console.log('🔧 EDIT DEBUG - Field classes after update:', fieldWrapper.className);

            // Show saving status
            const saveStatus = document.getElementById('save-status');
            if (saveStatus) {
                saveStatus.textContent = 'Saving field changes...';
                saveStatus.className = '';
                saveStatus.style.opacity = '1';
            }

            try {
                // Save the updated form structure to the database
                const response = await fetch(`/api/documents/#{document_id}/form_structure`, {
                    method: 'PATCH',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        form_fields: formData
                    })
                });

                if (response.ok) {
                    closeEditFieldDialog();

                    // Show success message
                    if (saveStatus) {
                        saveStatus.textContent = 'Field updated and saved successfully!';
                        saveStatus.className = 'success';
                        setTimeout(() => {
                            saveStatus.style.opacity = '0';
                        }, 3000);
                    }
                } else {
                    throw new Error('Failed to save field changes');
                }
            } catch (error) {
                console.error('Error saving field changes:', error);
                if (saveStatus) {
                    saveStatus.textContent = 'Error saving field changes. Please try again.';
                    saveStatus.className = 'error';
                    setTimeout(() => {
                        saveStatus.style.opacity = '0';
                    }, 5000);
                }
            }
        }

        function updateFieldDOM(fieldWrapper, fieldType, label, options) {
            const dataIndex = fieldWrapper.getAttribute('data-index');

            // Update field type
            fieldWrapper.setAttribute('data-type', fieldType);
            fieldWrapper.classList.remove('half-width'); // Always full width

            // Generate new field HTML
            const fieldName = \`field_\${dataIndex}\`;
            let formElement = '';

            switch (fieldType) {
                case 'textarea':
                    formElement = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <textarea id="\${fieldName}" name="\${fieldName}" placeholder="\${label}"></textarea>
                    \`;
                    break;
                case 'select':
                    const selectOptions = options.length > 0
                        ? options.map(option => \`<option value="\${option}">\${option}</option>\`).join('')
                        : \`<option value="option1">Option 1</option><option value="option2">Option 2</option><option value="option3">Option 3</option>\`;
                    formElement = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <select id="\${fieldName}" name="\${fieldName}">\${selectOptions}</select>
                    \`;
                    break;
                case 'radio':
                    const radioOptions = options.length > 0 ? options : ['Option 1', 'Option 2', 'Option 3'];
                    const radioButtons = radioOptions.map((option, i) => \`
                        <div class="radio-option">
                            <input type="radio" id="\${fieldName}_\${i}" name="\${fieldName}" value="\${option}">
                            <label for="\${fieldName}_\${i}">\${option}</label>
                        </div>
                    \`).join('');
                    formElement = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <div class="radio-options">\${radioButtons}</div>
                    \`;
                    break;
                case 'checkbox':
                    formElement = \`
                        <div class="checkbox-wrapper">
                            <input type="checkbox" id="\${fieldName}" name="\${fieldName}">
                            <label class="editable-label" contenteditable="true" data-field="\${fieldName}" for="\${fieldName}">\${label}</label>
                        </div>
                    \`;
                    break;
                case 'email':
                    formElement = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <input type="email" id="\${fieldName}" name="\${fieldName}" placeholder="\${label}">
                    \`;
                    break;
                case 'date':
                    formElement = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <input type="date" id="\${fieldName}" name="\${fieldName}">
                    \`;
                    break;
                default:
                    formElement = \`
                        <label class="editable-label" contenteditable="true" data-field="\${fieldName}">\${label}</label>
                        <input type="text" id="\${fieldName}" name="\${fieldName}" placeholder="\${label}">
                    \`;
            }

            // Replace field content while preserving controls
            const dragHandle = fieldWrapper.querySelector('.drag-handle');
            const controls = fieldWrapper.querySelector('.field-controls');

            fieldWrapper.innerHTML = '';
            if (dragHandle) fieldWrapper.appendChild(dragHandle);
            if (controls) fieldWrapper.appendChild(controls);
            fieldWrapper.insertAdjacentHTML('beforeend', formElement);

            // Re-initialize field listeners
            initializeFieldListeners();
        }

        function createNewField() {
            const fieldLabel = document.getElementById('new-field-label').value.trim() || 'New Field';
            const selectedType = document.querySelector('.field-type-option.selected');
            const fieldType = selectedType ? selectedType.getAttribute('data-type') : 'text';

            if (isColumnLayoutActive && window.targetColumn) {
                // Add field to specific column
                const columnId = window.targetColumn === 'left' ? 'column-left' : 'column-right';
                const column = document.getElementById(columnId);
                const addFieldBtn = column.querySelector('.column-add-field');

                // Create field for column layout - generate unique ID based on timestamp
                const newIndex = Date.now();
                const fieldHTML = generateNewFieldHTML(fieldType, fieldLabel, newIndex);

                // Convert to column field format
                const tempDiv = document.createElement('div');
                tempDiv.innerHTML = fieldHTML;
                const field = tempDiv.firstElementChild;
                field.classList.add('column-field');

                // Insert before add field button
                column.insertBefore(field, addFieldBtn);

                // Update column states
                updateColumnStates();
                initializeColumnFieldListeners();

                // Clear target column
                window.targetColumn = null;

            } else if (!isColumnLayoutActive) {
                // Regular field insertion for list mode - generate unique ID based on timestamp
                const newIndex = Date.now();
                const newFieldHTML = generateNewFieldHTML(fieldType, fieldLabel, newIndex);

                if (window.insertionIndex !== null) {
                    // Insert at specific position
                    insertFieldAtPosition(newFieldHTML, window.insertionIndex);
                    // Reindex all fields after insertion
                    reindexFields();
                } else {
                    // Insert at end (before add field zone)
                    const addZone = document.getElementById('add-field-zone');
                    addZone.insertAdjacentHTML('beforebegin', newFieldHTML);
                }

                // Reinitialize all field functionality
                initializeFieldListeners();
                // Refresh drop zones (only if not in column mode)
                if (!isColumnLayoutActive) {
                    addDropZonesBetweenFields();
                }
            }

            // Reset form
            document.getElementById('new-field-label').value = '';
            document.querySelectorAll('.field-type-option').forEach(opt => opt.classList.remove('selected'));
            document.querySelector('.field-type-option[data-type="text"]').classList.add('selected');
            // Hide options section when resetting to text field
            document.getElementById('add-field-options-group').style.display = 'none';

            updateFormData();
            closeAddFieldDialog();

            // Show success message
            const saveStatus = document.getElementById('save-status');
            saveStatus.textContent = '✓ Field added successfully!';
            saveStatus.className = 'success';
            saveStatus.style.opacity = '1';
            setTimeout(() => {
                saveStatus.style.opacity = '0';
            }, 2000);
        }

        function insertFieldAtPosition(fieldHTML, position) {
            const fields = document.querySelectorAll('.editable-field-wrapper');
            if (position < fields.length) {
                fields[position].insertAdjacentHTML('beforebegin', fieldHTML);
            } else {
                // Insert at end
                const addZone = document.getElementById('add-field-zone');
                addZone.insertAdjacentHTML('beforebegin', fieldHTML);
            }
        }

        function reindexFields() {
            const fields = document.querySelectorAll('.editable-field-wrapper');
            fields.forEach((field, index) => {
                field.setAttribute('data-index', index);

                // Update field names and IDs
                const fieldName = `field_${index}`;
                const inputs = field.querySelectorAll('input, textarea, select');
                inputs.forEach(input => {
                    input.id = fieldName;
                    input.name = fieldName;
                });

                // Update labels
                const labels = field.querySelectorAll('label[for]');
                labels.forEach(label => {
                    label.setAttribute('for', fieldName);
                });

                const editableLabels = field.querySelectorAll('.editable-label[data-field]');
                editableLabels.forEach(label => {
                    label.setAttribute('data-field', fieldName);
                });
            });
        }

        function initializeFieldListeners() {
            const fields = document.querySelectorAll('.editable-field-wrapper');
            fields.forEach(field => {
                // Remove existing listeners first
                field.removeEventListener('dragstart', handleDragStart);
                field.removeEventListener('dragend', handleDragEnd);
                field.removeEventListener('dragover', handleDragOver);
                field.removeEventListener('drop', handleDrop);

                // Add drag and drop listeners
                field.addEventListener('dragstart', handleDragStart);
                field.addEventListener('dragend', handleDragEnd);
                field.addEventListener('dragover', handleDragOver);
                field.addEventListener('drop', handleDrop);

                // Initialize field control buttons
                const widthBtn = field.querySelector('.width-btn');
                const typeBtn = field.querySelector('.type-btn');
                const removeBtn = field.querySelector('.remove-btn');

                if (widthBtn) {
                    widthBtn.removeEventListener('click', toggleFieldWidth);
                    widthBtn.addEventListener('click', (e) => {
                        e.stopPropagation();
                        toggleFieldWidth(e);
                    });
                }

                if (typeBtn) {
                    typeBtn.addEventListener('click', (e) => {
                        e.stopPropagation();
                        editField(field);
                    });
                }

                if (removeBtn) {
                    removeBtn.removeEventListener('click', removeField);
                    removeBtn.addEventListener('click', (e) => {
                        e.stopPropagation();
                        removeField(e);
                    });
                }
            });
        }

        function generateNewFieldHTML(type, label, index) {
            const fieldName = `field_${index}`;
            let formElement = '';

            switch(type) {
                case 'textarea':
                    formElement = `
                        <label class="editable-label" contenteditable="true" data-field="${fieldName}">${label}</label>
                        <textarea id="${fieldName}" name="${fieldName}" rows="3" placeholder="${label}"></textarea>
                    `;
                    break;
                case 'checkbox':
                    formElement = `
                        <div class="checkbox-field">
                            <input type="checkbox" id="${fieldName}" name="${fieldName}" />
                            <label class="editable-label" contenteditable="true" data-field="${fieldName}" for="${fieldName}">${label}</label>
                        </div>
                    `;
                    break;
                case 'radio':
                    const radioOptions = Array.from(document.querySelectorAll('#add-field-options-list .field-option-input'))
                        .map(input => input.value.trim())
                        .filter(value => value)
                        .map(option => `<label><input type="radio" name="${fieldName}" value="${option}" /> ${option}</label>`)
                        .join('');

                    const defaultRadioOptions = radioOptions || `
                        <label><input type="radio" name="${fieldName}" value="option1" /> Option 1</label>
                        <label><input type="radio" name="${fieldName}" value="option2" /> Option 2</label>
                        <label><input type="radio" name="${fieldName}" value="option3" /> Option 3</label>
                    `;

                    formElement = `
                        <div class="radio-field">
                            <span class="editable-label radio-group-label" contenteditable="true" data-field="${fieldName}">${label}</span>
                            <div class="radio-options">
                                ${defaultRadioOptions}
                            </div>
                        </div>
                    `;
                    break;
                case 'select':
                    const selectOptions = Array.from(document.querySelectorAll('#add-field-options-list .field-option-input'))
                        .map(input => input.value.trim())
                        .filter(value => value)
                        .map(option => `<option value="${option}">${option}</option>`)
                        .join('');

                    const defaultSelectOptions = selectOptions || `
                        <option value="option1">Option 1</option>
                        <option value="option2">Option 2</option>
                        <option value="option3">Option 3</option>
                    `;

                    formElement = `
                        <label class="editable-label" contenteditable="true" data-field="${fieldName}">${label}</label>
                        <select id="${fieldName}" name="${fieldName}">
                            ${defaultSelectOptions}
                        </select>
                    `;
                    break;
                case 'email':
                    formElement = `
                        <label class="editable-label" contenteditable="true" data-field="${fieldName}">${label}</label>
                        <input type="email" id="${fieldName}" name="${fieldName}" placeholder="${label}" />
                    `;
                    break;
                case 'date':
                    formElement = `
                        <label class="editable-label" contenteditable="true" data-field="${fieldName}">${label}</label>
                        <input type="date" id="${fieldName}" name="${fieldName}" />
                    `;
                    break;
                default:
                    formElement = `
                        <label class="editable-label" contenteditable="true" data-field="${fieldName}">${label}</label>
                        <input type="text" id="${fieldName}" name="${fieldName}" placeholder="${label}" />
                    `;
            }

            return `
                <div class="editable-field-wrapper form-field" data-index="user_field_${index}" data-type="${type}" draggable="true">
                    <div class="drag-handle"></div>
                    <div class="field-controls">
                        <button class="control-btn type-btn" title="Change field type">⚙</button>
                        <button class="control-btn remove-btn" title="Remove field">×</button>
                    </div>
                    ${formElement}
                </div>
            `;
        }

        function loadFormData() {
            // First try to load user-added fields (those with user_field_ prefix in data-index)
            let fields = document.querySelectorAll('.editable-field-wrapper[data-index^="user_field_"]');

            // If no user_field_ fields found, check for any fields that might be restored user fields
            if (fields.length === 0) {
                // As a fallback, check for any editable fields that are user-added types
                const allEditableFields = document.querySelectorAll('.editable-field-wrapper');

                const potentialUserFields = Array.from(allEditableFields).filter(field => {
                    const dataType = field.getAttribute('data-type');
                    const dataIndex = field.getAttribute('data-index');

                    // Check if this might be a user-added field that was restored incorrectly
                    const isFormInput = dataType === 'form_input';
                    const isUserFieldType = dataType === 'text' || dataType === 'textarea' ||
                                          dataType === 'select' || dataType === 'radio' || dataType === 'checkbox' ||
                                          dataType === 'radio-group';
                    const hasAiFieldIndex = dataIndex && dataIndex.startsWith('ai_field_');
                    const hasNumericIndex = dataIndex && /^\d+$/.test(dataIndex);

                    // If it's a form_input with ai_field_ index, it might be a restored user field
                    const mightBeRestoredUserField = (isFormInput && hasAiFieldIndex) || isUserFieldType || hasNumericIndex;

                    return mightBeRestoredUserField || isUserFieldType;
                });

                if (potentialUserFields.length > 0) {
                    fields = potentialUserFields;
                }
            }

            formData = Array.from(fields).map((field, index) => {
                const fieldType = field.getAttribute('data-type') || inferFieldTypeFromElement(field);

                // Try multiple selectors for the label
                let label = 'Field';
                const labelSelectors = [
                    '.editable-label',
                    'legend.editable-label',
                    'fieldset legend',
                    'label.editable-label',
                    'span.editable-label',
                    'div.editable-label',
                    'label',
                    'input[type="text"]',
                    'textarea'
                ];

                for (const selector of labelSelectors) {
                    const labelElement = field.querySelector(selector);
                    if (labelElement && labelElement.textContent && labelElement.textContent.trim()) {
                        const extractedLabel = labelElement.textContent.trim();
                        // Skip generic placeholders or empty labels
                        if (extractedLabel !== 'Field' && extractedLabel !== '' && extractedLabel.length > 0) {
                            label = extractedLabel;
                            break;
                        }
                    }
                }

                // If still "Field", try to get a placeholder or name attribute
                if (label === 'Field') {
                    const input = field.querySelector('input, textarea');
                    if (input) {
                        const placeholder = input.getAttribute('placeholder');
                        const name = input.getAttribute('name');
                        if (placeholder && placeholder.trim()) {
                            label = placeholder.trim();
                        } else if (name && name.trim()) {
                            label = name.replace(/_/g, ' ').trim();
                        }
                    }
                }

                const dataIndex = field.getAttribute('data-index');
                console.log(`Field ${index}: type=${fieldType}, label="${label}", index=${dataIndex}`);


                let fieldData = {
                    id: dataIndex || 'user_field_' + index,
                    label: label,
                    fieldType: fieldType,
                    originalIndex: parseInt(dataIndex?.replace('user_field_', '')) || index,
                    width: field.classList.contains('half-width') ? 'half' : 'full'
                };

                // Capture options for radio buttons and dropdowns
                if (fieldType === 'radio' || fieldType === 'select') {
                    // Handle both .radio-options and .radio-group-fieldset structures for radio buttons
                    const options = Array.from(field.querySelectorAll('.radio-option label, .radio-options label, .radio-group-fieldset .radio-option label, option')).map(opt => opt.textContent.trim()).filter(text => text);
                    if (options.length > 0) {
                        fieldData.options = options;
                    }
                }

                return fieldData;
            });


            // Trigger form builder UI refresh to display the loaded fields

            // Re-initialize field controls for the restored fields
            console.log('Re-initializing field controls for restored fields...');
            if (typeof initializeFieldControls === 'function') {
                // Field controls are initialized with event delegation, so they should work automatically
                console.log('Field controls use event delegation - should work automatically');
            }

            // Re-initialize other interactive features
            if (typeof initializeLabelEditing === 'function') {
                initializeLabelEditing();
                console.log('Re-initialized label editing');
            }

            if (typeof initializeDragDrop === 'function') {
                initializeDragDrop();
                console.log('Re-initialized drag and drop');
            }

            // Call updateFormData to sync the data
            if (typeof updateFormData === 'function') {
                console.log('Calling updateFormData to refresh UI...');
                updateFormData();
            }

            // CRITICAL: Actually display the loaded user fields in the editing interface
            renderUserFieldsInEditor();

            // Check if the form builder is rendering these fields
            setTimeout(() => {
                const editableFields = document.querySelectorAll('.editable-field-wrapper');
                const controlButtons = document.querySelectorAll('.field-controls .control-btn');
                const dragHandles = document.querySelectorAll('.drag-handle');

                console.log('FORM BUILDER CHECK RESULTS:');
                console.log('  - Editable field wrappers:', editableFields.length);
                console.log('  - Control buttons:', controlButtons.length);
                console.log('  - Drag handles:', dragHandles.length);

                if (editableFields.length > 0 && controlButtons.length > 0) {
                    console.log('✅ Form builder appears to be working! Fields are editable.');
                    // Test if a field has the expected structure
                    const sampleField = editableFields[0];
                    const hasControls = sampleField.querySelector('.field-controls');
                    const hasDragHandle = sampleField.querySelector('.drag-handle');
                    console.log('  Sample field has controls:', !!hasControls, 'drag handle:', !!hasDragHandle);
                } else {
                    console.warn('⚠️ Form builder interface may not be fully functional');
                    console.log('Fields exist but missing interactive controls');
                }
            }, 1000);
        }

        function renderUserFieldsInEditor() {

            if (!formData || formData.length === 0) {
                console.log('No formData to render');
                return;
            }

            // Find the add field zone to insert fields before it
            const addZone = document.getElementById('add-field-zone');
            if (!addZone) {
                console.warn('Add field zone not found, cannot render user fields');
                return;
            }

            console.log('Rendering', formData.length, 'user fields...');

            // Filter formData to include user-added fields
            let userFields = formData.filter(field => {
                // Include any field that appears to be user-added:
                // 1. Fields with user_field_ prefix
                // 2. Fields with ai_field_ prefix (restored user fields)
                // 3. Fields with numeric IDs (like radio groups)
                // 4. Radio or radio-group fields (always user-added)
                const hasUserFieldId = field.id && field.id.startsWith('user_field_');
                const hasAiFieldId = field.id && field.id.startsWith('ai_field_');
                const hasNumericId = field.id && /^\d+$/.test(field.id);
                const isRadioType = field.fieldType === 'radio-group' || field.fieldType === 'radio';

                return hasUserFieldId || hasAiFieldId || hasNumericId || isRadioType;
            });


            // Sort userFields by their original document order (based on DOM position)
            userFields = userFields.sort((a, b) => {
                const elementA = document.querySelector(`[data-index="${a.id}"]`);
                const elementB = document.querySelector(`[data-index="${b.id}"]`);

                if (elementA && elementB) {
                    // Use compareDocumentPosition to determine relative position in DOM
                    const position = elementA.compareDocumentPosition(elementB);
                    if (position & Node.DOCUMENT_POSITION_FOLLOWING) return -1;
                    if (position & Node.DOCUMENT_POSITION_PRECEDING) return 1;
                }

                // Fallback to originalIndex or creation order
                return (a.originalIndex || 0) - (b.originalIndex || 0);
            });

            console.log('Found', userFields.length, 'fields that appear to be user-added');

            userFields.forEach((field, index) => {
                    // Map field types to generateNewFieldHTML compatible types
                let fieldType = field.fieldType;
                if (fieldType === 'radio-group') {
                    fieldType = 'radio';
                }

                // Generate HTML for this field using the same function as addNewField
                const fieldHTML = generateNewFieldHTML(fieldType, field.label, field.originalIndex || Date.now() + index);

                // Insert the field before the add field zone
                addZone.insertAdjacentHTML('beforebegin', fieldHTML);
            });

            // Reinitialize field listeners for the new fields
            if (typeof initializeFieldListeners === 'function') {
                initializeFieldListeners();
                console.log('Re-initialized field listeners for rendered fields');
            }

            console.log('✅ Finished rendering user fields in editor');
        }

        function inferFieldTypeFromElement(field) {
            // Try to determine field type from the HTML content
            if (field.querySelector('.radio-options') || field.querySelector('.radio-group-fieldset')) return 'radio';
            if (field.querySelector('select')) return 'select';
            if (field.querySelector('textarea')) return 'textarea';
            if (field.querySelector('input[type="checkbox"]')) return 'checkbox';
            if (field.querySelector('input[type="email"]')) return 'email';
            if (field.querySelector('input[type="date"]')) return 'date';
            return 'text'; // default
        }

        function updateFormData() {

            // First try to get user-added fields (those with user_field_ prefix in data-index)
            let fields = document.querySelectorAll('.editable-field-wrapper[data-index^="user_field_"]');

            // If no user_field_ fields found, use the same fallback logic as loadFormData
            if (fields.length === 0) {
                console.log('No user_field_ fields found, using fallback detection...');
                const allEditableFields = document.querySelectorAll('.editable-field-wrapper');

                const potentialUserFields = Array.from(allEditableFields).filter(field => {
                    const dataType = field.getAttribute('data-type');
                    const dataIndex = field.getAttribute('data-index');
                    const isFormInput = dataType === 'form_input';
                    const hasAiFieldIndex = dataIndex && dataIndex.startsWith('ai_field_');
                    const hasNumericIndex = dataIndex && /^\d+$/.test(dataIndex);
                    const mightBeRestoredUserField = (isFormInput && hasAiFieldIndex) || hasNumericIndex;
                    const isUserFieldType = dataType === 'text' || dataType === 'textarea' ||
                                          dataType === 'select' || dataType === 'radio' || dataType === 'checkbox' ||
                                          dataType === 'radio-group';
                    return mightBeRestoredUserField || isUserFieldType;
                });

                if (potentialUserFields.length > 0) {
                    console.log('Found', potentialUserFields.length, 'potential user fields for updateFormData');
                    fields = potentialUserFields;
                }
            }
            // Track used IDs to prevent duplicates
            const usedIds = new Set();

            formData = Array.from(fields).map((field, index) => {
                const fieldType = field.getAttribute('data-type') || inferFieldTypeFromElement(field);

                // Try multiple selectors for the label
                let label = 'Field';
                const labelSelectors = [
                    '.editable-label',
                    'legend.editable-label',
                    'fieldset legend',
                    'label.editable-label',
                    'span.editable-label',
                    'div.editable-label',
                    'label',
                    'input[type="text"]',
                    'textarea'
                ];

                for (const selector of labelSelectors) {
                    const labelElement = field.querySelector(selector);
                    if (labelElement && labelElement.textContent && labelElement.textContent.trim()) {
                        const extractedLabel = labelElement.textContent.trim();
                        // Skip generic placeholders or empty labels
                        if (extractedLabel !== 'Field' && extractedLabel !== '' && extractedLabel.length > 0) {
                            label = extractedLabel;
                            break;
                        }
                    }
                }

                // If still "Field", try to get a placeholder or name attribute
                if (label === 'Field') {
                    const input = field.querySelector('input, textarea');
                    if (input) {
                        const placeholder = input.getAttribute('placeholder');
                        const name = input.getAttribute('name');
                        if (placeholder && placeholder.trim()) {
                            label = placeholder.trim();
                        } else if (name && name.trim()) {
                            label = name.replace(/_/g, ' ').trim();
                        }
                    }
                }

                // Generate unique ID
                let proposedId = field.getAttribute('data-index') || `user_field_${index}`;
                let finalId = proposedId;
                let counter = 1;

                // If ID is already used, append a counter until we find a unique one
                while (usedIds.has(finalId)) {
                    finalId = `${proposedId}_${counter}`;
                    counter++;
                }
                usedIds.add(finalId);

                // Update the field's data-index if it was changed to ensure consistency
                if (finalId !== proposedId) {
                    field.setAttribute('data-index', finalId);
                }

                let fieldData = {
                    id: finalId,
                    label: label,
                    fieldType: fieldType,
                    originalIndex: parseInt(field.getAttribute('data-index')?.replace('user_field_', '')) || index,
                    width: field.classList.contains('half-width') ? 'half' : 'full'
                };

                // Capture options for radio buttons and dropdowns
                if (fieldType === 'radio') {
                    // Handle both .radio-options (old style) and .radio-group-fieldset (new style)
                    const radioLabels = field.querySelectorAll('.radio-options label, .radio-group-fieldset .radio-option label');
                    fieldData.options = Array.from(radioLabels).map(label => {
                        const input = label.querySelector('input[type="radio"]');
                        return input ? input.value : label.textContent.trim();
                    }).filter(option => option);
                } else if (fieldType === 'select') {
                    const selectElement = field.querySelector('select');
                    if (selectElement) {
                        fieldData.options = Array.from(selectElement.options).map(option => option.textContent);
                    }
                }

                return fieldData;
            });
        }


        async function saveFormChanges() {
            const saveStatus = document.getElementById('save-status');
            saveStatus.textContent = 'Saving...';
            saveStatus.className = '';
            saveStatus.style.opacity = '1';

            // Debug: Update form data and log it
            console.log('🚨 SAVE OPERATION - Updating form data...');
            updateFormData();
            console.log('🚨 SAVE DEBUG - Form data being sent:', formData);
            console.log('🚨 Total fields being saved:', formData.length);

            try {
                const response = await fetch(`/api/documents/#{document_id}/form_structure`, {
                    method: 'PATCH',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        form_fields: formData
                    })
                });

                if (response.ok) {
                    saveStatus.textContent = '✓ Changes saved successfully!';
                    saveStatus.className = 'success';
                    setTimeout(() => {
                        saveStatus.style.opacity = '0';
                    }, 3000);
                } else {
                    throw new Error('Failed to save changes');
                }
            } catch (error) {
                console.error('Save error:', error);
                saveStatus.textContent = '✗ Failed to save changes';
                saveStatus.className = 'error';
                setTimeout(() => {
                    saveStatus.style.opacity = '0';
                }, 5000);
            }
        }

        function resetForm() {
            if (confirm('Are you sure you want to reset the form to its original state?')) {
                location.reload();
            }
        }

        function initializeDropZones() {
            addDropZonesBetweenFields();
        }

        function addDropZonesBetweenFields() {
            // Don't add drop zones if column layout is active
            if (isColumnLayoutActive) {
                console.log('Skipping drop zone creation - column layout is active');
                return;
            }

            // Ensure we're in the right context
            const editableContent = document.querySelector('.editable-content');
            if (!editableContent || editableContent.classList.contains('column-layout-active')) {
                console.log('Skipping drop zone creation - not in list mode');
                return;
            }

            // Remove existing drop zones completely
            cleanupAllDropZones();

            const fields = document.querySelectorAll('.editable-field-wrapper');

            // Add drop zone before first field
            if (fields.length > 0) {
                const firstDropZone = createDropZone(0);
                fields[0].insertAdjacentHTML('beforebegin', firstDropZone);
            }

            // Add drop zones between fields
            fields.forEach((field, index) => {
                const dropZone = createDropZone(index + 1);
                field.insertAdjacentHTML('afterend', dropZone);
            });

            // Add event listeners to drop zones
            document.querySelectorAll('.field-drop-zone').forEach((zone, index) => {
                zone.addEventListener('dragover', function(e) {
                    e.preventDefault();
                    this.classList.add('drag-over');
                });

                zone.addEventListener('dragleave', function() {
                    this.classList.remove('drag-over');
                });

                zone.addEventListener('drop', function(e) {
                    e.preventDefault();
                    this.classList.remove('drag-over');
                    // Handle field reordering here if needed
                });

                zone.addEventListener('click', function() {
                    window.insertionIndex = parseInt(this.getAttribute('data-position'));
                    openAddFieldDialog();
                });
            });
        }

        function createDropZone(position) {
            return \`<div class="field-drop-zone" data-position="\${position}" title="Click to insert field here"></div>\`;
        }

        function showDropZones() {
            if (isColumnLayoutActive) return;
            document.querySelectorAll('.field-drop-zone').forEach(zone => {
                zone.classList.add('active');
            });
        }

        function hideDropZones() {
            if (isColumnLayoutActive) return;
            document.querySelectorAll('.field-drop-zone').forEach(zone => {
                zone.classList.remove('active', 'drag-over');
            });
        }

        let isColumnLayoutActive = false;

        function cleanupAllDropZones() {
            // Remove all types of drop zones
            document.querySelectorAll('.field-drop-zone').forEach(zone => {
                zone.remove();
            });
            document.querySelectorAll('.drop-zone').forEach(zone => {
                zone.remove();
            });

            // Force hide any remaining zones with inline styles
            document.querySelectorAll('[class*="drop-zone"]').forEach(zone => {
                zone.style.display = 'none';
                zone.remove();
            });

            // Clear any active states
            hideDropZones();
        }

        function toggleColumnLayout() {
            console.log('toggleColumnLayout called, isColumnLayoutActive:', isColumnLayoutActive);
            if (isColumnLayoutActive) {
                console.log('Exiting column layout');
                exitColumnLayout();
            } else {
                console.log('Entering column layout');
                enterColumnLayout();
            }
        }

        function enterColumnLayout() {
            console.log('Entering column layout mode');
            isColumnLayoutActive = true;

            // Complete cleanup of all drop zones
            cleanupAllDropZones();

            // Show column layout container
            let columnContainer = document.getElementById('column-layout-container');
            if (columnContainer) {
                console.log('Found column container, showing it');
                console.log('Full column container HTML:', columnContainer.innerHTML);

                // Check if the two-column-grid is empty and fix it
                const twoColumnGrid = columnContainer.querySelector('.two-column-grid');
                if (twoColumnGrid && twoColumnGrid.children.length === 0) {
                    console.log('Two-column-grid is empty, regenerating column structure');
                    twoColumnGrid.innerHTML = `
                        <div class="column-drop-zone" id="column-left" data-column="left" data-column-label="Left Column">
                            <div class="column-add-field" data-column="left">
                                <span class="add-field-icon">➕</span>
                                <span class="add-field-text">Add field to left column</span>
                            </div>
                        </div>
                        <div class="column-drop-zone" id="column-right" data-column="right" data-column-label="Right Column">
                            <div class="column-add-field" data-column="right">
                                <span class="add-field-icon">➕</span>
                                <span class="add-field-text">Add field to right column</span>
                            </div>
                        </div>
                    `;
                }

                columnContainer.style.display = 'block';
            } else {
                console.error('Column container not found!');
                return;
            }

            // Add class to hide regular layout
            const editableContent = document.querySelector('.editable-content');
            if (editableContent) {
                editableContent.classList.add('column-layout-active');
            }

            // Wait for DOM to be ready after showing container, then populate
            setTimeout(() => {
                console.log('Timeout executed, checking for columns...');
                const leftCheck = document.getElementById('column-left');
                const rightCheck = document.getElementById('column-right');
                console.log('Left column found:', !!leftCheck);
                console.log('Right column found:', !!rightCheck);

                // Try querySelector as alternative
                const leftByQuery = document.querySelector('#column-left');
                const rightByQuery = document.querySelector('#column-right');
                console.log('Left by querySelector:', !!leftByQuery);
                console.log('Right by querySelector:', !!rightByQuery);

                // Check all elements with column-drop-zone class
                const allDropZones = document.querySelectorAll('.column-drop-zone');
                console.log('Found column-drop-zone elements:', allDropZones.length);
                allDropZones.forEach((zone, idx) => {
                    console.log(`Drop zone ${idx}: id=${zone.id}, class=${zone.className}`);
                });

                // Move all fields to column layout
                populateColumnLayout();

                // Initialize column drag and drop
                initializeColumnDragDrop();
            }, 50);

            // Update button text
            document.getElementById('toggle-column-layout').innerHTML = '¶ List Layout';

            // Show status
            const saveStatus = document.getElementById('save-status');
            saveStatus.textContent = 'Column layout activated - drag fields to organize in columns';
            saveStatus.className = 'info';
            saveStatus.style.opacity = '1';
            setTimeout(() => {
                saveStatus.style.opacity = '0';
            }, 4000);
        }

        function exitColumnLayout() {
            isColumnLayoutActive = false;

            // Complete cleanup before switching
            cleanupAllDropZones();

            // Hide column layout container
            const columnContainer = document.getElementById('column-layout-container');
            columnContainer.style.display = 'none';

            // Remove class to show regular layout
            document.querySelector('.editable-content').classList.remove('column-layout-active');

            // Move fields back to regular layout
            restoreRegularLayout();

            // Update button text
            document.getElementById('toggle-column-layout').innerHTML = 'Column Layout';

            // Wait a frame before reinitializing to ensure DOM is ready
            setTimeout(() => {
                // Reinitialize regular drag and drop
                initializeFieldListeners();
                addDropZonesBetweenFields();
            }, 10);
        }

        function populateColumnLayout() {
            const fields = document.querySelectorAll('.editable-field-wrapper');
            const leftColumn = document.getElementById('column-left');
            const rightColumn = document.getElementById('column-right');

            if (!leftColumn || !rightColumn) {
                console.error('Column elements not found');
                return;
            }

            // Clear columns but preserve add field buttons (or create them if they don't exist)
            const leftAddBtnEl = leftColumn.querySelector('.column-add-field');
            const rightAddBtnEl = rightColumn.querySelector('.column-add-field');

            const leftAddBtn = leftAddBtnEl ? leftAddBtnEl.outerHTML : '<div class="column-add-field" data-column="left"><span class="add-field-icon">➕</span><span class="add-field-text">Add field to left column</span></div>';
            const rightAddBtn = rightAddBtnEl ? rightAddBtnEl.outerHTML : '<div class="column-add-field" data-column="right"><span class="add-field-icon">➕</span><span class="add-field-text">Add field to right column</span></div>';

            leftColumn.innerHTML = '';
            rightColumn.innerHTML = '';

            // Distribute fields to columns based on their current width setting
            fields.forEach((field, index) => {
                const isHalfWidth = field.classList.contains('half-width');
                const fieldClone = field.cloneNode(true);
                fieldClone.classList.add('column-field');

                if (isHalfWidth) {
                    // Alternate half-width fields between columns
                    const halfWidthIndex = Array.from(document.querySelectorAll('.editable-field-wrapper.half-width')).indexOf(field);
                    if (halfWidthIndex % 2 === 0) {
                        leftColumn.appendChild(fieldClone);
                    } else {
                        rightColumn.appendChild(fieldClone);
                    }
                } else {
                    // Full-width fields go to left column
                    leftColumn.appendChild(fieldClone);
                }
            });

            // Restore add field buttons
            leftColumn.insertAdjacentHTML('beforeend', leftAddBtn);
            rightColumn.insertAdjacentHTML('beforeend', rightAddBtn);

            // Update column visual states
            updateColumnStates();
        }

        function restoreRegularLayout() {
            const leftColumn = document.getElementById('column-left');
            const rightColumn = document.getElementById('column-right');
            const editableContent = document.querySelector('.editable-content');

            if (!leftColumn || !rightColumn || !editableContent) {
                console.error('Required elements not found for restoring layout');
                return;
            }

            // Get all fields from columns in order
            const leftFields = Array.from(leftColumn.querySelectorAll('.column-field'));
            const rightFields = Array.from(rightColumn.querySelectorAll('.column-field'));

            // Remove existing fields from regular layout
            const existingFields = document.querySelectorAll('.editable-content > .editable-field-wrapper');
            existingFields.forEach(field => field.remove());

            // Add fields back in the correct order, alternating between left and right
            const maxLength = Math.max(leftFields.length, rightFields.length);
            const addFieldZone = document.getElementById('add-field-zone');

            for (let i = 0; i < maxLength; i++) {
                if (leftFields[i]) {
                    const field = leftFields[i].cloneNode(true);
                    field.classList.remove('column-field');

                    // If there's a corresponding right field, make both half-width
                    if (rightFields[i]) {
                        field.classList.add('half-width');
                    } else {
                        field.classList.remove('half-width');
                    }

                    addFieldZone.parentNode.insertBefore(field, addFieldZone);
                }
                if (rightFields[i]) {
                    const field = rightFields[i].cloneNode(true);
                    field.classList.remove('column-field');
                    field.classList.add('half-width');
                    addFieldZone.parentNode.insertBefore(field, addFieldZone);
                }
            }

            // Clear columns
            leftColumn.innerHTML = '';
            rightColumn.innerHTML = '';
        }

        function initializeColumnDragDrop() {
            const leftColumn = document.getElementById('column-left');
            const rightColumn = document.getElementById('column-right');

            if (!leftColumn || !rightColumn) {
                console.error('Column elements not found for drag/drop initialization');
                return;
            }

            // Add drop listeners to columns
            [leftColumn, rightColumn].forEach(column => {
                column.addEventListener('dragover', function(e) {
                    e.preventDefault();
                    this.classList.add('drag-over');
                });

                column.addEventListener('dragleave', function(e) {
                    if (!this.contains(e.relatedTarget)) {
                        this.classList.remove('drag-over');
                    }
                });

                column.addEventListener('drop', function(e) {
                    e.preventDefault();
                    this.classList.remove('drag-over');

                    if (draggedElement) {
                        // Move field to this column
                        const fieldClone = draggedElement.cloneNode(true);
                        fieldClone.classList.add('column-field');

                        // Insert before the add field button
                        const addFieldBtn = this.querySelector('.column-add-field');
                        this.insertBefore(fieldClone, addFieldBtn);

                        // Remove from original location
                        if (draggedElement.parentNode.classList.contains('column-drop-zone')) {
                            draggedElement.remove();
                        }

                        updateColumnStates();
                        initializeColumnFieldListeners();
                    }
                });
            });

            // Initialize add field buttons
            document.querySelectorAll('.column-add-field').forEach(btn => {
                btn.addEventListener('click', function(e) {
                    e.stopPropagation();
                    const column = this.getAttribute('data-column');
                    window.targetColumn = column;
                    openAddFieldDialog();
                });
            });

            // Initialize field listeners in columns
            initializeColumnFieldListeners();
        }

        function initializeColumnFieldListeners() {
            const columnFields = document.querySelectorAll('.column-field');
            columnFields.forEach(field => {
                field.draggable = true;
                field.addEventListener('dragstart', function(e) {
                    draggedElement = this;
                    this.classList.add('dragging');
                });
                field.addEventListener('dragend', function(e) {
                    this.classList.remove('dragging');
                    draggedElement = null;
                });
            });
        }

        function updateColumnStates() {
            const leftColumn = document.getElementById('column-left');
            const rightColumn = document.getElementById('column-right');

            // Update visual states based on content
            if (leftColumn.children.length > 0) {
                leftColumn.classList.add('has-fields');
            } else {
                leftColumn.classList.remove('has-fields');
            }

            if (rightColumn.children.length > 0) {
                rightColumn.classList.add('has-fields');
            } else {
                rightColumn.classList.remove('has-fields');
            }
        }

        function togglePreviewMode() {
            // Remove editing toolbar and switch to regular view
            const url = new URL(window.location);
            url.searchParams.delete('editing');
            window.location.href = url.toString();
        }

        function initializeThemeSelector() {
            const themeSelect = document.getElementById('theme-select');
            if (!themeSelect) return;

            // Set current theme
            const currentTheme = getCurrentTheme();
            if (currentTheme) {
                themeSelect.value = currentTheme;
            }

            // Add change event listener
            themeSelect.addEventListener('change', function(e) {
                changeTheme(e.target.value);
            });
        }

        function getCurrentTheme() {
            // Try to get theme from URL parameters first
            const urlParams = new URLSearchParams(window.location.search);
            const urlTheme = urlParams.get('theme');
            if (urlTheme) return urlTheme;

            // Try to detect theme from CSS classes or other indicators
            const body = document.body;
            if (body.classList.contains('theme-dark')) return 'dark';
            if (body.classList.contains('theme-minimal')) return 'minimal';
            if (body.classList.contains('theme-modern')) return 'modern';
            if (body.classList.contains('theme-classic')) return 'classic';
            if (body.classList.contains('theme-colorful')) return 'colorful';
            if (body.classList.contains('theme-newspaper')) return 'newspaper';
            if (body.classList.contains('theme-elegant')) return 'elegant';

            return 'default';
        }

        function changeTheme(newTheme) {
            // For both editing and preview mode, update URL parameter and refresh for immediate effect
            const url = new URL(window.location);
            if (newTheme === 'default') {
                url.searchParams.delete('theme');
            } else {
                url.searchParams.set('theme', newTheme);
            }
            window.location.href = url.toString();
        }

    </script>
    """
  end
end
