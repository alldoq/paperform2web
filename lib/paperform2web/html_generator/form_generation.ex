defmodule Paperform2web.HtmlGenerator.FormGeneration do
  @moduledoc """
  Form generation functionality for HTML documents.
  Handles form sections, inputs, radio button grouping, and various field types.
  """

  # Alias Jason for JSON encoding

  @doc """
  Generates a form section based on the section type and metadata.
  """
  def generate_form_section(section, index, css_builder, style_builder, html_escaper, editing_mode \\ false) do
    type = section["type"] || "text"
    content = section["content"] || ""
    formatting = section["formatting"] || %{}
    position = section["position"] || %{}

    css_classes = css_builder.(type, formatting)
    inline_styles = style_builder.(formatting, position)
    field_name = get_in(section, ["metadata", "field_name"]) || "field_#{index}"

    # Debug logging for form sections
    if Application.get_env(:paperform2web, :debug_radio_buttons, false) do
      IO.puts("[Form Section] Processing section type: #{type}, content: #{content}, field_name: #{field_name}")
      if type == "form_input" do
        input_type = get_in(section, ["metadata", "input_type"])
        options = get_in(section, ["metadata", "options"]) || []
        IO.puts("  - input_type: #{input_type}, options count: #{length(options)}")
      end
    end

    # Remove width functionality - all fields are full width
    width_class = ""

    # Handle new AI-detected form elements
    case type do
      "form_input" ->
        if get_in(section, ["metadata", "input_type"]) do
          generate_form_input(content, "#{css_classes}#{width_class}", inline_styles, section, html_escaper, editing_mode)
        else
          # Fallback to legacy type-based generation
          generate_legacy_form_section(type, content, css_classes, inline_styles, width_class, field_name, section, index, html_escaper)
        end

      "form_label" ->
        # Check if this label is associated with a specific field
        label_field_name = get_in(section, ["metadata", "field_name"])
        if label_field_name do
          # This is a label for a specific input field
          "<label for=\"#{label_field_name}\" class=\"form-label #{css_classes}#{width_class}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</label>"
        else
          # This is standalone descriptive text (like a question)
          "<div class=\"form-question #{css_classes}#{width_class}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</div>"
        end

      "form_title" ->
        "<h1 class=\"form-title #{css_classes}#{width_class}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</h1>"

      "form_section" ->
        "<h2 class=\"form-section #{css_classes}#{width_class}\" style=\"#{inline_styles}\">#{html_escaper.(content)}</h2>"

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
              <input type="radio" id="#{radio_id}" name="#{field_name}" value="#{html_escaper.(option)}" />
              <label for="#{radio_id}">#{html_escaper.(option)}</label>
            </div>
            """
          end) |> Enum.join("")

          """
          <div class="form-field radio-field">
            <span class="radio-group-label">#{html_escaper.(content)}</span>
            <div class="radio-options">
              #{radio_buttons}
            </div>
          </div>
          """
        else
          # Fallback to form_input generation for radio without options
          generate_form_input(content, "#{css_classes}#{width_class}", inline_styles, section, html_escaper)
        end

      _ ->
        cond do
          # Check for form_field_id (indicates user-added field)
          Map.has_key?(section, "form_field_id") ->
            generate_form_input(content, "#{css_classes}#{width_class}", inline_styles, section, html_escaper, editing_mode)

          # Check if field_name starts with user_field_ (restored user field)
          String.starts_with?(field_name, "user_field_") ->
            generate_form_input(content, "#{css_classes}#{width_class}", inline_styles, section, html_escaper, editing_mode)

          # Check if it's a form_input type (AI-detected form field)
          type == "form_input" ->
            generate_form_input(content, "#{css_classes}#{width_class}", inline_styles, section, html_escaper, editing_mode)

          # Fallback to legacy type-based generation
          true ->
            generate_legacy_form_section(type, content, css_classes, inline_styles, width_class, field_name, section, index, html_escaper)
        end
    end
  end

  @doc """
  Generates form inputs based on input type and metadata.
  """
  def generate_form_input(content, css_classes, inline_styles, section, html_escaper, editing_mode \\ false) do
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

    # Debug logging for form input generation
    if Application.get_env(:paperform2web, :debug_radio_buttons, false) do
      IO.puts("[Form Input] Generating form input:")
      IO.puts("  - content: #{content}")
      IO.puts("  - input_type: #{input_type}")
      IO.puts("  - field_name: #{field_name}")
      IO.puts("  - options: #{inspect(options)}")
      IO.puts("  - section metadata: #{inspect(section["metadata"])}")
    end

    # Determine if we need to add editable-field class for editing mode
    form_field_id = get_in(section, ["form_field_id"]) || get_in(section, ["metadata", "field_name"])

    case input_type do
      "checkbox" ->
        # Create unique checkbox ID
        checkbox_id = "#{field_name}_#{:erlang.phash2(content)}"
        checked = if String.contains?(String.downcase(content), "checked") or field_value == "true", do: " checked", else: ""
        value = if field_value != "", do: field_value, else: "on"

        if editing_mode and form_field_id do
          """
          <div class="editable-field" data-field-type="#{input_type}" draggable="true" id="editable_#{form_field_id}">
              <div class="form-field checkbox-field #{css_classes}" style="#{inline_styles}">
                  <input type="checkbox" id="#{checkbox_id}" name="#{field_name}" value="#{html_escaper.(value)}"#{checked}#{required_attr}>
                  <label for="#{checkbox_id}" class="editable-label" contenteditable="true">#{html_escaper.(content)}</label>
              </div>
          </div>
          """
        else
          """
          <div class="form-field checkbox-field #{css_classes}" style="#{inline_styles}">
              <input type="checkbox" id="#{checkbox_id}" name="#{field_name}" value="#{html_escaper.(value)}"#{checked}#{required_attr}>
              <label for="#{checkbox_id}">#{html_escaper.(content)}</label>
          </div>
          """
        end

      "radio" ->
        # Handle radio buttons - check if we have multiple options
        if length(options) > 0 do
          # Debug logging for radio buttons with options
          if Application.get_env(:paperform2web, :debug_radio_buttons, false) do
            IO.puts("[Radio Input] Generating radio group with field_name: #{field_name}, content: #{content}, options: #{inspect(options)}")
          end

          # Generate radio group with multiple options
          radio_buttons = Enum.with_index(options, fn option, idx ->
            radio_id = "#{field_name}_#{idx}"
            radio_html = """
            <div class="radio-option">
              <input type="radio" id="#{radio_id}" name="#{field_name}" value="#{html_escaper.(option)}"#{required_attr}>
              <label for="#{radio_id}">#{html_escaper.(option)}</label>
            </div>
            """

            # Debug each radio button
            if Application.get_env(:paperform2web, :debug_radio_buttons, false) do
              IO.puts("[Radio Input] Generated radio button: #{radio_html}")
            end

            radio_html
          end) |> Enum.join("")

          final_html = if editing_mode and form_field_id do
            """
            <div class="editable-field" data-field-type="radio" draggable="true" id="editable_#{form_field_id}" data-options='#{Jason.encode!(options)}'>
              <div class="form-field">
                <div class="form-question editable-label" contenteditable="true">#{html_escaper.(content)}</div>
                <div class="radio-options">
                  #{radio_buttons}
                </div>
              </div>
            </div>
            """
          else
            """
            <div class="form-field radio-field #{css_classes}" style="#{inline_styles}">
              <span class="radio-group-label">#{html_escaper.(content)}</span>
              <div class="radio-options">
                #{radio_buttons}
              </div>
            </div>
            """
          end

          if Application.get_env(:paperform2web, :debug_radio_buttons, false) do
            IO.puts("[Radio Input] Final radio group HTML: #{final_html}")
          end

          final_html
        else
          # Single radio button (fallback for backwards compatibility)
          radio_id = "#{field_name}_#{sanitize_field_name(field_value != "" && field_value || content)}"
          value = if field_value != "", do: field_value, else: sanitize_field_name(content)
          """
          <div class="form-field #{css_classes}" style="#{inline_styles}">
              <input type="radio" id="#{radio_id}" name="#{field_name}" value="#{html_escaper.(value)}"#{required_attr}>
              <label for="#{radio_id}">#{html_escaper.(content)}</label>
          </div>
          """
        end

      "textarea" ->
        if editing_mode and form_field_id do
          """
          <div class="editable-field" data-field-type="textarea" draggable="true" id="editable_#{form_field_id}">
              <div class="form-field">
                  <label for="#{field_name}" class="form-label editable-label" contenteditable="true">#{html_escaper.(content)}</label>
                  <textarea id="#{field_name}" name="#{field_name}" class="editable-textarea" placeholder="#{html_escaper.(placeholder)}" rows="4">#{html_escaper.(field_value)}</textarea>
              </div>
          </div>
          """
        else
          """
          <div class="form-field #{css_classes}" style="#{inline_styles}">
              <label for="#{field_name}">#{html_escaper.(content)}</label>
              <textarea id="#{field_name}" name="#{field_name}" placeholder="#{html_escaper.(placeholder)}" rows="4"#{required_attr}>#{html_escaper.(field_value)}</textarea>
          </div>
          """
        end

      "select" ->
        options_html = if Enum.empty?(options) do
          "<option value=\"\">Select an option</option>"
        else
          Enum.map_join(options, "", fn option ->
            selected = if option == field_value, do: " selected", else: ""
            "<option value=\"#{html_escaper.(option)}\"#{selected}>#{html_escaper.(option)}</option>"
          end)
        end

        if editing_mode and form_field_id do
          """
          <div class="editable-field" data-field-type="select" draggable="true" id="editable_#{form_field_id}" data-options='#{Jason.encode!(options)}'>
              <div class="form-field">
                  <label for="#{field_name}" class="form-label editable-label" contenteditable="true">#{html_escaper.(content)}</label>
                  <select id="#{field_name}" name="#{field_name}" class="editable-select">
                      <option value="">Choose an option</option>
                      #{options_html}
                  </select>
              </div>
          </div>
          """
        else
          """
          <div class="form-field #{css_classes}" style="#{inline_styles}">
              <label for="#{field_name}">#{html_escaper.(content)}</label>
              <select id="#{field_name}" name="#{field_name}"#{required_attr}>#{options_html}</select>
          </div>
          """
        end

      input_type when input_type in ["date", "time", "datetime-local", "email", "tel", "url", "number", "password"] ->
        if editing_mode and form_field_id do
          """
          <div class="editable-field" data-field-type="#{input_type}" draggable="true" id="editable_#{form_field_id}">
              <div class="form-field">
                  <label for="#{field_name}" class="form-label editable-label" contenteditable="true">#{html_escaper.(content)}</label>
                  <input type="#{input_type}" id="#{field_name}" name="#{field_name}" class="editable-input" value="#{html_escaper.(field_value)}" placeholder="#{html_escaper.(placeholder)}">
              </div>
          </div>
          """
        else
          """
          <div class="form-field #{css_classes}" style="#{inline_styles}">
              <label for="#{field_name}">#{html_escaper.(content)}</label>
              <input type="#{input_type}" id="#{field_name}" name="#{field_name}" value="#{html_escaper.(field_value)}" placeholder="#{html_escaper.(placeholder)}"#{required_attr}>
          </div>
          """
        end

      "text" ->
        if editing_mode and form_field_id do
          """
          <div class="editable-field" data-field-type="text" draggable="true" id="editable_#{form_field_id}">
              <div class="form-field">
                  <label for="#{field_name}" class="form-label editable-label" contenteditable="true">#{html_escaper.(content)}</label>
                  <input type="text" id="#{field_name}" name="#{field_name}" class="editable-input" placeholder="Enter text..." value="#{html_escaper.(field_value)}">
              </div>
          </div>
          """
        else
          """
          <div class="form-field #{css_classes}" style="#{inline_styles}">
              <label for="#{field_name}">#{html_escaper.(content)}</label>
              <input type="text" id="#{field_name}" name="#{field_name}" value="#{html_escaper.(field_value)}" placeholder="#{html_escaper.(placeholder)}"#{required_attr}>
          </div>
          """
        end

      _ ->
        # Force create a text input even for unknown types - NO STATIC CONTENT
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{html_escaper.(content)}</label>
            <input type="text" id="#{field_name}" name="#{field_name}" value="#{html_escaper.(field_value || content)}" placeholder="Enter value"#{required_attr}>
        </div>
        """
    end
  end

  @doc """
  Generates legacy form sections for backward compatibility.
  """
  def generate_legacy_form_section(type, content, css_classes, inline_styles, width_class, field_name, section, _index, html_escaper) do
    case type do
      "text" ->
        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{html_escaper.(content)}</label>
            <input type="text" id="#{field_name}" name="#{field_name}" placeholder="#{html_escaper.(content)}" />
        </div>
        """

      "textarea" ->
        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{html_escaper.(content)}</label>
            <textarea id="#{field_name}" name="#{field_name}" rows="3" placeholder="#{html_escaper.(content)}"></textarea>
        </div>
        """

      "checkbox" ->
        """
        <div class="form-field#{width_class} checkbox-field #{css_classes}" style="#{inline_styles}">
            <input type="checkbox" id="#{field_name}" name="#{field_name}" />
            <label for="#{field_name}">#{html_escaper.(content)}</label>
        </div>
        """

      "select" ->
        options = get_in(section, ["metadata", "options"]) || ["Option 1", "Option 2", "Option 3"]
        options_html = Enum.map_join(options, "", fn option ->
          "<option value=\"#{html_escaper.(option)}\">#{html_escaper.(option)}</option>"
        end)

        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{html_escaper.(content)}</label>
            <select id="#{field_name}" name="#{field_name}">#{options_html}</select>
        </div>
        """

      "email" ->
        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{html_escaper.(content)}</label>
            <input type="email" id="#{field_name}" name="#{field_name}" placeholder="#{html_escaper.(content)}" />
        </div>
        """

      "date" ->
        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{html_escaper.(content)}</label>
            <input type="date" id="#{field_name}" name="#{field_name}" />
        </div>
        """

      # Handle legacy types and convert them to proper form fields
      "form_field" ->
        generate_form_field(content, css_classes <> width_class, inline_styles, section, html_escaper)

      "form_input" ->
        generate_form_input(content, css_classes <> width_class, inline_styles, section, html_escaper)

      _ ->
        # Default to text input for any other type
        """
        <div class="form-field#{width_class} #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{html_escaper.(content)}</label>
            <input type="text" id="#{field_name}" name="#{field_name}" placeholder="#{html_escaper.(content)}" />
        </div>
        """
    end
  end

  @doc """
  Groups radio button sections that belong together.
  """
  def group_radio_sections(sections) do
    # First pass: find radio groups and their associated labels
    group_radio_and_labels(sections)
  end

  # Enhanced grouping logic that handles form_label + radio patterns.
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

  # Find radio buttons with the same field name
  defp find_radio_siblings_with_same_field(sections, field_name) do
    sections
    |> Enum.with_index()
    |> Enum.filter(fn {section, _} ->
      section["type"] == "form_input" &&
      get_in(section, ["metadata", "input_type"]) == "radio" &&
      get_in(section, ["metadata", "field_name"]) == field_name
    end)
  end

  @doc """
  Generates radio button fieldset.
  """
  def generate_radio_fieldset(radio_sections, index) do
    if is_list(radio_sections) and length(radio_sections) > 1 do
      # This is a group of radio sections
      [first_section | radio_inputs] = radio_sections

      # Use the first section (usually a label) as the fieldset legend
      legend = first_section["content"] || "Radio Group"
      field_name = get_in(List.first(radio_inputs), ["metadata", "field_name"]) || "radio_group_#{index}"

      # Generate the fieldset with all radio inputs, ensuring they all share the same field name
      radio_buttons = Enum.map_join(radio_inputs, "", fn section ->
        # Ensure the section has the correct field_name for the radio group
        section_with_field_name = put_in(section, ["metadata", "field_name"], field_name)
        generate_form_input(section["content"], "", "", section_with_field_name, &escape_html/1)
      end)

      """
      <fieldset class="radio-fieldset">
        <legend class="radio-legend">#{escape_html(legend)}</legend>
        <div class="radio-options">
          #{radio_buttons}
        </div>
      </fieldset>
      """
    else
      # Single section, treat as regular form section
      section = if is_list(radio_sections), do: List.first(radio_sections), else: radio_sections
      generate_form_section(section, index, &build_css_classes/2, &build_inline_styles/2, &escape_html/1)
    end
  end

  @doc """
  Generates form wrapper with proper form tags.
  """
  def generate_form_wrapper(content_html, document_id, options) do
    share_token = Map.get(options, :share_token)
    document_id_attr = if document_id, do: " data-document-id=\"#{document_id}\"", else: ""
    share_token_attr = if share_token, do: " data-share-token=\"#{share_token}\"", else: ""

    """
    <main class="document-content">
        <form id="document-form"#{document_id_attr}#{share_token_attr}>
            #{content_html}
            <div class="form-actions">
                <button type="button" id="submit-form" class="submit-btn">📝 Submit Form</button>
            </div>
            <div id="form-status" class="form-status" style="display:none;"></div>
        </form>
    </main>
    """
  end

  # Helper functions
  defp infer_field_type(content) do
    content_lower = String.downcase(content)

    cond do
      String.contains?(content_lower, "email") -> "email"
      String.contains?(content_lower, "phone") or String.contains?(content_lower, "tel") -> "tel"
      String.contains?(content_lower, "date") -> "date"
      String.contains?(content_lower, "time") -> "time"
      String.contains?(content_lower, "number") or String.contains?(content_lower, "age") -> "number"
      String.contains?(content_lower, "password") -> "password"
      String.contains?(content_lower, "url") or String.contains?(content_lower, "website") -> "url"
      String.contains?(content, "☐") or String.contains?(content, "□") or String.contains?(content_lower, "check") -> "checkbox"
      String.contains?(content, "○") or String.contains?(content, "◯") or String.contains?(content_lower, "radio") or String.contains?(content_lower, "select one") -> "radio"
      String.contains?(content_lower, "message") or String.contains?(content_lower, "comment") or String.contains?(content_lower, "description") -> "textarea"
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
  defp generate_form_field(content, css_classes, inline_styles, section, html_escaper) do
    field_type = get_in(section, ["metadata", "field_type"]) || infer_field_type(content)
    field_name = get_in(section, ["metadata", "field_name"]) || sanitize_field_name(content)
    field_value = get_in(section, ["metadata", "field_value"]) || ""

    case field_type do
      "checkbox" ->
        checked = if String.contains?(String.downcase(content), "checked") or field_value == "true", do: "checked", else: ""
        """
        <div class="form-field checkbox-field #{css_classes}" style="#{inline_styles}">
            <input type="checkbox" id="#{field_name}" name="#{field_name}" #{checked}>
            <label for="#{field_name}">#{html_escaper.(content)}</label>
        </div>
        """

      _ ->
        # Default to text input
        """
        <div class="form-field #{css_classes}" style="#{inline_styles}">
            <label for="#{field_name}">#{html_escaper.(content)}</label>
            <input type="text" id="#{field_name}" name="#{field_name}" value="#{html_escaper.(field_value)}" placeholder="Enter value">
        </div>
        """
    end
  end

  # Placeholder functions - these would normally come from the main module
  defp build_css_classes(_type, _formatting), do: ""
  defp build_inline_styles(_formatting, _position), do: ""
  defp escape_html(text), do: text
end