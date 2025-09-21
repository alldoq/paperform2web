<template>
  <!-- Modal Overlay -->
  <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
    <div class="bg-white rounded-xl shadow-xl w-full max-w-md">
      <!-- Header -->
      <div class="flex items-center justify-between p-6 border-b border-gray-200">
        <div class="flex items-center space-x-3">
          <div class="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
            <ShareIcon class="w-4 h-4 text-blue-600" />
          </div>
          <h2 class="text-lg font-semibold text-gray-900">Share Form</h2>
        </div>
        <button
          @click="$emit('close')"
          class="p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100"
        >
          <XMarkIcon class="w-5 h-5" />
        </button>
      </div>

      <!-- Form Content -->
      <div class="p-6">
        <form @submit.prevent="handleShare" class="space-y-4">
          <!-- Recipient Email -->
          <div>
            <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
              Recipient Email
            </label>
            <input
              id="email"
              v-model="form.recipientEmail"
              type="email"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Enter email address"
            />
          </div>

          <!-- Recipient Name (Optional) -->
          <div>
            <label for="name" class="block text-sm font-medium text-gray-700 mb-1">
              Recipient Name (Optional)
            </label>
            <input
              id="name"
              v-model="form.recipientName"
              type="text"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Enter recipient name"
            />
          </div>

          <!-- Subject -->
          <div>
            <label for="subject" class="block text-sm font-medium text-gray-700 mb-1">
              Email Subject
            </label>
            <input
              id="subject"
              v-model="form.subject"
              type="text"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Subject line"
            />
          </div>

          <!-- Message -->
          <div>
            <label for="message" class="block text-sm font-medium text-gray-700 mb-1">
              Personal Message (Optional)
            </label>
            <textarea
              id="message"
              v-model="form.message"
              rows="4"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
              placeholder="Add a personal message..."
            ></textarea>
          </div>

          <!-- Expiration Date -->
          <div>
            <label for="expires" class="block text-sm font-medium text-gray-700 mb-1">
              Expiration Date (Optional)
            </label>
            <input
              id="expires"
              v-model="form.expiresAt"
              type="datetime-local"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <p class="text-xs text-gray-500 mt-1">Leave blank for no expiration</p>
          </div>

          <!-- Error Message -->
          <div v-if="error" class="p-3 bg-red-50 border border-red-200 rounded-md">
            <div class="flex">
              <ExclamationTriangleIcon class="w-5 h-5 text-red-400" />
              <div class="ml-3">
                <p class="text-sm text-red-700">{{ error }}</p>
              </div>
            </div>
          </div>

          <!-- Success Message -->
          <div v-if="success" class="p-3 bg-green-50 border border-green-200 rounded-md">
            <div class="flex">
              <CheckCircleIcon class="w-5 h-5 text-green-400" />
              <div class="ml-3">
                <p class="text-sm text-green-700">{{ success }}</p>
              </div>
            </div>
          </div>
        </form>
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-end space-x-3 p-6 border-t border-gray-200 bg-gray-50">
        <button
          @click="$emit('close')"
          type="button"
          class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          Cancel
        </button>
        <button
          @click="handleShare"
          :disabled="isLoading || !form.recipientEmail || !form.subject"
          class="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
        >
          <span v-if="isLoading" class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          <ShareIcon v-else class="w-4 h-4" />
          <span>{{ isLoading ? 'Sending...' : 'Send Form' }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed } from 'vue'
import { ShareIcon, XMarkIcon, ExclamationTriangleIcon, CheckCircleIcon } from '@heroicons/vue/24/outline'

export default {
  name: 'ShareDialog',
  components: {
    ShareIcon,
    XMarkIcon,
    ExclamationTriangleIcon,
    CheckCircleIcon
  },
  props: {
    document: {
      type: Object,
      required: true
    }
  },
  emits: ['close', 'share-sent'],
  setup(props, { emit }) {
    const isLoading = ref(false)
    const error = ref('')
    const success = ref('')

    const form = ref({
      recipientEmail: '',
      recipientName: '',
      subject: `You've been invited to fill out: ${props.document.filename}`,
      message: '',
      expiresAt: ''
    })

    const handleShare = async () => {
      if (!form.value.recipientEmail || !form.value.subject) {
        error.value = 'Please fill in all required fields'
        return
      }

      isLoading.value = true
      error.value = ''
      success.value = ''

      try {
        // Here we'll call the API to create the share and send email
        const shareData = {
          recipient_email: form.value.recipientEmail,
          recipient_name: form.value.recipientName,
          subject: form.value.subject,
          message: form.value.message,
          expires_at: form.value.expiresAt || null
        }

        const response = await fetch(`/api/documents/${props.document.id}/share`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(shareData)
        })

        if (!response.ok) {
          const errorData = await response.json()
          throw new Error(errorData.error || 'Failed to send form')
        }

        const result = await response.json()

        success.value = 'Form shared successfully! The recipient will receive an email shortly.'
        emit('share-sent', result.data)

        // Close dialog after a short delay
        setTimeout(() => {
          emit('close')
        }, 2000)

      } catch (err) {
        error.value = err.message || 'Failed to share form. Please try again.'
      } finally {
        isLoading.value = false
      }
    }

    return {
      form,
      isLoading,
      error,
      success,
      handleShare
    }
  }
}
</script>