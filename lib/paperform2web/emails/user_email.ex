defmodule Paperform2web.Emails.UserEmail do
  import Swoosh.Email

  def confirmation_email(user, confirmation_url) do
    new()
    |> to({user.name, user.email})
    |> from({"Paperform2Web", "noreply@paperform2web.com"})
    |> subject("Confirm your email address")
    |> html_body(build_html_content(user, confirmation_url))
    |> text_body(build_text_content(user, confirmation_url))
  end

  defp build_html_content(user, confirmation_url) do
    """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Confirm Your Email</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background-color: #f9fafb; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2rem; text-align: center; }
            .content { padding: 2rem; }
            .button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: 600; margin: 1rem 0; }
            .footer { background-color: #f3f4f6; padding: 1rem 2rem; text-align: center; color: #6b7280; font-size: 0.875rem; }
            .info { background-color: #dbeafe; border: 1px solid #3b82f6; border-radius: 6px; padding: 1rem; margin: 1rem 0; color: #1e3a8a; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Welcome to Paperform2Web!</h1>
                <p>Please confirm your email address</p>
            </div>

            <div class="content">
                <p>Hello #{user.name},</p>

                <p>Thank you for signing up for Paperform2Web! We're excited to have you on board.</p>

                <p>To complete your registration and start transforming PDF forms into interactive web forms, please confirm your email address by clicking the button below:</p>

                <p style="text-align: center;">
                    <a href="#{confirmation_url}" class="button">✅ Confirm Email Address</a>
                </p>

                <div class="info">
                    ℹ️ This confirmation link will remain valid until you confirm your email. For security reasons, please confirm your email as soon as possible.
                </div>

                <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
                <p style="word-break: break-all; color: #6b7280; font-size: 0.875rem;">#{confirmation_url}</p>

                <p>Once confirmed, you'll be able to:</p>
                <ul>
                    <li>Upload PDF forms and extract fields automatically</li>
                    <li>Customize forms with our visual editor</li>
                    <li>Choose from 8 beautiful themes</li>
                    <li>Export ready-to-use web forms</li>
                </ul>
            </div>

            <div class="footer">
                <p>If you didn't create an account with Paperform2Web, please ignore this email.</p>
                <p>&copy; #{DateTime.utc_now().year} Paperform2Web. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """
  end

  defp build_text_content(user, confirmation_url) do
    """
    Welcome to Paperform2Web!

    Hello #{user.name},

    Thank you for signing up for Paperform2Web! We're excited to have you on board.

    To complete your registration and start transforming PDF forms into interactive web forms, please confirm your email address by clicking the link below:

    #{confirmation_url}

    This confirmation link will remain valid until you confirm your email. For security reasons, please confirm your email as soon as possible.

    Once confirmed, you'll be able to:
    - Upload PDF forms and extract fields automatically
    - Customize forms with our visual editor
    - Choose from 8 beautiful themes
    - Export ready-to-use web forms

    ---

    If you didn't create an account with Paperform2Web, please ignore this email.

    © #{DateTime.utc_now().year} Paperform2Web. All rights reserved.
    """
  end
end
