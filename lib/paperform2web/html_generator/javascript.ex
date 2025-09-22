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
            fetch(`/api/documents/${window.documentId}/share`, {
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

            const styles = `
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
                        background: #3b82f6;
                        color: white;
                        border: none;
                        border-radius: 50%;
                        width: 24px;
                        height: 24px;
                        cursor: pointer;
                        font-size: 12px;
                        display: inline-flex;
                        align-items: center;
                        justify-content: center;
                        margin-left: 8px;
                        transition: all 0.2s ease;
                    }
                    .edit-options-btn:hover {
                        background: #2563eb;
                        transform: scale(1.1);
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
            `;
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
                endpoint = `/api/share/${shareToken}/response`;
                payload = {
                    response_data: {
                        form_data: formData,
                        is_completed: true,
                        completion_time_seconds: calculateCompletionTime()
                    }
                };
            } else {
                // Test submission for preview mode
                endpoint = `/api/documents/${documentId}/test-submission`;
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
            const label = document.querySelector(`label[for="${field.id}"]`);
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

            statusDiv.className = `form-status ${type}`;
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

            // Load existing form data
            loadFormData();

            // Auto-save changes
            setupAutoSave();
        }

        function initializeDragAndDrop() {
            // Make all form fields draggable
            const formFields = document.querySelectorAll('.editable-field');
            formFields.forEach(field => {
                field.draggable = true;
                field.addEventListener('dragstart', handleDragStart);
                field.addEventListener('dragover', handleDragOver);
                field.addEventListener('drop', handleDrop);
                field.addEventListener('dragend', handleDragEnd);
            });
        }

        function handleDragStart(e) {
            draggedElement = this;
            this.style.opacity = '0.5';
        }

        function handleDragOver(e) {
            e.preventDefault();
        }

        function handleDrop(e) {
            e.preventDefault();
            if (draggedElement !== this) {
                const draggedIndex = Array.from(this.parentNode.children).indexOf(draggedElement);
                const targetIndex = Array.from(this.parentNode.children).indexOf(this);

                if (draggedIndex < targetIndex) {
                    this.parentNode.insertBefore(draggedElement, this.nextSibling);
                } else {
                    this.parentNode.insertBefore(draggedElement, this);
                }
                saveFormStructure();
            }
        }

        function handleDragEnd(e) {
            this.style.opacity = '';
            draggedElement = null;
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
            // Load form data from server or localStorage
            const documentId = '#{document_id}';
            if (documentId) {
                // In a real implementation, you'd load from server
                console.log('Loading form data for document:', documentId);
            }
        }

        function saveFormData() {
            // Auto-save form data with slight delay to ensure DOM is updated
            setTimeout(() => {
                const documentId = '#{document_id}';
                if (documentId) {
                    // Collect current form state
                    const formState = collectCurrentFormState();

                    // Save to server (simplified - you'd implement proper API calls)
                    console.log('Auto-saving form data:', formState);
                }
            }, 100); // Small delay to ensure DOM is updated
        }

        function saveFormStructure() {
            // Save the current structure after drag and drop
            saveFormData();
        }

        function setupAutoSave() {
            // Auto-save every 30 seconds
            setInterval(saveFormData, 30000);
        }

        function collectCurrentFormState() {
            const formFields = document.querySelectorAll('.editable-field');
            const state = [];

            console.log('🔍 COLLECTING FORM STATE - Found fields:', formFields.length);

            // Additional debugging to understand DOM state
            console.log('🔍 DOM DEBUG INFO:');
            console.log('  - Document ready state:', document.readyState);
            console.log('  - Body exists:', !!document.body);
            console.log('  - All divs:', document.querySelectorAll('div').length);
            console.log('  - Elements with editable-field class:', document.querySelectorAll('.editable-field').length);
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

            formFields.forEach((field, index) => {
                const fieldType = field.dataset.fieldType || 'text';
                const fieldName = field.querySelector('input, textarea, select')?.name || `field_${index}`;
                const fieldContent = field.querySelector('.editable-label')?.textContent ||
                                   field.querySelector('label')?.textContent ||
                                   'Untitled Field';

                // Collect options for select and radio fields
                let options = [];
                if (fieldType === 'select' || fieldType === 'radio') {
                    try {
                        options = JSON.parse(field.dataset.options || '[]');
                    } catch (e) {
                        // Fallback: extract options from HTML
                        if (fieldType === 'select') {
                            const selectOptions = field.querySelectorAll('select option:not([value=""])');
                            options = Array.from(selectOptions).map(opt => opt.textContent.trim());
                        } else if (fieldType === 'radio') {
                            const radioInputs = field.querySelectorAll('input[type="radio"]');
                            options = Array.from(radioInputs).map(input => input.value);
                        }
                    }
                }

                const fieldData = {
                    index: index,
                    type: 'form_input',  // Mark as form input so it gets processed correctly
                    content: fieldContent,
                    id: field.id,
                    metadata: {
                        input_type: fieldType,  // Store the actual field type here
                        field_name: fieldName,
                        required: field.dataset.required === 'true',
                        options: options.length > 0 ? options : undefined  // Only include options if they exist
                    }
                };

                // Debug logging for radio fields
                if (fieldType === 'radio') {
                    console.log('📻 RADIO FIELD DETECTED:', {
                        fieldType,
                        fieldName,
                        fieldContent,
                        options,
                        dataOptions: field.dataset.options,
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
            fetch(`/api/documents/${documentId}`, {
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

            fetch(`/api/documents/${documentId}`, {
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
            const modalHtml = `
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
            `;

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
            const fieldId = `user_field_${Date.now()}`;
            const fieldName = `user_field_${Date.now()}`;
            let fieldHtml = '';

            if (fieldType === 'select') {
                const optionsHtml = options.map(option =>
                    `<option value="${escapeHtml(option)}">${escapeHtml(option)}</option>`
                ).join('');

                fieldHtml = `
                    <div class="editable-field" data-field-type="select" draggable="true" id="editable_${fieldId}" data-options='${JSON.stringify(options)}'>
                        <div class="form-field">
                            <label for="${fieldId}" class="form-label editable-label" contenteditable="true">${escapeHtml(fieldLabel)}</label>
                            <select id="${fieldId}" name="${fieldName}" class="editable-select">
                                <option value="">Choose an option</option>
                                ${optionsHtml}
                            </select>
                            <button class="edit-options-btn" onclick="editFieldOptions(this)" title="Edit options">⚙️</button>
                            <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                        </div>
                    </div>
                `;
            } else if (fieldType === 'radio') {
                const radioButtonsHtml = options.map((option, index) =>
                    `<label><input type="radio" name="${fieldName}" value="${escapeHtml(option)}"> ${escapeHtml(option)}</label>`
                ).join('');

                fieldHtml = `
                    <div class="editable-field" data-field-type="radio" draggable="true" id="editable_${fieldId}" data-options='${JSON.stringify(options)}'>
                        <div class="form-field">
                            <div class="form-question editable-label" contenteditable="true">${escapeHtml(fieldLabel)}</div>
                            <div class="radio-options">
                                ${radioButtonsHtml}
                            </div>
                            <button class="edit-options-btn" onclick="editFieldOptions(this)" title="Edit options">⚙️</button>
                            <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                        </div>
                    </div>
                `;
            }

            // Add the field to the form
            addFieldToForm(fieldHtml);
        }

        function addNewField(fieldType) {
            // Generate new field HTML based on type
            const fieldId = `user_field_${Date.now()}`;
            const fieldName = `user_field_${Date.now()}`;

            let fieldHtml = '';

            switch (fieldType) {
                case 'text':
                    fieldHtml = `
                        <div class="editable-field" data-field-type="text" draggable="true" id="editable_${fieldId}">
                            <div class="form-field">
                                <label for="${fieldId}" class="form-label editable-label" contenteditable="true">New Text Field</label>
                                <input type="text" id="${fieldId}" name="${fieldName}" class="editable-input" placeholder="Enter text...">
                                <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                            </div>
                        </div>
                    `;
                    break;
                case 'textarea':
                    fieldHtml = `
                        <div class="editable-field" data-field-type="textarea" draggable="true" id="editable_${fieldId}">
                            <div class="form-field">
                                <label for="${fieldId}" class="form-label editable-label" contenteditable="true">New Text Area</label>
                                <textarea id="${fieldId}" name="${fieldName}" class="editable-textarea" rows="4" placeholder="Enter text..."></textarea>
                                <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                            </div>
                        </div>
                    `;
                    break;
                case 'select':
                    fieldHtml = `
                        <div class="editable-field" data-field-type="select" draggable="true" id="editable_${fieldId}" data-options='["Option 1", "Option 2", "Option 3"]'>
                            <div class="form-field">
                                <label for="${fieldId}" class="form-label editable-label" contenteditable="true">New Dropdown</label>
                                <select id="${fieldId}" name="${fieldName}" class="editable-select">
                                    <option value="">Choose an option</option>
                                    <option value="Option 1">Option 1</option>
                                    <option value="Option 2">Option 2</option>
                                    <option value="Option 3">Option 3</option>
                                </select>
                                <button class="edit-options-btn" onclick="editFieldOptions(this)" title="Edit options">⚙️</button>
                                <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                            </div>
                        </div>
                    `;
                    break;
                case 'radio':
                    fieldHtml = `
                        <div class="editable-field" data-field-type="radio" draggable="true" id="editable_${fieldId}" data-options='["Option 1", "Option 2", "Option 3"]'>
                            <div class="form-field">
                                <div class="form-question editable-label" contenteditable="true">New Radio Group</div>
                                <div class="radio-options">
                                    <label><input type="radio" name="${fieldName}" value="Option 1"> Option 1</label>
                                    <label><input type="radio" name="${fieldName}" value="Option 2"> Option 2</label>
                                    <label><input type="radio" name="${fieldName}" value="Option 3"> Option 3</label>
                                </div>
                                <button class="edit-options-btn" onclick="editFieldOptions(this)" title="Edit options">⚙️</button>
                                <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                            </div>
                        </div>
                    `;
                    break;
                case 'checkbox':
                    fieldHtml = `
                        <div class="editable-field" data-field-type="checkbox" draggable="true" id="editable_${fieldId}">
                            <div class="form-field checkbox-field">
                                <input type="checkbox" id="${fieldId}" name="${fieldName}" value="checked">
                                <label for="${fieldId}" class="editable-label" contenteditable="true">New Checkbox</label>
                                <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                            </div>
                        </div>
                    `;
                    break;
                case 'email':
                    fieldHtml = `
                        <div class="editable-field" data-field-type="email" draggable="true" id="editable_${fieldId}">
                            <div class="form-field">
                                <label for="${fieldId}" class="form-label editable-label" contenteditable="true">Email Address</label>
                                <input type="email" id="${fieldId}" name="${fieldName}" class="editable-input" placeholder="Enter email...">
                                <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                            </div>
                        </div>
                    `;
                    break;
                case 'tel':
                    fieldHtml = `
                        <div class="editable-field" data-field-type="tel" draggable="true" id="editable_${fieldId}">
                            <div class="form-field">
                                <label for="${fieldId}" class="form-label editable-label" contenteditable="true">Phone Number</label>
                                <input type="tel" id="${fieldId}" name="${fieldName}" class="editable-input" placeholder="Enter phone...">
                                <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                            </div>
                        </div>
                    `;
                    break;
                case 'date':
                    fieldHtml = `
                        <div class="editable-field" data-field-type="date" draggable="true" id="editable_${fieldId}">
                            <div class="form-field">
                                <label for="${fieldId}" class="form-label editable-label" contenteditable="true">Date</label>
                                <input type="date" id="${fieldId}" name="${fieldName}" class="editable-input">
                                <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                            </div>
                        </div>
                    `;
                    break;
                case 'number':
                    fieldHtml = `
                        <div class="editable-field" data-field-type="number" draggable="true" id="editable_${fieldId}">
                            <div class="form-field">
                                <label for="${fieldId}" class="form-label editable-label" contenteditable="true">Number</label>
                                <input type="number" id="${fieldId}" name="${fieldName}" class="editable-input" placeholder="Enter number...">
                                <button class="delete-field-btn" onclick="deleteField(this)">🗑️</button>
                            </div>
                        </div>
                    `;
                    break;
            }

            // Add the new field to the form
            const addButton = document.getElementById('add-field-button');
            if (addButton && addButton.parentNode) {
                addButton.parentNode.insertBefore(createElementFromHTML(fieldHtml), addButton);

                // Re-initialize drag and drop for the new field
                const newField = addButton.previousElementSibling;
                newField.addEventListener('dragstart', handleDragStart);
                newField.addEventListener('dragover', handleDragOver);
                newField.addEventListener('drop', handleDrop);
                newField.addEventListener('dragend', handleDragEnd);

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
                // Re-initialize drag and drop for the new field
                const newField = addButton.previousElementSibling;
                newField.addEventListener('dragstart', handleDragStart);
                newField.addEventListener('dragover', handleDragOver);
                newField.addEventListener('drop', handleDrop);
                newField.addEventListener('dragend', handleDragEnd);
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
            const field = button.closest('.editable-field');
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
            const modalHtml = `
                <div id="edit-options-modal" class="modal-overlay">
                    <div class="modal">
                        <div class="modal-header">
                            <h3>Edit ${fieldType === 'select' ? 'Dropdown' : 'Radio Group'} Options</h3>
                            <button class="close-btn" onclick="closeEditOptionsDialog()">&times;</button>
                        </div>
                        <div class="modal-body">
                            <div class="field-label-section">
                                <label for="edit-field-label-input">Field Label:</label>
                                <input type="text" id="edit-field-label-input" value="${escapeHtml(currentLabel)}">
                            </div>
                            <div class="options-list">
                                <label>Options (one per line):</label>
                                <textarea id="edit-options-textarea" rows="6">${optionsText}</textarea>
                            </div>
                            <div class="modal-actions">
                                <button id="update-options-btn" class="btn btn-primary">Update Options</button>
                                <button onclick="closeEditOptionsDialog()" class="btn btn-secondary">Cancel</button>
                            </div>
                        </div>
                    </div>
                </div>
            `;

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
                    `<label><input type="radio" name="${fieldName}" value="${escapeHtml(option)}"> ${escapeHtml(option)}</label>`
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
            const field = document.getElementById(fieldId);
            if (!field) return;

            const fieldType = field.dataset.fieldType;

            // For radio and select fields, use the options editor
            if (fieldType === 'select' || fieldType === 'radio') {
                const editBtn = field.querySelector('.edit-options-btn');
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
                const field = button.closest('.editable-field');
                if (field) {
                    field.remove();
                    saveFormData();
                }
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
            notification.className = `notification notification-${type}`;
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
            const styles = `
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
                        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
                        position: relative;
                        justify-content: flex-start;
                        gap: 0.75rem;
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
                    .delete-field-btn {
                        position: absolute;
                        top: 5px;
                        right: 5px;
                        background: #ef4444;
                        color: white;
                        border: none;
                        border-radius: 50%;
                        width: 24px;
                        height: 24px;
                        cursor: pointer;
                        font-size: 12px;
                        display: none;
                    }
                    .editable-field {
                        position: relative;
                        border: 2px dashed transparent;
                        padding: 10px;
                        margin: 5px 0;
                        transition: all 0.2s;
                    }
                    .editable-field:hover {
                        border-color: #3b82f6;
                        background-color: #eff6ff;
                    }
                    .editable-field:hover .delete-field-btn {
                        display: block;
                    }
                </style>
            `;
            document.head.insertAdjacentHTML('beforeend', styles);
        }

    </script>
    """
  end
end