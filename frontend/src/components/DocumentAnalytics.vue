<template>
  <div class="analytics-container">
    <!-- Header -->
    <div class="analytics-header">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold text-gray-900">Document Analytics</h2>
          <p class="text-gray-600 mt-1">Aggregate metrics across all shares and responses</p>
        </div>
        <button
          @click="refreshAnalytics"
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
    <div v-if="loading && !analytics" class="analytics-loading">
      <div class="text-center py-12">
        <div class="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto"></div>
        <p class="text-gray-600 mt-4">Loading analytics...</p>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="analytics-error">
      <div class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
        <div class="text-red-600 text-lg font-medium mb-2">Error Loading Analytics</div>
        <p class="text-red-700 mb-4">{{ error }}</p>
        <button
          @click="loadAnalytics"
          class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium transition-colors"
        >
          Try Again
        </button>
      </div>
    </div>

    <!-- Analytics Content -->
    <div v-else-if="analytics" class="analytics-content">
      <!-- Summary Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div class="stat-card group">
          <div class="stat-icon bg-gradient-to-br from-purple-400 to-purple-600">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
            </svg>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ analytics.total_shares }}</div>
            <div class="stat-label">Total Shares</div>
          </div>
        </div>

        <div class="stat-card group">
          <div class="stat-icon bg-gradient-to-br from-blue-400 to-blue-600">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ analytics.total_opens }}</div>
            <div class="stat-label">Total Opens</div>
          </div>
        </div>

        <div class="stat-card group">
          <div class="stat-icon bg-gradient-to-br from-green-400 to-green-600">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
            </svg>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ analytics.total_responses }}</div>
            <div class="stat-label">Responses</div>
          </div>
        </div>

        <div class="stat-card group">
          <div class="stat-icon bg-gradient-to-br from-orange-400 to-orange-600">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ completionPercentage }}%</div>
            <div class="stat-label">Completion Rate</div>
          </div>
        </div>
      </div>

      <!-- Field Analytics -->
      <div class="bg-white rounded-lg border border-gray-200 mb-8">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Field Response Breakdown</h3>
          <p class="text-gray-600 text-sm mt-1">Aggregated responses across all shares</p>
        </div>
        <div class="px-6 py-4">
          <div v-if="analytics.analytics && analytics.analytics.length > 0" class="space-y-4">
            <div
              v-for="field in analytics.analytics"
              :key="field.field_key"
              class="field-analytics-item"
            >
              <div class="flex items-center justify-between mb-2">
                <div class="flex items-center space-x-3">
                  <div class="field-type-badge">
                    {{ getFieldTypeIcon(field.field_type) }}
                  </div>
                  <div>
                    <div class="font-medium text-gray-900">
                      {{ field.field_label || field.field_key }}
                    </div>
                    <div class="text-sm text-gray-500">
                      {{ field.field_type }} field
                    </div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="font-semibold text-gray-900">
                    {{ Math.round(field.response_count) }} responses
                  </div>
                  <div class="text-sm text-gray-500">
                    {{ Math.round((field.completion_rate || 0) * 100) }}% completion
                  </div>
                </div>
              </div>

              <!-- Response Value -->
              <div v-if="field.response_value" class="ml-10 mb-2">
                <div class="text-sm text-gray-600">Most common response:</div>
                <div class="text-gray-900 font-medium">{{ field.response_value }}</div>
              </div>

              <!-- Progress Bar -->
              <div class="ml-10">
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div
                    class="bg-blue-500 h-2 rounded-full transition-all duration-300"
                    :style="{ width: Math.round((field.completion_rate || 0) * 100) + '%' }"
                  ></div>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="text-center py-8 text-gray-500">
            <div class="w-16 h-16 bg-gray-100 rounded-lg flex items-center justify-center mx-auto mb-4">
              <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            </div>
            <h3 class="text-lg font-medium text-gray-900 mb-2">No responses yet</h3>
            <p class="text-gray-600">Share your form to start collecting responses and analytics</p>
          </div>
        </div>
      </div>

      <!-- Shares Breakdown -->
      <div v-if="analytics.shares && analytics.shares.length > 0" class="bg-white rounded-lg border border-gray-200">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Shares Overview</h3>
          <p class="text-gray-600 text-sm mt-1">Individual share performance</p>
        </div>
        <div class="px-6 py-4">
          <div class="space-y-3">
            <div
              v-for="share in analytics.shares"
              :key="share.id"
              class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <div class="flex items-center space-x-3">
                <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
                  <span class="text-sm font-semibold text-blue-600">
                    {{ getInitials(share.recipient_name || share.recipient_email) }}
                  </span>
                </div>
                <div>
                  <div class="font-medium text-gray-900">{{ share.recipient_name || share.recipient_email }}</div>
                  <div class="text-sm text-gray-500">{{ formatDate(share.sent_at) }}</div>
                </div>
              </div>
              <div class="flex items-center space-x-4 text-sm">
                <div class="text-center">
                  <div class="font-semibold text-gray-900">{{ share.total_opens }}</div>
                  <div class="text-gray-500">Opens</div>
                </div>
                <div class="text-center">
                  <div class="font-semibold text-gray-900">{{ share.response_count }}</div>
                  <div class="text-gray-500">Responses</div>
                </div>
                <div v-if="share.is_completed" class="px-2 py-1 bg-green-100 text-green-800 rounded text-xs font-medium">
                  Completed
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { documentsApi } from '../services/api.js'

const props = defineProps({
  documentId: {
    type: String,
    required: true
  }
})

const analytics = ref(null)
const loading = ref(false)
const error = ref(null)

const completionPercentage = computed(() => {
  if (!analytics.value) return 0
  return Math.round((analytics.value.completion_rate || 0) * 100)
})

const loadAnalytics = async () => {
  if (!props.documentId) return

  loading.value = true
  error.value = null

  try {
    const response = await documentsApi.getDocumentAnalytics(props.documentId)
    analytics.value = response.data.data
  } catch (err) {
    console.error('Failed to load analytics:', err)
    error.value = err.response?.data?.error || 'Failed to load analytics'
  } finally {
    loading.value = false
  }
}

const refreshAnalytics = () => {
  loadAnalytics()
}

const formatDate = (timestamp) => {
  if (!timestamp) return 'Not sent'
  const date = new Date(timestamp)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const getFieldTypeIcon = (fieldType) => {
  const icons = {
    text: 'T',
    textarea: '¶',
    email: '@',
    date: 'D',
    select: '▼',
    checkbox: '☑',
    radio: '○',
    number: '#'
  }
  return icons[fieldType] || 'F'
}

const getInitials = (name) => {
  if (!name) return '?'
  return name.split('@')[0].substring(0, 2).toUpperCase()
}

onMounted(() => {
  loadAnalytics()
})
</script>

<style scoped>
.analytics-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.analytics-header {
  margin-bottom: 2rem;
}

.stat-card {
  @apply bg-white rounded-xl border border-gray-200 p-6 shadow-sm hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 flex items-center space-x-4;
}

.stat-icon {
  @apply w-14 h-14 rounded-xl flex items-center justify-center flex-shrink-0 shadow-md group-hover:shadow-lg transition-all duration-300;
}

.stat-content {
  flex: 1;
}

.stat-value {
  @apply text-2xl font-bold text-gray-900;
}

.stat-label {
  @apply text-sm text-gray-500 mt-1;
}

.field-analytics-item {
  @apply border border-gray-100 rounded-lg p-4;
}

.field-type-badge {
  @apply w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center text-sm font-semibold text-gray-600;
}
</style>
