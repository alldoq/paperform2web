<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h3>Add New Field</h3>
        <button @click="$emit('close')" class="close-btn">&times;</button>
      </div>

      <div class="modal-body">
        <!-- Field Type Selection -->
        <div class="form-group">
          <label>Field Type</label>
          <div class="field-type-grid">
            <button
              v-for="type in fieldTypes"
              :key="type.value"
              @click="newField.type = type.value"
              :class="{ active: newField.type === type.value }"
              class="field-type-btn"
            >
              <span class="field-type-icon">{{ type.icon }}</span>
              <span class="field-type-label">{{ type.label }}</span>
            </button>
          </div>
        </div>

        <!-- Field Label -->
        <div class="form-group">
          <label>Field Label</label>
          <input
            v-model="newField.label"
            type="text"
            class="form-control"
            placeholder="Enter field label"
          />
        </div>

        <!-- Field Name -->
        <div class="form-group" v-if="!['label', 'heading'].includes(newField.type)">
          <label>Field Name (for form data)</label>
          <input
            v-model="newField.field_name"
            type="text"
            class="form-control"
            placeholder="e.g., user_email"
          />
        </div>

        <!-- Type-specific Options -->
        <template v-if="newField.type === 'input'">
          <div class="form-group">
            <label>Input Type</label>
            <select v-model="newField.input_type" class="form-control">
              <option value="text">Text</option>
              <option value="email">Email</option>
              <option value="number">Number</option>
              <option value="tel">Phone</option>
              <option value="url">URL</option>
              <option value="date">Date</option>
              <option value="time">Time</option>
              <option value="datetime-local">Date & Time</option>
              <option value="password">Password</option>
            </select>
          </div>

          <div class="form-group">
            <label>Placeholder</label>
            <input
              v-model="newField.placeholder"
              type="text"
              class="form-control"
              placeholder="Enter placeholder text"
            />
          </div>
        </template>

        <!-- Options for Select and Radio -->
        <template v-if="['select', 'radio'].includes(newField.type)">
          <div class="form-group">
            <label>Options</label>
            <div class="options-list">
              <div
                v-for="(option, index) in newField.options"
                :key="index"
                class="option-row"
              >
                <input
                  v-model="newField.options[index]"
                  type="text"
                  class="form-control"
                  placeholder="Option text"
                />
                <button @click="removeOption(index)" class="remove-option-btn">
                  &times;
                </button>
              </div>
              <button @click="addOption" class="add-option-btn">
                + Add Option
              </button>
            </div>
          </div>
        </template>

        <!-- Textarea Options -->
        <template v-if="newField.type === 'textarea'">
          <div class="form-group">
            <label>Rows</label>
            <input
              v-model.number="newField.rows"
              type="number"
              class="form-control"
              min="2"
              max="20"
            />
          </div>

          <div class="form-group">
            <label>Placeholder</label>
            <input
              v-model="newField.placeholder"
              type="text"
              class="form-control"
              placeholder="Enter placeholder text"
            />
          </div>
        </template>

        <!-- Heading Options -->
        <template v-if="newField.type === 'heading'">
          <div class="form-group">
            <label>Heading Level</label>
            <select v-model.number="newField.level" class="form-control">
              <option :value="1">H1 - Main Title</option>
              <option :value="2">H2 - Section Title</option>
              <option :value="3">H3 - Subsection</option>
              <option :value="4">H4 - Minor Heading</option>
              <option :value="5">H5 - Small Heading</option>
              <option :value="6">H6 - Tiny Heading</option>
            </select>
          </div>
        </template>

        <!-- Required Field -->
        <div class="form-group" v-if="!['label', 'heading'].includes(newField.type)">
          <label class="checkbox-label">
            <input
              v-model="newField.required"
              type="checkbox"
            />
            Required field
          </label>
        </div>
      </div>

      <div class="modal-footer">
        <button @click="$emit('close')" class="btn btn-secondary">
          Cancel
        </button>
        <button @click="addField" class="btn btn-primary" :disabled="!isValid">
          Add Field
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const emit = defineEmits(['add', 'close'])

const fieldTypes = [
  { value: 'input', label: 'Text Input', icon: '📝' },
  { value: 'textarea', label: 'Text Area', icon: '📄' },
  { value: 'select', label: 'Dropdown', icon: '▼' },
  { value: 'radio', label: 'Radio', icon: '◉' },
  { value: 'checkbox', label: 'Checkbox', icon: '☑' },
  { value: 'heading', label: 'Heading', icon: 'H' },
  { value: 'label', label: 'Label', icon: '🏷' }
]

const newField = ref({
  type: 'input',
  label: '',
  field_name: '',
  input_type: 'text',
  placeholder: '',
  options: ['Option 1', 'Option 2'],
  required: false,
  rows: 4,
  level: 2,
  formatting: {
    alignment: 'left'
  }
})

const isValid = computed(() => {
  if (!newField.value.label) return false

  if (!['label', 'heading'].includes(newField.value.type)) {
    if (!newField.value.field_name) {
      // Auto-generate field name from label if not provided
      newField.value.field_name = newField.value.label
        .toLowerCase()
        .replace(/[^a-z0-9]/g, '_')
        .replace(/_+/g, '_')
        .replace(/^_|_$/g, '')
    }
  }

  if (['select', 'radio'].includes(newField.value.type)) {
    return newField.value.options.length > 0 &&
           newField.value.options.some(opt => opt.trim().length > 0)
  }

  return true
})

const addOption = () => {
  newField.value.options.push(`Option ${newField.value.options.length + 1}`)
}

const removeOption = (index) => {
  newField.value.options.splice(index, 1)
}

const addField = () => {
  if (!isValid.value) return

  const field = { ...newField.value }

  // Clean up field based on type
  if (!['select', 'radio'].includes(field.type)) {
    delete field.options
  }

  if (!['input', 'textarea'].includes(field.type)) {
    delete field.placeholder
  }

  if (field.type !== 'textarea') {
    delete field.rows
  }

  if (field.type !== 'heading') {
    delete field.level
  }

  if (field.type === 'label' || field.type === 'heading') {
    field.text = field.label
    delete field.field_name
    delete field.required
  }

  emit('add', field)
}
</script>

<style scoped>
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

.modal-content {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 600px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}

.modal-header {
  padding: 20px;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h3 {
  font-size: 18px;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  font-size: 28px;
  color: #6b7280;
  cursor: pointer;
  line-height: 1;
  padding: 0;
  width: 30px;
  height: 30px;
}

.close-btn:hover {
  color: #374151;
}

.modal-body {
  padding: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  font-weight: 500;
  color: #374151;
  font-size: 14px;
}

.form-control {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  transition: all 0.2s;
}

.form-control:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.field-type-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  gap: 10px;
}

.field-type-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 12px;
  border: 1px solid #d1d5db;
  background: white;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.field-type-btn:hover {
  border-color: #3b82f6;
  background-color: #eff6ff;
}

.field-type-btn.active {
  border-color: #3b82f6;
  background-color: #3b82f6;
  color: white;
}

.field-type-icon {
  font-size: 24px;
  margin-bottom: 4px;
}

.field-type-label {
  font-size: 12px;
  font-weight: 500;
}

.options-list {
  space-y: 8px;
}

.option-row {
  display: flex;
  gap: 8px;
  margin-bottom: 8px;
}

.remove-option-btn {
  padding: 8px 12px;
  background-color: #ef4444;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 18px;
  line-height: 1;
}

.remove-option-btn:hover {
  background-color: #dc2626;
}

.add-option-btn {
  width: 100%;
  padding: 8px;
  border: 1px dashed #9ca3af;
  background: transparent;
  border-radius: 6px;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.2s;
}

.add-option-btn:hover {
  border-color: #3b82f6;
  color: #3b82f6;
  background-color: #eff6ff;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.checkbox-label input[type="checkbox"] {
  width: 18px;
  height: 18px;
  cursor: pointer;
}

.modal-footer {
  padding: 20px;
  border-top: 1px solid #e5e7eb;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn {
  padding: 8px 16px;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
}

.btn-secondary {
  background-color: #f3f4f6;
  color: #374151;
}

.btn-secondary:hover {
  background-color: #e5e7eb;
}

.btn-primary {
  background-color: #3b82f6;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #2563eb;
}

.btn-primary:disabled {
  background-color: #9ca3af;
  cursor: not-allowed;
}
</style>