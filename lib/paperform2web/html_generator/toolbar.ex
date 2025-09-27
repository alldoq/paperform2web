defmodule Paperform2web.HtmlGenerator.Toolbar do
  @moduledoc """
  Toolbar generation functionality for HTML documents.
  Provides editing and preview mode toolbars with styling.
  """

  @doc """
  Generates the appropriate toolbar based on editing mode.
  """
  def generate_toolbar(editing_mode, document_id) do
    if editing_mode do
      generate_editing_toolbar(document_id)
    else
      generate_preview_toolbar(document_id)
    end
  end

  @doc """
  Generates the preview mode toolbar.
  """
  def generate_preview_toolbar(_document_id) do
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

  @doc """
  Generates the editing mode toolbar.
  """
  def generate_editing_toolbar(_document_id) do
    """
    <div class="editing-toolbar">
        <div class="toolbar-content">
            <h3>Form Editor</h3>
            <div class="toolbar-actions">
                <button id="switch-to-preview" class="btn btn-secondary">Switch to Preview</button>
                <button id="save-form" class="btn btn-primary">Save Changes</button>
                <button id="reset-form" class="btn btn-secondary">Reset</button>
                <button id="add-field" class="btn btn-secondary">Add Field</button>
                #{generate_style_selector()}
            </div>
        </div>
    </div>
    """
  end

  @doc """
  Generates the theme style selector dropdown.
  """
  def generate_style_selector do
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

  @doc """
  Generates CSS styles for toolbars and editing interface.
  """
  def generate_editing_css do
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

        .editing-mode .container {
            margin-top: 80px;
        }

        /* Editable Field Styles */
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

        /* Disable hover effects during drag operations to prevent double borders */
        .dragging-active .editable-field-wrapper:hover {
            border-color: transparent !important;
            background: transparent !important;
        }

        .editable-field-wrapper.dragging {
            transform: rotate(2deg);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
            z-index: 100;
        }

        /* CSS drag handle removed - using JavaScript-created handle instead */

        .field-controls {
            position: absolute;
            top: -8px;
            right: -8px;
            display: flex;
            gap: 0.5rem;
            opacity: 0;
            transition: opacity 0.2s ease;
            z-index: 50;
        }

        .editable-field-wrapper:hover .field-controls,
        .editable-field:hover .field-controls {
            opacity: 1;
        }

        .field-control-btn {
            width: 20px;
            height: 20px;
            border-radius: 4px;
            border: 1px solid #d1d5db;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 11px;
            font-weight: 500;
            transition: all 0.2s ease;
            background: white;
            color: #6b7280;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .field-control-btn:hover {
            border-color: #9ca3af;
            color: #374151;
            transform: translateY(-1px);
            box-shadow: 0 2px 6px rgba(0,0,0,0.15);
        }

        .remove-field-btn {
            color: #dc2626 !important;
            border-color: #fecaca !important;
        }

        .remove-field-btn:hover {
            background: #fef2f2 !important;
            border-color: #dc2626 !important;
            color: #b91c1c !important;
        }

        /* Editable Content */
        [contenteditable="true"]:focus {
            outline: 2px solid #3498db;
            outline-offset: 2px;
            border-radius: 4px;
        }

        .editable-title {
            transition: all 0.2s ease;
        }

        .editable-title:hover {
            background: rgba(52, 152, 219, 0.1);
            border-radius: 4px;
        }

        /* Form Status */
        .form-status {
            margin-top: 1rem;
            padding: 1rem;
            border-radius: 6px;
            font-weight: 500;
        }

        .form-status.success {
            background: #d1fae5;
            color: #065f46;
            border: 1px solid #a7f3d0;
        }

        .form-status.error {
            background: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
        }

        .form-status.loading {
            background: #dbeafe;
            color: #1e40af;
            border: 1px solid #93c5fd;
        }

        /* Submit Button */
        .submit-btn {
            background: #10b981;
            color: white;
            border: none;
            padding: 1rem 2rem;
            border-radius: 8px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }

        .submit-btn:hover {
            background: #059669;
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
        }

        .submit-btn:disabled {
            background: #9ca3af;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }

        .form-actions {
            text-align: center;
            margin: 2rem 0;
            padding: 2rem 0;
            border-top: 1px solid #e5e7eb;
        }

        /* Add Field Button */
        .add-field-container {
            text-align: center;
            margin: 2rem 0;
            padding: 2rem 0;
            border-top: 2px dashed #e5e7eb;
        }

        .add-field-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 1rem 2rem;
            border-radius: 12px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 0.75rem;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }

        .add-field-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
            background: linear-gradient(135deg, #5a6fd8 0%, #6c5ce7 100%);
        }

        .add-field-btn:active {
            transform: translateY(0);
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }

        .add-field-icon {
            font-size: 1.25rem;
            line-height: 1;
        }

        .add-field-text {
            font-weight: 600;
            letter-spacing: 0.5px;
        }
    </style>
    """
  end
end