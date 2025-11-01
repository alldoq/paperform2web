<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50/30 to-gray-100 font-sans">
    <!-- Header -->
    <header class="nav-header">
      <div class="container nav-container">
        <div class="nav-brand">
          <Logo :size="72" />
          <span class="brand-name">Paperform2Web</span>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10 main-content">
      <!-- Loading State -->
      <div v-if="loading" class="card">
        <div class="p-8 text-center">
          <div class="spinner mx-auto mb-4"></div>
          <p class="text-gray-600">Loading form...</p>
        </div>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="card">
        <div class="p-8 text-center">
          <div class="text-red-500 mb-4">
            <svg class="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h2 class="text-2xl font-bold text-gray-900 mb-2">{{ error }}</h2>
          <p class="text-gray-600 mb-6">{{ errorMessage }}</p>
          <router-link to="/" class="btn btn-primary">
            Go to Homepage
          </router-link>
        </div>
      </div>

      <!-- Success State -->
      <div v-else-if="submitted" class="card">
        <div class="p-8 text-center">
          <div class="text-green-500 mb-4">
            <svg class="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h2 class="text-2xl font-bold text-gray-900 mb-2">Thank you!</h2>
          <p class="text-gray-600 mb-6">Your form has been submitted successfully.</p>
          <router-link to="/" class="btn btn-primary">
            Go to Homepage
          </router-link>
        </div>
      </div>

      <!-- Form State -->
      <div v-else-if="formData" class="card">
        <div class="p-6">
          <FormRenderer
            :fields="formData.form_fields"
            :formTitle="formData.title"
            :theme="formData.theme"
            :showSubmitButton="true"
            submitButtonText="Submit Form"
            @submit="handleSubmit"
          />
        </div>
      </div>
    </main>

    <!-- Footer -->
    <AppFooter />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import Logo from '../components/Logo.vue'
import AppFooter from '../components/AppFooter.vue'
import FormRenderer from '../components/FormRenderer.vue'
import api from '../services/api'

const route = useRoute()
const loading = ref(true)
const error = ref(null)
const errorMessage = ref('')
const formData = ref(null)
const submitted = ref(false)
const sessionId = ref(null)

// Generate a session ID for tracking multiple submissions
const generateSessionId = () => {
  return 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9)
}

const loadFormData = async () => {
  loading.value = true
  error.value = null

  try {
    const token = route.params.token
    const response = await api.get(`/share/${token}/data`)

    if (response.data && response.data.data) {
      formData.value = response.data.data
      sessionId.value = generateSessionId()
    } else {
      error.value = 'Invalid Response'
      errorMessage.value = 'The server returned an invalid response.'
    }
  } catch (err) {
    console.error('Failed to load shared form:', err)

    if (err.response) {
      const status = err.response.status

      if (status === 404) {
        error.value = 'Form Not Found'
        errorMessage.value = 'This form does not exist or has been removed.'
      } else if (status === 410) {
        error.value = 'Form Expired'
        errorMessage.value = err.response.data?.error || 'This form link has expired.'
      } else {
        error.value = 'Error Loading Form'
        errorMessage.value = 'An error occurred while loading the form. Please try again later.'
      }
    } else {
      error.value = 'Connection Error'
      errorMessage.value = 'Unable to connect to the server. Please check your internet connection.'
    }
  } finally {
    loading.value = false
  }
}

const handleSubmit = async (formSubmission) => {
  try {
    const token = route.params.token
    const response = await api.post(`/share/${token}/response`, {
      response_data: formSubmission.data,
      session_id: sessionId.value
    })

    if (response.data) {
      submitted.value = true
    }
  } catch (err) {
    console.error('Failed to submit form:', err)

    if (err.response) {
      const status = err.response.status

      if (status === 404) {
        error.value = 'Form Not Found'
        errorMessage.value = 'This form does not exist or has been removed.'
      } else if (status === 422) {
        error.value = 'Validation Error'
        errorMessage.value = 'Please check your form data and try again.'
      } else {
        error.value = 'Submission Failed'
        errorMessage.value = 'An error occurred while submitting the form. Please try again.'
      }
    } else {
      error.value = 'Connection Error'
      errorMessage.value = 'Unable to connect to the server. Please check your internet connection.'
    }
  }
}

onMounted(() => {
  loadFormData()
})
</script>

<style scoped>
.nav-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 50;
  height: 80px;
}

.container {
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 1rem;
}

.nav-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 80px;
}

.nav-brand {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  cursor: pointer;
}

.brand-name {
  font-size: 1.5rem;
  font-weight: 700;
  color: white;
  letter-spacing: -0.025em;
}

.main-content {
  min-height: calc(100vh - 300px);
  padding-top: 112px;
}

.card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.spinner {
  border: 4px solid #e5e7eb;
  border-top: 4px solid #3b82f6;
  border-radius: 50%;
  width: 48px;
  height: 48px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.75rem 1.5rem;
  font-weight: 500;
  border-radius: 8px;
  transition: all 0.2s;
  text-decoration: none;
  cursor: pointer;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
}

.btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

@media (max-width: 768px) {
  .main-content {
    padding-top: 96px;
  }
}
</style>
