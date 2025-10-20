<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h3>Edit Field</h3>
        <button @click="$emit('close')" class="close-btn">&times;</button>
      </div>

      <div class="modal-body">
        <!-- Field Label -->
        <div class="form-group">
          <label>Field Label</label>
          <input
            v-model="editedField.label"
            type="text"
            class="form-control"
            placeholder="Enter field label"
          />
        </div>

        <!-- Field Name (for form submission) -->
        <div class="form-group">
          <label>Field Name (for form data)</label>
          <input
            v-model="editedField.field_name"
            type="text"
            class="form-control"
            placeholder="e.g., user_email"
          />
        </div>

        <!-- Field Type specific options -->
        <template v-if="editedField.type === 'input'">
          <div class="form-group">
            <label>Input Type</label>
            <select v-model="editedField.input_type" class="form-control">
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
              v-model="editedField.placeholder"
              type="text"
              class="form-control"
              placeholder="Enter placeholder text"
            />
          </div>
        </template>

        <!-- Options for Select and Radio -->
        <template v-if="['select', 'radio'].includes(editedField.type)">
          <div class="form-group">
            <label>Options (one per line)</label>
            <textarea
              v-model="optionsText"
              class="form-control"
              rows="5"
              placeholder="Option 1&#10;Option 2&#10;Option 3"
            ></textarea>
          </div>
        </template>

        <!-- Textarea specific options -->
        <template v-if="editedField.type === 'textarea'">
          <div class="form-group">
            <label>Rows</label>
            <input
              v-model.number="editedField.rows"
              type="number"
              class="form-control"
              min="2"
              max="20"
            />
          </div>

          <div class="form-group">
            <label>Placeholder</label>
            <input
              v-model="editedField.placeholder"
              type="text"
              class="form-control"
              placeholder="Enter placeholder text"
            />
          </div>
        </template>

        <!-- Heading specific options -->
        <template v-if="editedField.type === 'heading'">
          <div class="form-group">
            <label>Heading Level</label>
            <select v-model.number="editedField.level" class="form-control">
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
        <div class="form-group" v-if="!['label', 'heading'].includes(editedField.type)">
          <label class="checkbox-label">
            <input
              v-model="editedField.required"
              type="checkbox"
            />
            Required field
          </label>
        </div>

        <!-- Formatting Options -->
        <div class="form-group">
          <label>Text Alignment</label>
          <div class="button-group">
            <button
              @click="setAlignment('left')"
              :class="{ active: editedField.formatting?.alignment === 'left' }"
              class="align-btn"
            >
              Left
            </button>
            <button
              @click="setAlignment('center')"
              :class="{ active: editedField.formatting?.alignment === 'center' }"
              class="align-btn"
            >
              Center
            </button>
            <button
              @click="setAlignment('right')"
              :class="{ active: editedField.formatting?.alignment === 'right' }"
              class="align-btn"
            >
              Right
            </button>
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button @click="$emit('close')" class="btn btn-secondary">
          Cancel
        </button>
        <button @click="saveChanges" class="btn btn-primary">
          Save Changes
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  field: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['save', 'close'])

const editedField = ref({ ...props.field })

// Options handling for select/radio
const optionsText = ref('')

watch(() => props.field, (newField) => {
  editedField.value = { ...newField }
  if (editedField.value.options && Array.isArray(editedField.value.options)) {
    optionsText.value = editedField.value.options.join('\n')
  }
}, { immediate: true })

const setAlignment = (alignment) => {
  if (!editedField.value.formatting) {
    editedField.value.formatting = {}
  }
  editedField.value.formatting.alignment = alignment
}

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

textarea.form-control {
  resize: vertical;
  font-family: inherit;
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

.button-group {
  display: flex;
  gap: 8px;
}

.align-btn {
  flex: 1;
  padding: 8px;
  border: 1px solid #d1d5db;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.align-btn:hover {
  background-color: #f3f4f6;
}

.align-btn.active {
  background-color: #3b82f6;
  color: white;
  border-color: #3b82f6;
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

.btn-primary:hover {
  background-color: #2563eb;
}
</style>