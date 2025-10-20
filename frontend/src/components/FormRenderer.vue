<template>
  <div class="form-renderer" :class="[`theme-${theme}`, { 'editing-mode': editMode }]">
    <!-- Form Header -->
    <div v-if="formTitle" class="form-header">
      <h1 class="form-title">{{ formTitle }}</h1>
    </div>

    <!-- Form Fields Container -->
    <form
      v-if="!editMode"
      @submit.prevent="handleSubmit"
      class="form-container"
      :id="formId"
    >
      <div
        v-for="field in processedFields"
        :key="field.id"
        class="field-wrapper"
        :class="[`field-type-${field.type}`, { 'required': field.required }]"
      >
        <!-- Field Renderer based on type -->
        <component
          :is="getFieldComponent(field)"
          v-bind="field"
          :modelValue="formData[getFieldKey(field)]"
          @update:modelValue="updateFieldValue(getFieldKey(field), $event)"
        />
      </div>

      <!-- Submit Button -->
      <div class="form-actions" v-if="showSubmitButton">
        <button
          type="submit"
          class="submit-button"
          :disabled="isSubmitting || !isFormValid"
        >
          <span v-if="!isSubmitting">{{ submitButtonText }}</span>
          <span v-else>Submitting...</span>
        </button>
      </div>
    </form>

    <!-- Edit Mode Container -->
    <div v-else class="edit-container">
      <draggable
        v-model="groupedFieldsForEdit"
        group="fields"
        @end="handleGroupedFieldReorder"
        item-key="id"
        class="draggable-container"
        handle=".field-drag-handle"
      >
        <template #item="{element}">
          <div class="editable-field-wrapper" :class="{ 'field-group': element.type === 'group' }">
            <div class="field-controls">
              <span class="field-drag-handle">⋮⋮</span>
              <button
                v-if="element.fields.length === 1"
                @click="editField(element.fields[0])"
                class="edit-btn"
              >✎</button>
              <button
                v-if="element.fields.length === 1"
                @click="removeField(element.fields[0].id)"
                class="remove-btn"
              >✕</button>
              <span v-if="element.type === 'group'" class="group-label">Group</span>
            </div>

            <!-- Render all fields in the group -->
            <div v-for="field in element.fields" :key="field.id" class="grouped-field">
              <component
                :is="getFieldComponent(field)"
                v-bind="field"
                :modelValue="formData[getFieldKey(field)]"
                :editMode="true"
                @update:modelValue="updateFieldValue(getFieldKey(field), $event)"
              />
            </div>
          </div>
        </template>
      </draggable>

      <!-- Add Field Button -->
      <button @click="showAddField = true" class="add-field-button">
        + Add Field
      </button>
    </div>

    <!-- Field Editor Modal -->
    <FieldEditorModal
      v-if="editingField"
      :field="editingField"
      @save="saveFieldChanges"
      @close="editingField = null"
    />

    <!-- Add Field Modal -->
    <AddFieldModal
      v-if="showAddField"
      @add="addNewField"
      @close="showAddField = false"
    />
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import draggable from 'vuedraggable/src/vuedraggable'
import InputField from './fields/InputField.vue'
import SelectField from './fields/SelectField.vue'
import RadioField from './fields/RadioField.vue'
import CheckboxField from './fields/CheckboxField.vue'
import TextareaField from './fields/TextareaField.vue'
import LabelField from './fields/LabelField.vue'
import HeadingField from './fields/HeadingField.vue'
import FieldEditorModal from './FieldEditorModal.vue'
import AddFieldModal from './AddFieldModal.vue'

// Props
const props = defineProps({
  fields: {
    type: Array,
    required: true
  },
  formTitle: {
    type: String,
    default: ''
  },
  theme: {
    type: String,
    default: 'default'
  },
  editMode: {
    type: Boolean,
    default: false
  },
  showSubmitButton: {
    type: Boolean,
    default: true
  },
  submitButtonText: {
    type: String,
    default: 'Submit'
  },
  formId: {
    type: String,
    default: 'form-' + Math.random().toString(36).substr(2, 9)
  },
  initialData: {
    type: Object,
    default: () => ({})
  }
})

// Emits
const emit = defineEmits(['submit', 'update:fields', 'field-reorder', 'field-update', 'save-fields'])

// State
const formData = ref({ ...props.initialData })
const isSubmitting = ref(false)
const editableFields = ref([...props.fields])
const editingField = ref(null)
const showAddField = ref(false)
const errors = ref({})
const groupedFieldsForEdit = ref([])

// Field component mapping
const fieldComponents = {
  input: InputField,
  select: SelectField,
  radio: RadioField,
  checkbox: CheckboxField,
  textarea: TextareaField,
  label: LabelField,
  heading: HeadingField
}

// Computed
const processedFields = computed(() => {
  // Group radio buttons by field_name
  const grouped = []
  const radioGroups = {}

  for (const field of editableFields.value) {
    if (field.type === 'radio') {
      if (!radioGroups[field.field_name]) {
        radioGroups[field.field_name] = {
          id: field.field_name,
          type: 'radio',
          label: field.label,
          field_name: field.field_name,
          required: field.required,
          options: []
        }
        grouped.push(radioGroups[field.field_name])
      }
      radioGroups[field.field_name].options.push({
        value: field.value || field.label,
        label: field.label
      })
    } else {
      grouped.push(field)
    }
  }

  return grouped
})

const isFormValid = computed(() => {
  for (const field of processedFields.value) {
    if (field.required) {
      // Use field.id for checkboxes, field_name for others
      const fieldKey = field.input_type === 'checkbox' ? field.id : (field.field_name || field.id)
      const value = formData.value[fieldKey]
      if (!value || (Array.isArray(value) && value.length === 0)) {
        return false
      }
    }
  }
  return true
})

// Methods
// Function to group labels with their immediately following input fields for edit mode
const updateGroupedFields = () => {
  // First, group radio buttons by field_name (same as processedFields)
  const radioGroups = {}
  const nonRadioFields = []

  for (const field of editableFields.value) {
    if (field.type === 'radio' || field.input_type === 'radio') {
      const fieldName = field.field_name || field.id
      if (!radioGroups[fieldName]) {
        radioGroups[fieldName] = {
          id: fieldName,
          type: 'radio',
          label: field.label,
          field_name: fieldName,
          required: field.required,
          options: [],
          _originalFields: []  // Keep track of original fields for ungrouping
        }
      }
      radioGroups[fieldName].options.push({
        value: field.value || field.label,
        label: field.label
      })
      radioGroups[fieldName]._originalFields.push(field)
    } else {
      nonRadioFields.push(field)
    }
  }

  // Combine radio groups with other fields (preserve order)
  const fieldsWithRadioGroups = []
  const processedRadioGroups = new Set()

  for (const field of editableFields.value) {
    if (field.type === 'radio' || field.input_type === 'radio') {
      const fieldName = field.field_name || field.id
      if (!processedRadioGroups.has(fieldName)) {
        fieldsWithRadioGroups.push(radioGroups[fieldName])
        processedRadioGroups.add(fieldName)
      }
    } else {
      fieldsWithRadioGroups.push(field)
    }
  }

  // Now group labels with inputs
  const groups = []
  let i = 0

  while (i < fieldsWithRadioGroups.length) {
    const currentField = fieldsWithRadioGroups[i]
    const nextField = fieldsWithRadioGroups[i + 1]

    // Check if current field is a label and next field is an input
    if (currentField.type === 'label' && nextField && nextField.type === 'input') {
      // Group them together
      groups.push({
        id: `group_${currentField.id}_${nextField.id}`,
        type: 'group',
        fields: [currentField, nextField]
      })
      i += 2 // Skip both fields
    } else {
      // Keep field standalone
      groups.push({
        id: currentField.id || `field_${i}`,
        type: 'single',
        fields: [currentField]
      })
      i += 1
    }
  }

  groupedFieldsForEdit.value = groups
}
const getFieldComponent = (field) => {
  // For 'input' type fields, use the input_type to determine the component
  const componentType = field.type === 'input' ? field.input_type : field.type
  return fieldComponents[componentType] || InputField
}

const getFieldKey = (field) => {
  // Checkboxes need unique keys (use field ID)
  // Radio buttons and other inputs use field_name to group them properly
  if (field.input_type === 'checkbox') {
    return field.id
  }
  return field.field_name || field.id
}

const updateFieldValue = (fieldName, value) => {
  formData.value[fieldName] = value
  validateField(fieldName, value)
}

const validateField = (fieldKey, value) => {
  // Find field by either field_name or id (checkboxes use id)
  const field = processedFields.value.find(f =>
    getFieldKey(f) === fieldKey
  )
  if (field && field.required && !value) {
    errors.value[fieldKey] = 'This field is required'
  } else {
    delete errors.value[fieldKey]
  }
}

const handleSubmit = async () => {
  // Validate all fields
  for (const field of processedFields.value) {
    if (field.field_name) {
      validateField(field.field_name, formData.value[field.field_name])
    }
  }

  if (Object.keys(errors.value).length > 0) {
    return
  }

  isSubmitting.value = true
  emit('submit', {
    data: formData.value,
    fields: processedFields.value
  })

  // Reset submission state after a delay
  setTimeout(() => {
    isSubmitting.value = false
  }, 1000)
}

const handleFieldReorder = () => {
  emit('update:fields', editableFields.value)
  emit('field-reorder', editableFields.value)
}

const handleGroupedFieldReorder = () => {
  // Flatten the groups back to individual fields
  const flattenedFields = []
  for (const group of groupedFieldsForEdit.value) {
    for (const field of group.fields) {
      // If this is a grouped radio field, expand it back to individual options
      if (field.type === 'radio' && field._originalFields) {
        flattenedFields.push(...field._originalFields)
      } else {
        flattenedFields.push(field)
      }
    }
  }
  editableFields.value = flattenedFields
  emit('update:fields', editableFields.value)
  emit('field-reorder', editableFields.value)
}

const editField = (field) => {
  editingField.value = { ...field }
}

const saveFieldChanges = (updatedField) => {
  const index = editableFields.value.findIndex(f => f.id === updatedField.id)
  if (index !== -1) {
    editableFields.value[index] = updatedField
    emit('update:fields', editableFields.value)
    emit('field-update', updatedField)
  }
  editingField.value = null
}

const removeField = (fieldId) => {
  if (confirm('Are you sure you want to remove this field?')) {
    editableFields.value = editableFields.value.filter(f => f.id !== fieldId)
    emit('update:fields', editableFields.value)
  }
}

const addNewField = (field) => {
  const newField = {
    ...field,
    id: 'field_' + Date.now()
  }
  editableFields.value.push(newField)
  emit('update:fields', editableFields.value)
  showAddField.value = false
}

// Watch for prop changes
watch(() => props.fields, (newFields) => {
  editableFields.value = [...newFields]
}, { deep: true })

// Watch for editable fields changes to update groups
watch(editableFields, () => {
  updateGroupedFields()
}, { deep: true })

// Initialize form data for all fields
onMounted(() => {
  // Initialize grouped fields
  updateGroupedFields()

  // Initialize form data
  for (const field of processedFields.value) {
    if (field.field_name && !(field.field_name in formData.value)) {
      formData.value[field.field_name] = field.type === 'checkbox' ? false : ''
    }
  }
})
</script>

<style scoped>
/* Base Styles */
.form-renderer {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.form-header {
  margin-bottom: 30px;
  padding-bottom: 15px;
  border-bottom: 2px solid #e5e7eb;
}

.form-title {
  font-size: 28px;
  font-weight: bold;
  color: #1f2937;
}

.form-container {
  space-y: 20px;
}

.field-wrapper {
  margin-bottom: 20px;
}

.field-wrapper.required > :deep(label):after {
  content: ' *';
  color: #ef4444;
}

.form-actions {
  margin-top: 30px;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.submit-button {
  background-color: #3b82f6;
  color: white;
  padding: 10px 24px;
  border-radius: 8px;
  font-weight: 500;
  transition: all 0.2s;
  border: none;
  cursor: pointer;
}

.submit-button:hover:not(:disabled) {
  background-color: #2563eb;
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.submit-button:disabled {
  background-color: #9ca3af;
  cursor: not-allowed;
}

/* Edit Mode Styles */
.edit-container {
  border: 2px dashed #d1d5db;
  border-radius: 8px;
  padding: 20px;
  min-height: 400px;
}

.draggable-container {
  min-height: 300px;
}

.editable-field-wrapper {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 15px;
  margin-bottom: 15px;
  position: relative;
  transition: all 0.2s;
}

.editable-field-wrapper:hover {
  border-color: #3b82f6;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

/* Grouped fields (label + input) styling */
.editable-field-wrapper.field-group {
  border-left: 2px solid #e5e7eb;
  background: transparent;
  padding-left: 18px;
}

.grouped-field {
  margin-bottom: 8px;
}

.grouped-field:last-child {
  margin-bottom: 0;
}

.group-label {
  font-size: 9px;
  color: #9ca3af;
  background: #f9fafb;
  padding: 1px 4px;
  border-radius: 2px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.field-controls {
  position: absolute;
  top: 10px;
  right: 10px;
  display: flex;
  gap: 8px;
  align-items: center;
  z-index: 10;
  background: white;
  padding: 4px;
  border-radius: 6px;
}

.field-drag-handle {
  cursor: move;
  color: #9ca3af;
  font-size: 18px;
  padding: 0 5px;
}

.edit-btn, .remove-btn {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 4px;
  padding: 4px 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.edit-btn:hover {
  background-color: #3b82f6;
  color: white;
}

.remove-btn:hover {
  background-color: #ef4444;
  color: white;
}

.add-field-button {
  width: 100%;
  padding: 15px;
  border: 2px dashed #9ca3af;
  border-radius: 8px;
  background: transparent;
  color: #6b7280;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.add-field-button:hover {
  border-color: #3b82f6;
  color: #3b82f6;
  background-color: #eff6ff;
}

.edit-mode-actions {
  display: flex;
  gap: 12px;
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #e5e7eb;
}

.save-button {
  flex: 1;
  padding: 12px 24px;
  background-color: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.save-button:hover:not(:disabled) {
  background-color: #2563eb;
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.save-button:disabled {
  background-color: #9ca3af;
  cursor: not-allowed;
  opacity: 0.6;
}

.cancel-button {
  flex: 1;
  padding: 12px 24px;
  background-color: white;
  color: #6b7280;
  border: 2px solid #d1d5db;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.cancel-button:hover {
  border-color: #9ca3af;
  background-color: #f9fafb;
  color: #374151;
}

/* Theme Variations */

/* Default/Professional Theme - Dark blue header, gray background */
.theme-default {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  background-color: #f4f4f4;
}

.theme-default .form-header {
  background: #2c3e50;
  color: white;
  padding: 30px;
  margin: -20px -20px 30px -20px;
  border-radius: 8px 8px 0 0;
}

.theme-default .form-title {
  color: white;
}

.theme-default .field-label {
  color: #2c3e50;
  font-weight: 600;
}

.theme-default .field-input,
.theme-default .field-textarea,
.theme-default .field-select {
  background-color: #ffffff;
  border: 2px solid #d1d5db;
}

.theme-default .submit-button {
  background-color: #2c3e50;
}

.theme-default :deep(.heading-field) {
  color: #2c3e50;
}

.theme-default :deep(.label-text) {
  color: #4b5563;
}

/* Minimal Theme - White background, clean lines */
.theme-minimal {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background-color: white;
}

.theme-minimal .form-header {
  background: #eeeeee;
  color: #222222;
  padding: 25px;
  margin: -20px -20px 30px -20px;
  border-bottom: 2px solid #e0e0e0;
}

.theme-minimal .form-title {
  color: #222222;
  font-weight: 400;
}

.theme-minimal .field-label {
  color: #222222;
  font-weight: 500;
}

.theme-minimal .field-input,
.theme-minimal .field-textarea,
.theme-minimal .field-select {
  background-color: #f8f8f8;
  border: none;
  border-bottom: 1px solid #cccccc;
  border-radius: 0;
}

.theme-minimal .submit-button {
  background-color: #111827;
  border-radius: 4px;
}

.theme-minimal :deep(.heading-field) {
  color: #111827;
}

.theme-minimal :deep(.label-text) {
  color: #4b5563;
}

/* Dark Mode Theme - Dark backgrounds throughout */
.theme-dark {
  background-color: #2d2d2d;
  color: #e0e0e0;
}

.theme-dark .form-header {
  background: #1e3a5f;
  color: white;
  padding: 30px;
  margin: -20px -20px 30px -20px;
}

.theme-dark .form-title {
  color: white;
}

.theme-dark .field-label {
  color: #e0e0e0;
}

.theme-dark .field-input,
.theme-dark .field-textarea,
.theme-dark .field-select {
  background-color: #3a3a3a;
  border: 1px solid #4a4a4a;
  color: #e0e0e0;
}

.theme-dark .submit-button {
  background-color: #4f46e5;
}

.theme-dark :deep(.heading-field) {
  color: #f3f4f6;
}

.theme-dark :deep(.label-text) {
  color: #d1d5db;
}

/* Modern Theme - Purple gradient header */
.theme-modern {
  font-family: 'Poppins', -apple-system, BlinkMacSystemFont, sans-serif;
  background-color: white;
}

.theme-modern .form-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 35px;
  margin: -20px -20px 30px -20px;
  border-radius: 8px 8px 0 0;
}

.theme-modern .form-title {
  color: white;
}

.theme-modern .field-label {
  color: #1f2937;
  font-weight: 500;
}

.theme-modern .field-input,
.theme-modern .field-textarea,
.theme-modern .field-select {
  background-color: #f7fafc;
  border: 2px solid #e2e8f0;
  border-radius: 6px;
}

.theme-modern .submit-button {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 30px;
  padding: 12px 30px;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
}

.theme-modern :deep(.heading-field) {
  color: #1f2937;
}

.theme-modern :deep(.label-text) {
  color: #4b5563;
}

/* Classic Theme - Brown/tan traditional colors */
.theme-classic {
  font-family: Georgia, 'Times New Roman', serif;
  background-color: #f8f9fa;
  border: 3px double #8b4513;
}

.theme-classic .form-header {
  background: #8b4513;
  color: #f4e4c1;
  padding: 30px;
  margin: -20px -20px 30px -20px;
  border-bottom: 3px double #a0522d;
}

.theme-classic .form-title {
  color: #f4e4c1;
  font-weight: 600;
}

.theme-classic .field-label {
  color: #2c3e50;
  font-weight: 600;
}

.theme-classic .field-input,
.theme-classic .field-textarea,
.theme-classic .field-select {
  background-color: #fefefe;
  border: 2px solid #8b4513;
  border-radius: 4px;
}

.theme-classic .submit-button {
  background-color: #8b4513;
  border-radius: 4px;
}

.theme-classic :deep(.heading-field) {
  color: #8b4513;
}

.theme-classic :deep(.label-text) {
  color: #2c3e50;
}

/* Colorful Theme - Gradient backgrounds */
.theme-colorful {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: linear-gradient(135deg, #fff9e6 0%, #f0f8ff 100%);
}

.theme-colorful .form-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 35px;
  margin: -20px -20px 30px -20px;
  border-radius: 8px 8px 0 0;
}

.theme-colorful .form-title {
  color: white;
}

.theme-colorful .field-label {
  color: #2c3e50;
  font-weight: 600;
}

.theme-colorful .field-input,
.theme-colorful .field-textarea,
.theme-colorful .field-select {
  background: linear-gradient(135deg, #fff 0%, #f8f9ff 100%);
  border: 3px solid #ff6b6b;
  border-radius: 8px;
}

.theme-colorful .submit-button {
  background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%);
  border-radius: 25px;
  box-shadow: 0 4px 15px rgba(255, 107, 107, 0.3);
}

.theme-colorful :deep(.heading-field) {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.theme-colorful :deep(.label-text) {
  color: #2c3e50;
}

/* Professional/Corporate Theme - Blue gradient */
.theme-professional {
  font-family: 'Roboto', -apple-system, BlinkMacSystemFont, sans-serif;
  background-color: white;
}

.theme-professional .form-header {
  background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
  color: white;
  padding: 35px;
  margin: -20px -20px 30px -20px;
  border-radius: 8px 8px 0 0;
}

.theme-professional .form-title {
  color: white;
  font-weight: 500;
}

.theme-professional .field-label {
  color: #2c3e50;
  font-weight: 500;
}

.theme-professional .field-input,
.theme-professional .field-textarea,
.theme-professional .field-select {
  background-color: #f7f9fc;
  border: 2px solid #e2e8f0;
  border-radius: 4px;
}

.theme-professional .submit-button {
  background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
  border-radius: 6px;
}

.theme-professional :deep(.heading-field) {
  color: #1e3c72;
}

.theme-professional :deep(.label-text) {
  color: #4b5563;
}

/* Vibrant Theme - Red/orange gradient */
.theme-vibrant {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: linear-gradient(135deg, #fff5f5 0%, #fff0e6 100%);
}

.theme-vibrant .form-header {
  background: linear-gradient(135deg, #ff6b6b 0%, #ff8e53 100%);
  color: white;
  padding: 35px;
  margin: -20px -20px 30px -20px;
  border-radius: 8px 8px 0 0;
  box-shadow: 0 4px 15px rgba(255, 107, 107, 0.2);
}

.theme-vibrant .form-title {
  color: white;
  font-weight: 600;
}

.theme-vibrant .field-label {
  color: #2c3e50;
  font-weight: 600;
}

.theme-vibrant .field-input,
.theme-vibrant .field-textarea,
.theme-vibrant .field-select {
  background-color: white;
  border: 3px solid #ff6b6b;
  border-radius: 10px;
}

.theme-vibrant .field-input:focus,
.theme-vibrant .field-textarea:focus,
.theme-vibrant .field-select:focus {
  border-color: #ff8e53;
  box-shadow: 0 0 0 3px rgba(255, 107, 107, 0.1);
}

.theme-vibrant .submit-button {
  background: linear-gradient(135deg, #ff6b6b 0%, #ff8e53 100%);
  border-radius: 25px;
  box-shadow: 0 4px 15px rgba(255, 107, 107, 0.3);
}

.theme-vibrant :deep(.heading-field) {
  color: #ff6b6b;
}

.theme-vibrant :deep(.label-text) {
  color: #2c3e50;
}
</style>