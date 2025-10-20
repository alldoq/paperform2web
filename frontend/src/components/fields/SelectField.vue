<template>
  <div class="select-field">
    <label v-if="label" :for="fieldId" class="field-label">
      {{ label }}
    </label>
    <select
      :id="fieldId"
      :name="field_name"
      :value="modelValue"
      :required="required"
      @change="$emit('update:modelValue', $event.target.value)"
      class="field-select"
    >
      <option value="" disabled>Choose an option</option>
      <option v-for="option in options" :key="option" :value="option">
        {{ option }}
      </option>
    </select>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  id: String,
  label: String,
  field_name: String,
  options: Array,
  required: Boolean,
  modelValue: String,
  editMode: Boolean
})

const fieldId = computed(() => props.id || props.field_name || 'select-' + Math.random())

defineEmits(['update:modelValue'])
</script>

<style scoped>
.select-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-weight: 500;
  color: inherit;
  font-size: 14px;
}

.field-select {
  padding: 8px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  transition: all 0.2s;
  width: 100%;
  background-color: white;
  cursor: pointer;
}

.field-select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.field-select:disabled {
  background-color: #f9fafb;
  cursor: not-allowed;
}
</style>