<template>
  <div class="input-field">
    <label v-if="label" :for="fieldId" class="field-label">
      {{ label }}
    </label>
    <input
      :id="fieldId"
      :type="inputType || 'text'"
      :name="field_name"
      :value="modelValue"
      :placeholder="placeholder"
      :required="required"
      @input="$emit('update:modelValue', $event.target.value)"
      class="field-input"
    />
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  id: String,
  label: String,
  field_name: String,
  inputType: String,
  input_type: String,
  placeholder: String,
  required: Boolean,
  modelValue: [String, Number],
  editMode: Boolean
})

const fieldId = computed(() => props.id || props.field_name || 'input-' + Math.random())

defineEmits(['update:modelValue'])
</script>

<style scoped>
.input-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-weight: 500;
  color: inherit;
  font-size: 14px;
}

.field-input {
  padding: 8px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  transition: all 0.2s;
  width: 100%;
}

.field-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.field-input:disabled {
  background-color: #f9fafb;
  cursor: not-allowed;
}
</style>