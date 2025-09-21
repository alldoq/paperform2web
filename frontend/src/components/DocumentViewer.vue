<template>
  <!-- Modal Overlay -->
  <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
    <div class="bg-white rounded-xl shadow-xl w-[80%] max-h-[90vh] flex flex-col">
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

      <!-- Main Template Selection Content -->
      <div class="flex-1 overflow-hidden bg-gradient-to-br from-gray-50 via-blue-50/30 to-gray-100">
        <div v-if="document.status === 'completed'" class="h-full p-8 overflow-auto">
          <div class="max-w-6xl mx-auto">

            <!-- Header Section -->
            <div class="text-center mb-8">
Choose a template for your form:
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
                    <div class="w-5 h-5 border-2 border-primary-600 border-t-transparent rounded-full animate-spin"></div>
                    <span class="text-sm font-medium text-primary-600">Applying...</span>
                  </div>
                </div>
              </button>
            </div>

          </div>
        </div>

        <!-- Processing State -->
        <div v-else class="flex items-center justify-center h-full">
          <div class="text-center space-y-4">
            <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto">
              <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
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
        <div class="flex items-center space-x-3">
          <button
            @click="openHTMLInNewTab"
            v-if="document.status === 'completed'"
            class="px-4 py-2 text-sm font-medium rounded-md transition-colors bg-primary-100 text-primary-700 hover:bg-primary-200 border border-primary-200"
          >
            👁️ Preview
          </button>
          <button
            @click="openEditableHTMLInNewTab"
            v-if="document.status === 'completed'"
            class="px-4 py-2 text-sm font-medium rounded-md transition-colors bg-green-500 text-white hover:bg-green-600 shadow-md"
          >
            ✏️ Edit
          </button>
        </div>


        <button
          @click="$emit('close')"
          class="px-4 py-2 text-sm font-medium rounded-md transition-colors bg-gray-500 text-white hover:bg-gray-600"
        >
          Close
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, watch } from 'vue'
import { DocumentTextIcon, XMarkIcon } from '@heroicons/vue/24/outline'
import StatusBadge from './StatusBadge.vue'
import { documentsApi } from '../services/api.js'

export default {
  name: 'DocumentViewer',
  components: {
    DocumentTextIcon,
    XMarkIcon,
    StatusBadge
  },
  props: {
    document: {
      type: Object,
      required: true
    }
  },
  emits: ['close', 'document-updated'],
  setup(props, { emit }) {
    const selectedTheme = ref(props.document.theme || 'default')
    const isUpdatingTheme = ref(false)


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
        value: 'newspaper',
        name: 'Newspaper',
        headerStyle: 'background: #000; color: white;',
        contentStyle: 'background: white; color: #000;',
        inputStyle: 'background: transparent; border-bottom: 2px solid #000;',
        previewStyle: 'background: #f5f5dc; border: 2px solid #000;'
      },
      {
        value: 'elegant',
        name: 'Elegant',
        headerStyle: 'background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%); color: #ecf0f1;',
        contentStyle: 'background: white; color: #2c3e50;',
        inputStyle: 'background: #fcfcfc; border: 1px solid #d5d8dc;',
        previewStyle: 'background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);'
      }
    ])

    const getTemplateName = (themeValue) => {
      const template = templateOptions.value.find(t => t.value === themeValue)
      return template ? template.name : 'Professional'
    }

    const selectTemplate = async (themeValue) => {
      if (themeValue === selectedTheme.value || isUpdatingTheme.value) return

      selectedTheme.value = themeValue
      await updateTheme()

      // After theme is updated, redirect to edit mode
      setTimeout(() => {
        openEditableHTMLInNewTab()
      }, 500)
    }


    // Watch for document changes to update selected theme
    watch(() => props.document, () => {
      selectedTheme.value = props.document?.theme || 'default'
    }, { immediate: true })

    watch(() => props.document.theme, (newTheme) => {
      selectedTheme.value = newTheme || 'default'
    })

    const formatDate = (timestamp) => {
      if (!timestamp) return 'Unknown'

      // Handle different timestamp formats
      let date
      if (typeof timestamp === 'string') {
        // Convert Elixir/Phoenix datetime strings
        date = new Date(timestamp.replace(' ', 'T'))
      } else {
        date = new Date(timestamp)
      }

      if (isNaN(date.getTime())) {
        console.warn('Invalid timestamp:', timestamp)
        return 'Invalid Date'
      }

      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    const downloadHTML = () => {
      const link = document.createElement('a')
      link.href = `/api/documents/${props.document.id}/html`
      link.download = `${props.document.filename.replace(/\.[^/.]+$/, "")}.html`
      link.click()
    }

    const openHTMLInNewTab = () => {
      window.open(`/api/documents/${props.document.id}/html`, '_blank')
    }

    const openEditableHTMLInNewTab = () => {
      window.open(`/api/documents/${props.document.id}/html?editing=true`, '_blank')
    }

    const updateTheme = async () => {
      if (selectedTheme.value === props.document.theme) return
      
      isUpdatingTheme.value = true
      
      try {
        const response = await documentsApi.updateDocumentTheme(props.document.id, selectedTheme.value)
        emit('document-updated', response.data.data)
      } catch (error) {
        console.error('Failed to update theme:', error)
        // Reset theme selector to original value on error
        selectedTheme.value = props.document.theme || 'default'
      } finally {
        isUpdatingTheme.value = false
      }
    }

    return {
      selectedTheme,
      isUpdatingTheme,
      templateOptions,
      formatDate,
      downloadHTML,
      openHTMLInNewTab,
      openEditableHTMLInNewTab,
      updateTheme,
      getTemplateName,
      selectTemplate
    }
  }
}
</script>

<style scoped>
/* Template selection animations */
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.template-card-enter-active {
  animation: fadeInUp 0.3s ease-out;
}

/* Enhance hover effects for template cards */
.template-card {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.template-card:hover {
  transform: translateY(-4px) scale(1.02);
}
</style>