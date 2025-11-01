<template>
  <div class="responses-container">
    <!-- Header -->
    <div class="responses-header">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold text-gray-900">Form Responses</h2>
          <p class="text-gray-600 mt-1">View all submissions from shared forms</p>
        </div>
        <button
          @click="refreshResponses"
          :disabled="loading"
          class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
        >
          <div v-if="loading" class="flex items-center space-x-2">
            <div class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
            <span>Loading...</span>
          </div>
          <span v-else>Refresh</span>
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading && responses.length === 0" class="responses-loading">
      <div class="text-center py-12">
        <div class="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto"></div>
        <p class="text-gray-600 mt-4">Loading responses...</p>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="responses-error">
      <div class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
        <div class="text-red-600 text-lg font-medium mb-2">Error Loading Responses</div>
        <p class="text-red-700 mb-4">{{ error }}</p>
        <button
          @click="loadResponses"
          class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium transition-colors"
        >
          Try Again
        </button>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="responses.length === 0 && !loading" class="responses-empty">
      <div class="text-center py-12">
        <div class="w-16 h-16 bg-gray-100 rounded-lg flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
        </div>
        <h3 class="text-lg font-medium text-gray-900 mb-2">No responses yet</h3>
        <p class="text-gray-600 mb-6">Share your form to start receiving responses</p>
      </div>
    </div>

    <!-- Responses List -->
    <div v-else class="responses-list">
      <div class="grid grid-cols-1 gap-4">
        <div
          v-for="response in responses"
          :key="response.id"
          @click="viewResponse(response)"
          class="bg-white rounded-lg border border-gray-200 p-6 hover:shadow-md hover:border-blue-300 transition-all cursor-pointer"
        >
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <!-- Response Header -->
              <div class="flex items-center space-x-3 mb-3">
                <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
                  <span class="text-sm font-semibold text-blue-600">
                    {{ getInitials(response.share?.recipient_name || response.share?.recipient_email) }}
                  </span>
                </div>
                <div>
                  <div class="font-medium text-gray-900">
                    {{ response.share?.recipient_name || response.share?.recipient_email }}
                  </div>
                  <div class="text-sm text-gray-500">
                    {{ formatDate(response.inserted_at) }}
                  </div>
                </div>
              </div>

              <!-- Response Preview -->
              <div class="space-y-2">
                <div v-for="(field, index) in getResponsePreview(response.response_data)" :key="index" class="text-sm">
                  <span class="text-gray-600">{{ field.label }}:</span>
                  <span class="text-gray-900 ml-2 font-medium">{{ field.value }}</span>
                </div>
              </div>
            </div>

            <!-- Status Badge -->
            <div class="flex flex-col items-end space-y-2">
              <span
                :class="response.is_completed ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'"
                class="px-2.5 py-0.5 rounded-full text-xs font-medium"
              >
                {{ response.is_completed ? 'Completed' : 'Partial' }}
              </span>
              <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Response Detail Modal -->
    <ResponseDetailModal
      v-if="selectedResponse"
      :response="selectedResponse"
      @close="selectedResponse = null"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { documentsApi } from '../services/api.js'
import ResponseDetailModal from './ResponseDetailModal.vue'

const props = defineProps({
  documentId: {
    type: String,
    required: true
  }
})

const responses = ref([])
const loading = ref(false)
const error = ref(null)
const selectedResponse = ref(null)

const loadResponses = async () => {
  if (!props.documentId) return

  loading.value = true
  error.value = null

  try {
    const response = await documentsApi.getDocumentResponses(props.documentId)
    responses.value = response.data.data || []
    console.log('Loaded responses:', JSON.stringify(responses.value, null, 2))
  } catch (err) {
    console.error('Failed to load responses:', err)
    error.value = err.response?.data?.error || 'Failed to load responses'
  } finally {
    loading.value = false
  }
}

const refreshResponses = () => {
  loadResponses()
}

const viewResponse = (response) => {
  selectedResponse.value = response
}

const formatDate = (timestamp) => {
  if (!timestamp) return 'Unknown'
  const date = new Date(timestamp)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getInitials = (name) => {
  if (!name) return '?'
  return name.split('@')[0].substring(0, 2).toUpperCase()
}

const getResponsePreview = (responseData) => {
  if (!responseData) return []

  // Get the form_data if it exists
  const formData = responseData.form_data || responseData

  // Convert to array and take first 3 fields
  const fields = Object.entries(formData).slice(0, 3).map(([key, value]) => {
    let displayValue = value
    let displayLabel = key

    // If value is an object with label and value properties (enriched data from backend)
    if (typeof value === 'object' && value !== null) {
      displayLabel = value.label || key
      // Use value.value if it exists (even if empty string)
      displayValue = value.value !== undefined ? value.value : value
    }

    // Handle empty values
    if (displayValue === '' || displayValue === null || displayValue === undefined) {
      displayValue = 'No response'
    }

    // Convert arrays/objects to string
    if (typeof displayValue === 'object') {
      displayValue = Array.isArray(displayValue) ? displayValue.join(', ') : JSON.stringify(displayValue)
    }

    // Truncate long values
    if (typeof displayValue === 'string' && displayValue.length > 50) {
      displayValue = displayValue.substring(0, 50) + '...'
    }

    return {
      label: displayLabel,
      value: displayValue
    }
  })

  return fields
}

onMounted(() => {
  loadResponses()
})
</script>

<style scoped>
.responses-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.responses-header {
  margin-bottom: 2rem;
}

.responses-list {
  /* Additional styling if needed */
}
</style>
