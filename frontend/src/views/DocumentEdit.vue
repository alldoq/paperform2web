<template>
  <div class="document-edit-page">
    <AppHeader
      :show-dashboard-nav="false"
      @page-change="handlePageChange"
    />

    <main class="document-edit-content">
      <DocumentViewer
        v-if="document"
        :document="document"
        :is-page-mode="true"
        @close="handleClose"
        @document-updated="handleDocumentUpdated"
      />
      <div v-else class="loading-state">
        <div class="spinner"></div>
        <p>Loading document...</p>
      </div>
    </main>

    <AppFooter />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import AppHeader from '../components/AppHeader.vue'
import AppFooter from '../components/AppFooter.vue'
import DocumentViewer from '../components/DocumentViewer.vue'
import { documentsApi } from '../services/api.js'

const router = useRouter()
const route = useRoute()
const document = ref(null)

const loadDocument = async () => {
  try {
    const response = await documentsApi.getDocument(route.params.id)
    document.value = response.data.data
  } catch (error) {
    console.error('Failed to load document:', error)
    router.push('/upload')
  }
}

const handleClose = () => {
  router.push('/upload')
}

const handlePageChange = (page) => {
  router.push('/upload')
}

const handleDocumentUpdated = (updatedDocument) => {
  document.value = updatedDocument
}

onMounted(() => {
  loadDocument()
})
</script>

<style scoped>
.document-edit-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: #f9fafb;
}

.document-edit-content {
  flex: 1;
  padding-top: 112px;
  min-height: calc(100vh - 200px);
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 400px;
  gap: 16px;
}

.spinner {
  width: 48px;
  height: 48px;
  border: 4px solid #e5e7eb;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.loading-state p {
  color: #6b7280;
  font-size: 16px;
}

@media (max-width: 768px) {
  .document-edit-content {
    padding-top: 96px;
  }
}
</style>
