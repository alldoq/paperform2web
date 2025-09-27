defmodule Paperform2web.HtmlGenerator.Javascript do
  @moduledoc """
  JavaScript generation for HTML documents.
  Provides both standard (preview mode) and editing mode JavaScript functionality.
  """

  @doc """
  Generates JavaScript content based on editing mode.
  """
  def generate_javascript(editing_mode \\ false, document_id \\ nil) do
    if editing_mode && document_id do
      generate_editing_javascript(document_id)
    else
      generate_standard_javascript(document_id)
    end
  end

  @doc """
  Generates standard JavaScript for preview mode.
  """
  def generate_standard_javascript(document_id \\ nil) do
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
            const modalHtml = \`
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
            \`;

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

                    /* Option editing styles */
                    .edit-options-btn {
                        width: 20px;
                        height: 20px;
                        border-radius: 4px;
                        border: 1px solid #d1d5db;
                        cursor: pointer;
                        display: inline-flex;
                        align-items: center;
                        justify-content: center;
                        font-size: 11px;
                        font-weight: 500;
                        transition: all 0.2s ease;
                        background: white;
                        color: #6b7280;
                        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                        margin-left: 8px;
                    }
                    .edit-options-btn:hover {
                        border-color: #9ca3af;
                        color: #374151;
                        transform: translateY(-1px);
                        box-shadow: 0 2px 6px rgba(0,0,0,0.15);
                    }
                    .field-type-btn.selected {
                        border-color: #3b82f6;
                        background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
                        color: #1e40af;
                        box-shadow: 0 4px 14px rgba(59, 130, 246, 0.25);
                        transform: translateY(-1px);
                    }
                    .field-type-btn.selected::after {
                        content: '✓';
                        position: absolute;
                        top: 8px;
                        right: 12px;
                        color: #3b82f6;
                        font-weight: bold;
                        font-size: 1.2rem;
                    }
                    .field-options-section {
                        margin-top: 2rem !important;
                        padding-top: 2rem !important;
                        border-top: 2px solid #e5e7eb !important;
                        background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%) !important;
                        margin: 1.5rem -1.5rem -1.5rem -1.5rem !important;
                        padding: 2rem 1.5rem 1.5rem 1.5rem !important;
                        border-radius: 0 0 12px 12px !important;
                        box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.05) !important;
                    }
                    .field-options-section h4 {
                        margin: 0 0 1.5rem 0;
                        color: #1f2937;
                        font-size: 1.3rem;
                        font-weight: 700;
                        letter-spacing: -0.025em;
                        display: flex;
                        align-items: center;
                        gap: 0.5rem;
                    }
                    .field-options-section h4::before {
                        content: '⚙️';
                        font-size: 1.2rem;
                    }
                    .field-label-section {
                        margin-bottom: 1.5rem;
                    }
                    .field-label-section label {
                        display: block;
                        margin-bottom: 0.75rem;
                        font-weight: 600;
                        color: #374151;
                        font-size: 0.95rem;
                        text-transform: uppercase;
                        letter-spacing: 0.025em;
                        position: relative;
                    }
                    .field-label-section label::after {
                        content: '*';
                        color: #ef4444;
                        margin-left: 4px;
                        font-weight: bold;
                    }
                    .field-label-section input {
                        width: 100% !important;
                        padding: 1.25rem !important;
                        border: 2px solid #e5e7eb !important;
                        border-radius: 12px !important;
                        font-size: 1rem !important;
                        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
                        background: white !important;
                        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05) !important;
                        font-weight: 500 !important;
                    }
                    .field-label-section input:focus {
                        outline: none;
                        border-color: #3b82f6;
                        box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.15), 0 4px 12px rgba(0, 0, 0, 0.1);
                        background: #fefefe;
                        transform: translateY(-1px);
                    }
                    .field-label-section input::placeholder {
                        color: #9ca3af;
                        font-weight: 400;
                    }
                    .options-list {
                        margin-bottom: 2rem;
                    }
                    .options-list label {
                        display: block;
                        margin-bottom: 0.75rem;
                        font-weight: 600;
                        color: #374151;
                        font-size: 0.95rem;
                        text-transform: uppercase;
                        letter-spacing: 0.025em;
                        position: relative;
                    }
                    .options-list label::after {
                        content: ' (one per line)';
                        text-transform: none;
                        color: #6b7280;
                        font-weight: 400;
                        font-size: 0.875rem;
                    }
                    .options-list textarea {
                        width: 100% !important;
                        padding: 1.25rem !important;
                        border: 2px solid #e5e7eb !important;
                        border-radius: 12px !important;
                        font-size: 1rem !important;
                        resize: vertical !important;
                        min-height: 160px !important;
                        line-height: 1.7 !important;
                        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
                        background: white !important;
                        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05) !important;
                        font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace !important;
                        font-weight: 500 !important;
                    }
                    .options-list textarea:focus {
                        outline: none;
                        border-color: #3b82f6;
                        box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.15), 0 4px 12px rgba(0, 0, 0, 0.1);
                        background: #fefefe;
                        transform: translateY(-1px);
                    }
                    .options-list textarea::placeholder {
                        color: #9ca3af;
                        font-style: italic;
                        font-weight: 400;
                        line-height: 1.8;
                    }
                    .modal-actions {
                        display: flex;
                        gap: 1rem;
                        justify-content: flex-end;
                        padding-top: 1rem;
                        border-top: 1px solid #e5e7eb;
                        margin-top: 1rem;
                    }
                    .modal-actions .btn {
                        padding: 1rem 2.5rem;
                        font-weight: 600;
                        font-size: 1rem;
                        border-radius: 12px;
                        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                        min-width: 140px;
                        justify-content: center;
                        border: none;
                        cursor: pointer;
                        display: inline-flex;
                        align-items: center;
                        gap: 0.5rem;
                        letter-spacing: 0.025em;
                    }
                    .modal-actions .btn-primary {
                        background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
                        color: white;
                        box-shadow: 0 4px 14px rgba(59, 130, 246, 0.25);
                        position: relative;
                        overflow: hidden;
                    }
                    .modal-actions .btn-primary::before {
                        content: '';
                        position: absolute;
                        top: 0;
                        left: -100%;
                        width: 100%;
                        height: 100%;
                        background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
                        transition: left 0.5s;
                    }
                    .modal-actions .btn-primary:hover::before {
                        left: 100%;
                    }
                    .modal-actions .btn-primary:hover {
                        background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
                        transform: translateY(-2px);
                        box-shadow: 0 8px 25px rgba(59, 130, 246, 0.4);
                    }
                    .modal-actions .btn-secondary {
                        background: white;
                        color: #6b7280;
                        border: 2px solid #e5e7eb;
                        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
                    }
                    .modal-actions .btn-secondary:hover {
                        background: #f9fafb;
                        border-color: #d1d5db;
                        color: #374151;
                        transform: translateY(-1px);
                        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
                    }

                    /* Specific styling for Add Field modal - Higher specificity */
                    #add-field-modal .field-options-section {
                        margin-top: 2rem !important;
                        padding-top: 2rem !important;
                        border-top: 2px solid #e5e7eb !important;
                        background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%) !important;
                        margin: 1.5rem -1.5rem -1.5rem -1.5rem !important;
                        padding: 2rem 1.5rem 1.5rem 1.5rem !important;
                        border-radius: 0 0 12px 12px !important;
                        box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.05) !important;
                    }

                    #add-field-modal .field-options-section h4 {
                        margin: 0 0 1.5rem 0 !important;
                        color: #1f2937 !important;
                        font-size: 1.3rem !important;
                        font-weight: 700 !important;
                        letter-spacing: -0.025em !important;
                        display: flex !important;
                        align-items: center !important;
                        gap: 0.5rem !important;
                    }

                    #add-field-modal .field-options-section h4::before {
                        content: '⚙️' !important;
                        font-size: 1.2rem !important;
                    }

                    #add-field-modal .field-label-section label {
                        display: block !important;
                        margin-bottom: 0.75rem !important;
                        font-weight: 600 !important;
                        color: #374151 !important;
                        font-size: 0.95rem !important;
                        text-transform: uppercase !important;
                        letter-spacing: 0.025em !important;
                        position: relative !important;
                    }

                    #add-field-modal .field-label-section label::after {
                        content: '*' !important;
                        color: #ef4444 !important;
                        margin-left: 4px !important;
                        font-weight: bold !important;
                    }

                    #add-field-modal .field-label-section input,
                    #field-label-input {
                        width: 100% !important;
                        padding: 1.25rem !important;
                        border: 2px solid #e5e7eb !important;
                        border-radius: 12px !important;
                        font-size: 1rem !important;
                        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
                        background: white !important;
                        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05) !important;
                        font-weight: 500 !important;
                        margin: 0 !important;
                        box-sizing: border-box !important;
                    }

                    #add-field-modal .field-label-section input:focus,
                    #field-label-input:focus {
                        outline: none !important;
                        border-color: #3b82f6 !important;
                        box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.15), 0 4px 12px rgba(0, 0, 0, 0.1) !important;
                        background: #fefefe !important;
                        transform: translateY(-1px) !important;
                    }

                    #add-field-modal .options-list label {
                        display: block !important;
                        margin-bottom: 0.75rem !important;
                        font-weight: 600 !important;
                        color: #374151 !important;
                        font-size: 0.95rem !important;
                        text-transform: uppercase !important;
                        letter-spacing: 0.025em !important;
                        position: relative !important;
                    }

                    #add-field-modal .options-list label::after {
                        content: ' (one per line)' !important;
                        text-transform: none !important;
                        color: #6b7280 !important;
                        font-weight: 400 !important;
                        font-size: 0.875rem !important;
                    }

                    #add-field-modal .options-list textarea,
                    #options-textarea {
                        width: 100% !important;
                        padding: 1.25rem !important;
                        border: 2px solid #e5e7eb !important;
                        border-radius: 12px !important;
                        font-size: 1rem !important;
                        resize: vertical !important;
                        min-height: 160px !important;
                        line-height: 1.7 !important;
                        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
                        background: white !important;
                        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05) !important;
                        font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace !important;
                        font-weight: 500 !important;
                        margin: 0 !important;
                        box-sizing: border-box !important;
                    }

                    #add-field-modal .options-list textarea:focus,
                    #options-textarea:focus {
                        outline: none !important;
                        border-color: #3b82f6 !important;
                        box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.15), 0 4px 12px rgba(0, 0, 0, 0.1) !important;
                        background: #fefefe !important;
                        transform: translateY(-1px) !important;
                    }

                    #add-field-modal .modal-actions {
                        display: flex !important;
                        gap: 1rem !important;
                        justify-content: flex-end !important;
                        padding-top: 1rem !important;
                        border-top: 1px solid #e5e7eb !important;
                        margin-top: 1rem !important;
                    }

                    #add-field-modal .modal-actions .btn {
                        padding: 1rem 2.5rem !important;
                        font-weight: 600 !important;
                        font-size: 1rem !important;
                        border-radius: 12px !important;
                        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
                        min-width: 140px !important;
                        justify-content: center !important;
                        border: none !important;
                        cursor: pointer !important;
                        display: inline-flex !important;
                        align-items: center !important;
                        gap: 0.5rem !important;
                        letter-spacing: 0.025em !important;
                        text-decoration: none !important;
                    }

                    #add-field-modal .modal-actions .btn-primary {
                        background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%) !important;
                        color: white !important;
                        box-shadow: 0 4px 14px rgba(59, 130, 246, 0.25) !important;
                        position: relative !important;
                        overflow: hidden !important;
                    }

                    #add-field-modal .modal-actions .btn-primary:hover {
                        background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%) !important;
                        transform: translateY(-2px) !important;
                        box-shadow: 0 8px 25px rgba(59, 130, 246, 0.4) !important;
                    }

                    #add-field-modal .modal-actions .btn-secondary {
                        background: white !important;
                        color: #6b7280 !important;
                        border: 2px solid #e5e7eb !important;
                        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05) !important;
                    }

                    #add-field-modal .modal-actions .btn-secondary:hover {
                        background: #f9fafb !important;
                        border-color: #d1d5db !important;
                        color: #374151 !important;
                        transform: translateY(-1px) !important;
                        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1) !important;
                    }
                </style>
            \`;
            document.head.insertAdjacentHTML('beforeend', styles);
            console.log('Modal styles added successfully!');
            console.log('Styles element:', document.getElementById('modal-styles'));
            console.log('Total style elements in head:', document.head.querySelectorAll('style').length);
        }

        function applyBasicModalStyling() {
            console.log('Applying basic modal styling as fallback...');

            const modal = document.getElementById('add-field-modal');
            const modalContent = modal?.querySelector('.modal');
            const modalHeader = modal?.querySelector('.modal-header');
            const modalBody = modal?.querySelector('.modal-body');

            if (modal) {
                // Essential modal overlay styles
                Object.assign(modal.style, {
                    position: 'fixed',
                    top: '0',
                    left: '0',
                    width: '100%',
                    height: '100%',
                    backgroundColor: 'rgba(0, 0, 0, 0.5)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    zIndex: '1000'
                });
            }

            if (modalContent) {
                // Essential modal content styles
                Object.assign(modalContent.style, {
                    background: 'white',
                    borderRadius: '12px',
                    boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
                    width: '90%',
                    maxWidth: '600px',
                    maxHeight: '90vh',
                    overflowY: 'auto'
                });
            }

            if (modalHeader) {
                Object.assign(modalHeader.style, {
                    padding: '1.5rem',
                    borderBottom: '1px solid #e5e7eb'
                });
            }

            if (modalBody) {
                Object.assign(modalBody.style, {
                    padding: '1.5rem'
                });
            }

            console.log('Basic modal styling applied');
        }

        function applyModalStylesDirectly() {
            console.log('Applying modal styles directly to elements...');

            const modal = document.getElementById('add-field-modal');
            const modalContent = modal?.querySelector('.modal');
            const modalHeader = modal?.querySelector('.modal-header');
            const modalBody = modal?.querySelector('.modal-body');
            const modalFieldTypeBtns = modal?.querySelectorAll('.field-type-btn');

            if (modal) {
                // Modal overlay styles
                Object.assign(modal.style, {
                    position: 'fixed',
                    top: '0',
                    left: '0',
                    width: '100%',
                    height: '100%',
                    backgroundColor: 'rgba(0, 0, 0, 0.5)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    zIndex: '1000'
                });
            }

            if (modalContent) {
                // Modal content styles
                Object.assign(modalContent.style, {
                    background: 'white',
                    borderRadius: '12px',
                    boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
                    width: '90%',
                    maxWidth: '600px',
                    maxHeight: '90vh',
                    overflowY: 'auto'
                });
            }

            if (modalHeader) {
                // Modal header styles
                Object.assign(modalHeader.style, {
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '1.5rem',
                    borderBottom: '1px solid #e5e7eb'
                });

                const h3 = modalHeader.querySelector('h3');
                if (h3) {
                    Object.assign(h3.style, {
                        margin: '0',
                        fontSize: '1.25rem',
                        fontWeight: '600',
                        color: '#111827'
                    });
                }

                const closeBtn = modalHeader.querySelector('.close-btn');
                if (closeBtn) {
                    Object.assign(closeBtn.style, {
                        background: 'none',
                        border: 'none',
                        fontSize: '1.5rem',
                        cursor: 'pointer',
                        color: '#6b7280',
                        padding: '0.25rem',
                        borderRadius: '0.375rem'
                    });
                }
            }

            if (modalBody) {
                // Modal body styles
                Object.assign(modalBody.style, {
                    padding: '1.5rem'
                });

                const fieldTypes = modalBody.querySelector('.field-types');
                if (fieldTypes) {
                    Object.assign(fieldTypes.style, {
                        display: 'grid',
                        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                        gap: '1rem'
                    });
                }
            }

            // Style field type buttons
            if (modalFieldTypeBtns) {
                modalFieldTypeBtns.forEach(btn => {
                    Object.assign(btn.style, {
                        display: 'flex',
                        alignItems: 'center',
                        padding: '1.25rem',
                        border: '2px solid #e5e7eb',
                        background: 'white',
                        borderRadius: '12px',
                        cursor: 'pointer',
                        transition: 'all 0.2s ease',
                        fontSize: '1rem',
                        textAlign: 'left',
                        fontWeight: '500',
                        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
                        position: 'relative',
                        justifyContent: 'flex-start',
                        gap: '0.75rem'
                    });

                    // Add hover effects
                    btn.addEventListener('mouseenter', function() {
                        this.style.borderColor = '#3b82f6';
                        this.style.backgroundColor = '#eff6ff';
                        this.style.transform = 'translateY(-1px)';
                        this.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.15)';
                    });

                    btn.addEventListener('mouseleave', function() {
                        if (!this.classList.contains('selected')) {
                            this.style.borderColor = '#e5e7eb';
                            this.style.backgroundColor = 'white';
                            this.style.transform = 'translateY(0)';
                            this.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
                        }
                    });
                });
            }

            console.log('Direct modal styles applied successfully');
        }

        function applyOptionsSeccionStyling(optionsSection, fieldLabelInput, optionsTextarea) {
            console.log('Applying options section styling...');

            // Options section styling
            Object.assign(optionsSection.style, {
                marginTop: '2rem',
                paddingTop: '2rem',
                borderTop: '2px solid #e5e7eb',
                background: 'linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%)',
                margin: '1.5rem -1.5rem -1.5rem -1.5rem',
                padding: '2rem 1.5rem 1.5rem 1.5rem',
                borderRadius: '0 0 12px 12px',
                boxShadow: 'inset 0 1px 3px rgba(0, 0, 0, 0.05)'
            });

            // Header styling
            const h4 = optionsSection.querySelector('h4');
            if (h4) {
                Object.assign(h4.style, {
                    margin: '0 0 1.5rem 0',
                    color: '#1f2937',
                    fontSize: '1.3rem',
                    fontWeight: '700',
                    letterSpacing: '-0.025em',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem'
                });
            }

            // Field label section styling
            const fieldLabelSection = optionsSection.querySelector('.field-label-section');
            if (fieldLabelSection) {
                Object.assign(fieldLabelSection.style, {
                    marginBottom: '1.5rem'
                });

                const label = fieldLabelSection.querySelector('label');
                if (label) {
                    Object.assign(label.style, {
                        display: 'block',
                        marginBottom: '0.75rem',
                        fontWeight: '600',
                        color: '#374151',
                        fontSize: '0.95rem',
                        textTransform: 'uppercase',
                        letterSpacing: '0.025em'
                    });
                }
            }

            // Field label input styling
            if (fieldLabelInput) {
                Object.assign(fieldLabelInput.style, {
                    width: '100%',
                    padding: '1.25rem',
                    border: '2px solid #e5e7eb',
                    borderRadius: '12px',
                    fontSize: '1rem',
                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    background: 'white',
                    boxShadow: '0 2px 4px rgba(0, 0, 0, 0.05)',
                    fontWeight: '500',
                    margin: '0',
                    boxSizing: 'border-box'
                });
            }

            // Options list styling
            const optionsList = optionsSection.querySelector('.options-list');
            if (optionsList) {
                Object.assign(optionsList.style, {
                    marginBottom: '2rem'
                });

                const label = optionsList.querySelector('label');
                if (label) {
                    Object.assign(label.style, {
                        display: 'block',
                        marginBottom: '0.75rem',
                        fontWeight: '600',
                        color: '#374151',
                        fontSize: '0.95rem',
                        textTransform: 'uppercase',
                        letterSpacing: '0.025em'
                    });
                }
            }

            // Options textarea styling
            if (optionsTextarea) {
                Object.assign(optionsTextarea.style, {
                    width: '100%',
                    padding: '1.25rem',
                    border: '2px solid #e5e7eb',
                    borderRadius: '12px',
                    fontSize: '1rem',
                    resize: 'vertical',
                    minHeight: '160px',
                    lineHeight: '1.7',
                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    background: 'white',
                    boxShadow: '0 2px 4px rgba(0, 0, 0, 0.05)',
                    fontFamily: "'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace",
                    fontWeight: '500',
                    margin: '0',
                    boxSizing: 'border-box'
                });
            }

            // Modal actions styling
            const modalActions = optionsSection.querySelector('.modal-actions');
            if (modalActions) {
                Object.assign(modalActions.style, {
                    display: 'flex',
                    gap: '1rem',
                    justifyContent: 'flex-end',
                    paddingTop: '1rem',
                    borderTop: '1px solid #e5e7eb',
                    marginTop: '1rem'
                });

                // Style buttons
                const buttons = modalActions.querySelectorAll('.btn');
                buttons.forEach(btn => {
                    Object.assign(btn.style, {
                        padding: '1rem 2.5rem',
                        fontWeight: '600',
                        fontSize: '1rem',
                        borderRadius: '12px',
                        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                        minWidth: '140px',
                        justifyContent: 'center',
                        border: 'none',
                        cursor: 'pointer',
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        letterSpacing: '0.025em',
                        textDecoration: 'none'
                    });

                    if (btn.classList.contains('btn-primary')) {
                        Object.assign(btn.style, {
                            background: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)',
                            color: 'white',
                            boxShadow: '0 4px 14px rgba(59, 130, 246, 0.25)'
                        });
                    } else if (btn.classList.contains('btn-secondary')) {
                        Object.assign(btn.style, {
                            background: 'white',
                            color: '#6b7280',
                            border: '2px solid #e5e7eb',
                            boxShadow: '0 2px 4px rgba(0, 0, 0, 0.05)'
                        });
                    }
                });
            }

            console.log('Options section styling applied successfully');
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

  @doc """
  Generates editing JavaScript for editing mode.
  This is a large function that handles drag-and-drop editing functionality.
  """
  def generate_editing_javascript(document_id) do
    """
    <script>
        // Form editing functionality
        let isEditingMode = true;
        let draggedElement = null;
        let formData = [];

        document.addEventListener('DOMContentLoaded', function() {
            // Add editing mode class to body for specific styling
            document.body.classList.add('editing-mode');

            addModalStyles(); // Add styles immediately when DOM loads
            initializeFormEditor();
        });

        function initializeFormEditor() {
            // Initialize all editing functionality
            initializeDragAndDrop();
            initializeFieldEditing();
            initializeToolbarButtons();
            initializeThemeSelector();
            initializePreviewMode();

            // Clean up any duplicate edit options buttons from legacy fields
            cleanupDuplicateEditButtons();

            // Load existing form data - with delay to ensure DOM is ready
            setTimeout(() => {
                loadFormData();
            }, 500);

            // Auto-save changes
            setupAutoSave();
        }

        function cleanupDuplicateEditButtons() {
            // Remove any edit options buttons that are inside form fields (legacy structure)
            // Keep only the ones in field controls
            const formFieldButtons = document.querySelectorAll('.form-field .edit-options-btn');
            console.log(`🧹 Removing ${formFieldButtons.length} duplicate edit options buttons from form fields`);

            formFieldButtons.forEach(button => {
                button.remove();
            });

            // Also remove any standalone edit options buttons that might be floating
            const allEditButtons = document.querySelectorAll('.edit-options-btn');
            allEditButtons.forEach(button => {
                // Keep only buttons that are direct children of field-controls
                if (!button.closest('.field-controls')) {
                    console.log('🧹 Removing orphaned edit options button:', button);
                    button.remove();
                }
            });
        }

        // Drop indicator management
        let dropIndicators = [];
        let currentDropTarget = null;

        function createDropIndicators() {
            // Remove existing drop indicators
            removeDropIndicators();

            const container = document.querySelector('.document-content') || document.querySelector('main');
            if (!container) return;

            const wrappers = container.querySelectorAll('.editable-field-wrapper');
            console.log('🎯 Creating drop zones for', wrappers.length, 'wrappers');

            // Create drop zones between wrappers and at the beginning/end
            wrappers.forEach((wrapper, index) => {
                // Drop zone before each wrapper
                const zoneBefore = document.createElement('div');
                zoneBefore.className = 'drop-zone';
                zoneBefore.dataset.dropIndex = index.toString();
                zoneBefore.dataset.dropPosition = 'before';
                zoneBefore.innerHTML = \`
                    <div class="drop-zone-content">
                        <span class="drop-zone-icon">⬇️</span>
                        <div class="drop-zone-text">DRAG YOUR ELEMENT HERE</div>
                        <div class="drop-zone-subtext">Field will be placed before this one</div>
                    </div>
                \`;
                wrapper.parentNode.insertBefore(zoneBefore, wrapper);
                zoneBefore.style.display = 'none'; // Initially hidden
                dropIndicators.push(zoneBefore);

                // Drop zone after the last wrapper
                if (index === wrappers.length - 1) {
                    const zoneAfter = document.createElement('div');
                    zoneAfter.className = 'drop-zone';
                    zoneAfter.dataset.dropIndex = (index + 1).toString();
                    zoneAfter.dataset.dropPosition = 'after';
                    zoneAfter.innerHTML = \`
                        <div class="drop-zone-content">
                            <span class="drop-zone-icon">⬇️</span>
                            <div class="drop-zone-text">DRAG YOUR ELEMENT HERE</div>
                            <div class="drop-zone-subtext">Field will be placed at the end</div>
                        </div>
                    \`;
                    wrapper.parentNode.insertBefore(zoneAfter, wrapper.nextSibling);
                    zoneAfter.style.display = 'none'; // Initially hidden
                    dropIndicators.push(zoneAfter);
                }
            });

            // If no wrappers exist, create one at the beginning
            if (wrappers.length === 0 && container) {
                const zone = document.createElement('div');
                zone.className = 'drop-zone';
                zone.dataset.dropIndex = '0';
                zone.dataset.dropPosition = 'before';
                zone.innerHTML = \`
                    <div class="drop-zone-content">
                        <span class="drop-zone-icon">⬇️</span>
                        <div class="drop-zone-text">DRAG YOUR ELEMENT HERE</div>
                        <div class="drop-zone-subtext">Field will be placed at the beginning</div>
                    </div>
                \`;
                container.insertBefore(zone, container.firstChild);
                zone.style.display = 'none'; // Initially hidden
                dropIndicators.push(zone);
            }

            // Use compact drop lines for tight spaces or many fields
            if (wrappers.length > 8) {
                // Replace zones with compact lines for better UX with many fields
                dropIndicators.forEach(indicator => {
                    if (indicator.classList.contains('drop-zone')) {
                        indicator.className = 'drop-line';
                        indicator.innerHTML = '';
                        indicator.style.display = 'none'; // Keep hidden after transformation
                    }
                });
            }
        }

        function removeDropIndicators() {
            console.log('🧹 Hiding drop indicators...');
            console.log('Total indicators to hide:', dropIndicators.length);
            // Hide all indicators instead of removing them
            dropIndicators.forEach(indicator => {
                console.log('Hiding indicator:', indicator.className, indicator.dataset.dropIndex);
                indicator.classList.remove('active');
                indicator.style.display = 'none';
                // Reset any custom transforms
                if (indicator.classList.contains('drop-zone')) {
                    indicator.style.transform = '';
                } else if (indicator.classList.contains('drop-line')) {
                    indicator.style.transform = '';
                }
            });
            currentDropTarget = null;
        }

        function updateDropIndicator(targetIndex, position) {
            console.log('🔧 updateDropIndicator called with:', { targetIndex, position, totalIndicators: dropIndicators.length });

            // Remove active class from all indicators
            dropIndicators.forEach(indicator => {
                indicator.classList.remove('active');
            });

            // Find and activate the target indicator
            const targetIndicator = dropIndicators.find(indicator =>
                parseInt(indicator.dataset.dropIndex) === targetIndex &&
                indicator.dataset.dropPosition === position
            );

            console.log('🎯 Found target indicator:', targetIndicator);

            if (targetIndicator) {
                console.log('✅ Activating indicator:', targetIndicator.className, targetIndicator.dataset);
                targetIndicator.classList.add('active');
                currentDropTarget = { index: targetIndex, position: position };

                // Add different styling based on type
                if (targetIndicator.classList.contains('drop-zone')) {
                    targetIndicator.style.transform = 'scale(1.05) translateY(0)';
                } else if (targetIndicator.classList.contains('drop-line')) {
                    targetIndicator.style.transform = 'scale(1.02) translateY(0)';
                }
            } else {
                console.log('❌ No matching indicator found');
                currentDropTarget = null;
            }
        }

        function initializeDragAndDrop() {
            // Create drop indicators first
            createDropIndicators();

            // Debug: Log initial state
            console.log('🔧 initializeDragAndDrop called');
            console.log('🔧 Drop indicators created:', dropIndicators.length);
            console.log('🔧 Drop zones in DOM:', document.querySelectorAll('.drop-zone').length);


            // Make all form field wrappers draggable (these contain the full field structure)
            const formFieldWrappers = document.querySelectorAll('.editable-field-wrapper');
            console.log('🎯 Initializing drag and drop for', formFieldWrappers.length, 'field wrappers');

            formFieldWrappers.forEach((wrapper, index) => {
                console.log(\`🔧 Setting up drag functionality for wrapper \${index + 1}:\`, wrapper.id);
                addDragFunctionality(wrapper);
            });

            // Also handle any direct editable fields that aren't wrapped
            const directFields = document.querySelectorAll('.editable-field:not(.editable-field-wrapper .editable-field)');
            console.log('🎯 Found', directFields.length, 'direct editable fields (not wrapped)');
            directFields.forEach((field, index) => {
                console.log(\`🔧 Setting up drag functionality for direct field \${index + 1}:\`, field.id, 'type:', field.dataset.fieldType);
                addDragFunctionality(field);
            });

            // Additional debugging for radio buttons specifically
            const radioFields = document.querySelectorAll('.editable-field[data-field-type="radio"]');
            console.log('🔘 Found radio fields:', radioFields.length);
            radioFields.forEach(radio => {
                console.log('🔘 Radio field details:', radio.id, radio.className, radio.dataset.fieldType);
            });
        }

        function addDragFunctionality(field) {
            if (!field || (!field.classList.contains('editable-field') && !field.classList.contains('editable-field-wrapper'))) return;

            console.log(`🔧 Adding drag functionality to field: ${field.id}`);

            // Disable draggable on contenteditable elements to prevent conflicts
            const editableElements = field.querySelectorAll('[contenteditable]');
            editableElements.forEach(el => {
                el.draggable = false;
                el.addEventListener('dragstart', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                });
            });

            // Remove any existing drag handles first
            const existingHandles = field.querySelectorAll('.drag-handle');
            existingHandles.forEach(handle => handle.remove());

            // Add our JavaScript drag handle
            const dragHandle = document.createElement('div');
            dragHandle.className = 'drag-handle';
            dragHandle.innerHTML = \`
                    <svg width="12" height="20" viewBox="0 0 12 20" fill="none">
                        <circle cx="3" cy="4" r="1.5" fill="currentColor"/>
                        <circle cx="9" cy="4" r="1.5" fill="currentColor"/>
                        <circle cx="3" cy="10" r="1.5" fill="currentColor"/>
                        <circle cx="9" cy="10" r="1.5" fill="currentColor"/>
                        <circle cx="3" cy="16" r="1.5" fill="currentColor"/>
                        <circle cx="9" cy="16" r="1.5" fill="currentColor"/>
                    </svg>
                \`;
                dragHandle.title = 'Drag to reorder fields';
                dragHandle.draggable = false; // Handle itself not draggable
                dragHandle.style.cssText = \`
                    position: absolute;
                    top: 50%;
                    left: 5px;
                    transform: translateY(-50%);
                    cursor: grab;
                    background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                    color: white;
                    padding: 10px 8px;
                    border-radius: 6px;
                    font-size: 12px;
                    z-index: 10;
                    user-select: none;
                    box-shadow: 0 3px 12px rgba(52, 152, 219, 0.4);
                    border: 2px solid rgba(255,255,255,0.3);
                    transition: all 0.2s ease;
                    opacity: 0.7;
                \`;

                // Add hover effects
                dragHandle.addEventListener('mouseenter', function() {
                    this.style.opacity = '1';
                    this.style.transform = 'translateY(-50%) scale(1.1)';
                    this.style.boxShadow = '0 5px 20px rgba(52, 152, 219, 0.6)';
                });

                dragHandle.addEventListener('mouseleave', function() {
                    if (!field.isDragging) {
                        this.style.opacity = '0.7';
                        this.style.transform = 'translateY(-50%) scale(1)';
                        this.style.boxShadow = '0 3px 12px rgba(52, 152, 219, 0.4)';
                    }
                });
                field.appendChild(dragHandle);

                // Add field controls (edit and remove buttons)
                const fieldControls = document.createElement('div');
                fieldControls.className = 'field-controls';
                fieldControls.innerHTML = \`
                    <button type="button" class="field-control-btn remove-field-btn" onclick="removeField(this)" title="Remove field">
                        ×
                    </button>
                \`;
                field.appendChild(fieldControls);

                    // Make the drag handle trigger mouse-based drag
                    let isDragging = false;
                    let dragStartY = 0;
                    let dragPreview = null;
                    let currentHandleMouseMove = null;
                    let currentHandleMouseUp = null;

                    dragHandle.addEventListener('mousedown', function(e) {
                        console.log('🖱️ Drag handle mousedown for field:', field.id);
                        e.preventDefault();
                        e.stopPropagation();

                        isDragging = true;
                        dragStartY = e.clientY;
                        draggedElement = field; // Set the global dragged element
                        console.log('🚀 Mouse drag started for:', field.id);

                        // Visual feedback
                        field.style.opacity = '0.5';
                        dragHandle.style.cursor = 'grabbing';

                        // Show drop indicators
                        console.log('📍 Showing drop indicators...');
                        console.log('Total indicators to show:', dropIndicators.length);

                        // Debug: Check if indicators exist in DOM
                        const allDropZonesInDOM = document.querySelectorAll('.drop-zone');
                        console.log('🔍 Drop zones found in DOM:', allDropZonesInDOM.length);

                        dropIndicators.forEach((indicator, index) => {
                            console.log(\`Showing indicator \${index}:\`, indicator.className, indicator.dataset.dropIndex, indicator.dataset.dropPosition);
                            console.log('Indicator in DOM?', document.contains(indicator));
                            indicator.style.display = 'block';
                            indicator.style.visibility = 'visible';
                            console.log('Indicator display set to:', indicator.style.display);
                        });

                        // Add dragging state to body
                        document.body.classList.add('dragging-active');

                        // Create drag preview
                        dragPreview = field.cloneNode(true);
                        dragPreview.style.cssText = \`
                            position: fixed;
                            pointer-events: none;
                            z-index: 1000;
                            opacity: 0.8;
                            transform: rotate(2deg) scale(0.9);
                            background: white;
                            border: 2px solid #3498db;
                            border-radius: 8px;
                            box-shadow: 0 8px 25px rgba(0,0,0,0.3);
                            width: \${field.offsetWidth}px;
                            max-width: 400px;
                        \`;
                        dragPreview.style.left = e.clientX + 10 + 'px';
                        dragPreview.style.top = e.clientY + 10 + 'px';
                        document.body.appendChild(dragPreview);

                        // Disable hover effects during drag to prevent double borders
                        document.body.classList.add('dragging-active');

                        // Add visual indicators to all fields (use existing wrapper borders)
                        document.querySelectorAll('.editable-field').forEach(f => {
                            if (f !== field) {
                                // Find the wrapper and activate its border
                                const wrapper = f.closest('.editable-field-wrapper');
                                if (wrapper) {
                                    wrapper.style.borderStyle = 'dashed';
                                    wrapper.style.borderColor = '#3498db';
                                    wrapper.style.borderWidth = '2px';
                                    wrapper.style.background = 'rgba(52, 152, 219, 0.08)';
                                    wrapper.style.borderRadius = '8px';
                                    wrapper.style.transition = 'all 0.2s ease';
                                }

                                const dropZone = document.createElement('div');
                                dropZone.className = 'drop-zone-indicator';
                                dropZone.innerHTML = \`
                                    <div style="display: flex; align-items: center; gap: 8px;">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" style="color: white;">
                                            <path d="M7 13l3 3 7-7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                                        </svg>
                                        <span>Drop to reorder</span>
                                    </div>
                                \`;
                                dropZone.style.cssText = \`
                                    position: absolute;
                                    top: 50%;
                                    left: 50%;
                                    transform: translate(-50%, -50%);
                                    background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                                    color: white;
                                    padding: 12px 16px;
                                    border-radius: 8px;
                                    font-size: 13px;
                                    font-weight: 600;
                                    z-index: 200;
                                    opacity: 0.95;
                                    pointer-events: none;
                                    box-shadow: 0 4px 12px rgba(52, 152, 219, 0.4);
                                    border: 2px solid rgba(255, 255, 255, 0.3);
                                    animation: dropZonePulse 2s infinite;
                                \`;
                                f.appendChild(dropZone);
                            }
                        });

                        // Add CSS animation for drop zone pulsing
                        if (!document.getElementById('drop-zone-animation')) {
                            const style = document.createElement('style');
                            style.id = 'drop-zone-animation';
                            style.textContent = \`
                                @keyframes dropZonePulse {
                                    0%, 100% { transform: translate(-50%, -50%) scale(1); opacity: 0.95; }
                                    50% { transform: translate(-50%, -50%) scale(1.05); opacity: 1; }
                                }
                            \`;
                            document.head.appendChild(style);
                        }

                        currentHandleMouseMove = function(e) {
                            if (!isDragging) return;

                            console.log('🖱️ Mouse move during drag:', { x: e.clientX, y: e.clientY });

                            // Update preview position
                            if (dragPreview) {
                                dragPreview.style.left = e.clientX + 10 + 'px';
                                dragPreview.style.top = e.clientY + 10 + 'px';
                            }

                            // Calculate drop position based on mouse Y coordinate
                            const container = document.querySelector('.document-content') || document.querySelector('main');
                            if (!container) return;

                            const wrappers = Array.from(container.querySelectorAll('.editable-field-wrapper'));
                            const mouseY = e.clientY;

                            // Find the best drop position
                            let bestIndex = 0;
                            let bestPosition = 'before';
                            let minDistance = Infinity;

                            // Check position relative to each wrapper
                            wrappers.forEach((wrapper, index) => {
                                const rect = wrapper.getBoundingClientRect();
                                const wrapperCenterY = rect.top + rect.height / 2;
                                const distance = Math.abs(mouseY - wrapperCenterY);

                                if (distance < minDistance) {
                                    minDistance = distance;
                                    bestIndex = index;
                                    bestPosition = mouseY < wrapperCenterY ? 'before' : 'after';
                                }
                            });

                            // If no wrappers, default to position 0
                            if (wrappers.length === 0) {
                                bestIndex = 0;
                                bestPosition = 'before';
                            }

                            // Update drop indicator
                            console.log('🎯 Mouse move - updating drop indicator:', { bestIndex, bestPosition, wrappers: wrappers.length });
                            updateDropIndicator(bestIndex, bestPosition);

                            // Update wrapper highlighting based on drop position
                            wrappers.forEach((wrapper, index) => {
                                if (index === bestIndex) {
                                    if (bestPosition === 'before') {
                                        // Highlight as drop target before this wrapper
                                        wrapper.classList.add('drag-over');
                                    } else {
                                        // This wrapper will be pushed down, highlight it too
                                        wrapper.classList.add('drag-over');
                                    }
                                } else {
                                    wrapper.classList.remove('drag-over');
                                }
                            });

                            // If dropping at the end, highlight the last wrapper
                            if (bestPosition === 'after' && wrappers.length > 0) {
                                const lastWrapper = wrappers[wrappers.length - 1];
                                lastWrapper.classList.add('drag-over');
                            }
                        };

                        currentHandleMouseUp = function(e) {
                            console.log('🎯 Mouse drag ended for:', field.id);
                            console.log('📍 Final mouse position:', { x: e.clientX, y: e.clientY });
                            if (!isDragging) return;

                            // Clean up event listeners immediately
                            if (currentHandleMouseMove) {
                                document.removeEventListener('mousemove', currentHandleMouseMove);
                                currentHandleMouseMove = null;
                            }
                            if (currentHandleMouseUp) {
                                document.removeEventListener('mouseup', currentHandleMouseUp);
                                currentHandleMouseUp = null;
                            }

                            isDragging = false;
                            field.style.opacity = '';
                            dragHandle.style.cursor = 'grab';

                            // Remove drop indicators and highlighting
                            removeDropIndicators();
                            document.querySelectorAll('.editable-field-wrapper').forEach(w => {
                                w.classList.remove('drag-over');
                            });

                            // Re-enable hover effects
                            document.body.classList.remove('dragging-active');

                            // Remove drag preview
                            if (dragPreview) {
                                document.body.removeChild(dragPreview);
                                dragPreview = null;
                            }

                            // Remove all visual indicators
                            document.querySelectorAll('.editable-field').forEach(f => {
                                f.style.borderTop = '';
                                f.style.backgroundColor = '';

                                // Reset wrapper borders to transparent and clear all drag styles
                                const wrapper = f.closest('.editable-field-wrapper');
                                if (wrapper) {
                                    wrapper.style.borderStyle = '';
                                    wrapper.style.borderColor = 'transparent';
                                    wrapper.style.borderWidth = '';
                                    wrapper.style.background = '';
                                    wrapper.style.borderRadius = '';
                                    wrapper.style.transition = '';
                                    wrapper.style.boxShadow = '';
                                }

                                const dropZone = f.querySelector('.drop-zone-indicator');
                                if (dropZone) {
                                    f.removeChild(dropZone);
                                }
                            });

                            // Check drop target - exclude the dragged element from hit testing
                            field.style.pointerEvents = 'none';
                            if (dragPreview) {
                                dragPreview.style.pointerEvents = 'none';
                            }

                            const elementBelow = document.elementFromPoint(e.clientX, e.clientY);
                            field.style.pointerEvents = '';

                            let targetField = elementBelow?.closest('.editable-field');

                            // More detailed debugging
                            console.log('🎯 Drop detection debug:', {
                                mouseX: e.clientX,
                                mouseY: e.clientY,
                                elementBelow: elementBelow?.tagName + (elementBelow?.className ? '.' + elementBelow.className : ''),
                                elementBelowId: elementBelow?.id,
                                targetField: targetField?.id || 'NONE',
                                allEditableFields: Array.from(document.querySelectorAll('.editable-field')).map(f => f.id).slice(0, 5)
                            });

                            // If no target found, try alternative detection
                            if (!targetField) {
                                console.log('🔍 Alternative detection - checking all fields at mouse position');
                                const allFields = document.querySelectorAll('.editable-field');
                                let closestField = null;
                                let minDistance = Infinity;
                                const distances = [];

                                allFields.forEach(f => {
                                    if (f === field) return; // Skip the dragged field

                                    const rect = f.getBoundingClientRect();
                                    const centerX = rect.left + rect.width / 2;
                                    const centerY = rect.top + rect.height / 2;
                                    const distance = Math.sqrt(
                                        Math.pow(e.clientX - centerX, 2) +
                                        Math.pow(e.clientY - centerY, 2)
                                    );

                                    distances.push({
                                        id: f.id,
                                        distance: Math.round(distance)
                                    });

                                    if (distance < minDistance && distance < 500) { // Increased to 500px
                                        minDistance = distance;
                                        closestField = f;
                                    }
                                });

                                console.log('🔍 Distance check:', {
                                    mousePos: \`\${e.clientX}, \${e.clientY}\`,
                                    closestDistances: distances.sort((a, b) => a.distance - b.distance).slice(0, 5),
                                    foundWithin500px: !!closestField
                                });

                                if (closestField) {
                                    console.log('🎯 Found closest field:', closestField.id, 'distance:', Math.round(minDistance));
                                    targetField = closestField; // Use the closest field as target
                                } else {
                                    console.log('🔍 No nearby fields found within 500px');
                                }
                            }

                            if (targetField && targetField !== field) {
                                console.log('🔄 Dropping on target field:', targetField.id);

                                // Find the actual wrapper elements to move (since fields are wrapped)
                                const fieldWrapper = field.closest('.editable-field-wrapper') || field.parentNode;
                                const targetWrapper = targetField.closest('.editable-field-wrapper') || targetField.parentNode;

                                console.log('🔍 Wrapper detection:', {
                                    fieldId: field.id,
                                    targetId: targetField.id,
                                    fieldWrapper: fieldWrapper?.tagName + '.' + (fieldWrapper?.className || ''),
                                    targetWrapper: targetWrapper?.tagName + '.' + (targetWrapper?.className || ''),
                                    fieldWrapperFound: !!field.closest('.editable-field-wrapper'),
                                    targetWrapperFound: !!targetField.closest('.editable-field-wrapper')
                                });

                                // Find their common parent container
                                const fieldParent = fieldWrapper.parentNode;
                                const targetParent = targetWrapper.parentNode;

                                console.log('🔍 Parent check:', {
                                    fieldWrapper: fieldWrapper?.tagName + '.' + (fieldWrapper?.className || ''),
                                    targetWrapper: targetWrapper?.tagName + '.' + (targetWrapper?.className || ''),
                                    fieldParent: fieldParent?.tagName + '.' + (fieldParent?.className || ''),
                                    targetParent: targetParent?.tagName + '.' + (targetParent?.className || ''),
                                    sameParent: fieldParent === targetParent,
                                    fieldWrapperInParent: fieldParent?.contains(fieldWrapper),
                                    targetWrapperInParent: targetParent?.contains(targetWrapper)
                                });

                                // Additional validation for wrappers
                                const fieldWrapperInDOM = document.body.contains(fieldWrapper);
                                const targetWrapperInDOM = document.body.contains(targetWrapper);
                                const fieldParentValid = fieldParent && document.body.contains(fieldParent);
                                const targetParentValid = targetParent && document.body.contains(targetParent);

                                console.log('🔍 Extended validation:', {
                                    fieldWrapperInDOM,
                                    targetWrapperInDOM,
                                    fieldParentValid,
                                    targetParentValid,
                                    sameParent: fieldParent === targetParent
                                });

                                if (fieldWrapperInDOM && targetWrapperInDOM && fieldParentValid && targetParentValid && fieldParent === targetParent) {
                                    const allChildren = Array.from(fieldParent.children);
                                    const draggedIndex = allChildren.indexOf(fieldWrapper);
                                    const targetIndex = allChildren.indexOf(targetWrapper);

                                    console.log('🔄 Moving element', {
                                        draggedIndex,
                                        targetIndex,
                                        direction: draggedIndex < targetIndex ? 'down' : 'up',
                                        totalChildren: allChildren.length,
                                        draggedInDOM: draggedIndex !== -1,
                                        targetInDOM: targetIndex !== -1
                                    });

                                    if (draggedIndex !== -1 && targetIndex !== -1 && draggedIndex !== targetIndex) {
                                        try {
                                            // Double-check before manipulation - move wrappers instead of fields
                                            if (fieldParent.contains(fieldWrapper) && fieldParent.contains(targetWrapper)) {
                                                if (draggedIndex < targetIndex) {
                                                    const nextSibling = targetWrapper.nextSibling;
                                                    if (nextSibling && fieldParent.contains(nextSibling)) {
                                                        fieldParent.insertBefore(fieldWrapper, nextSibling);
                                                    } else {
                                                        fieldParent.appendChild(fieldWrapper);
                                                    }
                                                } else {
                                                    fieldParent.insertBefore(fieldWrapper, targetWrapper);
                                                }
                                                console.log('✅ Wrapper moved successfully, saving form structure');
                                                saveFormStructure();
                                            } else {
                                                console.log('❌ Final validation failed - wrappers not in parent');
                                            }
                                        } catch (error) {
                                            console.error('❌ DOM manipulation error:', error.message);
                                            console.log('Error details:', {
                                                fieldId: field.id,
                                                targetId: targetField.id,
                                                fieldWrapperTag: fieldWrapper?.tagName,
                                                targetWrapperTag: targetWrapper?.tagName,
                                                fieldParentTag: fieldParent?.tagName,
                                                targetParentTag: targetParent?.tagName,
                                                fieldWrapperInParent: fieldParent?.contains(fieldWrapper),
                                                targetWrapperInParent: fieldParent?.contains(targetWrapper)
                                            });
                                        }
                                    } else {
                                        console.log('❌ Cannot move - invalid indices or same element');
                                    }
                                } else {
                                    console.log('❌ Cannot move - validation failed');
                                }
                            } else {
                                console.log('⚠️ No valid drop target found');
                            }

                            draggedElement = null;
                        };

                        // Clean up any existing listeners first
                        if (currentHandleMouseMove) {
                            document.removeEventListener('mousemove', currentHandleMouseMove);
                        }
                        if (currentHandleMouseUp) {
                            document.removeEventListener('mouseup', currentHandleMouseUp);
                        }

                        document.addEventListener('mousemove', currentHandleMouseMove);
                        document.addEventListener('mouseup', currentHandleMouseUp);
                    });
        }

        function addDragFunctionality(field) {
            if (!field || (!field.classList.contains('editable-field') && !field.classList.contains('editable-field-wrapper'))) return;

            console.log(`🔧 Adding drag functionality to field: ${field.id}`);

            // Disable draggable on contenteditable elements to prevent conflicts
            const editableElements = field.querySelectorAll('[contenteditable]');
            editableElements.forEach(el => {
                el.draggable = false;
                el.addEventListener('dragstart', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                });
            });

            // Remove any existing drag handles first
            const existingHandles = field.querySelectorAll('.drag-handle');
            existingHandles.forEach(handle => handle.remove());

            // Add our JavaScript drag handle
            const dragHandle = document.createElement('div');
            dragHandle.className = 'drag-handle';
            dragHandle.innerHTML = `
                <svg width="12" height="20" viewBox="0 0 12 20" fill="none">
                    <circle cx="3" cy="4" r="1.5" fill="currentColor"/>
                    <circle cx="9" cy="4" r="1.5" fill="currentColor"/>
                    <circle cx="3" cy="10" r="1.5" fill="currentColor"/>
                    <circle cx="9" cy="10" r="1.5" fill="currentColor"/>
                    <circle cx="3" cy="16" r="1.5" fill="currentColor"/>
                    <circle cx="9" cy="16" r="1.5" fill="currentColor"/>
                </svg>
            `;
            dragHandle.title = 'Drag to reorder fields';
            dragHandle.draggable = false;
            dragHandle.style.cssText = `
                position: absolute;
                top: 50%;
                left: -25px;
                transform: translateY(-50%);
                cursor: grab;
                background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                color: white;
                padding: 10px 8px;
                border-radius: 6px;
                font-size: 12px;
                z-index: 10;
                user-select: none;
                box-shadow: 0 3px 12px rgba(52, 152, 219, 0.4);
                border: 2px solid rgba(255,255,255,0.3);
                transition: all 0.2s ease;
                opacity: 0.7;
            `;

            // Add hover effects
            dragHandle.addEventListener('mouseenter', function() {
                this.style.opacity = '1';
                this.style.transform = 'translateY(-50%) scale(1.1)';
                this.style.boxShadow = '0 5px 20px rgba(52, 152, 219, 0.6)';
            });
            dragHandle.addEventListener('mouseleave', function() {
                if (!field.isDragging) {
                    this.style.opacity = '0.7';
                    this.style.transform = 'translateY(-50%) scale(1)';
                    this.style.boxShadow = '0 3px 12px rgba(52, 152, 219, 0.4)';
                }
            });

            field.appendChild(dragHandle);

            // Add field controls if they don't exist
            let fieldControls = field.querySelector('.field-controls');
            if (!fieldControls) {
                fieldControls = document.createElement('div');
                fieldControls.className = 'field-controls';
                fieldControls.innerHTML = `
                    <button type="button" class="field-control-btn remove-field-btn" onclick="removeField(this)" title="Remove field">
                        ×
                    </button>
                `;
                field.appendChild(fieldControls);
            }

            // Set up mouse-based drag functionality
            let isDragging = false;
            let dragStartY = 0;
            let currentHandleMouseMove = null;
            let currentHandleMouseUp = null;

            dragHandle.addEventListener('mousedown', function(e) {
                console.log('🖱️ Drag handle mousedown for field:', field.id);
                e.preventDefault();
                e.stopPropagation();
                isDragging = true;
                field.isDragging = true;
                dragStartY = e.clientY;
                draggedElement = field;

                // Visual feedback
                field.style.opacity = '0.8';
                field.style.transform = 'scale(1.02)';
                field.style.zIndex = '1000';
                field.style.boxShadow = '0 8px 25px rgba(0,0,0,0.15)';

                // Show drop indicators
                console.log('📍 Showing drop indicators...');
                console.log('Total indicators to show:', dropIndicators.length);

                // Debug: Check if indicators exist in DOM
                const allDropZonesInDOM = document.querySelectorAll('.drop-zone');
                console.log('🔍 Drop zones found in DOM:', allDropZonesInDOM.length);

                dropIndicators.forEach((indicator, index) => {
                    console.log(\`Showing indicator \${index}:\`, indicator.className, indicator.dataset.dropIndex, indicator.dataset.dropPosition);
                    console.log('Indicator in DOM?', document.contains(indicator));
                    indicator.style.display = 'block';
                    indicator.style.visibility = 'visible';
                    console.log('Indicator display set to:', indicator.style.display);
                });

                // Add dragging state to body
                document.body.classList.add('dragging-active');

                // Set up mouse move and up handlers
                currentHandleMouseMove = function(e) {
                    if (!isDragging) return;

                    // Update drop indicator based on mouse position
                    const wrappers = Array.from(document.querySelectorAll('.editable-field-wrapper'));
                    const mouseY = e.clientY;

                    let bestIndex = 0;
                    let bestPosition = 'before';
                    let minDistance = Infinity;

                    wrappers.forEach((wrapper, index) => {
                        const rect = wrapper.getBoundingClientRect();
                        const centerY = rect.top + rect.height / 2;

                        // Distance to drop before this wrapper
                        const distanceBefore = Math.abs(mouseY - rect.top);
                        if (distanceBefore < minDistance) {
                            minDistance = distanceBefore;
                            bestIndex = index;
                            bestPosition = 'before';
                        }

                        // Distance to drop after this wrapper (only for last wrapper)
                        if (index === wrappers.length - 1) {
                            const distanceAfter = Math.abs(mouseY - rect.bottom);
                            if (distanceAfter < minDistance) {
                                minDistance = distanceAfter;
                                bestIndex = index + 1;
                                bestPosition = 'after';
                            }
                        }
                    });

                    // Update drop indicator
                    updateDropIndicator(bestIndex, bestPosition);

                    // Update wrapper highlighting
                    wrappers.forEach((wrapper, index) => {
                        if (index === bestIndex && bestPosition === 'before') {
                            wrapper.classList.add('drag-over');
                        } else if (index === bestIndex - 1 && bestPosition === 'after') {
                            wrapper.classList.add('drag-over');
                        } else {
                            wrapper.classList.remove('drag-over');
                        }
                    });
                };

                currentHandleMouseUp = function(e) {
                    console.log('🎯 Mouse drag ended for:', field.id);
                    if (!isDragging) return;

                    // Clean up event listeners
                    if (currentHandleMouseMove) {
                        document.removeEventListener('mousemove', currentHandleMouseMove);
                        currentHandleMouseMove = null;
                    }
                    if (currentHandleMouseUp) {
                        document.removeEventListener('mouseup', currentHandleMouseUp);
                        currentHandleMouseUp = null;
                    }

                    isDragging = false;
                    field.isDragging = false;

                    // Reset visual state
                    field.style.opacity = '';
                    field.style.transform = '';
                    field.style.zIndex = '';
                    field.style.boxShadow = '';

                    // Hide drop indicators and remove dragging state
                    removeDropIndicators();
                    document.body.classList.remove('dragging-active');
                    document.querySelectorAll('.editable-field-wrapper').forEach(w => {
                        w.classList.remove('drag-over');
                    });

                    // Handle drop logic
                    handleFieldDrop(field, e);

                    draggedElement = null;
                };

                document.addEventListener('mousemove', currentHandleMouseMove);
                document.addEventListener('mouseup', currentHandleMouseUp);
            });
        }

        function handleFieldDrop(draggedField, e) {
            console.log('🎯 Handling field drop for:', draggedField.id);
            console.log('📍 Drop position:', { x: e.clientX, y: e.clientY });
            console.log('📊 Current drop target state:', currentDropTarget);

            // Use the drop target calculated during mouse movement
            if (!currentDropTarget) {
                console.log('⚠️ No drop target calculated during drag - attempting fallback calculation');

                // Fallback: calculate drop position on the fly
                const container = document.querySelector('.document-content') || document.querySelector('main');
                if (!container) {
                    console.log('❌ No container found for fallback');
                    return;
                }

                const wrappers = Array.from(container.querySelectorAll('.editable-field-wrapper'));
                const mouseY = e.clientY;

                // Find the best drop position
                let bestIndex = 0;
                let bestPosition = 'before';
                let minDistance = Infinity;

                wrappers.forEach((wrapper, index) => {
                    const rect = wrapper.getBoundingClientRect();
                    const wrapperCenterY = rect.top + rect.height / 2;
                    const distance = Math.abs(mouseY - wrapperCenterY);

                    if (distance < minDistance) {
                        minDistance = distance;
                        bestIndex = index;
                        bestPosition = mouseY < wrapperCenterY ? 'before' : 'after';
                    }
                });

                console.log('🔄 Fallback calculation result:', { bestIndex, bestPosition, total: wrappers.length });

                if (wrappers.length === 0) {
                    console.log('❌ No wrappers for fallback');
                    return;
                }

                currentDropTarget = { index: bestIndex, position: bestPosition };
            }

            const { index: targetIndex, position: dropPosition } = currentDropTarget;
            console.log('🎯 Using calculated drop target:', { targetIndex, dropPosition });

            // Get the parent container
            const container = draggedField.parentNode;
            const allWrappers = Array.from(container.querySelectorAll('.editable-field-wrapper'));
            const draggedIndex = allWrappers.indexOf(draggedField);

            console.log('📊 Drop calculation:', {
                draggedIndex,
                targetIndex,
                dropPosition,
                total: allWrappers.length
            });

            if (draggedIndex === -1) {
                console.log('❌ Dragged element not found in container');
                return;
            }

            // Calculate the actual insertion index
            let insertIndex = targetIndex;
            if (dropPosition === 'after') {
                insertIndex = targetIndex;
            }

            // Adjust for the fact that we're moving the dragged element
            if (draggedIndex < insertIndex) {
                insertIndex--;
            }

            // Ensure valid index
            insertIndex = Math.max(0, Math.min(insertIndex, allWrappers.length - 1));

            console.log('📍 Final insertion index:', insertIndex);

            if (insertIndex === draggedIndex) {
                console.log('⚠️ Drop position is same as current position');
                return;
            }

            // Find the target element for insertion
            let targetElement = null;
            if (insertIndex < allWrappers.length) {
                targetElement = allWrappers[insertIndex];
            }

            if (targetElement) {
                console.log('🔄 Inserting before target:', targetElement.id);
                container.insertBefore(draggedField, targetElement);
            } else {
                console.log('🔄 Appending to container end');
                container.appendChild(draggedField);
            }

            console.log('✅ Field moved successfully');
            console.log('🔄 Triggering save after field reorder...');
            window.isReorderOperation = true; // Mark as reorder operation
            saveFormData();
            window.isReorderOperation = false; // Reset flag
        }

        function handleDragStart(e) {
            draggedElement = this;
            this.style.opacity = '0.5';
            // Store the element ID in dataTransfer as backup
            e.dataTransfer.setData('text/plain', this.id);
            e.dataTransfer.effectAllowed = 'move';
            console.log('🚀 Drag started:', this.id);
        }

        function handleDragOver(e) {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
        }

        function handleDrop(e) {
            e.preventDefault();
            e.stopPropagation(); // Prevent container drop handler from firing

            // Get dragged element - use backup from dataTransfer if needed
            let actualDraggedElement = draggedElement;
            if (!actualDraggedElement) {
                const draggedId = e.dataTransfer.getData('text/plain');
                actualDraggedElement = document.getElementById(draggedId);
                console.log('🔄 Retrieved dragged element from dataTransfer:', draggedId);
            }

            console.log('🎯 Field drop event triggered', {
                draggedElement: actualDraggedElement?.id || 'UNDEFINED',
                draggedElementExists: !!actualDraggedElement,
                targetElement: this.id,
                sameElement: actualDraggedElement === this,
                bothExist: !!(actualDraggedElement && this)
            });

            if (actualDraggedElement && actualDraggedElement !== this) {
                const parent = this.parentNode;
                const draggedIndex = Array.from(parent.children).indexOf(actualDraggedElement);
                const targetIndex = Array.from(parent.children).indexOf(this);

                console.log('🔄 Moving element', {
                    draggedIndex,
                    targetIndex,
                    direction: draggedIndex < targetIndex ? 'down' : 'up'
                });

                if (draggedIndex < targetIndex) {
                    // Moving down: insert after target
                    parent.insertBefore(actualDraggedElement, this.nextSibling);
                } else {
                    // Moving up: insert before target
                    parent.insertBefore(actualDraggedElement, this);
                }

                console.log('✅ Element moved, saving form structure');
                saveFormStructure();
                draggedElement = null; // Clear after successful move
            } else {
                console.log('⚠️ No valid drag operation (same element or no dragged element)');
            }
        }

        function handleDragEnd(e) {
            console.log('🏁 Drag ended for:', this.id);
            this.style.opacity = '';
            // Don't immediately clear draggedElement - let the drop handler clear it
            setTimeout(() => {
                if (draggedElement) {
                    console.log('⚠️ Clearing draggedElement after timeout');
                    draggedElement = null;
                }
            }, 100);
        }

        function handleContainerDragOver(e) {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
        }

        function handleContainerDrop(e) {
            // Only handle container drops if we didn't drop on a field
            if (e.target.closest('.editable-field')) {
                return; // Let the field handler deal with it
            }

            e.preventDefault();

            // Get dragged element - use backup from dataTransfer if needed
            let actualDraggedElement = draggedElement;
            if (!actualDraggedElement) {
                const draggedId = e.dataTransfer.getData('text/plain');
                actualDraggedElement = document.getElementById(draggedId);
                console.log('🔄 Retrieved dragged element from dataTransfer for container:', draggedId);
            }

            console.log('📦 Container drop event triggered (empty area)', {
                draggedElement: actualDraggedElement?.id || 'UNDEFINED',
                targetElement: e.target.tagName + (e.target.className ? '.' + e.target.className : '')
            });

            // Dropping on empty container area - append to the end
            if (actualDraggedElement) {
                const addButton = document.getElementById('add-field-button');
                console.log('📦 Add button found:', !!addButton, 'Parent found:', !!addButton?.parentNode);

                if (addButton && addButton.parentNode) {
                    console.log('📦 Moving element to end of form');
                    addButton.parentNode.insertBefore(actualDraggedElement, addButton);
                    console.log('📦 Element moved, saving form structure');
                    saveFormStructure();
                    draggedElement = null; // Clear after successful move
                } else {
                    console.log('❌ Could not find add button or its parent');
                }
            } else {
                console.log('❌ No dragged element found in container drop');
            }
        }

        function initializeFieldEditing() {
            // Make all content editable
            const editableElements = document.querySelectorAll('[contenteditable="true"]');
            editableElements.forEach(element => {
                element.addEventListener('blur', function() {
                    saveFormData();
                });
                element.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        this.blur();
                    }
                });
            });
        }

        function initializeToolbarButtons() {
            // Initialize all toolbar buttons
            const saveBtn = document.getElementById('save-form');
            const previewBtn = document.getElementById('switch-to-preview');
            const addFieldBtn = document.getElementById('add-field');
            const addFieldContentBtn = document.getElementById('add-field-button');
            const clearAllBtn = document.getElementById('clear-all-fields');
            const shareBtn = document.getElementById('share-form');

            if (saveBtn) {
                saveBtn.addEventListener('click', saveForm);
            }

            if (previewBtn) {
                previewBtn.addEventListener('click', switchToPreview);
            }

            if (addFieldBtn) {
                addFieldBtn.addEventListener('click', showAddFieldDialog);
            }

            if (addFieldContentBtn) {
                addFieldContentBtn.addEventListener('click', showAddFieldDialog);
            }

            if (clearAllBtn) {
                clearAllBtn.addEventListener('click', clearAllFields);
            }

            if (shareBtn) {
                shareBtn.addEventListener('click', openShareDialog);
            }
        }

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
            // In edit mode, update URL and refresh
            const url = new URL(window.location);
            if (newTheme === 'default') {
                url.searchParams.delete('theme');
            } else {
                url.searchParams.set('theme', newTheme);
            }
            window.location.href = url.toString();
        }

        function initializePreviewMode() {
            // Preview mode functionality is handled by switching to preview URL
        }

        function loadFormData() {
            // Load form data from server and reorder fields to match saved state
            const documentId = '#{document_id}';
            if (documentId) {
                console.log('Loading form data for document:', documentId);

                fetch(\`/api/documents/\${documentId}\`)
                .then(response => response.json())
                .then(data => {
                    console.log('📊 Raw response data:', data);

                    if (data.form_data && Array.isArray(data.form_data)) {
                        console.log('📊 Loaded form data:', data.form_data.length, 'items');

                        // Sort form data by index to get correct order
                        const sortedFormData = data.form_data.sort((a, b) => (a.index || 0) - (b.index || 0));
                        console.log('📊 Sorted form data by index:', sortedFormData.map(item => ({ id: item.id, index: item.index })));

                        // Reorder DOM elements to match saved order
                        reorderDOMElements(sortedFormData);
                    } else if (data.processed_data && data.processed_data.content && data.processed_data.content.sections) {
                        console.log('📊 Found processed_data with sections:', data.processed_data.content.sections.length);

                        // Try to extract form fields from sections and create ordering data
                        const formFields = data.processed_data.content.sections
                            .filter(section => section.type === 'form_input' && section.form_field_id)
                            .map((section, index) => ({
                                id: section.form_field_id,
                                index: index,
                                type: 'form_input'
                            }));

                        if (formFields.length > 0) {
                            console.log('📊 Extracted form fields for reordering:', formFields);
                            reorderDOMElements(formFields);
                        }
                    } else {
                        console.log('📊 No form data found or invalid format');
                    }
                })
                .catch(error => {
                    console.error('Failed to load form data:', error);
                });
            }
        }

        function reorderDOMElements(sortedFormData) {
            const container = document.querySelector('.document-content') || document.querySelector('main');
            if (!container) {
                console.log('❌ No container found for reordering');
                return;
            }

            // Create a map of current DOM elements by ID - try multiple strategies
            const elementMap = new Map();
            const wrappers = container.querySelectorAll('.editable-field-wrapper');

            wrappers.forEach(wrapper => {
                // Strategy 1: Look for field inside wrapper
                const field = wrapper.querySelector('.editable-field');
                if (field && field.id) {
                    elementMap.set(field.id, wrapper);
                    console.log('🔍 Mapped field:', field.id, 'to wrapper');
                }

                // Strategy 2: Check if wrapper itself has the ID pattern
                if (wrapper.id && wrapper.id.startsWith('editable_')) {
                    elementMap.set(wrapper.id, wrapper);
                    console.log('🔍 Mapped wrapper:', wrapper.id);
                }

                // Strategy 3: Look for any element with editable_ ID pattern inside wrapper
                const editableElements = wrapper.querySelectorAll('[id*="editable_"]');
                editableElements.forEach(el => {
                    if (el.id) {
                        elementMap.set(el.id, wrapper);
                        console.log('🔍 Mapped nested element:', el.id, 'to wrapper');
                    }
                });
            });

            console.log('🔧 Found', elementMap.size, 'elements to reorder');
            console.log('🔧 Element map keys:', Array.from(elementMap.keys()));
            console.log('🔧 Form data IDs to reorder:', sortedFormData.map(item => item.id));

            // Find and preserve the Add Field button
            const addButton = container.querySelector('.add-field-btn');
            if (addButton) {
                addButton.remove();
            }

            // Remove all wrappers from container temporarily
            const allWrappers = Array.from(wrappers);
            allWrappers.forEach(wrapper => wrapper.remove());

            // Re-insert elements in the correct order based on saved data
            let reorderedCount = 0;
            sortedFormData.forEach((item, index) => {
                if (item.id && elementMap.has(item.id)) {
                    const wrapper = elementMap.get(item.id);
                    container.appendChild(wrapper);
                    console.log(\`✅ Moved \${item.id} to position \${index}\`);
                    reorderedCount++;
                } else {
                    console.log(\`❌ Could not find element for ID: \${item.id}\`);
                }
            });

            console.log(\`🎯 Reordered \${reorderedCount} out of \${sortedFormData.length} elements\`);

            // Re-add the Add Field button at the end
            if (addButton) {
                container.appendChild(addButton);
            }

            // Re-create drop indicators with new order
            createDropIndicators();

            console.log('🎯 DOM reordering complete');
        }

        function saveFormData() {
            // Auto-save form data with slight delay to ensure DOM is updated
            setTimeout(() => {
                const documentId = '#{document_id}';
                if (documentId) {
                    // Collect current form state
                    const formState = collectCurrentFormState();
                    const title = document.querySelector('.editable-title')?.textContent || 'Untitled Form';

                    // Check if this is a reorder operation
                    const requestBody = {
                        title: title,
                        form_data: formState,
                        last_modified: new Date().toISOString()
                    };

                    if (window.isReorderOperation) {
                        requestBody.is_reorder = true;
                        console.log('🔄 Marking request as REORDER operation');
                        console.log('🔄 Request body with reorder flag:', JSON.stringify(requestBody, null, 2));
                    } else {
                        console.log('⚠️ Regular save operation (no reorder flag)');
                        console.log('⚠️ Request body:', JSON.stringify(requestBody, null, 2));
                    }

                    // Save to server
                    fetch(\`/api/documents/\${documentId}\`, {
                        method: 'PUT',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify(requestBody)
                    })
                    .then(response => response.json())
                    .then(data => {
                        if (data.error) {
                            throw new Error(data.error);
                        }
                        console.log('✅ Form data saved successfully after drag/drop');
                    })
                    .catch(error => {
                        console.error('❌ Failed to save form data:', error);
                        showNotification(error.message || 'Failed to save form changes', 'error');
                    });
                }
            }, 100); // Small delay to ensure DOM is updated
        }

        function saveFormStructure() {
            // Skip saving entirely during reorder operations
            console.log('🔄 saveFormStructure called - SKIPPING save operation to prevent duplicates');
            console.log('🔄 Drag and drop reordering is visual-only, no database changes needed');

            // Don't save anything during drag operations
            // The order will be preserved by the browser until the user manually saves
            return;
        }

        function saveFormDataForced() {
            // Force save the form data to backend, bypassing the drag skip logic
            console.log('🔄 saveFormDataForced called - FORCING save operation');

            const documentId = '#{document_id}';
            if (!documentId) {
                console.log('❌ No document ID available for forced save');
                return;
            }

            const formState = collectCurrentFormState();
            console.log('🔄 Collected form state for forced save:', formState);

            const requestData = {
                title: document.querySelector('.editable-title')?.textContent || 'Untitled Form',
                form_data: formState
            };

            console.log('🔄 Sending forced save request:', requestData);

            fetch(\`/api/documents/\${documentId}\`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error(\`HTTP error! status: \${response.status}\`);
                }
                return response.json();
            })
            .then(data => {
                console.log('✅ Forced save successful:', data);
            })
            .catch(error => {
                console.error('❌ Forced save failed:', error);
                showNotification('Failed to save cleared state', 'error');
            });
        }

        function setupAutoSave() {
            // Auto-save every 30 seconds
            setInterval(saveFormData, 30000);
        }

        function collectCurrentFormState() {
            // Collect form state based on current DOM order - look for wrappers first, then inner fields
            const formWrappers = document.querySelectorAll('.editable-field-wrapper');
            const state = [];
            const seenFieldNames = new Set(); // Track field names to prevent duplicates

            console.log('🔍 COLLECTING FORM STATE - Found wrappers:', formWrappers.length);
            console.log('🔍 Current DOM order:');
            formWrappers.forEach((wrapper, index) => {
                console.log(\`  \${index}: \${wrapper.id} (type: \${wrapper.dataset.fieldType})\`);
            });

            // If no wrappers found, fall back to editable fields (for backward compatibility)
            const elementsToProcess = formWrappers.length > 0 ? formWrappers : document.querySelectorAll('.editable-field');
            console.log('🔍 Processing elements:', elementsToProcess.length, 'type:', formWrappers.length > 0 ? 'wrappers' : 'fields');

            // Additional debugging to understand DOM state
            console.log('🔍 DOM DEBUG INFO:');
            console.log('  - Document ready state:', document.readyState);
            console.log('  - Body exists:', !!document.body);
            console.log('  - All divs:', document.querySelectorAll('div').length);
            console.log('  - Elements with editable-field class:', document.querySelectorAll('.editable-field').length);
            console.log('  - Elements with editable-field-wrapper class:', document.querySelectorAll('.editable-field-wrapper').length);
            console.log('  - Elements with data-field-type:', document.querySelectorAll('[data-field-type]').length);
            console.log('  - Radio inputs:', document.querySelectorAll('input[type="radio"]').length);
            console.log('  - Form fields container:', document.querySelector('.form-fields, .form-content, .container'));

            // Check if we have any elements at all that might be related
            const allEditableElements = document.querySelectorAll('[class*="editable"], [id*="editable"]');
            console.log('  - Any elements with "editable" in class/id:', allEditableElements.length);
            if (allEditableElements.length > 0) {
                console.log('  - First editable element:', allEditableElements[0]);
                console.log('  - Its classes:', allEditableElements[0].className);
            }

            elementsToProcess.forEach((element, index) => {
                // For wrappers, get the field type from the inner field or wrapper itself
                const fieldElement = element.classList.contains('editable-field-wrapper')
                    ? element.querySelector('.editable-field') || element
                    : element;

                const fieldType = fieldElement.dataset.fieldType || element.dataset.fieldType || 'text';
                const fieldName = fieldElement.querySelector('input, textarea, select')?.name || \`field_\${index}\`;

                // Skip duplicates - check if we've already processed this field name
                // Remove editable_ prefixes to get clean field name for comparison
                const cleanFieldName = fieldName.replace(/^editable_+/, '');
                const elementId = fieldElement.id || element.id || '';
                const cleanElementId = elementId.replace(/^editable_+/, '');

                // Skip if we've already seen this field name or if this looks like a duplicate
                if (seenFieldNames.has(cleanFieldName) || seenFieldNames.has(cleanElementId)) {
                    console.log(\`⚠️ Skipping duplicate field: \${fieldName} (ID: \${elementId})\`);
                    return;
                }

                // Add to seen set using both field name and clean ID
                seenFieldNames.add(cleanFieldName);
                if (cleanElementId) {
                    seenFieldNames.add(cleanElementId);
                }

                // Try multiple ways to get the field content, preserving original labels
                let fieldContent = fieldElement.querySelector('.editable-label')?.textContent?.trim() ||
                                 fieldElement.querySelector('label')?.textContent?.trim() ||
                                 fieldElement.querySelector('.form-question')?.textContent?.trim() ||
                                 fieldElement.querySelector('.form-label')?.textContent?.trim() ||
                                 element.querySelector('.editable-label')?.textContent?.trim() ||
                                 element.querySelector('label')?.textContent?.trim();

                // Fallback: try to get from the field's data attribute or input placeholder
                if (!fieldContent || fieldContent === '') {
                    fieldContent = fieldElement.dataset.originalLabel ||
                                 fieldElement.querySelector('input, textarea')?.placeholder ||
                                 'Untitled Field';
                }

                // Collect options for select and radio fields
                let options = [];
                if (fieldType === 'select' || fieldType === 'radio') {
                    try {
                        options = JSON.parse(fieldElement.dataset.options || '[]');
                    } catch (e) {
                        // Fallback: extract options from HTML
                        if (fieldType === 'select') {
                            const selectOptions = fieldElement.querySelectorAll('select option:not([value=""])');
                            options = Array.from(selectOptions).map(opt => opt.textContent.trim());
                        } else if (fieldType === 'radio') {
                            const radioInputs = fieldElement.querySelectorAll('input[type="radio"]');
                            options = Array.from(radioInputs).map(input => input.value);
                        }
                    }
                }

                const fieldData = {
                    index: state.length,  // Use state length for proper sequential indexing
                    type: 'form_input',  // Mark as form input so it gets processed correctly
                    content: fieldContent,
                    id: fieldElement.id,
                    metadata: {
                        input_type: fieldType,  // Store the actual field type here
                        field_name: cleanFieldName,  // Use clean field name
                        required: fieldElement.dataset.required === 'true',
                        options: options.length > 0 ? options : undefined  // Only include options if they exist
                    }
                };

                console.log(\`✅ Including field: \${fieldName} (ID: \${fieldElement.id}) - Clean name: \${cleanFieldName}\`);

                // Debug logging for radio fields
                if (fieldType === 'radio') {
                    console.log('📻 RADIO FIELD DETECTED:', {
                        fieldType,
                        fieldName,
                        fieldContent,
                        options,
                        dataOptions: fieldElement.dataset.options,
                        fieldData
                    });
                }

                state.push(fieldData);
            });

            return state;
        }

        function saveForm() {
            const documentId = '#{document_id}';
            const saveBtn = document.getElementById('save-form');

            if (!documentId) {
                alert('No document ID available');
                return;
            }

            // Show loading state
            const originalText = saveBtn.innerHTML;
            saveBtn.disabled = true;
            saveBtn.innerHTML = '<span class="loading-spinner"></span> Saving...';

            // Collect form data
            const formState = collectCurrentFormState();
            const title = document.querySelector('.editable-title').textContent;

            // Save to server
            fetch(\`/api/documents/\${documentId}\`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    title: title,
                    form_data: formState,
                    last_modified: new Date().toISOString()
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.error) {
                    throw new Error(data.error);
                }
                // Show success message
                showNotification('Form saved successfully!', 'success');
            })
            .catch(error => {
                console.error('Save error:', error);
                showNotification(error.message || 'Failed to save form', 'error');
            })
            .finally(() => {
                saveBtn.disabled = false;
                saveBtn.innerHTML = originalText;
            });
        }

        function switchToPreview() {
            const documentId = '#{document_id}';
            if (!documentId) {
                // If no document ID, just switch mode without saving
                const url = new URL(window.location);
                url.searchParams.delete('editing');
                window.location.href = url.toString();
                return;
            }

            // Save current state before switching to preview
            const formState = collectCurrentFormState();
            const title = document.querySelector('.editable-title')?.textContent || 'Document';

            console.log('💾 SAVING BEFORE PREVIEW SWITCH:', {
                formState,
                radioFields: formState.filter(field => field.metadata.input_type === 'radio')
            });

            fetch(\`/api/documents/\${documentId}\`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    title: title,
                    form_data: formState,
                    last_modified: new Date().toISOString()
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.error) {
                    throw new Error(data.error);
                }
                // Now switch to preview mode
                const url = new URL(window.location);
                url.searchParams.delete('editing');
                window.location.href = url.toString();
            })
            .catch(error => {
                console.error('Save error before preview:', error);
                // Still switch to preview even if save fails, but show warning
                showNotification('Warning: Changes may not be saved', 'warning');
                setTimeout(() => {
                    const url = new URL(window.location);
                    url.searchParams.delete('editing');
                    window.location.href = url.toString();
                }, 1000);
            });
        }

        function showAddFieldDialog() {
            console.log('showAddFieldDialog called');

            // Force add modal styles first
            addModalStyles();

            // Create add field modal HTML
            const modalHtml = \`
                <div id="add-field-modal" class="modal-overlay">
                    <div class="modal">
                        <div class="modal-header">
                            <h3>Add New Field</h3>
                            <button class="close-btn" onclick="closeAddFieldDialog()">&times;</button>
                        </div>
                        <div class="modal-body">
                            <div class="field-types">
                                <button class="field-type-btn" data-type="text">📝 Text Input</button>
                                <button class="field-type-btn" data-type="textarea">📄 Text Area</button>
                                <button class="field-type-btn" data-type="select">📋 Dropdown</button>
                                <button class="field-type-btn" data-type="radio">⚪ Radio Buttons</button>
                                <button class="field-type-btn" data-type="checkbox">☑️ Checkbox</button>
                                <button class="field-type-btn" data-type="email">📧 Email</button>
                                <button class="field-type-btn" data-type="tel">📞 Phone</button>
                                <button class="field-type-btn" data-type="date">📅 Date</button>
                                <button class="field-type-btn" data-type="number">🔢 Number</button>
                            </div>

                            <div id="field-options-section" class="field-options-section" style="display: none; margin-top: 2rem; padding-top: 2rem; border-top: 2px solid #e5e7eb; background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%); margin: 1.5rem -1.5rem -1.5rem -1.5rem; padding: 2rem 1.5rem 1.5rem 1.5rem; border-radius: 0 0 12px 12px; box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.05);">
                                <h4 style="margin: 0 0 1.5rem 0; color: #1f2937; font-size: 1.3rem; font-weight: 700; letter-spacing: -0.025em; display: flex; align-items: center; gap: 0.5rem;">⚙️ Configure Options</h4>
                                <div class="field-label-section" style="margin-bottom: 1.5rem;">
                                    <label for="field-label-input" style="display: block; margin-bottom: 0.75rem; font-weight: 600; color: #374151; font-size: 0.95rem; text-transform: uppercase; letter-spacing: 0.025em;">Field Label: <span style="color: #ef4444; margin-left: 4px; font-weight: bold;">*</span></label>
                                    <input type="text" id="field-label-input" placeholder="Enter field label" value="" style="width: 100%; padding: 1.25rem; border: 2px solid #e5e7eb; border-radius: 12px; font-size: 1rem; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); background: white; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05); font-weight: 500; margin: 0; box-sizing: border-box;">
                                </div>
                                <div class="options-list" style="margin-bottom: 2rem;">
                                    <label style="display: block; margin-bottom: 0.75rem; font-weight: 600; color: #374151; font-size: 0.95rem; text-transform: uppercase; letter-spacing: 0.025em;">Options <span style="text-transform: none; color: #6b7280; font-weight: 400; font-size: 0.875rem;">(one per line)</span>:</label>
                                    <textarea id="options-textarea" rows="5" placeholder="Option 1&#10;Option 2&#10;Option 3" style="width: 100%; padding: 1.25rem; border: 2px solid #e5e7eb; border-radius: 12px; font-size: 1rem; resize: vertical; min-height: 160px; line-height: 1.7; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); background: white; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05); font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace; font-weight: 500; margin: 0; box-sizing: border-box;"></textarea>
                                </div>
                                <div class="modal-actions" style="display: flex; gap: 1rem; justify-content: flex-end; padding-top: 1rem; border-top: 1px solid #e5e7eb; margin-top: 1rem;">
                                    <button id="create-field-btn" class="btn btn-primary" style="padding: 1rem 2.5rem; font-weight: 600; font-size: 1rem; border-radius: 12px; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); min-width: 140px; justify-content: center; border: none; cursor: pointer; display: inline-flex; align-items: center; gap: 0.5rem; letter-spacing: 0.025em; text-decoration: none; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); color: white; box-shadow: 0 4px 14px rgba(59, 130, 246, 0.25);">Create Field</button>
                                    <button onclick="closeAddFieldDialog()" class="btn btn-secondary" style="padding: 1rem 2.5rem; font-weight: 600; font-size: 1rem; border-radius: 12px; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); min-width: 140px; justify-content: center; cursor: pointer; display: inline-flex; align-items: center; gap: 0.5rem; letter-spacing: 0.025em; text-decoration: none; background: white; color: #6b7280; border: 2px solid #e5e7eb; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);">Cancel</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            \`;

            // Add modal to page
            document.body.insertAdjacentHTML('beforeend', modalHtml);
            console.log('Modal HTML added to body');
            console.log('Modal element:', document.getElementById('add-field-modal'));

            // Add modal styles immediately after creating the modal
            addModalStyles();

            // Force apply critical styles directly to the created modal
            if (typeof applyModalStylesDirectly === 'function') {
                applyModalStylesDirectly();
            } else {
                console.log('applyModalStylesDirectly not available, using fallback...');
                // Apply basic modal styling as fallback
                if (typeof applyBasicModalStyling === 'function') {
                    applyBasicModalStyling();
                } else {
                    console.log('applyBasicModalStyling not available, applying inline styles...');
                    // Apply minimal inline styling
                    const modalElement = document.getElementById('add-field-modal');
                    if (modalElement) {
                        Object.assign(modalElement.style, {
                            position: 'fixed',
                            top: '0',
                            left: '0',
                            width: '100%',
                            height: '100%',
                            backgroundColor: 'rgba(0, 0, 0, 0.5)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            zIndex: '1000'
                        });

                        const modalContent = modalElement.querySelector('.modal');
                        if (modalContent) {
                            Object.assign(modalContent.style, {
                                background: 'white',
                                borderRadius: '12px',
                                boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
                                width: '90%',
                                maxWidth: '600px',
                                maxHeight: '90vh',
                                overflowY: 'auto'
                            });
                        }
                    }
                }
            }

            // Apply additional styling enhancements
            const modal = document.getElementById('add-field-modal');
            const optionsSection = document.getElementById('field-options-section');

            if (modal) {
                console.log('Applying enhanced modal styling...');

                // Style the field types grid
                const fieldTypes = modal.querySelector('.field-types');
                if (fieldTypes) {
                    Object.assign(fieldTypes.style, {
                        display: 'grid',
                        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                        gap: '1rem'
                    });
                }
            }

            // Add hover effects to buttons since inline styles can't handle :hover
            const addFieldModal = document.getElementById('add-field-modal');
            if (addFieldModal) {
                // Add hover effects for input and textarea focus
                const fieldLabelInput = document.getElementById('field-label-input');
                const optionsTextarea = document.getElementById('options-textarea');
                const createFieldBtn = document.getElementById('create-field-btn');
                const cancelBtn = addFieldModal.querySelector('.btn-secondary');

                if (fieldLabelInput) {
                    fieldLabelInput.addEventListener('focus', function() {
                        this.style.borderColor = '#3b82f6';
                        this.style.boxShadow = '0 0 0 4px rgba(59, 130, 246, 0.15), 0 4px 12px rgba(0, 0, 0, 0.1)';
                        this.style.background = '#fefefe';
                        this.style.transform = 'translateY(-1px)';
                    });
                    fieldLabelInput.addEventListener('blur', function() {
                        this.style.borderColor = '#e5e7eb';
                        this.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.05)';
                        this.style.background = 'white';
                        this.style.transform = 'translateY(0)';
                    });
                }

                if (optionsTextarea) {
                    optionsTextarea.addEventListener('focus', function() {
                        this.style.borderColor = '#3b82f6';
                        this.style.boxShadow = '0 0 0 4px rgba(59, 130, 246, 0.15), 0 4px 12px rgba(0, 0, 0, 0.1)';
                        this.style.background = '#fefefe';
                        this.style.transform = 'translateY(-1px)';
                    });
                    optionsTextarea.addEventListener('blur', function() {
                        this.style.borderColor = '#e5e7eb';
                        this.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.05)';
                        this.style.background = 'white';
                        this.style.transform = 'translateY(0)';
                    });
                }

                if (createFieldBtn) {
                    createFieldBtn.addEventListener('mouseenter', function() {
                        this.style.background = 'linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%)';
                        this.style.transform = 'translateY(-2px)';
                        this.style.boxShadow = '0 8px 25px rgba(59, 130, 246, 0.4)';
                    });
                    createFieldBtn.addEventListener('mouseleave', function() {
                        this.style.background = 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)';
                        this.style.transform = 'translateY(0)';
                        this.style.boxShadow = '0 4px 14px rgba(59, 130, 246, 0.25)';
                    });
                }

                if (cancelBtn) {
                    cancelBtn.addEventListener('mouseenter', function() {
                        this.style.background = '#f9fafb';
                        this.style.borderColor = '#d1d5db';
                        this.style.color = '#374151';
                        this.style.transform = 'translateY(-1px)';
                        this.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.1)';
                    });
                    cancelBtn.addEventListener('mouseleave', function() {
                        this.style.background = 'white';
                        this.style.borderColor = '#e5e7eb';
                        this.style.color = '#6b7280';
                        this.style.transform = 'translateY(0)';
                        this.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.05)';
                    });
                }
            }

            // Add event listeners to field type buttons
            const fieldTypeBtns = document.querySelectorAll('.field-type-btn');
            const optionsSectionElement = document.getElementById('field-options-section');
            const fieldLabelInputElement = document.getElementById('field-label-input');
            const optionsTextareaElement = document.getElementById('options-textarea');
            const createFieldBtn = document.getElementById('create-field-btn');

            // Style field type buttons
            if (fieldTypeBtns) {
                fieldTypeBtns.forEach(btn => {
                    Object.assign(btn.style, {
                        display: 'flex',
                        alignItems: 'center',
                        padding: '1.25rem',
                        border: '2px solid #e5e7eb',
                        background: 'white',
                        borderRadius: '12px',
                        cursor: 'pointer',
                        fontSize: '1rem',
                        fontWeight: '500',
                        gap: '0.75rem',
                        transition: 'all 0.2s ease'
                    });
                });
            }

            let selectedFieldType = null;

            fieldTypeBtns.forEach(btn => {
                btn.addEventListener('click', function() {
                    selectedFieldType = this.dataset.type;

                    // Reset previous selections
                    fieldTypeBtns.forEach(b => b.classList.remove('selected'));
                    this.classList.add('selected');

                    if (selectedFieldType === 'select' || selectedFieldType === 'radio') {
                        // Show options configuration for dropdown and radio
                        optionsSectionElement.style.display = 'block';

                        // Force apply the enhanced styling when section becomes visible
                        console.log('Applying enhanced styling to visible options section...');
                        if (typeof applyOptionsSeccionStyling === 'function') {
                            applyOptionsSeccionStyling(optionsSectionElement, fieldLabelInputElement, optionsTextareaElement);
                        } else {
                            console.log('applyOptionsSeccionStyling not available, using basic styling...');
                            // Apply basic styling inline
                            optionsSectionElement.style.background = 'linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%)';
                            optionsSectionElement.style.padding = '2rem 1.5rem';
                            optionsSectionElement.style.borderRadius = '0 0 12px 12px';
                            optionsSectionElement.style.borderTop = '2px solid #e5e7eb';
                            optionsSectionElement.style.marginTop = '2rem';
                        }

                        fieldLabelInputElement.value = selectedFieldType === 'select' ? 'New Dropdown' : 'New Radio Group';
                        optionsTextareaElement.value = 'Option 1' + String.fromCharCode(10) + 'Option 2' + String.fromCharCode(10) + 'Option 3';
                    } else {
                        // For other field types, create immediately
                        addNewField(selectedFieldType);
                        closeAddFieldDialog();
                    }
                });
            });

            // Handle create field button for fields with options
            if (createFieldBtn) {
                createFieldBtn.addEventListener('click', function() {
                    if (selectedFieldType === 'select' || selectedFieldType === 'radio') {
                        const fieldLabel = fieldLabelInputElement.value.trim() || (selectedFieldType === 'select' ? 'New Dropdown' : 'New Radio Group');
                        const optionsText = optionsTextareaElement.value.trim();
                        const options = optionsText ? optionsText.split(String.fromCharCode(10)).map(opt => opt.trim()).filter(opt => opt.length > 0) : ['Option 1', 'Option 2', 'Option 3'];

                        addNewFieldWithOptions(selectedFieldType, fieldLabel, options);
                        closeAddFieldDialog();
                    }
                });
            }

            // Add modal styles
            addModalStyles();
        }

        function closeAddFieldDialog() {
            const modal = document.getElementById('add-field-modal');
            if (modal) {
                modal.remove();
            }
        }

        function addNewFieldWithOptions(fieldType, fieldLabel, options) {
            // Generate new field with custom options for radio and select
            const fieldId = \`user_field_\${Date.now()}\`;
            const fieldName = \`user_field_\${Date.now()}\`;
            let fieldHtml = '';

            if (fieldType === 'select') {
                const optionsHtml = options.map(option =>
                    \`<option value="\${escapeHtml(option)}">\${escapeHtml(option)}</option>\`
                ).join('');

                fieldHtml = \`
                    <div class="editable-field-wrapper" data-field-type="select" draggable="true" id="editable_${fieldId}">
                        <div class="field-controls">
                            <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                            <button class="field-control-btn edit-options-btn" onclick="editFieldOptions(this)" title="Edit options">⋯</button>
                            <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                        </div>
                        <div class="editable-field" data-field-type="select" data-options='${JSON.stringify(options)}'>
                            <div class="form-field">
                                <label for="${fieldId}" class="form-label editable-label" contenteditable="true">${escapeHtml(fieldLabel)}</label>
                                <select id="${fieldId}" name="${fieldName}" class="editable-select">
                                    <option value="">Choose an option</option>
                                    ${optionsHtml}
                                </select>
                            </div>
                        </div>
                    </div>
                \`;
            } else if (fieldType === 'radio') {
                const radioButtonsHtml = options.map((option, index) =>
                    \`<label><input type="radio" name="\${fieldName}" value="\${escapeHtml(option)}"> \${escapeHtml(option)}</label>\`
                ).join('');

                fieldHtml = \`
                    <div class="editable-field-wrapper" data-field-type="radio" draggable="true" id="editable_${fieldId}">
                        <div class="field-controls">
                            <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                            <button class="field-control-btn edit-options-btn" onclick="editFieldOptions(this)" title="Edit options">⋯</button>
                            <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                        </div>
                        <div class="editable-field" data-field-type="radio" data-options='${JSON.stringify(options)}'>
                            <div class="form-field">
                                <div class="form-question editable-label" contenteditable="true">${escapeHtml(fieldLabel)}</div>
                                <div class="radio-options">
                                    ${radioButtonsHtml}
                                </div>
                            </div>
                        </div>
                    </div>
                \`;
            }

            // Add the field to the form
            addFieldToForm(fieldHtml);
        }

        function addNewField(fieldType) {
            // Generate new field HTML based on type
            const fieldId = \`user_field_\${Date.now()}\`;
            const fieldName = \`user_field_\${Date.now()}\`;

            let fieldHtml = '';

            switch (fieldType) {
                case 'text':
                    fieldHtml = \`
                        <div class="editable-field-wrapper" data-field-type="text" draggable="true" id="editable_${fieldId}">
                            <div class="field-controls">
                                <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                                <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                            </div>
                            <div class="editable-field" data-field-type="text">
                                <div class="form-field">
                                    <label for="${fieldId}" class="form-label editable-label" contenteditable="true">New Text Field</label>
                                    <input type="text" id="${fieldId}" name="${fieldName}" class="editable-input" placeholder="Enter text...">
                                </div>
                            </div>
                        </div>
                    \`;
                    break;
                case 'textarea':
                    fieldHtml = \`
                        <div class="editable-field-wrapper" data-field-type="textarea" draggable="true" id="editable_${fieldId}">
                            <div class="field-controls">
                                <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                                <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                            </div>
                            <div class="editable-field" data-field-type="textarea">
                                <div class="form-field">
                                    <label for="${fieldId}" class="form-label editable-label" contenteditable="true">New Text Area</label>
                                    <textarea id="${fieldId}" name="${fieldName}" class="editable-textarea" rows="4" placeholder="Enter text..."></textarea>
                                </div>
                            </div>
                        </div>
                    \`;
                    break;
                case 'select':
                    fieldHtml = \`
                        <div class="editable-field-wrapper" data-field-type="select" draggable="true" id="editable_${fieldId}">
                            <div class="field-controls">
                                <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                                <button class="field-control-btn edit-options-btn" onclick="editFieldOptions(this)" title="Edit options">⋯</button>
                                <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                            </div>
                            <div class="editable-field" data-field-type="select" data-options='["Option 1", "Option 2", "Option 3"]'>
                                <div class="form-field">
                                    <label for="${fieldId}" class="form-label editable-label" contenteditable="true">New Dropdown</label>
                                    <select id="${fieldId}" name="${fieldName}" class="editable-select">
                                        <option value="">Choose an option</option>
                                        <option value="Option 1">Option 1</option>
                                        <option value="Option 2">Option 2</option>
                                        <option value="Option 3">Option 3</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                    \`;
                    break;
                case 'radio':
                    fieldHtml = \`
                        <div class="editable-field-wrapper" data-field-type="radio" draggable="true" id="editable_${fieldId}">
                            <div class="field-controls">
                                <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                                <button class="field-control-btn edit-options-btn" onclick="editFieldOptions(this)" title="Edit options">⋯</button>
                                <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                            </div>
                            <div class="editable-field" data-field-type="radio" data-options='["Option 1", "Option 2", "Option 3"]'>
                                <div class="form-field">
                                    <div class="form-question editable-label" contenteditable="true">New Radio Group</div>
                                    <div class="radio-options">
                                        <label><input type="radio" name="${fieldName}" value="Option 1"> Option 1</label>
                                        <label><input type="radio" name="${fieldName}" value="Option 2"> Option 2</label>
                                        <label><input type="radio" name="${fieldName}" value="Option 3"> Option 3</label>
                                    </div>
                                </div>
                            </div>
                        </div>
                    \`;
                    break;
                case 'checkbox':
                    fieldHtml = \`
                        <div class="editable-field-wrapper" data-field-type="checkbox" draggable="true" id="editable_${fieldId}">
                            <div class="field-controls">
                                <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                                <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                            </div>
                            <div class="editable-field" data-field-type="checkbox">
                                <div class="form-field checkbox-field">
                                    <input type="checkbox" id="${fieldId}" name="${fieldName}" value="checked">
                                    <label for="${fieldId}" class="editable-label" contenteditable="true">New Checkbox</label>
                                </div>
                            </div>
                        </div>
                    \`;
                    break;
                case 'email':
                    fieldHtml = \`
                        <div class="editable-field-wrapper" data-field-type="email" draggable="true" id="editable_${fieldId}">
                            <div class="field-controls">
                                <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                                <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                            </div>
                            <div class="editable-field" data-field-type="email">
                                <div class="form-field">
                                    <label for="${fieldId}" class="form-label editable-label" contenteditable="true">Email Address</label>
                                    <input type="email" id="${fieldId}" name="${fieldName}" class="editable-input" placeholder="Enter email...">
                                </div>
                            </div>
                        </div>
                    \`;
                    break;
                case 'tel':
                    fieldHtml = \`
                        <div class="editable-field-wrapper" data-field-type="tel" draggable="true" id="editable_${fieldId}">
                            <div class="field-controls">
                                <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                                <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                            </div>
                            <div class="editable-field" data-field-type="tel">
                                <div class="form-field">
                                    <label for="${fieldId}" class="form-label editable-label" contenteditable="true">Phone Number</label>
                                    <input type="tel" id="${fieldId}" name="${fieldName}" class="editable-input" placeholder="Enter phone...">
                                </div>
                            </div>
                        </div>
                    \`;
                    break;
                case 'date':
                    fieldHtml = \`
                        <div class="editable-field-wrapper" data-field-type="date" draggable="true" id="editable_${fieldId}">
                            <div class="field-controls">
                                <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                                <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                            </div>
                            <div class="editable-field" data-field-type="date">
                                <div class="form-field">
                                    <label for="${fieldId}" class="form-label editable-label" contenteditable="true">Date</label>
                                    <input type="date" id="${fieldId}" name="${fieldName}" class="editable-input">
                                </div>
                            </div>
                        </div>
                    \`;
                    break;
                case 'number':
                    fieldHtml = \`
                        <div class="editable-field-wrapper" data-field-type="number" draggable="true" id="editable_${fieldId}">
                            <div class="field-controls">
                                <button class="field-control-btn edit-btn" onclick="editField('editable_${fieldId}')" title="Edit field">✏️</button>
                                <button class="field-control-btn delete-btn" onclick="deleteField(this)" title="Delete field">🗑️</button>
                            </div>
                            <div class="editable-field" data-field-type="number">
                                <div class="form-field">
                                    <label for="${fieldId}" class="form-label editable-label" contenteditable="true">Number</label>
                                    <input type="number" id="${fieldId}" name="${fieldName}" class="editable-input" placeholder="Enter number...">
                                </div>
                            </div>
                        </div>
                    \`;
                    break;
            }

            // Add the new field to the form
            const addButton = document.getElementById('add-field-button');
            if (addButton && addButton.parentNode) {
                addButton.parentNode.insertBefore(createElementFromHTML(fieldHtml), addButton);

                // Re-initialize drag and drop for the new field using mouse-based system
                const newField = addButton.previousElementSibling;
                addDragFunctionality(newField);

                // Initialize editing for new editable elements
                const editableElements = newField.querySelectorAll('[contenteditable="true"]');
                editableElements.forEach(element => {
                    element.addEventListener('blur', function() {
                        saveFormData();
                    });
                });

                // Auto-save after adding field
                saveFormData();
            }
        }

        function addFieldToForm(fieldHtml) {
            const addButton = document.getElementById('add-field-button');
            if (addButton && addButton.parentNode) {
                addButton.parentNode.insertBefore(createElementFromHTML(fieldHtml), addButton);
                // Re-initialize drag and drop for the new field using mouse-based system
                const newField = addButton.previousElementSibling;
                addDragFunctionality(newField);
                // Recreate drop indicators to include the new field
                createDropIndicators();
                // Initialize editing for new editable elements
                const editableElements = newField.querySelectorAll('[contenteditable="true"]');
                editableElements.forEach(element => {
                    element.addEventListener('blur', function() {
                        saveFormData();
                    });
                });
                // Auto-save after adding field
                saveFormData();
            }
        }

        function editFieldOptions(button) {
            // Find the wrapper first, then the field inside it
            const wrapper = button.closest('.editable-field-wrapper');
            const field = wrapper ? wrapper.querySelector('.editable-field') : button.closest('.editable-field');
            const fieldType = field.dataset.fieldType;

            if (fieldType !== 'select' && fieldType !== 'radio') {
                return; // Only works for select and radio fields
            }

            // Get current options
            let currentOptions = [];
            try {
                currentOptions = JSON.parse(field.dataset.options || '[]');
            } catch (e) {
                currentOptions = ['Option 1', 'Option 2', 'Option 3'];
            }

            // Get current label
            const currentLabel = field.querySelector('.editable-label').textContent.trim();

            // Prepare options text (avoiding template literal issues)
            const optionsText = currentOptions.join(String.fromCharCode(10));

            // Create options edit modal
            const modalHtml = \`
                <div id="edit-options-modal" class="options-modal-overlay">
                    <div class="options-modal">
                        <div class="options-modal-header">
                            <div class="options-modal-title">
                                <span class="options-modal-icon">${fieldType === 'select' ? '📋' : '⚪'}</span>
                                <h3>Edit ${fieldType === 'select' ? 'Dropdown' : 'Radio Group'}</h3>
                            </div>
                            <button class="options-close-btn" onclick="closeEditOptionsDialog()" title="Close">✕</button>
                        </div>
                        <div class="options-modal-body">
                            <div class="options-form-group">
                                <label for="edit-field-label-input" class="options-label">Field Label</label>
                                <input type="text" id="edit-field-label-input" class="options-input" value="${escapeHtml(currentLabel)}" placeholder="Enter field label">
                            </div>
                            <div class="options-form-group">
                                <label for="edit-options-textarea" class="options-label">Options</label>
                                <textarea id="edit-options-textarea" class="options-textarea" rows="5" placeholder="Enter one option per line">${optionsText}</textarea>
                                <div class="options-help">One option per line</div>
                            </div>
                        </div>
                        <div class="options-modal-footer">
                            <button onclick="closeEditOptionsDialog()" class="options-btn options-btn-cancel">Cancel</button>
                            <button id="update-options-btn" class="options-btn options-btn-primary">Update</button>
                        </div>
                    </div>
                </div>
            \`;

            // Add modal to page
            document.body.insertAdjacentHTML('beforeend', modalHtml);

            // Handle update button
            document.getElementById('update-options-btn').addEventListener('click', function() {
                const newLabel = document.getElementById('edit-field-label-input').value.trim();
                const optionsText = document.getElementById('edit-options-textarea').value.trim();
                const newOptions = optionsText ? optionsText.split(String.fromCharCode(10)).map(opt => opt.trim()).filter(opt => opt.length > 0) : ['Option 1'];

                updateFieldOptions(field, newLabel, newOptions);
                closeEditOptionsDialog();
            });

            // Add modal styles if not already present
            addModalStyles();
        }

        function updateFieldOptions(field, newLabel, newOptions) {
            const fieldType = field.dataset.fieldType;
            const fieldId = field.querySelector('input, select').id;
            const fieldName = field.querySelector('input, select').name;

            // Update label
            const labelElement = field.querySelector('.editable-label');
            labelElement.textContent = newLabel;

            // Update options data attribute
            field.dataset.options = JSON.stringify(newOptions);

            if (fieldType === 'select') {
                // Update select options
                const selectElement = field.querySelector('select');
                selectElement.innerHTML = '<option value="">Choose an option</option>' +
                    newOptions.map(option => `<option value="${escapeHtml(option)}">${escapeHtml(option)}</option>`).join('');
            } else if (fieldType === 'radio') {
                // Update radio buttons
                const radioContainer = field.querySelector('.radio-options');
                radioContainer.innerHTML = newOptions.map(option =>
                    \`<label><input type="radio" name="\${fieldName}" value="\${escapeHtml(option)}"> \${escapeHtml(option)}</label>\`
                ).join('');
            }

            // Auto-save changes
            saveFormData();
        }

        function closeEditOptionsDialog() {
            const modal = document.getElementById('edit-options-modal');
            if (modal) {
                modal.remove();
            }
        }

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        function editField(fieldId) {
            const fieldWrapper = document.getElementById(fieldId);
            if (!fieldWrapper) return;

            // Get the actual field element (may be the wrapper or inner field)
            const field = fieldWrapper.querySelector('.editable-field') || fieldWrapper;
            const fieldType = field.dataset.fieldType || fieldWrapper.dataset.fieldType;

            // For radio and select fields, use the options editor
            if (fieldType === 'select' || fieldType === 'radio') {
                const editBtn = fieldWrapper.querySelector('.edit-options-btn');
                if (editBtn) {
                    editFieldOptions(editBtn);
                }
                return;
            }

            // For other field types, make the label editable and focus it
            const label = field.querySelector('.editable-label');
            if (label) {
                label.focus();
                // Select all text for easy editing
                if (window.getSelection && document.createRange) {
                    const range = document.createRange();
                    range.selectNodeContents(label);
                    const selection = window.getSelection();
                    selection.removeAllRanges();
                    selection.addRange(range);
                }
            }
        }

        function createElementFromHTML(htmlString) {
            const div = document.createElement('div');
            div.innerHTML = htmlString.trim();
            return div.firstChild;
        }

        function deleteField(button) {
            if (confirm('Are you sure you want to delete this field?')) {
                // Look for the wrapper first, then fall back to the field
                const wrapper = button.closest('.editable-field-wrapper');
                const elementToRemove = wrapper || button.closest('.editable-field');
                if (elementToRemove) {
                    elementToRemove.remove();
                    saveFormData();
                }
            }
        }

        function removeField(button) {
            if (confirm('Remove this field?')) {
                const field = button.closest('.editable-field');
                if (field) {
                    field.remove();
                    saveFormData();
                }
            }
        }

        function clearAllFields() {
            if (confirm('Are you sure you want to clear all content? This will remove all fields, labels, titles, radio buttons, checkboxes, and text. This action cannot be undone.')) {
                // Clear all editable fields (form inputs, radio groups, checkboxes, etc.)
                const allFields = document.querySelectorAll('.editable-field');

                // Clear all field wrappers
                const allWrappers = document.querySelectorAll('.editable-field-wrapper');

                // Clear all form field containers and elements
                const allFormFields = document.querySelectorAll('.form-field, .radio-field, .checkbox-field, .radio-fieldset');

                // Clear all other content including titles, labels, and text sections
                const allContent = document.querySelectorAll('.form-title, .form-section, .form-question, .form-label, .editable-title, [contenteditable="true"]');

                // Clear individual form inputs that might not be wrapped
                const allInputs = document.querySelectorAll('input, textarea, select, .radio-options, .radio-option');

                console.log(\`🗑️ Clearing \${allFields.length} editable fields, \${allWrappers.length} wrappers, \${allFormFields.length} form fields, \${allContent.length} content elements, and \${allInputs.length} individual inputs\`);

                // Remove all editable fields first (these are the main containers)
                allFields.forEach(field => {
                    field.remove();
                });

                // Remove all field wrappers
                allWrappers.forEach(wrapper => {
                    if (wrapper.parentNode) {
                        wrapper.remove();
                    }
                });

                // Remove all form field containers
                allFormFields.forEach(field => {
                    // Only remove if it wasn't already removed as part of an editable field
                    if (field.parentNode) {
                        field.remove();
                    }
                });

                // Remove all other content elements
                allContent.forEach(element => {
                    // Only remove if it's not inside a field we already removed and still exists
                    if (element.parentNode && !element.closest('.editable-field')) {
                        element.remove();
                    }
                });

                // Remove any remaining individual inputs
                allInputs.forEach(input => {
                    // Only remove if it's not inside a field we already removed and still exists
                    if (input.parentNode && !input.closest('.editable-field, .form-field')) {
                        input.remove();
                    }
                });

                // Force save the cleared state to backend (bypass the drag skip logic)
                saveFormDataForced();

                // Show confirmation
                showNotification('All content has been cleared', 'success');
            }
        }

        function openShareDialog() {
            // Reuse the share dialog from standard JavaScript
            if (!window.documentId) {
                alert('Document ID not available');
                return;
            }
            // Implementation would be similar to standard JavaScript version
            console.log('Share dialog for editing mode');
        }

        function showNotification(message, type = 'info') {
            // Create notification element
            const notification = document.createElement('div');
            notification.className = \`notification notification-\${type}\`;
            notification.textContent = message;

            // Add to page
            document.body.appendChild(notification);

            // Auto-remove after 3 seconds
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 3000);
        }

        function addModalStyles() {
            // Remove existing modal styles if they exist
            const existingStyles = document.getElementById('modal-styles');
            if (existingStyles) {
                console.log('Removing existing modal styles...');
                existingStyles.remove();
            }

            console.log('Adding fresh modal styles...');
            console.log('Current document head:', document.head);
            console.log('About to add styles to head...');
            const styles = \`
                <style id="modal-styles">
                    /* Editing mode specific styles - ensure left alignment */
                    body.editing-mode .form-field,
                    body.editing-mode .radio-field,
                    body.editing-mode .form-section {
                        text-align: left !important;
                    }

                    body.editing-mode .form-field *,
                    body.editing-mode .radio-field *,
                    body.editing-mode .form-section * {
                        text-align: left !important;
                    }

                    /* Override any centering that might be inherited */
                    .form-field, .radio-field, .form-section {
                        text-align: left !important;
                    }

                    .form-field *, .radio-field *, .form-section * {
                        text-align: left !important;
                    }
                    .modal-overlay {
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
                    .modal {
                        background: white;
                        border-radius: 12px;
                        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
                        width: 90%;
                        max-width: 600px;
                        max-height: 90vh;
                        overflow-y: auto;
                    }
                    .modal-header {
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        padding: 1.5rem;
                        border-bottom: 1px solid #e5e7eb;
                    }
                    .modal-header h3 {
                        margin: 0;
                        font-size: 1.25rem;
                        font-weight: 600;
                        color: #111827;
                    }
                    .close-btn {
                        background: none;
                        border: none;
                        font-size: 1.5rem;
                        cursor: pointer;
                        color: #6b7280;
                        padding: 0.25rem;
                        border-radius: 0.375rem;
                    }
                    .close-btn:hover {
                        background-color: #f3f4f6;
                        color: #111827;
                    }
                    .modal-body {
                        padding: 1.5rem;
                    }
                    .field-types {
                        display: grid;
                        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                        gap: 1rem;
                    }
                    .field-type-btn {
                        display: flex;
                        align-items: center;
                        padding: 1.25rem;
                        border: 2px solid #e5e7eb;
                        background: white;
                        border-radius: 12px;
                        cursor: pointer;
                        transition: all 0.2s ease;
                        font-size: 1rem;
                        text-align: left;
                        font-weight: 500;
                    }

                    /* Enhanced Options Modal Styles */
                    .options-modal-overlay {
                        position: fixed;
                        top: 0;
                        left: 0;
                        right: 0;
                        bottom: 0;
                        background: rgba(0, 0, 0, 0.4);
                        backdrop-filter: blur(8px);
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        z-index: 1000;
                        animation: fadeIn 0.2s ease-out;
                    }

                    @keyframes fadeIn {
                        from { opacity: 0; }
                        to { opacity: 1; }
                    }

                    @keyframes slideIn {
                        from {
                            opacity: 0;
                            transform: translateY(-20px) scale(0.95);
                        }
                        to {
                            opacity: 1;
                            transform: translateY(0) scale(1);
                        }
                    }

                    .options-modal {
                        background: white;
                        border-radius: 16px;
                        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
                        width: 90%;
                        max-width: 480px;
                        max-height: 90vh;
                        overflow: hidden;
                        animation: slideIn 0.3s ease-out;
                        border: 1px solid #f1f5f9;
                    }

                    .options-modal-header {
                        display: flex;
                        align-items: center;
                        justify-content: space-between;
                        padding: 1.5rem 2rem;
                        border-bottom: 1px solid #f1f5f9;
                        background: linear-gradient(135deg, #fafbfc 0%, #f8fafc 100%);
                    }

                    .options-modal-title {
                        display: flex;
                        align-items: center;
                        gap: 0.75rem;
                    }

                    .options-modal-icon {
                        font-size: 1.25rem;
                    }

                    .options-modal-title h3 {
                        margin: 0;
                        font-size: 1.125rem;
                        font-weight: 600;
                        color: #1f2937;
                        letter-spacing: -0.025em;
                    }

                    .options-close-btn {
                        background: none;
                        border: none;
                        font-size: 1.25rem;
                        cursor: pointer;
                        color: #6b7280;
                        padding: 0.5rem;
                        border-radius: 8px;
                        transition: all 0.2s ease;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        width: 2rem;
                        height: 2rem;
                    }

                    .options-close-btn:hover {
                        background-color: #f3f4f6;
                        color: #374151;
                    }

                    .options-modal-body {
                        padding: 2rem;
                    }

                    .options-form-group {
                        margin-bottom: 1.5rem;
                    }

                    .options-form-group:last-child {
                        margin-bottom: 0;
                    }

                    .options-label {
                        display: block;
                        margin-bottom: 0.75rem;
                        font-weight: 500;
                        color: #374151;
                        font-size: 0.875rem;
                        text-transform: uppercase;
                        letter-spacing: 0.05em;
                    }

                    .options-input,
                    .options-textarea {
                        width: 100%;
                        padding: 0.875rem 1rem;
                        border: 1.5px solid #e5e7eb;
                        border-radius: 12px;
                        font-size: 0.925rem;
                        transition: all 0.2s ease;
                        background: white;
                        box-sizing: border-box;
                        font-family: inherit;
                    }

                    .options-input:focus,
                    .options-textarea:focus {
                        outline: none;
                        border-color: #3b82f6;
                        box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
                    }

                    .options-textarea {
                        resize: vertical;
                        min-height: 120px;
                        line-height: 1.5;
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    }

                    .options-help {
                        margin-top: 0.5rem;
                        font-size: 0.8rem;
                        color: #6b7280;
                        font-style: italic;
                    }

                    .options-modal-footer {
                        padding: 1.5rem 2rem;
                        background: #fafbfc;
                        border-top: 1px solid #f1f5f9;
                        display: flex;
                        justify-content: flex-end;
                        gap: 0.75rem;
                    }

                    .options-btn {
                        padding: 0.75rem 1.5rem;
                        border: none;
                        border-radius: 8px;
                        font-size: 0.875rem;
                        font-weight: 500;
                        cursor: pointer;
                        transition: all 0.2s ease;
                        min-width: 80px;
                        display: inline-flex;
                        align-items: center;
                        justify-content: center;
                    }

                    .options-btn-cancel {
                        background: white;
                        color: #6b7280;
                        border: 1px solid #d1d5db;
                    }

                    .options-btn-cancel:hover {
                        background: #f9fafb;
                        color: #374151;
                    }

                    .options-btn-primary {
                        background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
                        color: white;
                        box-shadow: 0 2px 4px rgba(59, 130, 246, 0.2);
                    }

                    .options-btn-primary:hover {
                        background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
                        box-shadow: 0 4px 8px rgba(59, 130, 246, 0.3);
                    }
                    .field-type-btn:hover {
                        border-color: #3b82f6;
                        background-color: #eff6ff;
                        transform: translateY(-1px);
                        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                    }
                    .field-type-btn:active {
                        transform: translateY(0);
                    }
                    .notification {
                        position: fixed;
                        top: 20px;
                        right: 20px;
                        padding: 1rem 1.5rem;
                        border-radius: 8px;
                        color: white;
                        font-weight: 500;
                        z-index: 1001;
                        animation: slideIn 0.3s ease-out;
                    }
                    .notification-success {
                        background-color: #10b981;
                    }
                    .notification-error {
                        background-color: #ef4444;
                    }
                    .notification-info {
                        background-color: #3b82f6;
                    }
                    @keyframes slideIn {
                        from { transform: translateX(100%); opacity: 0; }
                        to { transform: translateX(0); opacity: 1; }
                    }

                    /* Drag and Drop Styles */
                    .drop-zone {
                        min-height: 80px;
                        border: 3px dashed #94a3b8;
                        border-radius: 12px;
                        background-color: #f1f5f9;
                        margin: 12px 0;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        transition: all 0.3s ease;
                        opacity: 0.9;
                        position: relative;
                        z-index: 100;
                    }

                    .drop-zone.active {
                        border-color: #3b82f6;
                        background-color: #dbeafe;
                        opacity: 1;
                        transform: scale(1.05);
                        box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2);
                    }

                    .drop-zone-content {
                        text-align: center;
                        color: #475569;
                        font-size: 16px;
                        font-weight: 500;
                    }

                    .drop-zone.active .drop-zone-content {
                        color: #3b82f6;
                        font-weight: 500;
                    }

                    .drop-zone-icon {
                        font-size: 18px;
                        margin-bottom: 4px;
                        display: block;
                    }

                    .drop-zone-text {
                        font-weight: 600;
                        margin-bottom: 4px;
                        font-size: 18px;
                        letter-spacing: 0.5px;
                    }

                    .drop-zone-subtext {
                        font-size: 13px;
                        opacity: 0.7;
                        font-weight: 400;
                    }

                    .drop-line {
                        min-height: 40px;
                        background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%);
                        border: 2px dashed #64748b;
                        border-radius: 8px;
                        margin: 8px 0;
                        transition: all 0.3s ease;
                        opacity: 0.8;
                        position: relative;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                    }

                    .drop-line:before {
                        content: "DRAG YOUR ELEMENT HERE";
                        color: #64748b;
                        font-size: 14px;
                        font-weight: 600;
                        letter-spacing: 0.5px;
                        text-align: center;
                    }

                    .drop-line.active {
                        background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
                        border-color: #3b82f6;
                        min-height: 50px;
                        opacity: 1;
                        transform: scale(1.02);
                        box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2);
                    }

                    .drop-line.active:before {
                        color: #3b82f6;
                        font-size: 16px;
                    }

                    .drag-over {
                        border: 2px solid #3b82f6 !important;
                        background-color: #eff6ff !important;
                        transform: scale(1.01);
                        transition: all 0.2s ease;
                    }

                    .dragging-active {
                        cursor: grabbing !important;
                    }

                    .dragging-active * {
                        cursor: grabbing !important;
                    }

                    .drop-zone-indicator {
                        pointer-events: none;
                        user-select: none;
                    }
                </style>
            \`;
            document.head.insertAdjacentHTML('beforeend', styles);
        }

    </script>
    """
  end
end