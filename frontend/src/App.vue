<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50/30 to-gray-100 font-sans">
    <!-- Header -->
    <header class="bg-white/80 backdrop-blur-md border-b border-white/20 shadow-lg sticky top-0 z-10">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center py-4">
          <div class="flex items-center space-x-4">
            <div class="w-10 h-10 bg-gradient-to-br from-primary-500 to-primary-700 rounded-lg flex items-center justify-center shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
            </div>
            <h1 class="text-2xl font-bold bg-gradient-to-r from-gray-800 via-gray-700 to-primary-600 bg-clip-text text-transparent">Paperform2Web</h1>
          </div>

          <nav class="flex items-center space-x-6">
            <button
              @click="currentPage = 'home'"
              :class="[
                'px-4 py-2 rounded-lg font-medium text-sm transition-all duration-200',
                currentPage === 'home'
                  ? 'bg-primary-100 text-primary-700 border border-primary-200'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
              ]"
            >
              Upload
            </button>
            <button
              @click="currentPage = 'processed'"
              :class="[
                'px-4 py-2 rounded-lg font-medium text-sm transition-all duration-200',
                currentPage === 'processed'
                  ? 'bg-primary-100 text-primary-700 border border-primary-200'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
              ]"
            >
              Processed Documents
            </button>
          </nav>
          
          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-2 text-sm text-gray-600">
              <span class="relative flex h-3 w-3">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
              </span>
              <span>Status:</span>
              <span class="font-semibold text-primary-700">Connected</span>
            </div>
          </div>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <!-- Upload Page -->
      <div v-if="currentPage === 'home'" class="space-y-8">
        <div class="card">
          <div class="card-header">
            <h2 class="card-title">Upload Document</h2>
          </div>
          <div class="p-6">
            <FileUpload @upload-complete="onUploadComplete" />
          </div>
        </div>

        <div v-if="currentProcessingDocument && !viewingDocument" class="card">
          <div class="card-header">
            <h2 class="card-title">Document Processing</h2>
          </div>
          <div class="p-6">
            <ProcessingStatus
              :document="currentProcessingDocument"
              @status-update="onStatusUpdate"
              @document-deleted="onDocumentDeleted"
            />
          </div>
        </div>
      </div>

      <!-- Processed Documents Page -->
      <div v-if="currentPage === 'processed'" class="space-y-8">
        <div class="card">
          <div class="card-header">
            <h2 class="card-title">Processed Documents</h2>
            <p class="text-gray-600 text-sm mt-1">View and manage all your processed documents</p>
          </div>
          <div class="p-6">
            <DocumentList
              :documents="completedDocuments"
              @view-document="viewDocument"
              @document-deleted="onDocumentDeleted"
            />
          </div>
        </div>
      </div>
    </main>

    <!-- Document Viewer Modal -->
    <DocumentViewer 
      v-if="viewingDocument"
      :document="viewingDocument"
      @close="closeViewer"
      @document-updated="onDocumentUpdated"
    />
  </div>
</template>

<script>
import { ref, reactive, onMounted } from 'vue'
import FileUpload from './components/FileUpload.vue'
import ProcessingStatus from './components/ProcessingStatus.vue'
import DocumentList from './components/DocumentList.vue'
import DocumentViewer from './components/DocumentViewer.vue'
import { documentsApi } from './services/api.js'

export default {
  name: 'App',
  components: {
    FileUpload,
    ProcessingStatus,
    DocumentList,
    DocumentViewer
  },
  setup() {
    const currentProcessingDocument = ref(null)
    const completedDocuments = ref([])
    const viewingDocument = ref(null)
    const currentPage = ref('home')

    const onUploadComplete = (document) => {
      currentProcessingDocument.value = document
    }

    const onStatusUpdate = (document) => {
      if (document.status === 'completed') {
        // Move to completed documents
        completedDocuments.value.unshift(document)

        // Clear current processing document
        currentProcessingDocument.value = null

        // Automatically open document viewer for template selection
        viewingDocument.value = document
      } else if (document.status === 'failed') {
        // Update the processing document with error status
        if (currentProcessingDocument.value && currentProcessingDocument.value.id === document.id) {
          currentProcessingDocument.value = document
        }
      } else {
        // Update current processing document
        if (currentProcessingDocument.value && currentProcessingDocument.value.id === document.id) {
          currentProcessingDocument.value = document
        }
      }
    }

    const viewDocument = (document) => {
      viewingDocument.value = document
    }

    const closeViewer = () => {
      viewingDocument.value = null
    }

    const onDocumentUpdated = (updatedDocument) => {
      // Update the viewing document
      viewingDocument.value = updatedDocument

      // Update the document in the completed documents list
      const index = completedDocuments.value.findIndex(doc => doc.id === updatedDocument.id)
      if (index !== -1) {
        completedDocuments.value[index] = updatedDocument
      }
    }

    const onDocumentDeleted = (deletedDocument) => {
      // Remove from completed documents list
      completedDocuments.value = completedDocuments.value.filter(doc => doc.id !== deletedDocument.id)

      // Clear current processing document if it's the deleted one
      if (currentProcessingDocument.value && currentProcessingDocument.value.id === deletedDocument.id) {
        currentProcessingDocument.value = null
      }

      // Close viewer if the deleted document was being viewed
      if (viewingDocument.value && viewingDocument.value.id === deletedDocument.id) {
        viewingDocument.value = null
      }
    }

    const loadDocuments = async () => {
      try {
        const response = await documentsApi.getDocuments()
        const documents = response.data.data

        // Load completed documents and find the most recent processing document
        let mostRecentProcessing = null
        documents.forEach(doc => {
          if (doc.status === 'completed') {
            completedDocuments.value.push(doc)
          } else if (doc.status === 'processing' || doc.status === 'uploaded' || doc.status === 'failed') {
            // Keep only the most recent processing document
            if (!mostRecentProcessing || new Date(doc.inserted_at) > new Date(mostRecentProcessing.inserted_at)) {
              mostRecentProcessing = doc
            }
          }
        })

        // Set the most recent processing document as current
        if (mostRecentProcessing) {
          currentProcessingDocument.value = mostRecentProcessing
        }
      } catch (error) {
        console.error('Failed to load documents:', error)
      }
    }

    onMounted(() => {
      loadDocuments()
    })

    return {
      currentProcessingDocument,
      completedDocuments,
      viewingDocument,
      currentPage,
      onUploadComplete,
      onStatusUpdate,
      viewDocument,
      closeViewer,
      onDocumentUpdated,
      onDocumentDeleted
    }
  }
}
</script>
