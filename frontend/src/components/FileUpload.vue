<template>
  <div class="space-y-6">
    <!-- Drop Zone -->
    <div 
      @drop.prevent="onDrop"
      @dragover.prevent
      @dragenter.prevent
      class="relative border-2 border-dashed border-gray-300/60 bg-white/40 backdrop-blur-sm rounded-xl p-12 text-center hover:border-primary-400 hover:bg-primary-50/30 transition-all duration-300 hover:shadow-lg"
      :class="{ 'border-primary-400 bg-primary-50/50 shadow-lg': isDragging }"
    >
      <div v-if="!selectedFile" class="space-y-4">
        <div class="mx-auto w-12 h-12 text-primary-400 opacity-70 hover:opacity-100 transition-opacity duration-300">
          <DocumentArrowUpIcon class="w-full h-full" />
        </div>
        <div>
          <p class="text-lg font-medium text-gray-700">Drop your document here</p>
          <p class="text-sm text-gray-500 mt-1">or click to browse</p>
        </div>
        <div class="text-xs text-gray-400">
          Supports: JPG, PNG, GIF, BMP, TIFF, PDF (max 10MB, up to 5 pages for PDFs)
        </div>
      </div>

      <!-- Selected File Preview -->
      <div v-else class="space-y-4">
        <div class="flex items-center justify-center space-x-4">
          <div class="w-16 h-16 bg-gradient-to-br from-primary-50 to-primary-100 border border-primary-200 rounded-xl flex items-center justify-center shadow-md">
            <DocumentTextIcon class="w-8 h-8 text-primary-600" />
          </div>
          <div class="text-left">
            <p class="font-medium text-gray-900">{{ selectedFile.name }}</p>
            <p class="text-sm text-gray-500">{{ formatFileSize(selectedFile.size) }}</p>
          </div>
        </div>
        <button 
          @click="clearFile"
          class="text-sm text-gray-500 hover:text-gray-700"
        >
          Remove file
        </button>
      </div>

      <input
        ref="fileInput"
        type="file"
        accept="image/*,.pdf"
        @change="onFileSelect"
        class="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
      >
    </div>

    <!-- Model Selection -->
    <div class="space-y-3">
      <label class="text-sm font-medium text-gray-700">AI Model</label>
      <select 
        v-model="selectedModel" 
        class="input-field"
        :disabled="isUploading"
      >

        <option value="openai/gpt-5">GPT5</option>
                <option value="openai/gpt-5">GPT5</option>
                                <option value="qwen/qwen2.5-vl-32b-instruct">QWEN 32B VL</option>
                                <option value="google/gemma-3-27b-it:free">google/gemma-3-27b-it:free</option>


                <option value="openai/gpt-oss-120b">GPT OSS</option>
        <option value="anthropic/claude-sonnet-4:1m">Sonnet 4</option>
      </select>
    </div>

    <!-- Theme Selection -->
    <div class="space-y-3">
      <label class="text-sm font-medium text-gray-700">Output Theme</label>
      <select 
        v-model="selectedTheme" 
        class="input-field"
        :disabled="isUploading"
      >
        <option value="default">Professional</option>
        <option value="minimal">Minimal</option>
        <option value="dark">Dark Mode</option>
        <option value="modern">Modern</option>
        <option value="classic">Classic</option>
        <option value="colorful">Colorful</option>
        <option value="newspaper">Newspaper</option>
        <option value="elegant">Elegant</option>
      </select>
    </div>

    <!-- Upload Button -->
    <button
      @click="uploadFile"
      :disabled="!selectedFile || isUploading"
      class="w-full btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
    >
      <div v-if="isUploading" class="flex items-center justify-center space-x-2">
        <div class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
        <span>Uploading...</span>
      </div>
      <span v-else>Process Document</span>
    </button>

    <!-- Upload Progress -->
    <div v-if="uploadProgress > 0" class="space-y-2">
      <div class="flex justify-between text-sm text-gray-600">
        <span>Uploading...</span>
        <span>{{ uploadProgress }}%</span>
      </div>
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div 
          class="bg-gradient-to-r from-primary-500 to-primary-600 h-2 rounded-full transition-all duration-300 shadow-sm"
          :style="{ width: uploadProgress + '%' }"
        ></div>
      </div>
    </div>

    <!-- Error Message -->
    <div v-if="errorMessage" class="p-4 bg-red-50 border border-red-200 rounded-lg">
      <div class="flex items-start space-x-2">
        <ExclamationTriangleIcon class="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
        <div>
          <p class="text-sm font-medium text-red-800">Upload Failed</p>
          <p class="text-sm text-red-600 mt-1">{{ errorMessage }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { DocumentArrowUpIcon, DocumentTextIcon, ExclamationTriangleIcon } from '@heroicons/vue/24/outline'
import { documentsApi } from '../services/api.js'

export default {
  name: 'FileUpload',
  components: {
    DocumentArrowUpIcon,
    DocumentTextIcon,
    ExclamationTriangleIcon
  },
  emits: ['upload-complete'],
  setup(props, { emit }) {
    const selectedFile = ref(null)
    const selectedModel = ref('llama2')
    const selectedTheme = ref('default')
    const isUploading = ref(false)
    const uploadProgress = ref(0)
    const errorMessage = ref('')
    const isDragging = ref(false)
    const fileInput = ref(null)

    const onFileSelect = (event) => {
      const file = event.target.files[0]
      if (file) {
        if (validateFile(file)) {
          selectedFile.value = file
          errorMessage.value = ''
        }
      }
    }

    const onDrop = (event) => {
      isDragging.value = false
      const files = event.dataTransfer.files
      if (files.length > 0) {
        const file = files[0]
        if (validateFile(file)) {
          selectedFile.value = file
          errorMessage.value = ''
        }
      }
    }

    const validateFile = (file) => {
      const maxSize = 10 * 1024 * 1024 // 10MB
      const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp', 'image/tiff', 'application/pdf']

      if (file.size > maxSize) {
        errorMessage.value = 'File size must be less than 10MB'
        return false
      }

      if (!allowedTypes.includes(file.type)) {
        errorMessage.value = 'Only image files and PDFs are supported (JPG, PNG, GIF, BMP, TIFF, PDF)'
        return false
      }

      return true
    }

    const clearFile = () => {
      selectedFile.value = null
      uploadProgress.value = 0
      errorMessage.value = ''
      if (fileInput.value) {
        fileInput.value.value = ''
      }
    }

    const uploadFile = async () => {
      if (!selectedFile.value) return

      isUploading.value = true
      uploadProgress.value = 0
      errorMessage.value = ''

      try {
        const formData = new FormData()
        formData.append('file', selectedFile.value)
        formData.append('model', selectedModel.value)
        formData.append('theme', selectedTheme.value)

        const response = await documentsApi.uploadDocument(formData, (progressEvent) => {
          if (progressEvent.lengthComputable) {
            uploadProgress.value = Math.round((progressEvent.loaded * 100) / progressEvent.total)
          }
        })

        // Emit the uploaded document
        emit('upload-complete', response.data.data)
        
        // Reset form
        clearFile()
        
      } catch (error) {
        console.error('Upload error:', error)
        errorMessage.value = error.response?.data?.message || 'Failed to upload document'
      } finally {
        isUploading.value = false
        uploadProgress.value = 0
      }
    }

    const formatFileSize = (bytes) => {
      if (bytes === 0) return '0 Bytes'
      const k = 1024
      const sizes = ['Bytes', 'KB', 'MB', 'GB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    }

    return {
      selectedFile,
      selectedModel,
      selectedTheme,
      isUploading,
      uploadProgress,
      errorMessage,
      isDragging,
      fileInput,
      onFileSelect,
      onDrop,
      clearFile,
      uploadFile,
      formatFileSize
    }
  }
}
</script>