<template>
  <div class="analytics-container">
    <!-- Header -->
    <div class="analytics-header">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold text-gray-900">Share Analytics</h2>
          <p class="text-gray-600 mt-1">Performance metrics for shared form</p>
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
          <div class="stat-icon bg-gradient-to-br from-blue-400 to-blue-600">
            <EyeIcon class="w-6 h-6 text-white" />
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ analytics.share.total_opens || 0 }}</div>
            <div class="stat-label">Total Opens</div>
          </div>
        </div>

        <div class="stat-card group">
          <div class="stat-icon bg-gradient-to-br from-green-400 to-green-600">
            <ChatBubbleBottomCenterTextIcon class="w-6 h-6 text-white" />
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ analytics.share.response_count || 0 }}</div>
            <div class="stat-label">Responses</div>
          </div>
        </div>

        <div class="stat-card group">
          <div class="stat-icon bg-gradient-to-br from-purple-400 to-purple-600">
            <ChartPieIcon class="w-6 h-6 text-white" />
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ completionPercentage }}%</div>
            <div class="stat-label">Completion Rate</div>
          </div>
        </div>

        <div class="stat-card group">
          <div class="stat-icon bg-gradient-to-br from-orange-400 to-orange-600">
            <CheckCircleIcon class="w-6 h-6 text-white" />
          </div>
          <div class="stat-content">
            <div class="stat-value">
              <span :class="statusClass">{{ analytics.share.is_completed ? 'Complete' : 'Active' }}</span>
            </div>
            <div class="stat-label">Status</div>
          </div>
        </div>
      </div>

      <!-- Share Details -->
      <div class="bg-white rounded-lg border border-gray-200 mb-8">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Share Details</h3>
        </div>
        <div class="px-6 py-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <div class="text-sm font-medium text-gray-500 mb-1">Recipient</div>
              <div class="text-gray-900">
                {{ analytics.share.recipient_email }}
              </div>
            </div>
            <div>
              <div class="text-sm font-medium text-gray-500 mb-1">Sent At</div>
              <div class="text-gray-900">
                {{ formatDate(analytics.share.sent_at) || 'Not sent yet' }}
              </div>
            </div>
            <div v-if="analytics.share.first_response_at">
              <div class="text-sm font-medium text-gray-500 mb-1">First Response</div>
              <div class="text-gray-900">
                {{ formatDate(analytics.share.first_response_at) }}
              </div>
            </div>
            <div v-if="analytics.share.last_response_at">
              <div class="text-sm font-medium text-gray-500 mb-1">Last Response</div>
              <div class="text-gray-900">
                {{ formatDate(analytics.share.last_response_at) }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Field Analytics -->
      <div class="bg-white rounded-lg border border-gray-200">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Field Analytics</h3>
          <p class="text-gray-600 text-sm mt-1">Response patterns for each form field</p>
        </div>
        <div class="px-6 py-4">
          <div v-if="analytics.analytics && analytics.analytics.length > 0" class="space-y-4">
            <div
              v-for="field in analytics.analytics"
              :key="`${field.field_key}-${field.response_value}`"
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
                    {{ field.response_count }} responses
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
            No field analytics available yet
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { documentsApi } from '../services/api.js'
import { EyeIcon, ChatBubbleBottomCenterTextIcon, ChartPieIcon, CheckCircleIcon } from '@heroicons/vue/24/outline'

export default {
  name: 'ShareAnalytics',
  components: {
    EyeIcon,
    ChatBubbleBottomCenterTextIcon,
    ChartPieIcon,
    CheckCircleIcon
  },
  props: {
    shareToken: {
      type: String,
      required: true
    }
  },
  setup(props) {
    const analytics = ref(null)
    const loading = ref(false)
    const error = ref(null)

    const completionPercentage = computed(() => {
      if (!analytics.value?.summary) return 0
      return Math.round((analytics.value.summary.completion_rate || 0) * 100)
    })

    const statusClass = computed(() => {
      if (!analytics.value?.share) return 'text-gray-600'
      return analytics.value.share.is_completed ? 'text-green-600' : 'text-blue-600'
    })

    const loadAnalytics = async () => {
      if (!props.shareToken) return

      loading.value = true
      error.value = null

      try {
        const response = await documentsApi.getShareAnalytics(props.shareToken)
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
      if (!timestamp) return null
      const date = new Date(timestamp)
      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
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

    onMounted(() => {
      loadAnalytics()
    })

    return {
      analytics,
      loading,
      error,
      completionPercentage,
      statusClass,
      loadAnalytics,
      refreshAnalytics,
      formatDate,
      getFieldTypeIcon
    }
  }
}
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