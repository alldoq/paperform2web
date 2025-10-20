<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50/30 to-gray-100">
    <!-- Header -->
    <div class="bg-white shadow-sm border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <button
              @click="goBack"
              class="p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </button>
            <div>
              <h1 class="text-xl font-semibold text-gray-900">{{ documentTitle }}</h1>
              <p class="text-sm text-gray-500">{{ themeName }} Theme</p>
            </div>
          </div>

          <div class="flex items-center space-x-3">
            <button
              @click="toggleEditMode"
              :class="[
                'px-4 py-2 text-sm font-medium rounded-md transition-colors',
                editMode
                  ? 'bg-blue-600 text-white hover:bg-blue-700'
                  : 'bg-white text-gray-700 hover:bg-gray-100 border border-gray-300'
              ]"
            >
              {{ editMode ? 'Edit Mode' : 'Preview Mode' }}
            </button>

            <!-- Save/Discard buttons -->
            <template v-if="editMode">
              <div class="border-l border-gray-300 h-8"></div>
              <button
                @click="saveFormChanges"
                :disabled="!hasChanges"
                :class="[
                  'px-4 py-2 text-sm font-medium rounded-md transition-all shadow-sm',
                  hasChanges
                    ? 'bg-green-600 text-white hover:bg-green-700 cursor-pointer'
                    : 'bg-gray-300 text-gray-500 cursor-not-allowed'
                ]"
              >
                Save Changes
              </button>
              <button
                @click="discardChanges"
                :disabled="!hasChanges"
                :class="[
                  'px-4 py-2 text-sm font-medium rounded-md transition-all border',
                  hasChanges
                    ? 'border-gray-300 text-gray-700 hover:bg-gray-100 cursor-pointer'
                    : 'border-gray-200 text-gray-400 cursor-not-allowed'
                ]"
              >
                Discard
              </button>
            </template>
          </div>
        </div>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-16">
      <div class="flex items-center space-x-3">
        <svg class="animate-spin h-10 w-10 text-primary-600" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
        </svg>
        <span class="text-gray-600">Loading form...</span>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="flex items-center justify-center py-16">
      <div class="text-center">
        <p class="text-red-600 font-medium">{{ error }}</p>
        <button
          @click="loadFormData"
          class="mt-4 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
        >
          Retry
        </button>
      </div>
    </div>

    <!-- Form Content -->
    <div v-else class="max-w-4xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div class="bg-white rounded-lg shadow-sm p-6">
        <FormRenderer
          v-if="formFields && formFields.length > 0"
          :key="`form-${selectedTheme}-${editMode}`"
          :fields="formFields"
          :formTitle="documentTitle"
          :theme="selectedTheme"
          :editMode="editMode"
          @submit="handleFormSubmit"
          @update:fields="handleFieldsUpdate"
          @field-reorder="handleFieldReorder"
          @field-update="handleFieldUpdate"
        />
        <div v-else class="text-center py-12 text-gray-500">
          <p>No form fields available</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import FormRenderer from '../components/FormRenderer.vue'
import { documentsApi } from '../services/api.js'

const route = useRoute()
const router = useRouter()

const documentId = route.params.id
const loading = ref(true)
const error = ref(null)
const formFields = ref([])
const originalFormFields = ref([])
const documentTitle = ref('')
const selectedTheme = ref('default')
const editMode = ref(false)

const themeNames = {
  default: 'Professional',
  minimal: 'Minimal',
  dark: 'Dark Mode',
  modern: 'Modern',
  classic: 'Classic',
  colorful: 'Colorful',
  professional: 'Corporate',
  vibrant: 'Vibrant'
}

const themeName = computed(() => themeNames[selectedTheme.value] || 'Default')

const hasChanges = computed(() => {
  return JSON.stringify(formFields.value) !== JSON.stringify(originalFormFields.value)
})

const loadFormData = async () => {
  loading.value = true
  error.value = null

  try {
    const response = await documentsApi.getDocumentFormData(documentId)
    const data = response.data.data

    formFields.value = data.form_fields || []
    originalFormFields.value = JSON.parse(JSON.stringify(formFields.value))
    documentTitle.value = data.title || data.filename || 'Form'
    selectedTheme.value = data.theme || 'default'
  } catch (err) {
    console.error('Error loading form data:', err)
    error.value = 'Failed to load form data. Please try again.'
  } finally {
    loading.value = false
  }
}

const toggleEditMode = () => {
  editMode.value = !editMode.value
}

const goBack = () => {
  if (window.history.length > 1) {
    router.go(-1)
  } else {
    router.push('/')
  }
}

const handleFormSubmit = (formData) => {
  console.log('Form submitted:', formData)
  alert('Form submitted! Check console for data.')
}

const handleFieldsUpdate = (updatedFields) => {
  formFields.value = updatedFields
}

const handleFieldReorder = (reorderedFields) => {
  formFields.value = reorderedFields
}

const handleFieldUpdate = (updatedField) => {
  const index = formFields.value.findIndex(f => f.id === updatedField.id)
  if (index !== -1) {
    formFields.value[index] = updatedField
  }
}

const saveFormChanges = async () => {
  try {
    const response = await documentsApi.updateFormStructure(documentId, formFields.value)
    console.log('Save response:', response)
    originalFormFields.value = JSON.parse(JSON.stringify(formFields.value))
    alert('Changes saved successfully!')

    // DON'T reload - this causes the form to revert to original order
    // The save has already updated formFields.value with the new order
  } catch (err) {
    console.error('Error saving changes:', err)
    alert('Failed to save changes')
  }
}

const discardChanges = () => {
  if (confirm('Are you sure you want to discard all unsaved changes?')) {
    formFields.value = JSON.parse(JSON.stringify(originalFormFields.value))
  }
}

onMounted(() => {
  loadFormData()
})
</script>

<style scoped>
/* Additional custom styles if needed */
</style>
