<template>
  <div class="textarea-field">
    <label v-if="label" :for="fieldId" class="field-label">
      {{ label }}
    </label>
    <textarea
      :id="fieldId"
      :name="field_name"
      :value="modelValue"
      :placeholder="placeholder"
      :required="required"
      :rows="rows"
      @input="$emit('update:modelValue', $event.target.value)"
      class="field-textarea"
    />
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  id: String,
  label: String,
  field_name: String,
  placeholder: String,
  required: Boolean,
  modelValue: String,
  editMode: Boolean,
  rows: {
    type: Number,
    default: 4
  }
})

const fieldId = computed(() => props.id || props.field_name || 'textarea-' + Math.random())

defineEmits(['update:modelValue'])
</script>

<style scoped>
.textarea-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-weight: 500;
  color: inherit;
  font-size: 14px;
}

.field-textarea {
  padding: 8px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  transition: all 0.2s;
  width: 100%;
  resize: vertical;
  min-height: 100px;
  font-family: inherit;
}

.field-textarea:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.field-textarea:disabled {
  background-color: #f9fafb;
  cursor: not-allowed;
  resize: none;
}
</style>