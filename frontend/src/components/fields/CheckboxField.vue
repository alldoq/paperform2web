<template>
  <div class="checkbox-field">
    <label class="checkbox-label">
      <input
        type="checkbox"
        :name="field_name"
        :checked="modelValue"
        :required="required"
        @change="$emit('update:modelValue', $event.target.checked)"
        class="checkbox-input"
      />
      <span class="checkbox-text">{{ label || value }}</span>
    </label>
  </div>
</template>

<script setup>
defineProps({
  id: String,
  label: String,
  value: String,
  field_name: String,
  required: Boolean,
  modelValue: Boolean,
  editMode: Boolean
})

defineEmits(['update:modelValue'])
</script>

<style scoped>
.checkbox-field {
  display: flex;
  align-items: center;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.checkbox-label:hover:not(.disabled) .checkbox-text {
  color: #3b82f6;
}

.checkbox-label.disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.checkbox-input {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #3b82f6;
}

.checkbox-input:disabled {
  cursor: not-allowed;
}

.checkbox-text {
  font-size: 14px;
  color: inherit;
  transition: color 0.2s;
}
</style>