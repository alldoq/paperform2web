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
                <!-- Page Navigation Section (for preview) -->
                <div class="page-management">
                    <div class="page-info">
                        <span id="page-counter">Page 1 of 1</span>
                    </div>
                    <div class="page-controls">
                        <button id="preview-prev-page" class="btn btn-secondary btn-small" disabled>‹</button>
                        <button id="preview-next-page" class="btn btn-secondary btn-small" disabled>›</button>
                    </div>
                </div>

                <!-- Form Actions Section -->
                <div class="form-actions-toolbar">
                    <button id="share-form" class="btn btn-primary">Share Form</button>
                    <button id="switch-to-edit" class="btn btn-secondary">Edit</button>
                </div>

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
                <!-- Page Management Section -->
                <div class="page-management">
                    <div class="page-info">
                        <span id="page-counter">Page 1 of 1</span>
                    </div>
                    <div class="page-controls">
                        <button id="edit-prev-page" class="btn btn-secondary btn-small" disabled>‹</button>
                        <button id="edit-next-page" class="btn btn-secondary btn-small" disabled>›</button>
                        <button id="edit-add-page" class="btn btn-success btn-small">+ Page</button>
                        <button id="edit-delete-page" class="btn btn-danger btn-small" disabled>🗑</button>
                    </div>
                </div>

                <!-- Field Management Section -->
                <div class="field-management">
                    <button id="add-field" class="btn btn-secondary">Add Field</button>
                    <button id="clear-all-fields" class="btn btn-danger">Clear All Fields</button>
                </div>

                <!-- Form Actions Section -->
                <div class="form-actions-toolbar">
                    <button id="switch-to-preview" class="btn btn-secondary">Preview</button>
                    <button id="save-form" class="btn btn-primary">Save Changes</button>
                    <button id="reset-form" class="btn btn-secondary">Reset</button>
                </div>

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
            gap: 1rem;
            align-items: center;
            flex-wrap: wrap;
        }

        /* Page Management Styles */
        .page-management {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1rem;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
        }

        .page-info {
            font-size: 0.875rem;
            font-weight: 500;
            color: #475569;
            min-width: 80px;
        }

        .page-controls {
            display: flex;
            gap: 0.25rem;
        }

        .field-management {
            display: flex;
            gap: 0.5rem;
        }

        .form-actions-toolbar {
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

        .btn-danger {
            background: #dc2626;
            color: white;
            border-color: #dc2626;
        }
        .btn-danger:hover {
            background: #b91c1c;
            border-color: #b91c1c;
        }

        .btn-success {
            background: #16a34a;
            color: white;
            border-color: #16a34a;
        }
        .btn-success:hover {
            background: #15803d;
            border-color: #15803d;
        }

        .btn-small {
            padding: 0.4rem 0.8rem;
            font-size: 0.75rem;
            font-weight: 500;
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

        /* Drag Handle Styles - positioned relative to wrapper */
        .editable-field-wrapper {
            position: relative;
            padding-left: 2.5rem; /* Make room for drag handle */
        }

        .drag-handle {
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
        }

        .drag-handle:hover {
            opacity: 1;
            transform: translateY(-50%) scale(1.1);
            box-shadow: 0 5px 20px rgba(52, 152, 219, 0.6);
        }

        .drag-handle:active {
            cursor: grabbing;
        }

        /* Dragging State Styles */
        .dragging-active {
            user-select: none;
        }

        .dragging-active .editable-field-wrapper {
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .dragging-active .editable-field-wrapper:not(.drag-over) {
            opacity: 0.7;
            transform: scale(0.98);
        }

        /* Enhanced Drop Zone Styles */
        .drop-zone {
            position: relative;
            min-height: 60px;
            margin: 8px 0;
            background: linear-gradient(135deg, rgba(52, 152, 219, 0.1) 0%, rgba(41, 128, 185, 0.15) 100%);
            border: 2px dashed rgba(52, 152, 219, 0.4);
            border-radius: 12px;
            opacity: 0;
            transform: scale(0.95) translateY(-5px);
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            pointer-events: none;
            z-index: 5;
            backdrop-filter: blur(8px);
            overflow: hidden;
        }

        .drop-zone.active {
            opacity: 1;
            transform: scale(1) translateY(0);
            animation: dropZonePulse 2s ease-in-out infinite;
        }

        @keyframes dropZonePulse {
            0%, 100% {
                border-color: rgba(52, 152, 219, 0.4);
                box-shadow: 0 4px 20px rgba(52, 152, 219, 0.2);
            }
            50% {
                border-color: rgba(52, 152, 219, 0.8);
                box-shadow: 0 8px 32px rgba(52, 152, 219, 0.4);
            }
        }

        .drop-zone::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(52, 152, 219, 0.3), transparent);
            animation: dropZoneShimmer 3s infinite;
        }

        @keyframes dropZoneShimmer {
            0% { left: -100%; }
            100% { left: 100%; }
        }

        .drop-zone-content {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            text-align: center;
            width: 100%;
            padding: 10px;
        }

        .drop-zone-icon {
            font-size: 24px;
            margin-bottom: 8px;
            display: block;
        }

        .drop-zone-text {
            color: #3498db;
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 4px;
            text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
        }

        .drop-zone-subtext {
            color: rgba(52, 152, 219, 0.8);
            font-size: 12px;
            opacity: 0;
            transform: translateY(10px);
            transition: all 0.3s ease;
        }

        .drop-zone.active .drop-zone-subtext {
            opacity: 1;
            transform: translateY(0);
        }

        .drop-zone::after {
            content: '';
            position: absolute;
            top: 10px;
            right: 10px;
            width: 8px;
            height: 8px;
            background: linear-gradient(135deg, #3498db, #2980b9);
            border-radius: 50%;
            animation: dropZoneDot 1.5s ease-in-out infinite;
        }

        @keyframes dropZoneDot {
            0%, 100% {
                transform: scale(1);
                opacity: 0.6;
            }
            50% {
                transform: scale(1.5);
                opacity: 1;
            }
        }

        /* Alternative compact drop line for tight spaces */
        .drop-line {
            position: relative;
            height: 8px;
            margin: 6px 0;
            background: linear-gradient(90deg, #3498db 0%, #2980b9 50%, #3498db 100%);
            background-size: 200% 100%;
            border-radius: 4px;
            opacity: 0;
            transform: scaleX(0) translateY(-5px);
            transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            pointer-events: none;
            z-index: 5;
            box-shadow: 0 2px 12px rgba(52, 152, 219, 0.4);
            overflow: visible;
        }

        .drop-line.active {
            opacity: 1;
            transform: scaleX(1) translateY(0);
            animation: dropLinePulse 1.5s ease-in-out infinite;
        }

        @keyframes dropLinePulse {
            0%, 100% {
                background-position: 0% 50%;
                box-shadow: 0 2px 12px rgba(52, 152, 219, 0.4);
            }
            50% {
                background-position: 100% 50%;
                box-shadow: 0 4px 20px rgba(52, 152, 219, 0.6);
            }
        }

        .drop-line::before {
            content: '';
            position: absolute;
            top: -2px;
            left: 0;
            right: 0;
            height: 12px;
            background: radial-gradient(ellipse at center, rgba(52, 152, 219, 0.2) 0%, transparent 70%);
            border-radius: 6px;
        }

        /* Enhanced drop zone highlighting */
        .editable-field-wrapper.drag-over {
            border-color: #3498db !important;
            border-style: solid !important;
            border-width: 3px !important;
            background: rgba(52, 152, 219, 0.1) !important;
            box-shadow: 0 0 20px rgba(52, 152, 219, 0.3) !important;
            transform: scale(1.02);
            transition: all 0.2s ease;
        }

        /* Ensure editable fields have relative positioning for drag handles */
        .editable-field {
            position: relative;
        }

        .editable-field-wrapper.dragging {
            transform: rotate(2deg);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
            z-index: 100;
        }

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

        /* Page Management Styles */
        .page-hidden {
            display: none !important;
            visibility: hidden !important;
            opacity: 0 !important;
            height: 0 !important;
            overflow: hidden !important;
            margin: 0 !important;
            padding: 0 !important;
        }

        .page-visible {
            display: block !important;
            visibility: visible !important;
            opacity: 1 !important;
        }
    </style>
    """
  end
end