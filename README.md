# Paperform2Web

A Phoenix backend application that converts scanned paper documents to HTML web pages using OLLAMA AI models.

## Features

- Document upload and processing via OLLAMA AI
- Configurable AI models
- Multiple authentication methods for OLLAMA
- Standardized JSON response format
- HTML generation with multiple themes
- RESTful API endpoints
- Real-time processing status tracking

## Authentication Configuration

The application supports multiple authentication methods for OLLAMA:

### Development Configuration

Edit `config/dev.exs`:

```elixir
# No authentication (default)
config :paperform2web, :ollama_auth, %{
  type: :none
}

# API Key authentication
config :paperform2web, :ollama_auth, %{
  type: :api_key,
  api_key: "your-api-key",
  custom_header: "X-API-Key"  # Optional, defaults to "X-API-Key"
}

# Bearer Token authentication
config :paperform2web, :ollama_auth, %{
  type: :bearer,
  token: "your-bearer-token"
}

# Basic Authentication
config :paperform2web, :ollama_auth, %{
  type: :basic,
  username: "your-username",
  password: "your-password"
}
```

### Production Configuration

Use environment variables for security:

```bash
export OLLAMA_URL="https://your-ollama-server.com"
export OLLAMA_AUTH_TYPE="api_key"  # Options: none, api_key, bearer, basic
export OLLAMA_API_KEY="your-api-key"
export OLLAMA_BEARER_TOKEN="your-token"
export OLLAMA_USERNAME="your-username" 
export OLLAMA_PASSWORD="your-password"
export OLLAMA_CUSTOM_HEADER="X-Custom-Auth"
export UPLOAD_DIRECTORY="/app/uploads/"
```

## API Endpoints

### Document Management
- `POST /api/upload` - Upload and process document
- `GET /api/documents` - List all documents
- `GET /api/documents/:id` - Get document details
- `GET /api/documents/:id/status` - Get processing status
- `GET /api/documents/:id/html` - Get generated HTML

### Authentication & Health
- `GET /api/auth/status` - Check authentication configuration
- `GET /api/auth/test` - Test OLLAMA connection
- `GET /api/models` - List available AI models

## Usage Examples

### Upload Document
```bash
curl -X POST http://localhost:4000/api/upload \
  -F "file=@document.jpg" \
  -F "model=llama2"
```

### Test Authentication
```bash
curl http://localhost:4000/api/auth/test
```

### Check Processing Status
```bash
curl http://localhost:4000/api/documents/123e4567-e89b-12d3-a456-426614174000/status
```

## Setup

1. Install dependencies:
```bash
mix deps.get
```

2. Create database:
```bash
mix ecto.create
mix ecto.migrate
```

3. Configure OLLAMA authentication in `config/dev.exs`

4. Start the server:
```bash
mix phx.server
```

## JSON Response Format

The AI processes documents into this standardized format:

```json
{
  "document_type": "form|invoice|letter|report|other",
  "title": "Document title if available",
  "content": {
    "sections": [
      {
        "type": "header|paragraph|list|table|form_field",
        "content": "extracted text content",
        "formatting": {
          "bold": true,
          "italic": false,
          "font_size": "medium",
          "alignment": "left"
        },
        "position": {
          "x": 100,
          "y": 200,
          "width": 300,
          "height": 50
        }
      }
    ]
  },
  "metadata": {
    "language": "en",
    "confidence": 0.95,
    "processing_notes": "Document processing completed successfully"
  }
}
```

## HTML Themes

Available themes for HTML generation:
- `default` - Professional styling with headers and sections
- `minimal` - Clean, simple typography
- `dark` - Dark mode with blue accents

## Security

- Credentials are stored in environment variables for production
- Authentication validation before API calls
- Proper error handling for auth failures
- File upload validation and secure storage