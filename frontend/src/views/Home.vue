<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50/30 to-gray-100 font-sans">
    <!-- Header -->
    <AppHeader
      :show-dashboard-nav="true"
      :current-page="currentPage"
      @page-change="currentPage = $event"
    />

    <!-- Main Content -->
    <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10 main-content">
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

        <div v-if="processingDocuments.length > 0 && !viewingDocument" class="card">
          <div class="card-header">
            <h2 class="card-title">Document Processing</h2>
            <p v-if="processingDocuments.length > 1" class="text-gray-600 text-sm mt-1">
              Processing {{ processingDocuments.length }} documents
            </p>
          </div>
          <div class="p-6 space-y-4">
            <ProcessingStatus
              v-for="document in processingDocuments"
              :key="document.id"
              :document="document"
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

    <!-- Footer -->
    <AppFooter />
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import AppHeader from '../components/AppHeader.vue'
import AppFooter from '../components/AppFooter.vue'
import FileUpload from '../components/FileUpload.vue'
import ProcessingStatus from '../components/ProcessingStatus.vue'
import DocumentList from '../components/DocumentList.vue'
import { documentsApi } from '../services/api.js'

export default {
  name: 'App',
  components: {
    AppHeader,
    AppFooter,
    FileUpload,
    ProcessingStatus,
    DocumentList
  },
  setup() {
    const router = useRouter()
    const processingDocuments = ref([])
    const completedDocuments = ref([])
    const currentPage = ref('home')

    // Computed property to get the most recent processing document
    const currentProcessingDocument = computed(() => {
      if (processingDocuments.value.length === 0) return null
      // Return the most recently uploaded processing document
      return processingDocuments.value.reduce((latest, doc) => {
        return new Date(doc.inserted_at) > new Date(latest.inserted_at) ? doc : latest
      })
    })

    const onUploadComplete = (document) => {
      // Add to processing documents list
      processingDocuments.value.unshift(document)
    }

    const onStatusUpdate = (document) => {
      if (document.status === 'completed') {
        // Move to completed documents
        completedDocuments.value.unshift(document)

        // Remove from processing documents
        processingDocuments.value = processingDocuments.value.filter(doc => doc.id !== document.id)

        // Automatically navigate to document viewer for template selection
        router.push(`/documents/${document.id}`)
      } else if (document.status === 'failed') {
        // Update or add to processing documents with error status
        const existingIndex = processingDocuments.value.findIndex(doc => doc.id === document.id)
        if (existingIndex !== -1) {
          processingDocuments.value[existingIndex] = document
        } else {
          processingDocuments.value.unshift(document)
        }
      } else {
        // Update or add to processing documents
        const existingIndex = processingDocuments.value.findIndex(doc => doc.id === document.id)
        if (existingIndex !== -1) {
          processingDocuments.value[existingIndex] = document
        } else {
          processingDocuments.value.unshift(document)
        }
      }
    }

    const viewDocument = (document) => {
      router.push(`/documents/${document.id}`)
    }

    const onDocumentDeleted = (deletedDocument) => {
      // Remove from completed documents list
      completedDocuments.value = completedDocuments.value.filter(doc => doc.id !== deletedDocument.id)

      // Remove from processing documents list
      processingDocuments.value = processingDocuments.value.filter(doc => doc.id !== deletedDocument.id)
    }

    const loadDocuments = async () => {
      try {
        const response = await documentsApi.getDocuments()
        const documents = response.data.data

        // Clear existing arrays
        completedDocuments.value = []
        processingDocuments.value = []

        // Separate documents by status
        documents.forEach(doc => {
          if (doc.status === 'completed') {
            completedDocuments.value.push(doc)
          } else if (doc.status === 'processing' || doc.status === 'uploaded' || doc.status === 'failed') {
            processingDocuments.value.push(doc)
          }
        })

        // Sort processing documents by insertion time (newest first)
        processingDocuments.value.sort((a, b) => new Date(b.inserted_at) - new Date(a.inserted_at))

        // Sort completed documents by insertion time (newest first)
        completedDocuments.value.sort((a, b) => new Date(b.inserted_at) - new Date(a.inserted_at))

        console.log(`Loaded ${processingDocuments.value.length} processing documents and ${completedDocuments.value.length} completed documents`)
      } catch (error) {
        console.error('Failed to load documents:', error)
      }
    }

    onMounted(() => {
      loadDocuments()
    })

    return {
      processingDocuments,
      currentProcessingDocument,
      completedDocuments,
      currentPage,
      onUploadComplete,
      onStatusUpdate,
      viewDocument,
      onDocumentDeleted
    }
  }
}
</script>

<style scoped>
.main-content {
  min-height: calc(100vh - 300px);
  padding-top: 112px;
}

@media (max-width: 768px) {
  .main-content {
    padding-top: 96px;
  }
}
</style>
