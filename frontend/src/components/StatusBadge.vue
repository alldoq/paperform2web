<template>
  <span 
    class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
    :class="getBadgeClass()"
  >
    <div 
      v-if="status === 'processing'" 
      class="w-2 h-2 rounded-full mr-1.5 animate-pulse"
      :class="getDotClass()"
    ></div>
    {{ getStatusText() }}
  </span>
</template>

<script>
export default {
  name: 'StatusBadge',
  props: {
    status: {
      type: String,
      required: true
    }
  },
  setup(props) {
    const getBadgeClass = () => {
      switch (props.status) {
        case 'uploaded':
          return 'bg-gray-100 text-gray-800'
        case 'processing':
          return 'bg-blue-100 text-blue-800'
        case 'completed':
          return 'bg-green-100 text-green-800'
        case 'failed':
          return 'bg-red-100 text-red-800'
        default:
          return 'bg-gray-100 text-gray-800'
      }
    }

    const getDotClass = () => {
      return 'bg-blue-500'
    }

    const getStatusText = () => {
      switch (props.status) {
        case 'uploaded':
          return 'Queued'
        case 'processing':
          return 'Processing'
        case 'completed':
          return 'Complete'
        case 'failed':
          return 'Failed'
        default:
          return 'Unknown'
      }
    }

    return {
      getBadgeClass,
      getDotClass,
      getStatusText
    }
  }
}
</script>