<template>
  <div class="shares-container">
    <!-- Header -->
    <div class="shares-header">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold text-gray-900">Document Shares</h2>
          <p class="text-gray-600 mt-1">Manage and track all shares for this document</p>
        </div>
        <div class="flex items-center space-x-3">
          <button
            @click="refreshShares"
            :disabled="loading"
            class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg font-medium transition-colors disabled:opacity-50"
          >
            <div v-if="loading" class="flex items-center space-x-2">
              <div class="w-4 h-4 border-2 border-gray-600 border-t-transparent rounded-full animate-spin"></div>
              <span>Loading...</span>
            </div>
            <span v-else>Refresh</span>
          </button>
          <button
            @click="$emit('create-share')"
            class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
          >
            Create New Share
          </button>
        </div>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading && shares.length === 0" class="shares-loading">
      <div class="text-center py-12">
        <div class="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto"></div>
        <p class="text-gray-600 mt-4">Loading shares...</p>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="shares-error">
      <div class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
        <div class="text-red-600 text-lg font-medium mb-2">Error Loading Shares</div>
        <p class="text-red-700 mb-4">{{ error }}</p>
        <button
          @click="loadShares"
          class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium transition-colors"
        >
          Try Again
        </button>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="shares.length === 0 && !loading" class="shares-empty">
      <div class="text-center py-12">
        <div class="w-16 h-16 bg-gray-100 rounded-lg flex items-center justify-center mx-auto mb-4">
          <span class="text-2xl text-gray-400">S</span>
        </div>
        <h3 class="text-lg font-medium text-gray-900 mb-2">No shares yet</h3>
        <p class="text-gray-600 mb-6">Share this document with others to start collecting responses</p>
        <button
          @click="$emit('create-share')"
          class="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
        >
          Create First Share
        </button>
      </div>
    </div>

    <!-- Shares List -->
    <div v-else class="shares-list">
      <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <!-- Table Header -->
        <div class="bg-gray-50 px-6 py-3 border-b border-gray-200">
          <div class="grid grid-cols-12 gap-4 text-sm font-medium text-gray-700">
            <div class="col-span-3">Recipient</div>
            <div class="col-span-2">Status</div>
            <div class="col-span-2">Opens</div>
            <div class="col-span-2">Responses</div>
            <div class="col-span-2">Created</div>
            <div class="col-span-1">Actions</div>
          </div>
        </div>

        <!-- Table Body -->
        <div class="divide-y divide-gray-200">
          <div
            v-for="share in shares"
            :key="share.id"
            class="px-6 py-4 hover:bg-gray-50 transition-colors"
          >
            <div class="grid grid-cols-12 gap-4 items-center">
              <!-- Recipient -->
              <div class="col-span-3">
                <div class="flex items-center space-x-3">
                  <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
                    <span class="text-sm font-semibold text-blue-600">
                      {{ getInitials(share.recipient_name || share.recipient_email) }}
                    </span>
                  </div>
                  <div class="min-w-0 flex-1">
                    <div class="font-medium text-gray-900 truncate">
                      {{ share.recipient_name || share.recipient_email }}
                    </div>
                    <div v-if="share.recipient_name" class="text-sm text-gray-500 truncate">
                      {{ share.recipient_email }}
                    </div>
                  </div>
                </div>
              </div>

              <!-- Status -->
              <div class="col-span-2">
                <span :class="getStatusClass(share.status)" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium">
                  {{ getStatusText(share.status) }}
                </span>
              </div>

              <!-- Opens -->
              <div class="col-span-2">
                <div class="text-sm text-gray-900">
                  {{ share.total_opens || 0 }}
                  <span class="text-gray-500">opens</span>
                </div>
                <div v-if="share.unique_opens" class="text-xs text-gray-500">
                  {{ share.unique_opens }} unique
                </div>
              </div>

              <!-- Responses -->
              <div class="col-span-2">
                <div class="text-sm text-gray-900">
                  {{ share.response_count || 0 }}
                  <span class="text-gray-500">responses</span>
                </div>
                <div v-if="share.is_completed" class="text-xs text-green-600 font-medium">
                  Completed
                </div>
              </div>

              <!-- Created -->
              <div class="col-span-2">
                <div class="text-sm text-gray-900">
                  {{ formatDate(share.inserted_at) }}
                </div>
                <div v-if="share.expires_at" class="text-xs text-gray-500">
                  Expires: {{ formatDate(share.expires_at) }}
                </div>
              </div>

              <!-- Actions -->
              <div class="col-span-1">
                <div class="flex items-center space-x-2">
                  <button
                    @click="viewAnalytics(share)"
                    :disabled="!share.response_count"
                    class="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    title="View Analytics"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                  </button>
                  <button
                    @click="copyShareLink(share)"
                    class="p-2 text-gray-400 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                    title="Copy Share Link"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Summary Stats -->
      <div class="mt-6 grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="bg-white rounded-lg border border-gray-200 p-4">
          <div class="text-sm font-medium text-gray-500 mb-1">Total Shares</div>
          <div class="text-2xl font-bold text-gray-900">{{ shares.length }}</div>
        </div>
        <div class="bg-white rounded-lg border border-gray-200 p-4">
          <div class="text-sm font-medium text-gray-500 mb-1">Total Opens</div>
          <div class="text-2xl font-bold text-gray-900">{{ totalOpens }}</div>
        </div>
        <div class="bg-white rounded-lg border border-gray-200 p-4">
          <div class="text-sm font-medium text-gray-500 mb-1">Total Responses</div>
          <div class="text-2xl font-bold text-gray-900">{{ totalResponses }}</div>
        </div>
        <div class="bg-white rounded-lg border border-gray-200 p-4">
          <div class="text-sm font-medium text-gray-500 mb-1">Completed</div>
          <div class="text-2xl font-bold text-green-600">{{ completedShares }}</div>
        </div>
      </div>
    </div>

    <!-- Copy Success Toast -->
    <div
      v-if="showCopySuccess"
      class="fixed bottom-4 right-4 bg-green-600 text-white px-4 py-2 rounded-lg shadow-lg z-50"
    >
      Share link copied to clipboard!
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { documentsApi } from '../services/api.js'

export default {
  name: 'SharesList',
  props: {
    documentId: {
      type: String,
      required: true
    }
  },
  emits: ['create-share', 'view-analytics'],
  setup(props, { emit }) {
    const shares = ref([])
    const loading = ref(false)
    const error = ref(null)
    const showCopySuccess = ref(false)

    const totalOpens = computed(() => {
      return shares.value.reduce((sum, share) => sum + (share.total_opens || 0), 0)
    })

    const totalResponses = computed(() => {
      return shares.value.reduce((sum, share) => sum + (share.response_count || 0), 0)
    })

    const completedShares = computed(() => {
      return shares.value.filter(share => share.is_completed).length
    })

    const loadShares = async () => {
      if (!props.documentId) return

      loading.value = true
      error.value = null

      try {
        const response = await documentsApi.getShares(props.documentId)
        shares.value = response.data.data || []
      } catch (err) {
        console.error('Failed to load shares:', err)
        error.value = err.response?.data?.error || 'Failed to load shares'
      } finally {
        loading.value = false
      }
    }

    const refreshShares = () => {
      loadShares()
    }

    const getInitials = (name) => {
      if (!name) return '?'
      return name.split('@')[0].substring(0, 2).toUpperCase()
    }

    const getStatusClass = (status) => {
      const classes = {
        pending: 'bg-yellow-100 text-yellow-800',
        sent: 'bg-blue-100 text-blue-800',
        opened: 'bg-indigo-100 text-indigo-800',
        responded: 'bg-green-100 text-green-800',
        completed: 'bg-green-100 text-green-800',
        expired: 'bg-gray-100 text-gray-800',
        failed: 'bg-red-100 text-red-800'
      }
      return classes[status] || 'bg-gray-100 text-gray-800'
    }

    const getStatusText = (status) => {
      const texts = {
        pending: 'Pending',
        sent: 'Sent',
        opened: 'Opened',
        responded: 'Responded',
        completed: 'Completed',
        expired: 'Expired',
        failed: 'Failed'
      }
      return texts[status] || status
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

    const viewAnalytics = (share) => {
      emit('view-analytics', share)
    }

    const copyShareLink = async (share) => {
      const shareUrl = `${window.location.origin}/api/share/${share.share_token}`

      try {
        await navigator.clipboard.writeText(shareUrl)
        showCopySuccess.value = true
        setTimeout(() => {
          showCopySuccess.value = false
        }, 3000)
      } catch (err) {
        console.error('Failed to copy share link:', err)
        // Fallback for older browsers
        const textArea = document.createElement('textarea')
        textArea.value = shareUrl
        document.body.appendChild(textArea)
        textArea.select()
        document.execCommand('copy')
        document.body.removeChild(textArea)
        showCopySuccess.value = true
        setTimeout(() => {
          showCopySuccess.value = false
        }, 3000)
      }
    }

    onMounted(() => {
      loadShares()
    })

    return {
      shares,
      loading,
      error,
      showCopySuccess,
      totalOpens,
      totalResponses,
      completedShares,
      loadShares,
      refreshShares,
      getInitials,
      getStatusClass,
      getStatusText,
      formatDate,
      viewAnalytics,
      copyShareLink
    }
  }
}
</script>

<style scoped>
.shares-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.shares-header {
  margin-bottom: 2rem;
}

.shares-list {
  /* Additional styling if needed */
}
</style>