<template>
  <div class="space-y-6">
    <!-- Form Basic Info -->
    <div class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Form Title</label>
        <input
          v-model="formTitle"
          type="text"
          class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          placeholder="Enter form title"
        />
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Description</label>
        <textarea
          v-model="formDescription"
          rows="3"
          class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          placeholder="Enter form description (optional)"
        />
      </div>
    </div>

    <!-- Pages Management -->
    <div class="border-t pt-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-800">Form Pages</h3>
        <div class="flex items-center space-x-2">
          <span class="text-sm text-gray-600">{{ pages.length }} page{{ pages.length !== 1 ? 's' : '' }}</span>
          <button
            @click="addPage"
            class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors duration-200 flex items-center space-x-2"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
            </svg>
            <span>Add Page</span>
          </button>
        </div>
      </div>

      <!-- Page Tabs -->
      <div class="flex border-b border-gray-200 mb-6">
        <button
          v-for="(page, index) in pages"
          :key="page.id"
          @click="currentPageIndex = index"
          :class="[
            'px-4 py-2 text-sm font-medium border-b-2 transition-colors',
            currentPageIndex === index
              ? 'text-primary-600 border-primary-600'
              : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'
          ]"
        >
          Page {{ index + 1 }}
          <span v-if="page.fields.length > 0" class="ml-1 text-xs bg-gray-100 text-gray-600 px-1.5 py-0.5 rounded-full">
            {{ page.fields.length }}
          </span>
          <button
            v-if="pages.length > 1"
            @click.stop="removePage(index)"
            class="ml-2 text-red-500 hover:text-red-700"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </button>
      </div>

      <!-- Current Page Fields -->
      <div class="bg-gray-50 p-4 rounded-lg mb-4">
        <div class="flex items-center justify-between mb-3">
          <h4 class="font-medium text-gray-800">Page {{ currentPageIndex + 1 }} Fields</h4>
          <button
            @click="addField"
            class="px-3 py-1.5 bg-primary-500 text-white text-sm rounded-md hover:bg-primary-600 transition-colors duration-200 flex items-center space-x-1"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
            </svg>
            <span>Add Field</span>
          </button>
        </div>

        <!-- Fields List -->
        <div v-if="currentPage.fields.length === 0" class="text-center py-8 text-gray-500">
          <p>No fields added to this page yet. Click "Add Field" to get started.</p>
        </div>

        <div v-else class="space-y-4">
          <div
            v-for="(field, index) in currentPage.fields"
            :key="field.id"
            class="border border-gray-200 rounded-lg p-4 bg-white"
          >
          <div class="flex items-start justify-between mb-3">
            <div class="flex items-center space-x-2">
              <span class="text-sm font-medium text-gray-500">Field {{ index + 1 }}</span>
              <span class="px-2 py-1 text-xs bg-primary-100 text-primary-700 rounded-full">{{ field.type }}</span>
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
    </div>

    <!-- Create Button -->
    <div class="border-t pt-6 flex justify-end">
      <button
        @click="createForm"
        :disabled="!canCreate"
        class="px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors duration-200 flex items-center space-x-2"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
        </svg>
        <span>{{ creating ? 'Creating...' : 'Create Form' }}</span>
      </button>
    </div>
  </div>
</template>

<script>
import { ref, computed } from 'vue'
import { documentsApi } from '../services/api.js'

export default {
  name: 'FormBuilder',
  emits: ['form-created'],
  setup(props, { emit }) {
    const formTitle = ref('')
    const formDescription = ref('')
    const pages = ref([{
      id: Date.now(),
      fields: []
    }])
    const currentPageIndex = ref(0)
    const creating = ref(false)

    const currentPage = computed(() => pages.value[currentPageIndex.value])
    const totalFields = computed(() => pages.value.reduce((sum, page) => sum + page.fields.length, 0))

    const canCreate = computed(() => {
      return formTitle.value.trim() && totalFields.value > 0 && !creating.value
    })

    const addPage = () => {
      pages.value.push({
        id: Date.now() + Math.random(),
        fields: []
      })
      currentPageIndex.value = pages.value.length - 1
    }

    const removePage = (index) => {
      if (pages.value.length > 1) {
        pages.value.splice(index, 1)
        if (currentPageIndex.value >= pages.value.length) {
          currentPageIndex.value = pages.value.length - 1
        }
      }
    }

    const addField = () => {
      currentPage.value.fields.push({
        id: Date.now() + Math.random(),
        label: '',
        type: 'text',
        required: false,
        options: ''
      })
    }

    const removeField = (index) => {
      currentPage.value.fields.splice(index, 1)
    }

    const createForm = async () => {
      if (!canCreate.value) return

      creating.value = true

      try {
        // Convert pages and fields to the format expected by the backend
        const formattedPages = pages.value.map(page => ({
          fields: page.fields.map(field => ({
            name: field.label.toLowerCase().replace(/\s+/g, '_'),
            label: field.label,
            type: field.type,
            required: field.required,
            ...(field.type === 'radio' || field.type === 'select' ? {
              options: field.options.split('\n').filter(opt => opt.trim()).map(opt => opt.trim())
            } : {})
          }))
        }))

        // Create the document structure
        const documentData = {
          title: formTitle.value,
          description: formDescription.value,
          pages: formattedPages,
          // For backward compatibility, also include all fields flattened
          form_fields: formattedPages.flatMap(page => page.fields)
        }

        // Call the API to create a new blank form
        const response = await documentsApi.createBlankForm(documentData)
        const newDocument = response.data.data

        // Emit the created document
        emit('form-created', newDocument)

        // Reset form
        formTitle.value = ''
        formDescription.value = ''
        pages.value = [{
          id: Date.now(),
          fields: []
        }]
        currentPageIndex.value = 0

      } catch (error) {
        console.error('Failed to create form:', error)
        alert('Failed to create form. Please try again.')
      } finally {
        creating.value = false
      }
    }

    return {
      formTitle,
      formDescription,
      pages,
      currentPageIndex,
      currentPage,
      creating,
      canCreate,
      addPage,
      removePage,
      addField,
      removeField,
      createForm
    }
  }
}
</script>