<template>
  <div class="border border-gray-200 rounded-lg p-4 space-y-4">
    <div class="flex items-start justify-between">
      <div class="flex items-start space-x-3">
        <div class="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0">
          <DocumentTextIcon class="w-5 h-5 text-gray-500" />
        </div>
        <div class="min-w-0 flex-1">
          <p class="font-medium text-gray-900 truncate">{{ document.filename }}</p>
          <p class="text-sm text-gray-500">Model: {{ document.model_used }}</p>
        </div>
      </div>
      
      <div class="flex items-center space-x-2">
        <StatusBadge :status="document.status" />
        <div class="flex items-center space-x-2">
          <button
            v-if="document.status === 'failed'"
            @click="retryProcessing"
            class="text-sm text-primary-600 hover:text-primary-700 px-2 py-1 rounded hover:bg-primary-50"
          >
            Retry
          </button>
          <button
            @click="showDeleteConfirm"
            class="p-1 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded transition-colors"
            :title="document.status === 'failed' ? 'Delete failed document' : 'Cancel and delete document'"
          >
            <TrashIcon class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Progress Bar -->
    <div class="space-y-2">
      <div class="flex justify-between text-sm">
        <span class="text-gray-600">{{ currentStatusMessage || progressLabel }}</span>
        <span class="text-gray-900 font-medium">{{ smoothProgress }}%</span>
      </div>
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div
          class="h-2 rounded-full transition-all duration-300"
          :class="progressBarClass"
          :style="{ width: smoothProgress + '%' }"
        ></div>
      </div>
    </div>

    <!-- Error Message -->
    <div v-if="document.status === 'failed' && document.error_message" class="p-3 bg-red-50 border border-red-200 rounded-lg">
      <div class="flex items-start space-x-2">
        <ExclamationTriangleIcon class="w-4 h-4 text-red-500 flex-shrink-0 mt-0.5" />
        <p class="text-sm text-red-700">{{ document.error_message }}</p>
      </div>
    </div>

    <!-- Processing Time -->
    <div class="flex justify-between items-center text-xs text-gray-500">
      <span>Started: {{ formatTime(document.inserted_at) }}</span>
      <span v-if="document.updated_at && document.updated_at !== document.inserted_at">
        Updated: {{ formatTime(document.updated_at) }}
      </span>
    </div>

    <!-- Delete Confirmation Dialog -->
    <div
      v-if="showDeleteDialog"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      @click="cancelDelete"
    >
      <div
        class="bg-white rounded-lg shadow-xl p-6 m-4 max-w-sm w-full"
        @click.stop
      >
        <div class="flex items-center space-x-3 mb-4">
          <div class="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center flex-shrink-0">
            <ExclamationTriangleIcon class="w-5 h-5 text-red-600" />
          </div>
          <div>
            <h3 class="text-lg font-medium text-gray-900">
              {{ document.status === 'failed' ? 'Delete Failed Document' : 'Cancel Processing' }}
            </h3>
            <p class="text-sm text-gray-500">This action cannot be undone.</p>
          </div>
        </div>

        <p class="text-sm text-gray-700 mb-6">
          <span v-if="document.status === 'failed'">
            Are you sure you want to delete the failed processing job for "<span class="font-medium">{{ document.filename }}</span>"?
          </span>
          <span v-else-if="document.status === 'processing'">
            Are you sure you want to cancel processing and delete "<span class="font-medium">{{ document.filename }}</span>"? The document will stop processing immediately.
          </span>
          <span v-else>
            Are you sure you want to delete "<span class="font-medium">{{ document.filename }}</span>"?
          </span>
        </p>

        <div class="flex space-x-3 justify-end">
          <button
            @click="cancelDelete"
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors"
            :disabled="deleting"
          >
            Cancel
          </button>
          <button
            @click="confirmDelete"
            class="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-md transition-colors disabled:opacity-50"
            :disabled="deleting"
          >
            <div v-if="deleting" class="flex items-center space-x-2">
              <div class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
              <span>{{ document.status === 'processing' ? 'Canceling...' : 'Deleting...' }}</span>
            </div>
            <span v-else>{{ document.status === 'processing' ? 'Stop & Delete' : 'Delete' }}</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { DocumentTextIcon, ExclamationTriangleIcon, TrashIcon } from '@heroicons/vue/24/outline'
import StatusBadge from './StatusBadge.vue'
import { documentsApi } from '../services/api.js'
import webSocketService from '../services/websocket.js'

export default {
  name: 'ProcessingStatus',
  components: {
    DocumentTextIcon,
    ExclamationTriangleIcon,
    TrashIcon,
    StatusBadge
  },
  props: {
    document: {
      type: Object,
      required: true
    }
  },
  emits: ['status-update', 'document-deleted'],
  setup(props, { emit }) {
    const showDeleteDialog = ref(false)
    const deleting = ref(false)
    const channel = ref(null)

    // Use computed properties to prevent unnecessary re-renders
    const progressLabel = computed(() => {
      switch (props.document.status) {
        case 'uploaded':
          return 'Queued for processing'
        case 'processing':
          return 'Processing with AI'
        case 'completed':
          return 'Processing complete'
        case 'failed':
          return 'Processing failed'
        default:
          return 'Unknown status'
      }
    })

    const progressBarClass = computed(() => {
      switch (props.document.status) {
        case 'uploaded':
          return 'bg-gray-400'
        case 'processing':
          return 'bg-primary-500'
        case 'completed':
          return 'bg-green-500'
        case 'failed':
          return 'bg-red-500'
        default:
          return 'bg-gray-400'
      }
    })

    // Debounced progress to prevent flashing
    const smoothProgress = computed(() => {
      return Math.min(100, Math.max(0, props.document.progress || 0))
    })

    // Current status message for detailed progress info
    const currentStatusMessage = computed(() => {
      return props.document.status_message
    })

    const formatTime = (timestamp) => {
      if (!timestamp) return 'Unknown'

      // Handle different timestamp formats
      let date
      if (typeof timestamp === 'string') {
        // Convert Elixir/Phoenix datetime strings (e.g., "2024-01-15T10:30:00Z")
        date = new Date(timestamp.replace(' ', 'T'))
      } else {
        date = new Date(timestamp)
      }

      if (isNaN(date.getTime())) {
        console.warn('Invalid timestamp:', timestamp)
        return 'Invalid Date'
      }

      return date.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit'
      })
    }


    const subscribeToUpdates = async () => {
      try {
        // Connect to WebSocket if not already connected
        await webSocketService.connect()

        // Subscribe to document updates
        channel.value = webSocketService.subscribeToDocument(props.document.id, {
          onJoin: (response) => {
            console.log('✅ Joined document channel for document:', props.document.id, response)
          },
          onDocumentUpdate: (payload) => {
            console.log('📄 Document updated via WebSocket:', payload)
            // Only emit if this is the same document
            if (payload.id === props.document.id) {
              emit('status-update', payload)
            }
          },
          onStatusUpdate: (payload) => {
            console.log('📊 Status updated via WebSocket:', payload)
            // Only emit if this update is for our document
            if (payload.id && payload.id === props.document.id) {
              // Merge status update with existing document data
              const updatedDocument = {
                ...props.document,
                ...payload
              }
              emit('status-update', updatedDocument)
            } else if (!payload.id) {
              // If no ID in payload, assume it's for our document (legacy format)
              const updatedDocument = {
                ...props.document,
                ...payload
              }
              emit('status-update', updatedDocument)
            }
          },
          onError: (error) => {
            console.error('❌ WebSocket error:', error)
          },
          onClose: () => {
            console.log('🔌 WebSocket channel closed')
          }
        })
      } catch (error) {
        console.error('Failed to connect to WebSocket:', error)
        // Fallback to polling if WebSocket fails
        fallbackToPolling()
      }
    }

    const unsubscribeFromUpdates = () => {
      if (channel.value) {
        webSocketService.unsubscribeFromDocument(props.document.id)
        channel.value = null
      }
    }

    const fallbackToPolling = async () => {
      console.log('Falling back to HTTP polling for document status')
      try {
        const response = await documentsApi.getDocumentStatus(props.document.id)
        const updatedDocument = response.data

        if (updatedDocument.status !== props.document.status ||
            updatedDocument.progress !== props.document.progress) {
          emit('status-update', updatedDocument)
        }

        // Only poll again if still processing
        if (updatedDocument.status === 'uploaded' || updatedDocument.status === 'processing') {
          setTimeout(fallbackToPolling, 3000)
        }
      } catch (error) {
        console.error('Failed to poll document status:', error)
      }
    }

    const retryProcessing = async () => {
      try {
        // This would require implementing a retry endpoint in the backend
        // For now, just emit a status update to refresh the document
        emit('status-update', { ...props.document, status: 'uploaded', progress: 0 })
      } catch (error) {
        console.error('Failed to retry processing:', error)
      }
    }

    const showDeleteConfirm = () => {
      showDeleteDialog.value = true
    }

    const cancelDelete = () => {
      showDeleteDialog.value = false
      deleting.value = false
    }

    const confirmDelete = async () => {
      if (!props.document) return

      deleting.value = true
      try {
        await documentsApi.deleteDocument(props.document.id)
        emit('document-deleted', props.document)
        showDeleteDialog.value = false
      } catch (error) {
        console.error('Failed to delete document:', error)
        // You could emit an error event or show a notification here
      } finally {
        deleting.value = false
      }
    }

    onMounted(() => {
      // Only subscribe to updates if document is still processing
      if (props.document.status === 'uploaded' || props.document.status === 'processing') {
        subscribeToUpdates()
      }
    })

    onUnmounted(() => {
      unsubscribeFromUpdates()
    })

    return {
      showDeleteDialog,
      deleting,
      progressLabel,
      progressBarClass,
      smoothProgress,
      currentStatusMessage,
      formatTime,
      retryProcessing,
      showDeleteConfirm,
      cancelDelete,
      confirmDelete
    }
  }
}
</script>