import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL ? `${import.meta.env.VITE_API_URL}/api` : '/api'

// Create axios instance with default config
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 120000, // 2 minutes for file uploads
  headers: {
    'Content-Type': 'application/json'
  }
})

// Request interceptor
api.interceptors.request.use(
  (config) => {
    // Add timestamp to prevent caching
    if (config.method === 'get') {
      config.params = { ...config.params, _t: Date.now() }
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor
api.interceptors.response.use(
  (response) => {
    return response
  },
  (error) => {
    console.error('API Error:', error)
    
    // Handle specific error cases
    if (error.response) {
      const { status, data } = error.response
      
      switch (status) {
        case 401:
          console.error('Unauthorized access')
          break
        case 403:
          console.error('Forbidden access')
          break
        case 404:
          console.error('Resource not found')
          break
        case 422:
          console.error('Validation error:', data.errors)
          break
        case 500:
          console.error('Server error')
          break
        default:
          console.error(`HTTP ${status}:`, data.message || 'Unknown error')
      }
    } else if (error.request) {
      console.error('Network error - no response received')
    } else {
      console.error('Request setup error:', error.message)
    }
    
    return Promise.reject(error)
  }
)

// Documents API
export const documentsApi = {
  // Upload a document
  uploadDocument: (formData, onUploadProgress = null) => {
    const config = {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    }
    
    if (onUploadProgress) {
      config.onUploadProgress = onUploadProgress
    }
    
    return api.post('/upload', formData, config)
  },

  // Get all documents
  getDocuments: (params = {}) => {
    return api.get('/documents', { params })
  },

  // Get a specific document
  getDocument: (id) => {
    return api.get(`/documents/${id}`)
  },

  // Get document processing status
  getDocumentStatus: (id) => {
    return api.get(`/documents/${id}/status`)
  },

  // Get document HTML output
  getDocumentHTML: (id, bustCache = false) => {
    const params = bustCache ? { _t: Date.now() } : {}
    return api.get(`/documents/${id}/html`, {
      params,
      headers: {
        'Accept': 'text/html'
      }
    })
  },

  // Delete a document
  deleteDocument: (id) => {
    return api.delete(`/documents/${id}`)
  },

  // Update document theme
  updateDocumentTheme: (id, theme) => {
    return api.patch(`/documents/${id}/theme`, { theme })
  },

  // Update document form structure
  updateFormStructure: (id, formFields) => {
    return api.patch(`/documents/${id}/form_structure`, { form_fields: formFields })
  },

  // Share management
  createShare: (id, shareData) => {
    return api.post(`/documents/${id}/share`, shareData)
  },

  getShares: (id) => {
    return api.get(`/documents/${id}/shares`)
  },

  // Analytics
  getShareAnalytics: (token) => {
    return api.get(`/share/${token}/analytics`)
  }
}

// Auth API
export const authApi = {
  // Check authentication status
  getAuthStatus: () => {
    return api.get('/auth/status')
  },

  // Test connection to Ollama
  testConnection: () => {
    return api.get('/auth/test')
  },

  // Get available models
  getModels: () => {
    return api.get('/models')
  }
}

// Health check API
export const healthApi = {
  // Check if the API is responding
  ping: () => {
    return api.get('/health', { timeout: 5000 })
  }
}

// Utility functions
export const apiUtils = {
  // Check if the API is available
  checkApiHealth: async () => {
    try {
      await healthApi.ping()
      return true
    } catch (error) {
      return false
    }
  },

  // Format file size for display
  formatFileSize: (bytes) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  },

  // Format date for display
  formatDate: (timestamp) => {
    const date = new Date(timestamp)
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  },

  // Get file extension from filename
  getFileExtension: (filename) => {
    return filename.split('.').pop().toLowerCase()
  },

  // Validate image file type
  isValidImageType: (file) => {
    const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp', 'image/tiff']
    return validTypes.includes(file.type)
  },

  // Validate file size
  isValidFileSize: (file, maxSizeInMB = 10) => {
    const maxSizeInBytes = maxSizeInMB * 1024 * 1024
    return file.size <= maxSizeInBytes
  }
}

export default api