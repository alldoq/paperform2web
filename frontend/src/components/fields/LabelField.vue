<template>
  <div class="label-field" :style="fieldStyle">
    <span class="label-text">{{ text || label || '' }}</span>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  id: String,
  label: String,
  text: String,
  formatting: {
    type: Object,
    default: () => ({})
  }
})

const fieldStyle = computed(() => {
  const style = {}

  if (props.formatting.alignment) {
    style.textAlign = props.formatting.alignment
  }

  if (props.formatting.bold) {
    style.fontWeight = 'bold'
  }

  if (props.formatting.italic) {
    style.fontStyle = 'italic'
  }

  if (props.formatting.fontSize) {
    style.fontSize = props.formatting.fontSize + 'px'
  }

  if (props.formatting.color) {
    style.color = props.formatting.color
  }

  return style
})
</script>

<style scoped>
.label-field {
  padding: 8px 0;
}

.label-text {
  font-size: 14px;
  color: inherit;
  line-height: 1.6;
}
</style>