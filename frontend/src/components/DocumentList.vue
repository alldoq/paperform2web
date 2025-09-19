<template>
  <div class="space-y-4">
    <div v-if="documents.length === 0" class="text-center py-8 text-gray-500">
      <DocumentIcon class="w-12 h-12 mx-auto mb-3 text-gray-300" />
      <p>No documents processed yet</p>
      <p class="text-sm mt-1">Upload your first document to get started</p>
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="document in documents"
        :key="document.id"
        class="group border border-gray-200 rounded-lg p-4 hover:border-gray-300 hover:shadow-sm transition-all duration-200"
      >
        <div class="flex items-start justify-between">
          <div
            class="flex items-start space-x-3 min-w-0 flex-1"
            @click="$emit('view-document', document)"
          >
            <div class="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center flex-shrink-0">
              <DocumentTextIcon class="w-4 h-4 text-primary-600" />
            </div>
            <div class="min-w-0 flex-1">
              <p class="font-medium text-gray-900 truncate group-hover:text-primary-600 transition-colors">
                {{ document.filename }}
              </p>
              <div class="flex items-center space-x-2 mt-1">
                <span class="text-xs text-gray-500">
                  {{ formatDate(document.updated_at) }}
                </span>
                <span class="text-xs text-gray-300">•</span>
                <span class="text-xs text-gray-500 capitalize">
                  {{ getDocumentType(document) }}
                </span>
              </div>
            </div>
          </div>

          <div class="flex items-center space-x-2 flex-shrink-0">
            <StatusBadge :status="document.status" />
            <button
              @click.stop="showDeleteConfirm(document)"
              class="p-1 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded transition-colors"
              title="Delete document"
            >
              <TrashIcon class="w-4 h-4" />
            </button>
            <button
              @click="$emit('view-document', document)"
              class="p-1 text-gray-400 group-hover:text-gray-600 hover:bg-gray-100 rounded transition-colors"
              title="View document"
            >
              <ChevronRightIcon class="w-4 h-4" />
            </button>
          </div>
        </div>

        <!-- Document Preview Info -->
        <div v-if="document.processed_data" class="mt-3 pt-3 border-t border-gray-100">
          <p class="text-xs text-gray-600 line-clamp-2">
            {{ getDocumentPreview(document) }}
          </p>
        </div>
      </div>
    </div>

    <!-- Load More Button -->
    <div v-if="hasMore" class="text-center pt-4">
      <button 
        @click="$emit('load-more')"
        class="btn-secondary text-sm"
        :disabled="loading"
      >
        <div v-if="loading" class="flex items-center space-x-2">
          <div class="w-3 h-3 border-2 border-gray-400 border-t-transparent rounded-full animate-spin"></div>
          <span>Loading...</span>
        </div>
        <span v-else>Load More</span>
      </button>
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
            <h3 class="text-lg font-medium text-gray-900">Delete Document</h3>
            <p class="text-sm text-gray-500">This action cannot be undone.</p>
          </div>
        </div>

        <p class="text-sm text-gray-700 mb-6">
          Are you sure you want to delete "<span class="font-medium">{{ documentToDelete?.filename }}</span>"?
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
              <span>Deleting...</span>
            </div>
            <span v-else>Delete</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { DocumentIcon, DocumentTextIcon, ChevronRightIcon, TrashIcon, ExclamationTriangleIcon } from '@heroicons/vue/24/outline'
import StatusBadge from './StatusBadge.vue'
import { documentsApi } from '../services/api.js'

export default {
  name: 'DocumentList',
  components: {
    DocumentIcon,
    DocumentTextIcon,
    ChevronRightIcon,
    TrashIcon,
    ExclamationTriangleIcon,
    StatusBadge
  },
  props: {
    documents: {
      type: Array,
      default: () => []
    },
    hasMore: {
      type: Boolean,
      default: false
    },
    loading: {
      type: Boolean,
      default: false
    }
  },
  emits: ['view-document', 'load-more', 'document-deleted'],
  setup(props, { emit }) {
    const showDeleteDialog = ref(false)
    const documentToDelete = ref(null)
    const deleting = ref(false)
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

      const now = new Date()
      const diffInHours = (now - date) / (1000 * 60 * 60)

      if (diffInHours < 1) {
        return 'Just now'
      } else if (diffInHours < 24) {
        return `${Math.floor(diffInHours)}h ago`
      } else if (diffInHours < 168) { // 7 days
        return `${Math.floor(diffInHours / 24)}d ago`
      } else {
        return date.toLocaleDateString('en-US', {
          month: 'short',
          day: 'numeric',
          year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
        })
      }
    }

    const getDocumentType = (document) => {
      if (document.processed_data && document.processed_data.document_type) {
        return document.processed_data.document_type
      }
      return 'document'
    }

    const getDocumentPreview = (document) => {
      if (!document.processed_data || !document.processed_data.content) {
        return 'Processing...'
      }

      const sections = document.processed_data.content.sections || []
      const textContent = sections
        .filter(section => section.content && section.content.trim())
        .map(section => section.content.trim())
        .join(' ')

      return textContent.length > 100 ? textContent.substring(0, 100) + '...' : textContent
    }

    const showDeleteConfirm = (document) => {
      documentToDelete.value = document
      showDeleteDialog.value = true
    }

    const cancelDelete = () => {
      showDeleteDialog.value = false
      documentToDelete.value = null
      deleting.value = false
    }

    const confirmDelete = async () => {
      if (!documentToDelete.value) return

      deleting.value = true
      try {
        await documentsApi.deleteDocument(documentToDelete.value.id)
        emit('document-deleted', documentToDelete.value)
        showDeleteDialog.value = false
        documentToDelete.value = null
      } catch (error) {
        console.error('Failed to delete document:', error)
        // You could emit an error event or show a notification here
      } finally {
        deleting.value = false
      }
    }

    return {
      formatDate,
      getDocumentType,
      getDocumentPreview,
      showDeleteDialog,
      documentToDelete,
      deleting,
      showDeleteConfirm,
      cancelDelete,
      confirmDelete
    }
  }
}
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>