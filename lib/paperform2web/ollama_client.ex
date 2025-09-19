defmodule Paperform2web.OllamaClient do
  @moduledoc """
  Client for interacting with Ollama AI models for document processing.
  Supports multiple authentication methods: API Key, Bearer Token, and Basic Auth.
  """

  require Logger

  @default_model "openai/gpt-5-mini"
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
      "openai/gpt-4o",
      "openai/gpt-4o-mini", 
      "anthropic/claude-3.5-sonnet",
      "anthropic/claude-3-haiku",
      "google/gemini-pro-vision"
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
    You are an ADVANCED FORM ANALYSIS AI specialized in VISUAL RECOGNITION of form elements. Your ONLY job is to convert form documents into interactive HTML forms by accurately identifying field types from VISUAL CUES.

    CRITICAL MISSION: Analyze the image pixel by pixel to identify form elements and their EXACT types. Every fillable area MUST become the CORRECT interactive input type based on VISUAL INDICATORS.

    🎯 VISUAL RECOGNITION PRIORITY:
    1. EXAMINE VISUAL SHAPES AND PATTERNS FIRST
    2. READ LABELS AND CONTEXT SECOND
    3. MATCH TO APPROPRIATE INPUT TYPE
    4. RECOGNIZE QUESTION-OPTION RELATIONSHIPS

    🚨 MOST IMPORTANT: QUESTION + YES/NO PATTERN RECOGNITION
    When you see a pattern like:
    "16 Do you intend to live outside the UK permanently?"
    [followed by]
    "No" [with input area]
    "Yes" [with input area]

    This is ONE question with TWO radio button options, NOT three separate questions!

    CRITICAL OUTPUT PATTERN:
    1. Create ONE form_label with the full question text (including number)
    2. Create TWO form_input entries with input_type="radio"
    3. Both radio inputs MUST have the SAME field_name
    4. Each radio input MUST have different field_value ("no", "yes")
    5. The radio inputs should have content="No" and content="Yes"

    NEVER create separate form_label entries for "No" and "Yes" - they are OPTIONS, not questions!

    Return your analysis in this JSON format:

    {
      "document_type": "form",
      "title": "Form title if available",
      "content": {
        "sections": [
          {
            "type": "form_title|form_section|form_label|form_input|form_group",
            "content": "text content or label",
            "formatting": {
              "bold": true/false,
              "italic": true/false,
              "font_size": "small|medium|large",
              "alignment": "left|center|right"
            },
            "metadata": {
              "input_type": "text|email|date|time|number|tel|url|password|textarea|select|checkbox|radio",
              "field_name": "field_name",
              "field_value": "pre-filled value",
              "options": ["option1", "option2"],
              "required": true/false,
              "placeholder": "placeholder text",
              "visual_cue": "description of what you see"
            }
          }
        ]
      },
      "metadata": {
        "language": "detected language",
        "confidence": 0.95,
        "total_fields": 5,
        "processing_notes": "visual analysis details"
      }
    }

    🔍 VISUAL PATTERN RECOGNITION GUIDE:

    📋 CHECKBOX IDENTIFICATION (Priority: HIGHEST):
    LOOK FOR THESE EXACT VISUAL PATTERNS:
    ✓ Square boxes: □ ☐ ▢ ◯ (empty or filled)
    ✓ Checkmarks: ☑ ✓ ✗ ✔
    ✓ Small boxes next to text: "□ I agree" "☑ Yes" "▢ No"
    ✓ Multiple choice options with boxes
    ✓ FORMS WITH YES/NO OPTIONS: Look for small squares next to "Yes" or "No" text
    ✓ GOVERNMENT FORMS: Often have small rectangular boxes for selection
    ✓ Any small rectangular shape that appears clickable or selectable
    ✓ Boxes that appear in pairs or groups with labels
    → ALWAYS classify as input_type: "checkbox"

    🔘 RADIO BUTTON IDENTIFICATION (Enhanced):
    LOOK FOR THESE EXACT VISUAL PATTERNS:
    ✓ Circular shapes: ○ ● ◯ ◉ ⚪ ⚫
    ✓ Dots or circles next to options: "○ Male ○ Female"
    ✓ Single selection groups with circles
    ✓ YES/NO PAIRS: When you see "Yes □ No □" pattern, these are often radio buttons
    ✓ MUTUALLY EXCLUSIVE OPTIONS: Options where only one can be selected
    ✓ Look for options that are clearly alternatives to each other
    → ALWAYS classify as input_type: "radio" when options are mutually exclusive
    → Use input_type: "checkbox" when multiple selections are possible

    📋 DROPDOWN/SELECT IDENTIFICATION:
    LOOK FOR THESE EXACT VISUAL PATTERNS:
    ✓ Dropdown arrows: ▼ ↓ ⬇ ⇓ ♦
    ✓ Rectangular boxes with arrows on the right
    ✓ Text like "Select..." "Choose..." "Pick..."
    ✓ Lists of options that appear to be selectable
    → ALWAYS classify as input_type: "select"

    📝 TEXT AREA IDENTIFICATION:
    LOOK FOR THESE EXACT VISUAL PATTERNS:
    ✓ Large rectangular boxes (wider and taller than regular inputs)
    ✓ Multi-line spaces for text
    ✓ Labels like: "Comments" "Description" "Address" "Notes"
    ✓ Boxes that are clearly bigger than single-line inputs
    → ALWAYS classify as input_type: "textarea"

    📅 DATE FIELD IDENTIFICATION (Enhanced):
    LOOK FOR THESE EXACT VISUAL PATTERNS:
    ✓ Date formats: DD/MM/YYYY, MM/DD/YYYY, __/__/__
    ✓ Multiple small boxes in sequence: [__] [__] [____] or [__] / [__] / [____]
    ✓ Calendar icons: 📅 🗓
    ✓ Labels containing: "date" "birth" "dob" "expire" "due" "leaving" "arrival"
    ✓ Slash or dash separators for dates: DD/MM/YYYY, DD-MM-YYYY
    ✓ GOVERNMENT FORMS: Often show as separate boxes for day, month, year
    ✓ Sequential numbered boxes (day/month/year pattern)
    ✓ Text showing format like "DD MM YYYY" or similar
    → ALWAYS classify as input_type: "date"

    ⏰ TIME FIELD IDENTIFICATION:
    ✓ Time formats: HH:MM, __:__
    ✓ AM/PM indicators
    ✓ Clock symbols: 🕐 ⏰
    ✓ Labels containing: "time" "hour" "appointment"
    → ALWAYS classify as input_type: "time"

    📧 EMAIL FIELD IDENTIFICATION:
    ✓ @ symbols visible
    ✓ Labels containing: "email" "e-mail" "@"
    ✓ Example text like "user@example.com"
    → ALWAYS classify as input_type: "email"

    📞 PHONE FIELD IDENTIFICATION:
    ✓ Phone number patterns: (XXX) XXX-XXXX, +1-XXX-XXX-XXXX
    ✓ Labels containing: "phone" "tel" "mobile" "cell"
    ✓ Country codes: +1, +44, etc.
    → ALWAYS classify as input_type: "tel"

    🔢 NUMBER FIELD IDENTIFICATION:
    ✓ Labels containing: "age" "quantity" "amount" "count" "number" "ID" "zip" "postal"
    ✓ Numeric patterns or examples
    → ALWAYS classify as input_type: "number"

    📄 TEXT FIELD (DEFAULT):
    ✓ Simple lines: _________ ___________
    ✓ Empty rectangular boxes
    ✓ Labels like: "name" "address" "city" "title"
    → ALWAYS classify as input_type: "text"

    ⚠️ CRITICAL ANALYSIS RULES:
    1. VISUAL SHAPE OVERRIDES TEXT CONTENT
    2. If you see □ → ALWAYS checkbox, regardless of text
    3. If you see ○ → ALWAYS radio button, regardless of text
    4. If you see ▼ → ALWAYS select dropdown, regardless of text
    5. Large boxes → ALWAYS textarea, regardless of text
    6. YES/NO PAIRS → Usually radio buttons (mutually exclusive)
    7. Multiple checkboxes in a row → Often checkboxes for multiple selection
    8. Sequential small boxes → Usually date fields (DD/MM/YYYY)
    9. GOVERNMENT FORMS: Be extra careful - they use many checkboxes and date fields

    📋 SPECIAL FORM PATTERNS (CRITICAL):
    ✓ "Yes □ No □" → Two radio buttons with same field_name, different values
    ✓ QUESTION + YES/NO PAIR: When you see a question followed by "No" and "Yes" sections, these are ONE question with TWO radio button options
    ✓ Multiple address lines → textarea field
    ✓ Postcode/ZIP fields → text input (short)
    ✓ Question numbers followed by checkboxes → checkbox fields
    ✓ Instructions like "If Yes, please..." → conditional checkbox logic

    🚨 CRITICAL: YES/NO GROUPING RULES:
    1. If you see a QUESTION followed by separate "No" and "Yes" sections, they belong to the SAME question
    2. Generate ONE form_label for the question + TWO form_input radio buttons
    3. Both radio buttons must have the SAME field_name but different field_values
    4. NEVER create separate questions for Yes and No - they are options for the same question
    5. NEVER create form_label entries for "Yes" or "No" - they go in form_input content
    6. The question NUMBER should be included in the form_label content

    🔥 ANTI-PATTERN TO AVOID:
    ❌ WRONG: Three separate sections for "16 Do you intend...", "No", "Yes"
    ✅ CORRECT: One form_label + two form_input radio buttons with same field_name

    📋 EXACT JSON STRUCTURE FOR YES/NO QUESTIONS:
    When you see: "16 Do you intend to live outside the UK permanently?" with "No" and "Yes" options

    Generate EXACTLY this structure:
    {
      "type": "form_label",
      "content": "16 Do you intend to live outside the UK permanently?"
    },
    {
      "type": "form_input",
      "content": "No",
      "metadata": {
        "input_type": "radio",
        "field_name": "live_outside_uk_permanently",
        "field_value": "no"
      }
    },
    {
      "type": "form_input",
      "content": "Yes",
      "metadata": {
        "input_type": "radio",
        "field_name": "live_outside_uk_permanently",
        "field_value": "yes"
      }
    }

    💡 PERFECT EXAMPLES - ANALYZE THESE PATTERNS:

    EXAMPLE 1: CORRECT Label + Input Pattern
    Visual: "Name: ____________"
    Analysis: "Name:" is descriptive text, "____" is fillable area
    CORRECT Output:
    - form_label: content="Name:", type="form_label"
    - form_input: content="", type="form_input", input_type="text", field_name="name", placeholder="Enter your name", visual_cue="underline for text input"

    EXAMPLE 1b: WRONG Pattern (DO NOT DO THIS)
    Visual: Same as above
    WRONG Output:
    - form_label: content="Name:", type="form_label"
    - form_input: content="Name", type="form_input", input_type="text", field_name="name"
    - form_input: content="Name:", type="form_input", input_type="text", field_name="name_label"
    ❌ WRONG! Don't create inputs for label text!

    EXAMPLE 2: Checkbox
    Visual: "☐ I agree to the terms and conditions"
    Analysis: See □ square box → Checkbox
    Output:
    - form_input: content="I agree to the terms and conditions", type="form_input", input_type="checkbox", field_name="agree_terms", visual_cue="square checkbox box"

    EXAMPLE 3: Radio Buttons
    Visual: "Gender: ○ Male ○ Female ○ Other"
    Analysis: See ○ circles → Radio buttons group
    Output:
    - form_label: content="Gender:", type="form_label"
    - form_input: content="Male", type="form_input", input_type="radio", field_name="gender", field_value="male", visual_cue="circular radio button"
    - form_input: content="Female", type="form_input", input_type="radio", field_name="gender", field_value="female", visual_cue="circular radio button"
    - form_input: content="Other", type="form_input", input_type="radio", field_name="gender", field_value="other", visual_cue="circular radio button"

    EXAMPLE 4: Dropdown
    Visual: "Country: [Select Country ▼]"
    Analysis: See ▼ dropdown arrow → Select field
    Output:
    - form_label: content="Country:", type="form_label"
    - form_input: content="Country", type="form_input", input_type="select", field_name="country", options=["USA", "Canada", "UK", "Other"], visual_cue="dropdown with arrow indicator"

    EXAMPLE 5: Email Field
    Visual: "Email: someone@example.com"
    Analysis: See @ symbol → Email input
    Output:
    - form_label: content="Email:", type="form_label"
    - form_input: content="Email", type="form_input", input_type="email", field_name="email", field_value="someone@example.com", visual_cue="@ symbol indicates email"

    EXAMPLE 6: Date Field (Government Form Style)
    Visual: "Your date of leaving the UK DD MM YYYY [__] [__] [____]"
    Analysis: See sequential boxes with date format → Date input
    Output:
    - form_label: content="Your date of leaving the UK", type="form_label"
    - form_input: content="Date of leaving UK", type="form_input", input_type="date", field_name="leaving_date", visual_cue="sequential date boxes DD MM YYYY format"

    EXAMPLE 7: Yes/No Radio Group (CORRECT Government Form Pattern)
    Visual: "16 Do you intend to live outside the UK permanently?" followed by separate "No" section and "Yes" section
    Analysis: This is ONE question with two radio button options in separate visual sections
    Output:
    - form_label: content="16 Do you intend to live outside the UK permanently?", type="form_label"
    - form_input: content="No", type="form_input", input_type="radio", field_name="live_outside_uk_permanently", field_value="no", visual_cue="No option section"
    - form_input: content="Yes", type="form_input", input_type="radio", field_name="live_outside_uk_permanently", field_value="yes", visual_cue="Yes option section"

    EXAMPLE 9: CORRECT Government Form Question
    Visual: "16 Do you intend to live outside the UK permanently?" (this is just text, no input area)
    Analysis: This is a question label with no fillable area - LABEL ONLY
    CORRECT Output:
    - form_label: content="16 Do you intend to live outside the UK permanently?", type="form_label"
    (No form_input because there's no fillable area for the question text itself)

    EXAMPLE 10: WRONG Way - Creating Inputs for Labels (DO NOT DO THIS):
    Visual: Same question text as above
    WRONG Output:
    - form_label: content="16 Do you intend to live outside the UK permanently?", type="form_label"
    - form_input: content="Do you intend to live outside the UK permanently?", type="form_input", input_type="text"
    ❌ WRONG! Question text is descriptive, not fillable - don't create inputs for it!

    EXAMPLE 8: Multi-line Address Field
    Visual: "Please tell us your full address in that country [large multi-line box with 'Postcode' at bottom]"
    Analysis: Large text area with multiple lines → Textarea
    Output:
    - form_label: content="Please tell us your full address in that country", type="form_label"
    - form_input: content="Full address", type="form_input", input_type="textarea", field_name="overseas_address", visual_cue="large multi-line address box"

    🚨 ABSOLUTE REQUIREMENTS:
    1. Every visual element that can be filled = form_input with correct input_type
    2. Visual shapes determine input_type (□=checkbox, ○=radio, ▼=select)
    3. Always include "visual_cue" in metadata to document what you saw
    4. Group radio buttons with same field_name but different field_values
    5. For selects, provide realistic options based on context
    6. Labels are separate from inputs (except checkboxes where text is content)

    🚨 CRITICAL: LABEL vs INPUT DISTINCTION

    DECISION TREE - For EVERY piece of text, ask:
    1. "Can a user FILL IN, TYPE IN, or SELECT this area?"
       → YES = form_input
       → NO = form_label (if it's descriptive text)

    2. "Is this text describing what to enter?"
       → YES = form_label only
       → NO = Check if it's fillable

    EXAMPLES OF LABELS ONLY (no inputs):
    ✓ Question numbers and text: "16 Do you intend..."
    ✓ Instructions: "Please complete..."
    ✓ Headings: "About you", "Personal details"
    ✓ Descriptive text: "For example British, Polish, French"

    EXAMPLES OF INPUTS ONLY:
    ✓ Empty boxes: □ (checkbox)
    ✓ Underlines: _____ (text input)
    ✓ Large empty areas (textarea)

    NEVER CREATE BOTH: Don't create a label AND a text input for the same text!

    🎯 SUCCESS CRITERIA FOR GOVERNMENT/OFFICIAL FORMS:
    ✓ Every checkbox symbol → input_type="checkbox"
    ✓ Every radio circle → input_type="radio"
    ✓ Every dropdown arrow → input_type="select"
    ✓ Every date pattern → input_type="date"
    ✓ Every large box → input_type="textarea"
    ✓ Every @ symbol → input_type="email"
    ✓ Every phone pattern → input_type="tel"
    ✓ Yes/No pairs → input_type="radio" with same field_name
    ✓ DD/MM/YYYY or similar → input_type="date"
    ✓ Address boxes → input_type="textarea"
    ✓ Question numbers + boxes → appropriate input type based on visual cue
    ✓ Multiple sequential boxes → likely date field
    ✓ Single line boxes → input_type="text"

    🚨 FINAL VALIDATION CHECKLIST:
    Before submitting your JSON, ask yourself:
    1. Did I create a form_input for every FILLABLE area I see?
    2. Did I create a form_label for every QUESTION or INSTRUCTION text?
    3. Did I avoid creating BOTH a label AND an input for the same descriptive text?
    4. Are Yes/No options grouped as radio buttons with the same field_name?
    5. Did I use the correct input_type based on VISUAL cues?

    ❌ COMMON MISTAKES TO AVOID:
    - Creating "8 Your nationality" as both form_label AND form_input
    - Making separate questions for "Yes" and "No" options
    - Using input_type="text" for checkboxes or radio buttons
    - Creating inputs for descriptive/instructional text

    Return ONLY valid JSON. FOCUS ON VISUAL RECOGNITION FIRST!
    """

    custom_instructions = Map.get(options, :custom_instructions, "")
    if custom_instructions != "", do: base_prompt <> "\n\nAdditional instructions: " <> custom_instructions, else: base_prompt
  end

  defp parse_response(response) do
    # Extract content from OpenRouter chat completions response
    content = get_in(response, ["choices", Access.at(0), "message", "content"])
    
    if content do
      # Strip markdown code block formatting if present
      json_content = content
        |> String.trim()
        |> String.replace(~r/^```json\s*/, "")
        |> String.replace(~r/\s*```$/, "")
        |> String.trim()

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
end
