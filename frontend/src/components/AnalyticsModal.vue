<template>
  <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50" @click.self="$emit('close')">
    <div class="bg-white rounded-xl shadow-xl w-full max-w-4xl max-h-[90vh] flex flex-col">
      <!-- Header -->
      <div class="flex items-center justify-between p-6 border-b border-gray-200">
        <div>
          <h2 class="text-2xl font-bold text-gray-900">Response Analytics</h2>
          <p class="text-gray-600 mt-1">{{ share.recipient_email }}</p>
        </div>
        <button
          @click="$emit('close')"
          class="text-gray-400 hover:text-gray-600 transition-colors"
        >
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Content -->
      <div class="flex-1 overflow-y-auto p-6">
        <!-- Loading State -->
        <div v-if="loading" class="flex flex-col items-center justify-center py-12">
          <div class="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mb-4"></div>
          <p class="text-gray-600">Loading analytics...</p>
        </div>

        <!-- Error State -->
        <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
          <div class="text-red-600 text-lg font-medium mb-2">Error Loading Analytics</div>
          <p class="text-red-700 mb-4">{{ error }}</p>
          <button
            @click="loadAnalytics"
            class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium transition-colors"
          >
            Try Again
          </button>
        </div>

        <!-- Analytics Data -->
        <div v-else-if="analytics" class="space-y-6">
          <!-- Summary Stats -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-4 border border-blue-200">
              <div class="text-sm font-medium text-blue-800 mb-1">Total Responses</div>
              <div class="text-3xl font-bold text-blue-900">{{ analytics.summary.total_responses }}</div>
            </div>
            <div class="bg-gradient-to-br from-green-50 to-green-100 rounded-lg p-4 border border-green-200">
              <div class="text-sm font-medium text-green-800 mb-1">Completed</div>
              <div class="text-3xl font-bold text-green-900">{{ analytics.summary.completed_responses }}</div>
            </div>
            <div class="bg-gradient-to-br from-purple-50 to-purple-100 rounded-lg p-4 border border-purple-200">
              <div class="text-sm font-medium text-purple-800 mb-1">Completion Rate</div>
              <div class="text-3xl font-bold text-purple-900">{{ Math.round(analytics.summary.completion_rate * 100) }}%</div>
            </div>
          </div>

          <!-- Share Info -->
          <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900 mb-3">Share Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
              <div>
                <span class="text-gray-600">Total Opens:</span>
                <span class="font-medium text-gray-900 ml-2">{{ analytics.share.total_opens || 0 }}</span>
              </div>
              <div>
                <span class="text-gray-600">Response Count:</span>
                <span class="font-medium text-gray-900 ml-2">{{ analytics.share.response_count || 0 }}</span>
              </div>
              <div v-if="analytics.share.sent_at">
                <span class="text-gray-600">Sent:</span>
                <span class="font-medium text-gray-900 ml-2">{{ formatDate(analytics.share.sent_at) }}</span>
              </div>
              <div v-if="analytics.share.first_response_at">
                <span class="text-gray-600">First Response:</span>
                <span class="font-medium text-gray-900 ml-2">{{ formatDate(analytics.share.first_response_at) }}</span>
              </div>
              <div v-if="analytics.share.last_response_at">
                <span class="text-gray-600">Last Response:</span>
                <span class="font-medium text-gray-900 ml-2">{{ formatDate(analytics.share.last_response_at) }}</span>
              </div>
              <div>
                <span class="text-gray-600">Status:</span>
                <span :class="analytics.share.is_completed ? 'text-green-600' : 'text-blue-600'" class="font-medium ml-2">
                  {{ analytics.share.is_completed ? 'Completed' : 'In Progress' }}
                </span>
              </div>
            </div>
          </div>

          <!-- Field Analytics -->
          <div v-if="analytics.analytics && analytics.analytics.length > 0">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Field Response Breakdown</h3>
            <div class="space-y-4">
              <div
                v-for="(field, index) in analytics.analytics"
                :key="index"
                class="bg-white rounded-lg border border-gray-200 p-4 hover:shadow-md transition-shadow"
              >
                <div class="flex items-start justify-between mb-3">
                  <div class="flex-1">
                    <div class="flex items-center space-x-2 mb-1">
                      <span class="text-xs font-medium text-gray-500 uppercase tracking-wider">
                        {{ field.field_type }}
                      </span>
                      <span class="text-xs text-gray-400">•</span>
                      <span class="text-xs text-gray-500">
                        {{ field.field_key }}
                      </span>
                    </div>
                    <h4 class="text-base font-medium text-gray-900">{{ field.field_label || field.field_key }}</h4>
                  </div>
                  <div class="text-right">
                    <div class="text-sm text-gray-600">
                      {{ field.response_count }} responses
                    </div>
                    <div class="text-xs text-gray-500">
                      {{ Math.round(field.completion_rate * 100) }}% completion
                    </div>
                  </div>
                </div>

                <!-- Response Value -->
                <div class="mt-3 pt-3 border-t border-gray-100">
                  <div class="text-sm text-gray-700">
                    <span class="font-medium">Most Common Response:</span>
                    <div class="mt-1 p-2 bg-gray-50 rounded border border-gray-200">
                      <span class="text-gray-900">{{ formatResponseValue(field.response_value) }}</span>
                    </div>
                  </div>
                </div>

                <!-- Progress Bar -->
                <div class="mt-3">
                  <div class="w-full bg-gray-200 rounded-full h-2">
                    <div
                      class="bg-blue-600 h-2 rounded-full transition-all duration-300"
                      :style="{ width: `${field.completion_rate * 100}%` }"
                    ></div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Empty State for Analytics -->
          <div v-else class="text-center py-8">
            <div class="w-16 h-16 bg-gray-100 rounded-lg flex items-center justify-center mx-auto mb-4">
              <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            </div>
            <h3 class="text-lg font-medium text-gray-900 mb-2">No field data available</h3>
            <p class="text-gray-600">Response analytics will appear here once data is collected</p>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex justify-end gap-3 p-6 border-t border-gray-200">
        <button
          @click="$emit('close')"
          class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg font-medium transition-colors"
        >
          Close
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { documentsApi } from '../services/api.js'

const props = defineProps({
  share: {
    type: Object,
    required: true
  }
})

defineEmits(['close'])

const analytics = ref(null)
const loading = ref(true)
const error = ref(null)

const loadAnalytics = async () => {
  loading.value = true
  error.value = null

  try {
    const response = await documentsApi.getShareAnalytics(props.share.share_token)
    analytics.value = response.data.data
  } catch (err) {
    console.error('Failed to load analytics:', err)
    error.value = err.response?.data?.error || 'Failed to load analytics'
  } finally {
    loading.value = false
  }
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

const formatResponseValue = (value) => {
  if (value === null || value === undefined) return 'No response'
  if (typeof value === 'object') return JSON.stringify(value)
  return String(value)
}

onMounted(() => {
  loadAnalytics()
})
</script>

<style scoped>
/* Additional styles if needed */
</style>
