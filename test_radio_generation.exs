# Test script to debug radio button generation
alias Paperform2web.HtmlGenerator

# Create a test section that matches what the frontend sends
test_section = %{
  "content" => "New Radio Group",
  "form_field_id" => "editable_user_field_1758519800642",
  "formatting" => %{
    "alignment" => "left",
    "bold" => false,
    "font_size" => "medium",
    "italic" => false,
    "width" => "full"
  },
  "metadata" => %{
    "field_name" => "user_field_1758519800642",
    "input_type" => "radio",
    "options" => ["Option 1", "Option 2", "Option 3"],
    "required" => false
  },
  "position" => %{
    "height" => 30,
    "width" => 400,
    "x" => 0,
    "y" => 0
  },
  "type" => "form_input"
}

# Test the form generation directly
IO.puts("=== Testing Radio Button Generation ===")

# Test generate_form_section
css_builder = fn _type, _formatting -> "" end
style_builder = fn _formatting, _position -> "" end
html_escaper = &Paperform2web.HtmlGenerator.ContentGeneration.escape_html/1

IO.puts("\n1. Testing generate_form_section:")
result = Paperform2web.HtmlGenerator.FormGeneration.generate_form_section(
  test_section,
  0,
  css_builder,
  style_builder,
  html_escaper
)
IO.puts("Result: #{result}")

# Test generate_form_input directly
IO.puts("\n2. Testing generate_form_input:")
input_result = Paperform2web.HtmlGenerator.FormGeneration.generate_form_input(
  test_section["content"],
  "",
  "",
  test_section,
  html_escaper
)
IO.puts("Result: #{input_result}")

# Test full HTML generation
IO.puts("\n3. Testing full HTML generation:")
test_data = %{
  "document_type" => "form",
  "title" => "Test Document",
  "content" => %{
    "sections" => [test_section]
  },
  "metadata" => %{}
}

case Paperform2web.HtmlGenerator.generate_html(test_data, %{editing: false}) do
  {:ok, html} ->
    IO.puts("Full HTML generated successfully!")
    IO.puts("HTML snippet around radio buttons:")
    lines = String.split(html, "\n")
    radio_lines = Enum.filter(lines, fn line ->
      String.contains?(line, "radio") || String.contains?(line, "radio-field")
    end)
    Enum.each(radio_lines, &IO.puts/1)
  {:error, reason} ->
    IO.puts("Error generating HTML: #{reason}")
end