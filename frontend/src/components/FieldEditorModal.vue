<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header" :style="{
        background: themeColors.primary,
        color: theme === 'dark' ? themeColors.text : '#ffffff'
      }">
        <div class="header-content">
          <div class="header-icon" :style="{ background: `rgba(255, 255, 255, ${theme === 'dark' ? '0.1' : '0.2'})` }">
            <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
          </div>
          <div>
            <h3>Edit Field</h3>
            <p class="field-type-badge">{{ getFieldTypeLabel(editedField.type) }}</p>
          </div>
        </div>
        <button @click="$emit('close')" class="close-btn" :style="{ background: `rgba(255, 255, 255, ${theme === 'dark' ? '0.1' : '0.2'})` }">
          <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <div class="modal-body-split" :style="{
        '--primary-color': themeColors.primary,
        '--primary-hover': themeColors.primaryHover,
        '--primary-light': themeColors.primaryLight
      }">
        <!-- Left Panel: Editor -->
        <div class="editor-panel">
          <div class="editor-scroll">
            <!-- Field Type Section -->
            <div class="editor-section">
              <div class="section-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" :style="{ color: themeColors.primary }">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                </svg>
                Field Type
              </div>

              <div class="field-type-grid">
                <button
                  v-for="fieldType in fieldTypes"
                  :key="fieldType.value"
                  @click="changeFieldType(fieldType.value)"
                  :class="{ active: editedField.type === fieldType.value }"
                  class="type-card"
                  :style="editedField.type === fieldType.value ? {
                    background: themeColors.primary,
                    borderColor: themeColors.primary,
                    color: theme === 'dark' ? themeColors.text : '#ffffff'
                  } : {}"
                >
                  <div class="type-icon" v-html="fieldType.icon" :style="editedField.type === fieldType.value ? { color: theme === 'dark' ? themeColors.text : '#ffffff' } : { color: themeColors.primary }"></div>
                  <span>{{ fieldType.label }}</span>
                </button>
              </div>
            </div>

            <!-- Content Section -->
            <div class="editor-section">
              <div class="section-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
                </svg>
                Content
              </div>

              <div class="form-group-modern">
                <label class="modern-label">Field Label</label>
                <input
                  v-model="editedField.label"
                  type="text"
                  class="modern-input"
                  placeholder="e.g., Email Address"
                />
              </div>

              <div class="form-group-modern" v-if="!['label', 'heading'].includes(editedField.type)">
                <label class="modern-label">Field ID (for data)</label>
                <input
                  v-model="editedField.field_name"
                  type="text"
                  class="modern-input modern-input-code"
                  placeholder="e.g., user_email"
                />
                <span class="input-hint">Used for form submission and data export</span>
              </div>
            </div>

            <!-- Field Type Section -->
            <div class="editor-section" v-if="editedField.type === 'input'">
              <div class="section-title">
                <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                </svg>
                Specify Input Format (Optional - defaults to Text)
              </div>

              <div class="input-type-grid">
                <button
                  v-for="type in inputTypes"
                  :key="type.value"
                  @click="editedField.input_type = type.value"
                  :class="{ active: editedField.input_type === type.value }"
                  class="type-card"
                  :style="editedField.input_type === type.value ? {
                    background: themeColors.primary,
                    borderColor: themeColors.primary,
                    color: theme === 'dark' ? themeColors.text : '#ffffff'
                  } : {}"
                >
                  <div class="type-icon" v-html="type.icon" :style="editedField.input_type === type.value ? { color: theme === 'dark' ? themeColors.text : '#ffffff' } : { color: themeColors.primary }"></div>
                  <span>{{ type.label }}</span>
                </button>
              </div>

              <div class="form-group-modern">
                <label class="modern-label">Placeholder Text</label>
                <input
                  v-model="editedField.placeholder"
                  type="text"
                  class="modern-input"
                  :placeholder="`e.g., ${getPlaceholderExample(editedField.input_type)}`"
                />
              </div>
            </div>

            <!-- Options Section -->
            <div class="editor-section" v-if="['select', 'radio'].includes(editedField.type)">
              <div class="section-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16" />
                </svg>
                Options
              </div>

              <div class="form-group-modern">
                <label class="modern-label">Add Options (one per line)</label>
                <textarea
                  v-model="optionsText"
                  class="modern-textarea"
                  rows="6"
                  placeholder="Option 1&#10;Option 2&#10;Option 3"
                ></textarea>
                <span class="input-hint">{{ optionsCount }} option(s)</span>
              </div>
            </div>

            <!-- Textarea Section -->
            <div class="editor-section" v-if="editedField.type === 'textarea'">
              <div class="section-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                Textarea Settings
              </div>

              <div class="form-group-modern">
                <label class="modern-label">Number of Rows</label>
                <div class="slider-group">
                  <input
                    v-model.number="editedField.rows"
                    type="range"
                    min="2"
                    max="12"
                    class="modern-slider"
                    :style="{
                      '--slider-color': themeColors.primary
                    }"
                  />
                  <span class="slider-value" :style="{ color: themeColors.primary }">{{ editedField.rows || 4 }} rows</span>
                </div>
              </div>

              <div class="form-group-modern">
                <label class="modern-label">Placeholder Text</label>
                <input
                  v-model="editedField.placeholder"
                  type="text"
                  class="modern-input"
                  placeholder="e.g., Enter your message here..."
                />
              </div>
            </div>

            <!-- Heading Section -->
            <div class="editor-section" v-if="editedField.type === 'heading'">
              <div class="form-group-modern">
                <label class="modern-label">Heading Level</label>
                <select
                  v-model="editedField.level"
                  class="modern-input"
                >
                  <option :value="1">H1 - Main Title</option>
                  <option :value="2">H2 - Section</option>
                  <option :value="3">H3 - Subsection</option>
                  <option :value="4">H4 - Small</option>
                  <option :value="5">H5 - Smaller</option>
                  <option :value="6">H6 - Smallest</option>
                </select>
              </div>
            </div>

            <!-- Settings Section -->
            <div class="editor-section" v-if="!['label', 'heading'].includes(editedField.type)">
              <div class="section-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                Field Settings
              </div>

              <label class="modern-toggle" :style="editedField.required ? { borderColor: themeColors.primary } : {}">
                <input
                  v-model="editedField.required"
                  type="checkbox"
                  class="toggle-input"
                />
                <span class="toggle-slider" :style="editedField.required ? { background: themeColors.primary } : {}"></span>
                <span class="toggle-label">
                  <svg width="16" height="16" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                  </svg>
                  Required Field
                </span>
              </label>
            </div>

            <!-- Formatting Section -->
            <div class="editor-section">
              <div class="section-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h8m-8 6h16" />
                </svg>
                Text Alignment
              </div>

              <div class="alignment-buttons">
                <button
                  @click="setAlignment('left')"
                  :class="{ active: editedField.formatting?.alignment === 'left' }"
                  class="align-button"
                  title="Left Align"
                  :style="editedField.formatting?.alignment === 'left' ? {
                    background: themeColors.primary,
                    borderColor: themeColors.primary,
                    color: theme === 'dark' ? themeColors.text : '#ffffff'
                  } : {}"
                >
                  <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h10M4 18h7" />
                  </svg>
                </button>
                <button
                  @click="setAlignment('center')"
                  :class="{ active: editedField.formatting?.alignment === 'center' }"
                  class="align-button"
                  title="Center Align"
                  :style="editedField.formatting?.alignment === 'center' ? {
                    background: themeColors.primary,
                    borderColor: themeColors.primary,
                    color: theme === 'dark' ? themeColors.text : '#ffffff'
                  } : {}"
                >
                  <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M7 12h10M9 18h6" />
                  </svg>
                </button>
                <button
                  @click="setAlignment('right')"
                  :class="{ active: editedField.formatting?.alignment === 'right' }"
                  class="align-button"
                  title="Right Align"
                  :style="editedField.formatting?.alignment === 'right' ? {
                    background: themeColors.primary,
                    borderColor: themeColors.primary,
                    color: theme === 'dark' ? themeColors.text : '#ffffff'
                  } : {}"
                >
                  <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M10 12h10M13 18h7" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Right Panel: Preview -->
        <div class="preview-panel">
          <div class="preview-header">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" :style="{ color: themeColors.primary }">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
            Live Preview
          </div>
          <div class="preview-content">
            <div class="preview-field" :style="{ textAlign: editedField.formatting?.alignment || 'left' }">
              <component
                :is="getPreviewComponent()"
                v-bind="getPreviewProps()"
              />
            </div>
            <div class="preview-info">
              <div class="info-item">
                <span class="info-label">Type:</span>
                <span class="info-value">{{ getFieldTypeLabel(editedField.type) }}</span>
              </div>
              <div class="info-item" v-if="editedField.field_name">
                <span class="info-label">ID:</span>
                <span class="info-value info-code">{{ editedField.field_name }}</span>
              </div>
              <div class="info-item" v-if="editedField.required">
                <span class="info-label">Required:</span>
                <span class="info-badge" :style="{
                  background: themeColors.primary,
                  color: theme === 'dark' ? themeColors.text : '#ffffff'
                }">Yes</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button @click="$emit('close')" class="btn btn-secondary">
          Cancel
        </button>
        <button @click="saveChanges" class="btn btn-primary" :style="{
          background: themeColors.primary,
          color: theme === 'dark' ? themeColors.text : '#ffffff'
        }">
          Save Changes
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import InputField from './fields/InputField.vue'
import TextareaField from './fields/TextareaField.vue'
import SelectField from './fields/SelectField.vue'
import RadioField from './fields/RadioField.vue'
import CheckboxField from './fields/CheckboxField.vue'
import LabelField from './fields/LabelField.vue'
import HeadingField from './fields/HeadingField.vue'

const props = defineProps({
  field: {
    type: Object,
    required: true
  },
  theme: {
    type: String,
    default: 'default'
  }
})

const emit = defineEmits(['save', 'close'])

const editedField = ref({ ...props.field })

// Field types with icons
const fieldTypes = [
  { value: 'input', label: 'Input', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"/></svg>' },
  { value: 'textarea', label: 'Textarea', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path d="M9 2a2 2 0 00-2 2v8a2 2 0 002 2h6a2 2 0 002-2V6.414A2 2 0 0016.414 5L14 2.586A2 2 0 0012.586 2H9z"/><path d="M3 8a2 2 0 012-2v10h8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/></svg>' },
  { value: 'select', label: 'Dropdown', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h6a1 1 0 110 2H4a1 1 0 01-1-1z" clip-rule="evenodd"/></svg>' },
  { value: 'radio', label: 'Radio', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>' },
  { value: 'checkbox', label: 'Checkbox', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M3 5a2 2 0 012-2h10a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V5zm11 1H6v8h8V6z" clip-rule="evenodd"/></svg>' },
  { value: 'label', label: 'Label', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 13V5a2 2 0 00-2-2H4a2 2 0 00-2 2v8a2 2 0 002 2h3l3 3 3-3h3a2 2 0 002-2zM5 7a1 1 0 011-1h8a1 1 0 110 2H6a1 1 0 01-1-1zm1 3a1 1 0 100 2h3a1 1 0 100-2H6z" clip-rule="evenodd"/></svg>' },
  { value: 'heading', label: 'Heading', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M4 4a1 1 0 011-1h4a1 1 0 011 1v12a1 1 0 11-2 0V11H6v5a1 1 0 11-2 0V4zm10 0a1 1 0 10-2 0v12a1 1 0 102 0V4z" clip-rule="evenodd"/></svg>' }
]

// Input types with icons
const inputTypes = [
  { value: 'text', label: 'Text', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"/></svg>' },
  { value: 'email', label: 'Email', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z"/><path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z"/></svg>' },
  { value: 'number', label: 'Number', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path d="M10 2a8 8 0 100 16 8 8 0 000-16zM8 11a1 1 0 112 0v2h2v-2a1 1 0 112 0v2a1 1 0 11-2 0v-1h-2v1a1 1 0 11-2 0v-2zm2-5a1 1 0 110-2 1 1 0 010 2z"/></svg>' },
  { value: 'tel', label: 'Phone', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z"/></svg>' },
  { value: 'url', label: 'URL', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M12.586 4.586a2 2 0 112.828 2.828l-3 3a2 2 0 01-2.828 0 1 1 0 00-1.414 1.414 4 4 0 005.656 0l3-3a4 4 0 00-5.656-5.656l-1.5 1.5a1 1 0 101.414 1.414l1.5-1.5zm-5 5a2 2 0 012.828 0 1 1 0 101.414-1.414 4 4 0 00-5.656 0l-3 3a4 4 0 105.656 5.656l1.5-1.5a1 1 0 10-1.414-1.414l-1.5 1.5a2 2 0 11-2.828-2.828l3-3z" clip-rule="evenodd"/></svg>' },
  { value: 'date', label: 'Date', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"/></svg>' },
  { value: 'time', label: 'Time', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"/></svg>' },
  { value: 'password', label: 'Password', icon: '<svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd"/></svg>' }
]

// Options handling for select/radio
const optionsText = ref('')

const optionsCount = computed(() => {
  return optionsText.value.split('\n').filter(opt => opt.trim().length > 0).length
})

watch(() => props.field, (newField) => {
  editedField.value = { ...newField }
  if (editedField.value.options && Array.isArray(editedField.value.options)) {
    // Handle both string and object formats
    optionsText.value = editedField.value.options.map(opt => {
      if (typeof opt === 'string') return opt
      if (typeof opt === 'object' && opt !== null) return opt.label || opt.value || ''
      return String(opt)
    }).join('\n')
  }
}, { immediate: true })

const getFieldTypeLabel = (type) => {
  const labels = {
    input: 'Input Field',
    textarea: 'Text Area',
    select: 'Dropdown',
    radio: 'Radio Buttons',
    checkbox: 'Checkbox',
    label: 'Label',
    heading: 'Heading'
  }
  return labels[type] || type
}

const getHeadingDesc = (level) => {
  const descs = {
    1: 'Main Title',
    2: 'Section Title',
    3: 'Subsection',
    4: 'Minor Heading',
    5: 'Small Heading',
    6: 'Tiny Heading'
  }
  return descs[level]
}

const getPlaceholderExample = (inputType) => {
  const examples = {
    text: 'Enter text here',
    email: 'your@email.com',
    number: '123',
    tel: '+1 (555) 123-4567',
    url: 'https://example.com',
    date: 'Select a date',
    time: 'Select a time',
    password: 'Enter password'
  }
  return examples[inputType] || 'Enter value'
}

const changeFieldType = (newType) => {
  editedField.value.type = newType

  // Reset type-specific properties
  if (newType === 'input') {
    if (!editedField.value.input_type) {
      editedField.value.input_type = 'text'
    }
  } else if (newType === 'textarea') {
    if (!editedField.value.rows) {
      editedField.value.rows = 4
    }
  } else if (['select', 'radio'].includes(newType)) {
    if (!editedField.value.options || !Array.isArray(editedField.value.options)) {
      editedField.value.options = []
      optionsText.value = ''
    }
  } else if (newType === 'heading') {
    if (!editedField.value.level) {
      editedField.value.level = 2
    }
  }
}

const setAlignment = (alignment) => {
  if (!editedField.value.formatting) {
    editedField.value.formatting = {}
  }
  editedField.value.formatting.alignment = alignment
}

const getPreviewComponent = () => {
  const components = {
    input: InputField,
    textarea: TextareaField,
    select: SelectField,
    radio: RadioField,
    checkbox: CheckboxField,
    label: LabelField,
    heading: HeadingField
  }
  return components[editedField.value.type] || LabelField
}

const getPreviewProps = () => {
  const baseProps = {
    ...editedField.value,
    label: editedField.value.label || 'Field Label',
    placeholder: editedField.value.placeholder || 'Placeholder...',
    modelValue: '',
    theme: props.theme
  }

  // Add options for select/radio if they exist
  if (['select', 'radio'].includes(editedField.value.type)) {
    const options = optionsText.value
      .split('\n')
      .map(opt => opt.trim())
      .filter(opt => opt.length > 0)

    if (options.length > 0) {
      baseProps.options = options
    }
  }

  return baseProps
}

// Theme colors
const themeColors = computed(() => {
  console.log('FieldEditorModal - Current theme:', props.theme)
  const themes = {
    default: {
      primary: '#3b82f6',
      primaryHover: '#2563eb',
      primaryLight: 'rgba(59, 130, 246, 0.1)',
      text: '#1f2937',
      background: '#ffffff'
    },
    minimal: {
      primary: '#000000',
      primaryHover: '#1f2937',
      primaryLight: 'rgba(0, 0, 0, 0.05)',
      text: '#000000',
      background: '#ffffff'
    },
    dark: {
      primary: '#6366f1',
      primaryHover: '#4f46e5',
      primaryLight: 'rgba(99, 102, 241, 0.15)',
      text: '#f3f4f6',
      background: '#1f2937'
    },
    modern: {
      primary: '#8b5cf6',
      primaryHover: '#7c3aed',
      primaryLight: 'rgba(139, 92, 246, 0.1)',
      text: '#1f2937',
      background: '#ffffff'
    },
    classic: {
      primary: '#059669',
      primaryHover: '#047857',
      primaryLight: 'rgba(5, 150, 105, 0.1)',
      text: '#1f2937',
      background: '#f9fafb'
    },
    colorful: {
      primary: '#f59e0b',
      primaryHover: '#d97706',
      primaryLight: 'rgba(245, 158, 11, 0.1)',
      text: '#1f2937',
      background: '#ffffff'
    },
    professional: {
      primary: '#1e40af',
      primaryHover: '#1e3a8a',
      primaryLight: 'rgba(30, 64, 175, 0.1)',
      text: '#1f2937',
      background: '#ffffff'
    },
    vibrant: {
      primary: '#ec4899',
      primaryHover: '#db2777',
      primaryLight: 'rgba(236, 72, 153, 0.1)',
      text: '#1f2937',
      background: '#ffffff'
    }
  }
  const colors = themes[props.theme] || themes.default
  console.log('FieldEditorModal - Theme colors:', colors)
  return colors
})

const saveChanges = () => {
  // Convert options text back to array
  if (['select', 'radio'].includes(editedField.value.type)) {
    editedField.value.options = optionsText.value
      .split('\n')
      .map(opt => opt.trim())
      .filter(opt => opt.length > 0)
  }

  emit('save', editedField.value)
}
</script>

<style scoped>
/* Modal Base */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
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

.modal-content {
  background: white;
  border-radius: 16px;
  width: 95%;
  max-width: 1200px;
  height: 85vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  animation: slideUp 0.3s ease-out;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Header */
.modal-header {
  padding: 14px 18px;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-radius: 16px 16px 0 0;
}

.header-content {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.header-icon svg {
  width: 18px;
  height: 18px;
}

.modal-header h3 {
  font-size: 18px;
  font-weight: 700;
  margin: 0;
}

.field-type-badge {
  font-size: 11px;
  margin: 2px 0 0 0;
  opacity: 0.85;
  font-weight: 500;
}

.close-btn {
  border: none;
  cursor: pointer;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.close-btn svg {
  width: 18px;
  height: 18px;
}

.close-btn:hover {
  transform: scale(1.05);
  opacity: 0.8;
}

/* Split Body */
.modal-body-split {
  display: grid;
  grid-template-columns: 1fr 400px;
  flex: 1;
  overflow: hidden;
}

/* Editor Panel */
.editor-panel {
  border-right: 1px solid #e5e7eb;
  background: #f9fafb;
  overflow: hidden;
}

.editor-scroll {
  height: 100%;
  overflow-y: auto;
  padding: 16px;
}

.editor-section {
  background: white;
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 12px;
  border: 1px solid #e5e7eb;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #1f2937;
  margin-bottom: 10px;
  padding-bottom: 8px;
  border-bottom: 1px solid #f3f4f6;
}

.section-title svg {
  color: var(--primary-color, #3b82f6);
  width: 16px;
  height: 16px;
}

/* Modern Form Groups */
.form-group-modern {
  margin-bottom: 12px;
}

.form-group-modern:last-child {
  margin-bottom: 0;
}

.modern-label {
  display: block;
  margin-bottom: 6px;
  font-weight: 600;
  color: #374151;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.modern-input {
  width: 100%;
  padding: 8px 12px;
  border: 2px solid #e5e7eb;
  border-radius: 6px;
  font-size: 14px;
  transition: all 0.2s;
  background: white;
}

.modern-input:focus {
  outline: none;
  border-color: var(--primary-color, #3b82f6);
  box-shadow: 0 0 0 4px var(--primary-light, rgba(59, 130, 246, 0.1));
  transform: translateY(-1px);
}

.modern-input-code {
  font-family: 'Monaco', 'Courier New', monospace;
  font-size: 13px;
  background: #f9fafb;
}

.modern-textarea {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #e5e7eb;
  border-radius: 10px;
  font-size: 15px;
  transition: all 0.2s;
  resize: vertical;
  font-family: inherit;
  background: white;
}

.modern-textarea:focus {
  outline: none;
  border-color: var(--primary-color, #3b82f6);
  box-shadow: 0 0 0 4px var(--primary-light, rgba(59, 130, 246, 0.1));
}

.input-hint {
  display: block;
  margin-top: 6px;
  font-size: 12px;
  color: #6b7280;
}

/* Field Type Grid */
.field-type-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 6px;
  margin-bottom: 0;
}

/* Input Type Grid */
.input-type-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
  margin-bottom: 0;
}

.type-card {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 6px;
  padding: 8px 6px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.type-card:hover {
  border-color: var(--primary-color, #3b82f6);
  transform: translateY(-1px);
  box-shadow: 0 2px 6px var(--primary-light, rgba(59, 130, 246, 0.15));
}

.type-icon {
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--primary-color, #3b82f6);
}

.type-card span {
  font-size: 11px;
  font-weight: 600;
}

/* Slider */
.slider-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.modern-slider {
  flex: 1;
  height: 6px;
  border-radius: 3px;
  background: #e5e7eb;
  outline: none;
  -webkit-appearance: none;
}

.modern-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--slider-color, #3b82f6);
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.modern-slider::-moz-range-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--slider-color, #3b82f6);
  cursor: pointer;
  border: none;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.slider-value {
  font-weight: 600;
  color: var(--primary-color, #3b82f6);
  min-width: 60px;
  text-align: right;
}

/* Heading Selector */
.heading-selector {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.heading-option {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 10px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: space-between;
  text-align: left;
}

.heading-option:hover {
  border-color: var(--primary-color, #3b82f6);
  background: #f9fafb;
}

.heading-preview {
  margin: 0;
  font-weight: 700;
}

.heading-desc {
  font-size: 13px;
  opacity: 0.7;
}

/* Toggle Switch */
.modern-toggle {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  padding: 10px 12px;
  background: #f9fafb;
  border-radius: 6px;
  border: 2px solid #e5e7eb;
  transition: all 0.2s;
}

.modern-toggle:hover {
  background: white;
  border-color: var(--primary-color, #3b82f6);
}

.toggle-input {
  display: none;
}

.toggle-slider {
  width: 40px;
  height: 22px;
  background: #d1d5db;
  border-radius: 11px;
  position: relative;
  transition: all 0.3s;
}

.toggle-slider::before {
  content: '';
  position: absolute;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: white;
  top: 3px;
  left: 3px;
  transition: all 0.3s;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.toggle-input:checked + .toggle-slider {
  background: var(--primary-color, #3b82f6);
}

.toggle-input:checked + .toggle-slider::before {
  transform: translateX(22px);
}

.toggle-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  color: #374151;
}

/* Alignment Buttons */
.alignment-buttons {
  display: flex;
  gap: 6px;
}

.align-button {
  flex: 1;
  padding: 8px;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6b7280;
}

.align-button:hover {
  border-color: var(--primary-color, #3b82f6);
  color: var(--primary-color, #3b82f6);
  transform: translateY(-1px);
  box-shadow: 0 2px 6px var(--primary-light, rgba(59, 130, 246, 0.15));
}

/* Preview Panel */
.preview-panel {
  background: #ffffff;
  display: flex;
  flex-direction: column;
}

.preview-header {
  padding: 12px 16px;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 700;
  font-size: 14px;
  color: #1f2937;
  background: linear-gradient(to right, #f9fafb, #ffffff);
}

.preview-header svg {
  color: var(--primary-color, #3b82f6);
  width: 18px;
  height: 18px;
}

.preview-content {
  flex: 1;
  padding: 16px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.preview-field {
  background: white;
  padding: 16px;
  border-radius: 8px;
  border: 2px dashed #e5e7eb;
  min-height: 80px;
}

.preview-info {
  background: #f9fafb;
  padding: 12px;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 0;
  border-bottom: 1px solid #e5e7eb;
}

.info-item:last-child {
  border-bottom: none;
}

.info-label {
  font-weight: 600;
  color: #6b7280;
  font-size: 13px;
  min-width: 80px;
}

.info-value {
  color: #1f2937;
  font-weight: 500;
}

.info-code {
  font-family: 'Monaco', 'Courier New', monospace;
  font-size: 12px;
  background: white;
  padding: 4px 8px;
  border-radius: 4px;
  border: 1px solid #e5e7eb;
}

.info-badge {
  background: var(--primary-color, #3b82f6);
  color: white;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
}

/* Footer */
.modal-footer {
  padding: 12px 16px;
  border-top: 1px solid #e5e7eb;
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  background: #f9fafb;
  border-radius: 0 0 16px 16px;
}

.btn {
  padding: 8px 16px;
  border-radius: 6px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
  font-size: 15px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-secondary {
  background-color: white;
  color: #374151;
  border: 2px solid #e5e7eb;
}

.btn-secondary:hover {
  background-color: #f3f4f6;
  border-color: #d1d5db;
  transform: translateY(-1px);
}

.btn-primary {
  background: var(--primary-color, #3b82f6);
  color: white;
  box-shadow: 0 4px 12px var(--primary-light, rgba(59, 130, 246, 0.3));
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px var(--primary-light, rgba(59, 130, 246, 0.4));
  filter: brightness(1.1);
}

/* Scrollbar Styling */
.editor-scroll::-webkit-scrollbar,
.preview-content::-webkit-scrollbar {
  width: 8px;
}

.editor-scroll::-webkit-scrollbar-track,
.preview-content::-webkit-scrollbar-track {
  background: #f1f1f1;
}

.editor-scroll::-webkit-scrollbar-thumb,
.preview-content::-webkit-scrollbar-thumb {
  background: #d1d5db;
  border-radius: 4px;
}

.editor-scroll::-webkit-scrollbar-thumb:hover,
.preview-content::-webkit-scrollbar-thumb:hover {
  background: #9ca3af;
}

/* Responsive */
@media (max-width: 1024px) {
  .modal-body-split {
    grid-template-columns: 1fr;
  }

  .preview-panel {
    display: none;
  }

  .field-type-grid {
    grid-template-columns: repeat(3, 1fr);
  }

  .input-type-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 640px) {
  .field-type-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .input-type-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .modal-content {
    width: 100%;
    height: 100vh;
    border-radius: 0;
  }

  .modal-header {
    border-radius: 0;
  }
}
</style>