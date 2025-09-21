defmodule Paperform2web.Emails.ShareEmail do
  import Swoosh.Email

  def form_invitation(share, document) do
    share_url = "#{get_base_url()}/api/share/#{share.share_token}"

    new()
    |> to({share.recipient_name || share.recipient_email, share.recipient_email})
    |> from({"Paperform2Web", "noreply@paperform2web.com"})
    |> subject(share.subject || "You've been invited to fill out a form")
    |> html_body(build_html_content(share, document, share_url))
    |> text_body(build_text_content(share, document, share_url))
  end

  defp build_html_content(share, document, share_url) do
    expiry_text = if share.expires_at do
      "This link will expire on #{format_datetime(share.expires_at)}."
    else
      ""
    end

    """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Form Invitation</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background-color: #f9fafb; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2rem; text-align: center; }
            .content { padding: 2rem; }
            .button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: 600; margin: 1rem 0; }
            .footer { background-color: #f3f4f6; padding: 1rem 2rem; text-align: center; color: #6b7280; font-size: 0.875rem; }
            .expiry { background-color: #fef3c7; border: 1px solid #f59e0b; border-radius: 6px; padding: 1rem; margin: 1rem 0; color: #92400e; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📋 Form Invitation</h1>
                <p>You've been invited to fill out a form</p>
            </div>

            <div class="content">
                <p>Hello#{if share.recipient_name, do: " #{share.recipient_name}", else: ""},</p>

                #{if share.message && share.message != "", do: "<p>#{String.replace(share.message, "\n", "<br>")}</p>", else: ""}

                <p>You have been invited to fill out the form: <strong>#{document.filename}</strong></p>

                <p>Click the button below to access the form:</p>

                <p style="text-align: center;">
                    <a href="#{share_url}" class="button">📝 Fill Out Form</a>
                </p>

                #{if expiry_text != "", do: "<div class=\"expiry\">⏰ #{expiry_text}</div>", else: ""}

                <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
                <p style="word-break: break-all; color: #6b7280; font-size: 0.875rem;">#{share_url}</p>
            </div>

            <div class="footer">
                <p>This email was sent by Paperform2Web. If you believe you received this email in error, please ignore it.</p>
            </div>
        </div>
    </body>
    </html>
    """
  end

  defp build_text_content(share, document, share_url) do
    expiry_text = if share.expires_at do
      "This link will expire on #{format_datetime(share.expires_at)}."
    else
      ""
    end

    """
    Form Invitation

    Hello#{if share.recipient_name, do: " #{share.recipient_name}", else: ""},

    #{share.message || "You have been invited to fill out a form."}

    Form: #{document.filename}

    Please click the link below to access the form:
    #{share_url}

    #{expiry_text}

    ---
    This email was sent by Paperform2Web. If you believe you received this email in error, please ignore it.
    """
  end

  defp format_datetime(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end

  defp get_base_url do
    Application.get_env(:paperform2web, :base_url, "http://localhost:4000")
  end
end