<template>
  <!-- Modal Overlay -->
  <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
    <div class="bg-white rounded-xl shadow-xl w-[95%] max-h-[90vh] flex flex-col">
      <!-- Header -->
      <div class="flex items-center justify-between p-6 border-b border-gray-200">
        <div class="flex items-center space-x-3">
          <div class="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center">
            <DocumentTextIcon class="w-4 h-4 text-primary-600" />
          </div>
          <div>
            <h2 class="text-lg font-semibold text-gray-900">{{ document.filename }}</h2>
            <div class="flex items-center space-x-2 text-sm text-gray-500">
              <span>{{ formatDate(document.updated_at) }}</span>
              <span>•</span>
              <StatusBadge :status="document.status" />
            </div>
          </div>
        </div>

        <!-- Close Button -->
        <button
          @click="$emit('close')"
          class="p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100"
        >
          <XMarkIcon class="w-5 h-5" />
        </button>
      </div>

      <!-- Tabs Navigation -->
      <div class="border-b border-gray-200 bg-white">
        <nav class="flex space-x-8 px-6" aria-label="Tabs">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            :class="[
              activeTab === tab.id
                ? 'border-primary-500 text-primary-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
              'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm'
            ]"
          >
            {{ tab.name }}
          </button>
        </nav>
      </div>

      <!-- Tab Content -->
      <div class="flex-1 overflow-y-auto bg-gradient-to-br from-gray-50 via-blue-50/30 to-gray-100">
        <!-- Preview Tab -->
        <div v-if="activeTab === 'preview' && document.status === 'completed'" class="p-8">
          <div class="max-w-4xl mx-auto">
            <!-- Mode Toggle -->
            <div class="flex justify-end mb-4">
              <div class="flex items-center gap-3">
                <div class="flex bg-gray-100 rounded-lg p-1">
                  <button
                    @click="editMode = false"
                    :class="[
                      'px-3 py-1 rounded text-sm font-medium transition-colors',
                      !editMode ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900'
                    ]"
                  >
                    Preview
                  </button>
                  <button
                    @click="editMode = true"
                    :class="[
                      'px-3 py-1 rounded text-sm font-medium transition-colors',
                      editMode ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900'
                    ]"
                  >
                    Edit
                  </button>
                </div>

                <!-- Save/Discard buttons (always shown in edit mode) -->
                <template v-if="editMode">
                  <div class="border-l border-gray-300 h-6"></div>
                  <button
                    @click="saveFormChanges"
                    :disabled="!hasChanges"
                    :class="[
                      'px-4 py-1.5 rounded text-sm font-medium transition-all shadow-sm',
                      hasChanges
                        ? 'bg-blue-600 text-white hover:bg-blue-700 cursor-pointer'
                        : 'bg-gray-300 text-gray-500 cursor-not-allowed'
                    ]"
                  >
                    Save Changes
                  </button>
                  <button
                    @click="discardChanges"
                    :disabled="!hasChanges"
                    :class="[
                      'px-4 py-1.5 rounded text-sm font-medium border transition-colors',
                      hasChanges
                        ? 'border-gray-300 text-gray-700 hover:bg-gray-50 cursor-pointer'
                        : 'border-gray-200 text-gray-400 cursor-not-allowed'
                    ]"
                  >
                    Discard
                  </button>
                </template>
              </div>
            </div>

            <!-- Form Renderer -->
            <div v-if="!loadingFormData" class="bg-white rounded-lg shadow-sm p-6">
              <FormRenderer
                v-if="formFields && formFields.length > 0"
                :key="`form-${selectedTheme}-${editMode}`"
                :fields="formFields"
                :formTitle="document.filename || 'Form'"
                :theme="selectedTheme"
                :editMode="editMode"
                @submit="handleFormSubmit"
                @update:fields="handleFieldsUpdate"
                @field-reorder="handleFieldReorder"
                @field-update="handleFieldUpdate"
                @save-fields="handleSaveFields"
              />
              <div v-else class="text-center py-12 text-gray-500">
                <p>No form fields available</p>
              </div>
            </div>
            <div v-else class="flex items-center justify-center py-12">
              <div class="flex items-center space-x-3">
                <svg class="animate-spin h-8 w-8 text-primary-600" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                </svg>
                <span class="text-gray-600">Loading form data...</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Template Tab -->
        <div v-if="activeTab === 'template' && document.status === 'completed'" class="p-8">
          <div class="max-w-6xl mx-auto">
            <!-- Header Section -->
            <div class="text-center mb-8">
              <h3 class="text-lg font-semibold text-gray-900">Choose a template for your form</h3>
              <p class="text-sm text-gray-600 mt-2">Click any template to preview it in a new tab</p>
            </div>

            <!-- Template Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
              <button
                v-for="template in templateOptions"
                :key="template.value"
                @click="selectTemplate(template.value)"
                :class="[
                  'relative p-4 rounded-2xl border-3 transition-all duration-300 hover:shadow-xl hover:scale-105',
                  selectedTheme === template.value
                    ? 'border-primary-500 bg-primary-50 shadow-lg ring-4 ring-primary-200'
                    : 'border-gray-200 bg-white hover:border-gray-300'
                ]"
                :disabled="isUpdatingTheme"
              >
                <!-- Template Preview -->
                <div class="mb-4 h-24 rounded-xl overflow-hidden shadow-sm" :style="template.previewStyle">
                  <div class="h-6 text-white text-xs flex items-center justify-center font-bold" :style="template.headerStyle">
                    {{ template.name }}
                  </div>
                  <div class="h-18 p-3 text-xs" :style="template.contentStyle">
                    <div class="mb-2 font-bold text-xs">Sample Field</div>
                    <div class="w-full h-3 rounded-md" :style="template.inputStyle"></div>
                  </div>
                </div>

                <!-- Template Name & Selection -->
                <div class="text-center">
                  <h3 class="text-sm font-semibold mb-1" :class="selectedTheme === template.value ? 'text-primary-700' : 'text-gray-700'">
                    {{ template.name }}
                  </h3>
                  <div v-if="selectedTheme === template.value" class="flex items-center justify-center space-x-1 text-xs text-primary-600">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                    </svg>
                    <span class="font-medium">Selected</span>
                  </div>
                </div>

                <!-- Loading Spinner -->
                <div v-if="isUpdatingTheme && selectedTheme === template.value" class="absolute inset-0 bg-white/90 rounded-2xl flex items-center justify-center">
                  <div class="flex items-center space-x-2">
                    <svg class="animate-spin h-5 w-5 text-primary-600" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                    </svg>
                    <span class="text-sm text-gray-600">Applying...</span>
                  </div>
                </div>
              </button>
            </div>
          </div>
        </div>

        <!-- Shares Tab -->
        <div v-if="activeTab === 'shares' && document.status === 'completed'" class="p-8">
          <SharesList
            :documentId="document.id"
            @view-analytics="viewShareAnalytics"
          />
        </div>

        <!-- Analytics Tab -->
        <div v-if="activeTab === 'analytics' && document.status === 'completed'" class="p-8">
          <ShareAnalytics
            v-if="selectedShareToken"
            :shareToken="selectedShareToken"
            @close="selectedShareToken = null"
          />
          <div v-else class="text-center py-12 text-gray-500">
            <p>Select a share from the Shares tab to view analytics</p>
          </div>
        </div>

        <!-- Processing Status -->
        <div v-if="document.status !== 'completed'" class="flex items-center justify-center py-16">
          <div class="flex items-center space-x-3">
            <div class="flex items-center justify-center">
              <svg class="animate-spin h-10 w-10 text-primary-600" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
              </svg>
            </div>
            <div>
              <p class="text-gray-900 font-medium">Processing Document</p>
              <p class="text-sm text-gray-500 mt-1">Please wait while we convert your document...</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-between p-6 border-t border-gray-200 bg-gray-50">
        <div class="flex items-center space-x-2">
          <button
            @click="openPreviewInNewTab"
            v-if="document.status === 'completed'"
            class="flex items-center space-x-2 px-4 py-2 text-sm font-medium rounded-md transition-colors bg-white text-gray-700 hover:bg-gray-100 border border-gray-300"
          >
            <EyeIcon class="w-4 h-4" />
            <span>Open Preview</span>
          </button>
          <button
            @click="saveFormChanges"
            v-if="document.status === 'completed' && editMode && hasChanges"
            class="flex items-center space-x-2 px-4 py-2 text-sm font-medium rounded-md transition-colors bg-green-600 text-white hover:bg-green-700 shadow-sm"
          >
            <CheckIcon class="w-4 h-4" />
            <span>Save Changes</span>
          </button>
          <button
            @click="showShareDialog = true"
            v-if="document.status === 'completed'"
            class="flex items-center space-x-2 px-4 py-2 text-sm font-medium rounded-md transition-colors bg-blue-600 text-white hover:bg-blue-700 shadow-sm"
          >
            <ShareIcon class="w-4 h-4" />
            <span>Share</span>
          </button>
        </div>

        <button
          @click="$emit('close')"
          class="px-4 py-2 text-sm font-medium rounded-md transition-colors bg-gray-200 text-gray-800 hover:bg-gray-300"
        >
          Close
        </button>
      </div>

      <!-- Share Dialog -->
      <ShareDialog
        v-if="showShareDialog"
        :document="document"
        @close="showShareDialog = false"
        @share-sent="onShareSent"
      />
    </div>
  </div>
</template>

<script>
import { ref, watch, onMounted } from 'vue'
import { DocumentTextIcon, XMarkIcon, ShareIcon, EyeIcon, PencilIcon, CheckIcon } from '@heroicons/vue/24/outline'
import StatusBadge from './StatusBadge.vue'
import ShareDialog from './ShareDialog.vue'
import SharesList from './SharesList.vue'
import ShareAnalytics from './ShareAnalytics.vue'
import FormRenderer from './FormRenderer.vue'
import { documentsApi } from '../services/api.js'

export default {
  name: 'DocumentViewer',
  components: {
    DocumentTextIcon,
    XMarkIcon,
    ShareIcon,
    EyeIcon,
    PencilIcon,
    CheckIcon,
    StatusBadge,
    ShareDialog,
    SharesList,
    ShareAnalytics,
    FormRenderer
  },
  props: {
    document: {
      type: Object,
      required: true
    }
  },
  emits: ['close', 'document-updated', 'edit-mode-changed', 'changes-state-changed'],
  setup(props, { emit, expose }) {
    const selectedTheme = ref(props.document.theme || 'default')
    const isUpdatingTheme = ref(false)
    const showShareDialog = ref(false)
    const activeTab = ref('preview')
    const selectedShareToken = ref(null)
    const editMode = ref(false)
    const formFields = ref([])
    const originalFormFields = ref([])
    const loadingFormData = ref(false)
    const hasChanges = ref(false)
    const useNewRenderer = ref(true) // Toggle for new vs old rendering

    const tabs = ref([
      { id: 'preview', name: 'Preview' },
      { id: 'template', name: 'Template' },
      { id: 'shares', name: 'Shares' },
      { id: 'analytics', name: 'Analytics' }
    ])

    const templateOptions = ref([
      {
        value: 'default',
        name: 'Professional',
        headerStyle: 'background: #2c3e50;',
        contentStyle: 'background: #f4f4f4; color: #333;',
        inputStyle: 'background: #ddd;',
        previewStyle: 'background: #f4f4f4;'
      },
      {
        value: 'minimal',
        name: 'Minimal',
        headerStyle: 'background: #eee; color: #222; border-bottom: 2px solid #eee;',
        contentStyle: 'background: white; color: #222;',
        inputStyle: 'background: #f8f8f8; border-bottom: 1px solid #ccc;',
        previewStyle: 'background: white;'
      },
      {
        value: 'dark',
        name: 'Dark Mode',
        headerStyle: 'background: #1e3a5f;',
        contentStyle: 'background: #2d2d2d; color: #e0e0e0;',
        inputStyle: 'background: #3a3a3a;',
        previewStyle: 'background: #1a1a1a;'
      },
      {
        value: 'modern',
        name: 'Modern',
        headerStyle: 'background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);',
        contentStyle: 'background: white; color: #1f2937;',
        inputStyle: 'background: #f7fafc; border: 2px solid #e2e8f0; border-radius: 6px;',
        previewStyle: 'background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);'
      },
      {
        value: 'classic',
        name: 'Classic',
        headerStyle: 'background: #8b4513; color: #f4e4c1;',
        contentStyle: 'background: white; color: #2c3e50;',
        inputStyle: 'background: #fefefe; border: 2px solid #8b4513;',
        previewStyle: 'background: #f8f9fa; border: 3px double #8b4513;'
      },
      {
        value: 'colorful',
        name: 'Colorful',
        headerStyle: 'background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);',
        contentStyle: 'background: linear-gradient(135deg, #fff9e6 0%, #f0f8ff 100%); color: #2c3e50;',
        inputStyle: 'background: linear-gradient(135deg, #fff 0%, #f8f9ff 100%); border: 3px solid #ff6b6b; border-radius: 8px;',
        previewStyle: 'background: linear-gradient(45deg, #ff9a9e 0%, #fecfef 50%, #fecfef 100%);'
      },
      {
        value: 'professional',
        name: 'Corporate',
        headerStyle: 'background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);',
        contentStyle: 'background: white; color: #2c3e50;',
        inputStyle: 'background: #f7f9fc; border: 2px solid #e2e8f0; border-radius: 4px;',
        previewStyle: 'background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);'
      },
      {
        value: 'vibrant',
        name: 'Vibrant',
        headerStyle: 'background: linear-gradient(135deg, #ff6b6b 0%, #ff8e53 100%);',
        contentStyle: 'background: linear-gradient(135deg, #fff5f5 0%, #fff0e6 100%); color: #2c3e50;',
        inputStyle: 'background: white; border: 3px solid #ff6b6b; border-radius: 10px;',
        previewStyle: 'background: linear-gradient(135deg, #ff6b6b 0%, #ff8e53 100%);'
      }
    ])

    // Load form data from the new JSON endpoint
    const loadFormData = async () => {
      if (props.document.status !== 'completed') return

      loadingFormData.value = true
      try {
        const response = await documentsApi.getDocumentFormData(props.document.id)
        formFields.value = response.data.data.form_fields || []
        originalFormFields.value = JSON.parse(JSON.stringify(formFields.value))
        hasChanges.value = false
      } catch (error) {
        console.error('Error loading form data:', error)
        formFields.value = []
      } finally {
        loadingFormData.value = false
      }
    }

    // Handle form submission
    const handleFormSubmit = (formData) => {
      console.log('Form submitted:', formData)
      // Here you can handle form submission, e.g., send to API
      alert('Form submitted! Check console for data.')
    }

    // Handle field updates
    const handleFieldsUpdate = (updatedFields) => {
      formFields.value = updatedFields
      checkForChanges()
    }

    const handleFieldReorder = (reorderedFields) => {
      formFields.value = reorderedFields
      checkForChanges()
    }

    const handleFieldUpdate = (updatedField) => {
      const index = formFields.value.findIndex(f => f.id === updatedField.id)
      if (index !== -1) {
        formFields.value[index] = updatedField
        checkForChanges()
      }
    }

    const handleSaveFields = async (updatedFields) => {
      try {
        // Update local state
        formFields.value = updatedFields

        // Save to backend
        const response = await documentsApi.updateFormStructure(props.document.id, updatedFields)

        // Update original fields to reflect saved state
        originalFormFields.value = JSON.parse(JSON.stringify(updatedFields))
        hasChanges.value = false

        // Notify parent component
        emit('document-updated', response.data.data)

        alert('Changes saved successfully!')
        console.log('Fields saved successfully')
      } catch (error) {
        console.error('Error saving fields:', error)
        alert('Failed to save changes. Please try again.')
      }
    }

    const checkForChanges = () => {
      hasChanges.value = JSON.stringify(formFields.value) !== JSON.stringify(originalFormFields.value)
    }

    // Save form changes to backend
    const saveFormChanges = async () => {
      try {
        const response = await documentsApi.updateFormStructure(props.document.id, formFields.value)
        originalFormFields.value = JSON.parse(JSON.stringify(formFields.value))
        hasChanges.value = false

        // Notify parent to update document
        emit('document-updated', response.data.data)

        alert('Changes saved successfully!')

        // Reload form data to ensure we have the latest from database
        await loadFormData()
      } catch (error) {
        console.error('Error saving changes:', error)
        alert('Failed to save changes')
      }
    }

    // Discard changes and restore original state
    const discardChanges = () => {
      if (confirm('Are you sure you want to discard all unsaved changes?')) {
        formFields.value = JSON.parse(JSON.stringify(originalFormFields.value))
        hasChanges.value = false
      }
    }

    const selectTemplate = async (templateValue) => {
      if (isUpdatingTheme.value) return

      selectedTheme.value = templateValue
      isUpdatingTheme.value = true

      try {
        const response = await documentsApi.updateDocumentTheme(props.document.id, templateValue)
        emit('document-updated', response.data.data)

        // Open preview in new tab after theme is applied
        setTimeout(() => {
          isUpdatingTheme.value = false
          openPreviewInNewTab()
        }, 500)
      } catch (error) {
        console.error('Error updating theme:', error)
        isUpdatingTheme.value = false
      }
    }

    const openPreviewInNewTab = () => {
      const previewUrl = `/preview/${props.document.id}`
      window.open(previewUrl, '_blank')
    }

    const formatDate = (timestamp) => {
      const date = new Date(timestamp)
      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    const openHTMLInNewTab = () => {
      const url = `/api/documents/${props.document.id}/html?editing=false&theme=${selectedTheme.value}`
      window.open(url, '_blank')
    }

    const openEditableHTMLInNewTab = () => {
      const url = `/api/documents/${props.document.id}/html?editing=true&theme=${selectedTheme.value}`
      window.open(url, '_blank')
    }

    const onShareSent = () => {
      showShareDialog.value = false
      activeTab.value = 'shares'
    }

    const viewShareAnalytics = (token) => {
      selectedShareToken.value = token
      activeTab.value = 'analytics'
    }

    // Load form data when component mounts or document changes
    onMounted(() => {
      loadFormData()
    })

    watch(() => props.document, () => {
      selectedTheme.value = props.document.theme || 'default'
      loadFormData()
    }, { deep: true })

    // Watch for edit mode changes and emit to parent
    watch(editMode, (newValue) => {
      emit('edit-mode-changed', newValue)
    })

    // Watch for hasChanges changes and emit to parent
    watch(hasChanges, (newValue) => {
      emit('changes-state-changed', newValue)
    })

    // Expose methods to parent component
    expose({
      triggerSave: saveFormChanges,
      triggerDiscard: discardChanges
    })

    return {
      selectedTheme,
      isUpdatingTheme,
      showShareDialog,
      activeTab,
      selectedShareToken,
      editMode,
      formFields,
      loadingFormData,
      hasChanges,
      useNewRenderer,
      tabs,
      templateOptions,
      selectTemplate,
      formatDate,
      openHTMLInNewTab,
      openEditableHTMLInNewTab,
      openPreviewInNewTab,
      onShareSent,
      viewShareAnalytics,
      handleFormSubmit,
      handleFieldsUpdate,
      handleFieldReorder,
      handleFieldUpdate,
      handleSaveFields,
      saveFormChanges,
      discardChanges,
      loadFormData
    }
  }
}
</script>

<style scoped>
/* Custom scrollbar for form preview */
.form-preview-container::-webkit-scrollbar {
  width: 8px;
}

.form-preview-container::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 4px;
}

.form-preview-container::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 4px;
}

.form-preview-container::-webkit-scrollbar-thumb:hover {
  background: #555;
}
</style>