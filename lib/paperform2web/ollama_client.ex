defmodule Paperform2web.OllamaClient do
  @moduledoc """
  Client for interacting with Ollama AI models for document processing.
  Supports multiple authentication methods: API Key, Bearer Token, and Basic Auth.
  """

  require Logger

  @default_model "openai/gpt-5"
  @default_url "https://openrouter.ai/api/v1"

  @type auth_config :: %{
    type: :api_key | :bearer | :basic | :none,
    api_key: String.t(),
    token: String.t(),
    username: String.t(),
    password: String.t(),
    custom_header: String.t()
  }

  def process_document(image_data, model \\ @default_model, options \\ %{}) do
    prompt = build_document_processing_prompt(options)
    image_url = "data:image/png;base64,#{Base.encode64(image_data)}"

    payload = %{
      model: model,
      messages: [
        %{
          role: "user",
          content: [
            %{
              type: "text",
              text: prompt
            },
            %{
              type: "image_url",
              image_url: %{
                url: image_url
              }
            }
          ]
        }
      ],
      temperature: Map.get(options, :temperature, 0.1),
      top_p: Map.get(options, :top_p, 0.9)
    }

    case make_request("/chat/completions", payload) do
      {:ok, response} -> parse_response(response)
      {:error, error} -> {:error, error}
    end
  end

  def list_models do
    # OpenRouter has different model listing - return common models for now
    {:ok, [
      "openai/gpt-4o",           # Best for complex forms, most accurate
      "openai/gpt-4o-mini",      # Faster, cheaper, still very good
      "anthropic/claude-3.5-sonnet",  # Excellent reasoning
      "anthropic/claude-3-haiku",     # Fast and affordable
      "google/gemini-pro-1.5",        # Good vision capabilities
      "google/gemini-flash-1.5"       # Fast and efficient
    ]}
  end

  def check_model_availability(model) do
    case list_models() do
      {:ok, models} -> {:ok, model in models}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Test the connection to OpenRouter with current authentication settings.
  """
  def test_connection do
    case make_request("/models", %{}, :get) do
      {:ok, response} ->
        Logger.info("OpenRouter connection test successful")
        {:ok, response}
      {:error, error} ->
        Logger.error("OpenRouter connection test failed: #{error}")
        {:error, error}
    end
  end

  @doc """
  Validate authentication configuration.
  """
  def validate_auth_config do
    auth_config = get_auth_config()

    case auth_config.type do
      :none ->
        {:ok, "No authentication configured"}

      :api_key ->
        if auth_config.api_key && String.length(auth_config.api_key) > 0 do
          {:ok, "API key authentication configured"}
        else
          {:error, "API key authentication selected but no API key provided"}
        end

      :bearer ->
        if auth_config.token && String.length(auth_config.token) > 0 do
          {:ok, "Bearer token authentication configured"}
        else
          {:error, "Bearer token authentication selected but no token provided"}
        end

      :basic ->
        if auth_config.username && auth_config.password &&
           String.length(auth_config.username) > 0 && String.length(auth_config.password) > 0 do
          {:ok, "Basic authentication configured"}
        else
          {:error, "Basic authentication selected but username or password missing"}
        end

      _ ->
        {:error, "Unknown authentication type: #{auth_config.type}"}
    end
  end

  defp build_document_processing_prompt(options) do
    base_prompt = """
    You are a FORM FIELD RECOGNITION SPECIALIST. Analyze this form image and convert it to structured JSON.

    🚨 CRITICAL RULES - READ THESE FIRST:

    1. **VISUAL SHAPES DETERMINE FIELD TYPE** - Look at the SHAPE, not just the text:
       - □ ☐ Square box = checkbox
       - ○ ● Circle = radio button
       - ▼ ↓ Arrow = dropdown/select
       - Large rectangle = textarea
       - DD/MM/YYYY pattern = date field
       - ___ Underline = text input

    2. **LABEL vs INPUT DECISION**:
       - If text is DESCRIPTIVE (question, instruction, heading) → form_label or form_section
       - If area is FILLABLE (user can type/select) → form_input
       - NEVER create both a label AND a text input for the same text!

    3. **YES/NO PATTERNS** (Most common error):
       - Question + "Yes □" and "No □" = ONE question with TWO radio buttons
       - SAME field_name for both options, DIFFERENT field_value
       - Example: "Do you agree?" → form_label, then "Yes" radio + "No" radio

    4. **GOVERNMENT FORM PATTERNS**:
       - Sequential boxes [__][__][____] = date field (DD/MM/YYYY)
       - Small squares next to options = checkboxes or radio buttons
       - Large address boxes = textarea
       - Question numbers are part of the label text

    🎯 FIELD TYPE QUICK REFERENCE:

    | Visual Cue | Input Type | Example |
    |------------|------------|---------|
    | □ ☐ Square | checkbox | "□ I agree" |
    | ○ ● Circle | radio | "○ Male ○ Female" |
    | ▼ Arrow | select | "Country [Select ▼]" |
    | [__][__][____] | date | "DD MM YYYY" |
    | Large box | textarea | Multi-line address |
    | @ symbol | email | "Email: user@example.com" |
    | Phone pattern | tel | "(123) 456-7890" |
    | "age", "quantity" | number | "Age: ___" |
    | ___ Underline | text | "Name: _______" |

    📋 JSON STRUCTURE:

    {
      "document_type": "form",
      "title": "Form title",
      "content": {
        "sections": [
          {
            "type": "form_title|form_section|form_label|form_input",
            "content": "text or label",
            "metadata": {
              "input_type": "text|email|date|number|tel|textarea|select|checkbox|radio",
              "field_name": "snake_case_name",
              "field_value": "pre-filled value (for radio/checkbox)",
              "options": ["opt1", "opt2"],
              "required": true
            }
          }
        ]
      }
    }

    ✅ CORRECT EXAMPLES:

    1. **Checkbox**: Visual "□ I agree to terms"
       → {"type": "form_input", "content": "I agree to terms", "metadata": {"input_type": "checkbox", "field_name": "agree_terms"}}

    2. **Radio Group**: Visual "Gender: ○ Male ○ Female"
       → {"type": "form_label", "content": "Gender:"}
       → {"type": "form_input", "content": "Male", "metadata": {"input_type": "radio", "field_name": "gender", "field_value": "male"}}
       → {"type": "form_input", "content": "Female", "metadata": {"input_type": "radio", "field_name": "gender", "field_value": "female"}}

    3. **Date Field**: Visual "Date of birth DD MM YYYY [__][__][____]"
       → {"type": "form_label", "content": "Date of birth"}
       → {"type": "form_input", "content": "", "metadata": {"input_type": "date", "field_name": "date_of_birth"}}

    4. **Yes/No Radio**: Visual "16 Do you agree?" with "No □" and "Yes □"
       → {"type": "form_label", "content": "16 Do you agree?"}
       → {"type": "form_input", "content": "No", "metadata": {"input_type": "radio", "field_name": "question_16_agree", "field_value": "no"}}
       → {"type": "form_input", "content": "Yes", "metadata": {"input_type": "radio", "field_name": "question_16_agree", "field_value": "yes"}}

    5. **Textarea**: Visual "Address: [large multi-line box]"
       → {"type": "form_label", "content": "Address:"}
       → {"type": "form_input", "content": "", "metadata": {"input_type": "textarea", "field_name": "address"}}

    ❌ COMMON MISTAKES TO AVOID:

    - DON'T create form_input for question text - only for fillable areas
    - DON'T use input_type="text" when you see □ or ○ - use checkbox/radio
    - DON'T create separate questions for "Yes" and "No" - they're radio options
    - DON'T miss sequential boxes [__][__][____] - these are date fields

    Return ONLY valid JSON. Analyze VISUAL SHAPES first!
    """

    custom_instructions = Map.get(options, :custom_instructions, "")
    if custom_instructions != "", do: base_prompt <> "\n\nAdditional instructions: " <> custom_instructions, else: base_prompt
  end

  defp parse_response(response) do
    # Extract content from OpenRouter chat completions response
    content = get_in(response, ["choices", Access.at(0), "message", "content"])
    
    if content do
      # Strip markdown code block formatting (aggressive approach)
      json_content = content
        |> String.trim()
        |> strip_markdown_blocks()

      # Log the first 200 chars for debugging if needed
      Logger.debug("Cleaned JSON content (first 200 chars): #{String.slice(json_content, 0, 200)}...")

      case Jason.decode(json_content) do
        {:ok, parsed_json} ->
          {:ok, {parsed_json, content}}
        {:error, _} ->
          Logger.warning("Failed to parse JSON from OpenRouter response: #{content}")
          {:error, "Invalid JSON response from AI model"}
      end
    else
      Logger.warning("No content found in OpenRouter response: #{inspect(response)}")
      {:error, "No response content from AI model"}
    end
  end

  defp make_request(endpoint, payload, method \\ :post) do
    url = ollama_url() <> endpoint
    headers = build_headers()
    request_options = [recv_timeout: 120_000, timeout: 30_000]

    case method do
      :post ->
        body = Jason.encode!(payload)
        case HTTPoison.post(url, body, headers, request_options) do
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in [200, 201] ->
            Jason.decode(body)
          {:ok, %HTTPoison.Response{status_code: 401}} ->
            {:error, "Authentication failed - check your credentials"}
          {:ok, %HTTPoison.Response{status_code: 403}} ->
            {:error, "Access forbidden - insufficient permissions"}
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
            {:error, "HTTP #{status_code}: #{body}"}
          {:error, %HTTPoison.Error{reason: reason}} ->
            {:error, "Connection error: #{reason}"}
        end

      :get ->
        case HTTPoison.get(url, headers, request_options) do
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in [200, 201] ->
            Jason.decode(body)
          {:ok, %HTTPoison.Response{status_code: 401}} ->
            {:error, "Authentication failed - check your credentials"}
          {:ok, %HTTPoison.Response{status_code: 403}} ->
            {:error, "Access forbidden - insufficient permissions"}
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
            {:error, "HTTP #{status_code}: #{body}"}
          {:error, %HTTPoison.Error{reason: reason}} ->
            {:error, "Connection error: #{reason}"}
        end
    end
  end

  defp build_headers do
    base_headers = [
      {"Content-Type", "application/json"},
      {"HTTP-Referer", "https://paperform2web.com"},
      {"X-Title", "Paperform2Web"}
    ]
    auth_config = get_auth_config()

    case auth_config.type do
      :none ->
        base_headers

      :api_key ->
        [{"Authorization", "Bearer #{auth_config.api_key}"} | base_headers]

      :bearer ->
        [{"Authorization", "Bearer #{auth_config.token}"} | base_headers]

      :basic ->
        credentials = Base.encode64("#{auth_config.username}:#{auth_config.password}")
        [{"Authorization", "Basic #{credentials}"} | base_headers]

      _ ->
        Logger.warning("Unknown authentication type: #{auth_config.type}, using no auth")
        base_headers
    end
  end

  defp get_auth_config do
    default_config = %{
      type: :none,
      api_key: nil,
      token: nil,
      username: nil,
      password: nil,
      custom_header: nil
    }

    config = Application.get_env(:paperform2web, :ollama_auth, %{})
    Map.merge(default_config, config)
  end

  defp ollama_url do
    Application.get_env(:paperform2web, :ollama_url, @default_url)
  end

  # Aggressively strip markdown code blocks
  defp strip_markdown_blocks(content) do
    content
    # First, try to find content between code blocks and extract just that
    |> extract_json_from_markdown()
    # If that doesn't work, try line-by-line cleaning
    |> clean_line_by_line()
    |> String.trim()
  end

  defp extract_json_from_markdown(content) do
    # Try to find JSON content between ```json and ``` markers
    case Regex.run(~r/```(?:json)?\s*\n?([\s\S]*?)\n?\s*```/mi, content, capture: :all_but_first) do
      [json_part] -> String.trim(json_part)
      _ -> content
    end
  end

  defp clean_line_by_line(content) do
    content
    |> String.split("\n")
    |> Enum.reject(fn line ->
      line_trimmed = String.trim(line)
      # Remove lines that are just markdown markers
      line_trimmed == "```" or
      line_trimmed == "```json" or
      line_trimmed == "```JSON" or
      String.starts_with?(line_trimmed, "```")
    end)
    |> Enum.join("\n")
  end
end
