<template>
  <component
    :is="headingTag"
    class="heading-field"
    :style="fieldStyle"
  >
    {{ text || label || '' }}
  </component>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  id: String,
  label: String,
  text: String,
  level: {
    type: Number,
    default: 2
  },
  formatting: {
    type: Object,
    default: () => ({})
  }
})

const headingTag = computed(() => {
  const level = Math.min(Math.max(props.level, 1), 6)
  return `h${level}`
})

const fieldStyle = computed(() => {
  const style = {}

  if (props.formatting.alignment) {
    style.textAlign = props.formatting.alignment
  }

  if (props.formatting.color) {
    style.color = props.formatting.color
  }

  return style
})
</script>

<style scoped>
.heading-field {
  margin: 20px 0 12px 0;
  line-height: 1.3;
}

h1.heading-field {
  font-size: 32px;
  font-weight: bold;
  color: inherit;
}

h2.heading-field {
  font-size: 24px;
  font-weight: 600;
  color: inherit;
}

h3.heading-field {
  font-size: 20px;
  font-weight: 600;
  color: inherit;
}

h4.heading-field {
  font-size: 18px;
  font-weight: 500;
  color: inherit;
}

h5.heading-field {
  font-size: 16px;
  font-weight: 500;
  color: inherit;
}

h6.heading-field {
  font-size: 14px;
  font-weight: 500;
  color: inherit;
}
</style>