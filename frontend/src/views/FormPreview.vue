<template>
  <div class="min-h-screen" :style="getThemeBackgroundStyle()">
    <!-- Header -->
    <div class="shadow-sm" :style="getHeaderStyle()">
      <div class="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <button
              @click="goBack"
              class="p-2 rounded-lg transition-colors back-button"
              :class="{ 'dark-header': isDarkHeader }"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </button>
            <div>
              <h1 class="text-xl font-semibold" :style="getHeaderTextStyle()">{{ documentTitle }}</h1>
              <p class="text-sm" :style="getHeaderSubtextStyle()">{{ themeName }} Theme</p>
            </div>
          </div>

          <div class="flex items-center space-x-3">
            <!-- Theme Selector -->
            <select
              v-model="selectedTheme"
              @change="handleThemeChange"
              class="px-3 py-2 text-sm font-medium rounded-md border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 transition-colors cursor-pointer"
            >
              <option value="default">Professional Theme</option>
              <option value="minimal">Minimal Theme</option>
              <option value="dark">Dark Theme</option>
              <option value="modern">Modern Theme</option>
              <option value="classic">Classic Theme</option>
              <option value="colorful">Colorful Theme</option>
              <option value="professional">Corporate Theme</option>
              <option value="vibrant">Vibrant Theme</option>
            </select>

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
      <div class="rounded-lg shadow-sm p-6" :style="getFormContainerStyle()">
        <FormRenderer
          v-if="formFields && formFields.length > 0"
          :key="`form-${selectedTheme}-${editMode}`"
          :fields="formFields"
          :formTitle="documentTitle"
          :theme="selectedTheme"
          :editMode="editMode"
          :pageCount="pageCount"
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
const pageCount = ref(1)

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

const isDarkHeader = computed(() => {
  return ['dark', 'modern', 'classic', 'colorful', 'professional', 'vibrant'].includes(selectedTheme.value)
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
    pageCount.value = data.metadata?.page_count || data.metadata?.total_pages || 1
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

const handleThemeChange = async () => {
  try {
    // Update the theme on the server
    await documentsApi.updateDocumentTheme(documentId, selectedTheme.value)
    console.log('Theme updated to:', selectedTheme.value)
  } catch (err) {
    console.error('Error updating theme:', err)
    alert('Failed to update theme')
  }
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

// Theme styling functions
const getThemeBackgroundStyle = () => {
  const themeBackgrounds = {
    'default': 'background: linear-gradient(to bottom right, #f8f9fa, #e9ecef);',
    'minimal': 'background: white;',
    'dark': 'background: #1a1a1a;',
    'modern': 'background: linear-gradient(to bottom right, #f7fafc, #edf2f7);',
    'classic': 'background: linear-gradient(to bottom right, #fef5e7, #f8f9fa);',
    'colorful': 'background: linear-gradient(to bottom right, #fff9e6, #ffe6f0);',
    'professional': 'background: linear-gradient(to bottom right, #f0f4f8, #e2e8f0);',
    'vibrant': 'background: linear-gradient(to bottom right, #fff5f5, #fff0e6);'
  }
  return themeBackgrounds[selectedTheme.value] || themeBackgrounds['default']
}

const getHeaderStyle = () => {
  const headerStyles = {
    'default': 'background: white; border-bottom: 1px solid #e5e7eb;',
    'minimal': 'background: white; border-bottom: 1px solid #e5e7eb;',
    'dark': 'background: #1e3a5f; border-bottom: 1px solid #2d4a6f;',
    'modern': 'background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-bottom: none;',
    'classic': 'background: #8b4513; border-bottom: 3px double #a0522d;',
    'colorful': 'background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-bottom: none;',
    'professional': 'background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); border-bottom: none;',
    'vibrant': 'background: linear-gradient(135deg, #ff6b6b 0%, #ff8e53 100%); border-bottom: none;'
  }
  return headerStyles[selectedTheme.value] || headerStyles['default']
}

const getHeaderTextStyle = () => {
  return isDarkHeader.value ? 'color: white;' : 'color: #111827;'
}

const getHeaderSubtextStyle = () => {
  return isDarkHeader.value ? 'color: rgba(255, 255, 255, 0.8);' : 'color: #6b7280;'
}

const getFormContainerStyle = () => {
  const themeContainers = {
    'default': 'background: white;',
    'minimal': 'background: white; border: 1px solid #e5e7eb;',
    'dark': 'background: #2d2d2d;',
    'modern': 'background: white;',
    'classic': 'background: white;',
    'colorful': 'background: linear-gradient(135deg, #fff9e6 0%, #f0f8ff 100%);',
    'professional': 'background: white;',
    'vibrant': 'background: linear-gradient(135deg, #fff5f5 0%, #fff0e6 100%);'
  }
  return themeContainers[selectedTheme.value] || themeContainers['default']
}

onMounted(() => {
  loadFormData()
})
</script>

<style scoped>
/* Header button styles */
.back-button {
  color: #9ca3af;
}

.back-button:hover {
  color: #4b5563;
  background: #f3f4f6;
}

.back-button.dark-header {
  color: rgba(255, 255, 255, 0.8);
}

.back-button.dark-header:hover {
  color: white;
  background: rgba(255, 255, 255, 0.1);
}
</style>
