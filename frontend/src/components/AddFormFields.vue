<template>
  <div class="space-y-6">
    <!-- Document Selection -->
    <div class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Select Existing Form</label>
        <select
          v-model="selectedDocumentId"
          class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          @change="onDocumentSelected"
        >
          <option value="">Choose a form to add fields to...</option>
          <option
            v-for="document in documents"
            :key="document.id"
            :value="document.id"
          >
            {{ document.title || 'Untitled Form' }} ({{ document.form_fields?.length || 0 }} fields)
          </option>
        </select>
      </div>

      <!-- Current Form Preview -->
      <div v-if="selectedDocument" class="bg-gray-50 rounded-lg p-4">
        <h4 class="font-medium text-gray-800 mb-2">Current Form Fields:</h4>
        <div v-if="selectedDocument.form_fields && selectedDocument.form_fields.length > 0" class="space-y-2">
          <div
            v-for="(field, index) in selectedDocument.form_fields"
            :key="index"
            class="flex items-center space-x-3 text-sm"
          >
            <span class="w-4 h-4 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center text-xs">{{ index + 1 }}</span>
            <span class="font-medium">{{ field.label }}</span>
            <span class="px-2 py-1 text-xs bg-gray-200 text-gray-700 rounded">{{ field.type }}</span>
            <span v-if="field.required" class="text-red-500 text-xs">*</span>
          </div>
        </div>
        <div v-else class="text-gray-500 text-sm">
          No fields in this form yet.
        </div>
      </div>
    </div>

    <!-- New Fields Builder -->
    <div v-if="selectedDocument" class="border-t pt-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-800">Add New Fields</h3>
        <button
          @click="addField"
          class="px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors duration-200 flex items-center space-x-2"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
          </svg>
          <span>Add Field</span>
        </button>
      </div>

      <!-- New Fields List -->
      <div v-if="newFields.length === 0" class="text-center py-8 text-gray-500">
        <p>No new fields added yet. Click "Add Field" to get started.</p>
      </div>

      <div v-else class="space-y-4">
        <div
          v-for="(field, index) in newFields"
          :key="field.id"
          class="border border-gray-200 rounded-lg p-4 bg-white"
        >
          <div class="flex items-start justify-between mb-3">
            <div class="flex items-center space-x-2">
              <span class="text-sm font-medium text-gray-500">New Field {{ index + 1 }}</span>
              <span class="px-2 py-1 text-xs bg-green-100 text-green-700 rounded-full">{{ field.type }}</span>
            </div>
            <button
              @click="removeField(index)"
              class="text-red-500 hover:text-red-700 transition-colors"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
              </svg>
            </button>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Label</label>
              <input
                v-model="field.label"
                type="text"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                placeholder="Field label"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Type</label>
              <select
                v-model="field.type"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              >
                <option value="text">Text</option>
                <option value="email">Email</option>
                <option value="textarea">Textarea</option>
                <option value="number">Number</option>
                <option value="date">Date</option>
                <option value="checkbox">Checkbox</option>
                <option value="radio">Radio Button</option>
                <option value="select">Select Dropdown</option>
              </select>
            </div>
          </div>

          <div class="mt-3">
            <label class="flex items-center space-x-2">
              <input
                v-model="field.required"
                type="checkbox"
                class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
              />
              <span class="text-sm text-gray-700">Required field</span>
            </label>
          </div>

          <!-- Options for radio/select -->
          <div v-if="field.type === 'radio' || field.type === 'select'" class="mt-3">
            <label class="block text-sm font-medium text-gray-700 mb-1">Options (one per line)</label>
            <textarea
              v-model="field.options"
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              placeholder="Option 1&#10;Option 2&#10;Option 3"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Add Fields Button -->
    <div v-if="selectedDocument && newFields.length > 0" class="border-t pt-6 flex justify-end">
      <button
        @click="addFieldsToForm"
        :disabled="!canAddFields"
        class="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors duration-200 flex items-center space-x-2"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
        </svg>
        <span>{{ adding ? 'Adding Fields...' : `Add ${newFields.length} Field${newFields.length > 1 ? 's' : ''}` }}</span>
      </button>
    </div>
  </div>
</template>

<script>
import { ref, computed } from 'vue'
import { documentsApi } from '../services/api.js'

export default {
  name: 'AddFormFields',
  props: {
    documents: {
      type: Array,
      default: () => []
    }
  },
  emits: ['fields-added'],
  setup(props, { emit }) {
    const selectedDocumentId = ref('')
    const selectedDocument = ref(null)
    const newFields = ref([])
    const adding = ref(false)

    const canAddFields = computed(() => {
      return selectedDocument.value &&
             newFields.value.length > 0 &&
             newFields.value.every(field => field.label.trim()) &&
             !adding.value
    })

    const onDocumentSelected = () => {
      selectedDocument.value = props.documents.find(doc => doc.id === selectedDocumentId.value)
      // Clear any existing new fields when switching documents
      newFields.value = []
    }

    const addField = () => {
      newFields.value.push({
        id: Date.now() + Math.random(),
        label: '',
        type: 'text',
        required: false,
        options: ''
      })
    }

    const removeField = (index) => {
      newFields.value.splice(index, 1)
    }

    const addFieldsToForm = async () => {
      if (!canAddFields.value) return

      adding.value = true

      try {
        // Convert new fields to the format expected by the backend
        const formattedNewFields = newFields.value.map(field => ({
          name: field.label.toLowerCase().replace(/\s+/g, '_'),
          label: field.label,
          type: field.type,
          required: field.required,
          ...(field.type === 'radio' || field.type === 'select' ? {
            options: field.options.split('\n').filter(opt => opt.trim()).map(opt => opt.trim())
          } : {})
        }))

        // Combine existing fields with new fields
        const currentFields = selectedDocument.value.form_fields || []
        const updatedFields = [...currentFields, ...formattedNewFields]

        // Call the API to update the form structure
        const response = await documentsApi.updateFormStructure(selectedDocument.value.id, updatedFields)
        const updatedDocument = response.data.data

        // Emit the updated document
        emit('fields-added', updatedDocument)

        // Reset new fields
        newFields.value = []

        // Show success message
        console.log(`Successfully added ${formattedNewFields.length} field(s) to ${selectedDocument.value.title}`)

      } catch (error) {
        console.error('Failed to add fields:', error)
        alert('Failed to add fields. Please try again.')
      } finally {
        adding.value = false
      }
    }

    return {
      selectedDocumentId,
      selectedDocument,
      newFields,
      adding,
      canAddFields,
      onDocumentSelected,
      addField,
      removeField,
      addFieldsToForm
    }
  }
}
</script>