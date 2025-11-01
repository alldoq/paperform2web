<template>
  <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50" @click.self="$emit('close')">
    <div class="bg-white rounded-xl shadow-xl w-full max-w-3xl max-h-[90vh] flex flex-col">
      <!-- Header -->
      <div class="flex items-center justify-between p-6 border-b border-gray-200">
        <div>
          <h2 class="text-2xl font-bold text-gray-900">Response Details</h2>
          <p class="text-gray-600 mt-1">
            From {{ response.share?.recipient_name || response.share?.recipient_email }}
          </p>
        </div>
        <button
          @click="$emit('close')"
          class="text-gray-400 hover:text-gray-600 transition-colors"
        >
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Content -->
      <div class="flex-1 overflow-y-auto p-6">
        <!-- Response Metadata -->
        <div class="bg-gray-50 rounded-lg p-4 mb-6">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
            <div>
              <span class="text-gray-600">Submitted:</span>
              <div class="font-medium text-gray-900 mt-1">{{ formatDate(response.inserted_at) }}</div>
            </div>
            <div>
              <span class="text-gray-600">Status:</span>
              <div class="mt-1">
                <span
                  :class="response.is_completed ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'"
                  class="px-2.5 py-0.5 rounded-full text-xs font-medium"
                >
                  {{ response.is_completed ? 'Completed' : 'Partial' }}
                </span>
              </div>
            </div>
            <div>
              <span class="text-gray-600">Session ID:</span>
              <div class="font-mono text-xs text-gray-900 mt-1 break-all">{{ response.session_id || 'N/A' }}</div>
            </div>
          </div>
        </div>

        <!-- Response Fields -->
        <div class="space-y-4">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Form Responses</h3>

          <div v-if="formFields.length > 0" class="space-y-4">
            <div
              v-for="(field, index) in formFields"
              :key="index"
              class="bg-white border border-gray-200 rounded-lg p-4"
            >
              <div class="flex items-start justify-between mb-2">
                <div class="flex-1">
                  <div class="text-sm text-gray-600 mb-1">{{ field.label }}</div>
                  <div class="text-gray-900 font-medium">
                    <div v-if="Array.isArray(field.value)">
                      <ul class="list-disc list-inside space-y-1">
                        <li v-for="(item, i) in field.value" :key="i">{{ item }}</li>
                      </ul>
                    </div>
                    <div v-else-if="typeof field.value === 'object'">
                      <pre class="text-sm bg-gray-50 p-2 rounded">{{ JSON.stringify(field.value, null, 2) }}</pre>
                    </div>
                    <div v-else-if="field.value === '' || field.value === null || field.value === undefined">
                      <span class="text-gray-400 italic">No response</span>
                    </div>
                    <div v-else>
                      {{ field.value }}
                    </div>
                  </div>
                </div>
                <div class="ml-4">
                  <span class="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                    {{ field.type || 'text' }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-8 text-gray-500">
            <p>No response data available</p>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex justify-end gap-3 p-6 border-t border-gray-200">
        <button
          @click="$emit('close')"
          class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg font-medium transition-colors"
        >
          Close
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  response: {
    type: Object,
    required: true
  }
})

defineEmits(['close'])

const formFields = computed(() => {
  if (!props.response?.response_data) return []

  // Get the form_data if it exists
  const responseData = props.response.response_data.form_data || props.response.response_data

  // Convert to array of field objects
  return Object.entries(responseData).map(([key, value]) => {
    let displayValue = value
    let displayLabel = key
    let displayType = 'text'

    // If value is an object with label and value properties
    if (typeof value === 'object' && value !== null) {
      displayLabel = value.label || key
      displayValue = value.value !== undefined ? value.value : value
      displayType = value.type || 'text'
    }

    return {
      key: key,
      label: displayLabel,
      value: displayValue,
      type: displayType
    }
  })
})

const formatDate = (timestamp) => {
  if (!timestamp) return 'Unknown'
  const date = new Date(timestamp)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}
</script>

<style scoped>
/* Additional styles if needed */
</style>
