<template>
  <div class="radio-field">
    <fieldset>
      <legend v-if="label" class="field-label">{{ label }}</legend>
      <div class="radio-options">
        <label
          v-for="option in normalizedOptions"
          :key="option.value"
          class="radio-option"
        >
          <input
            type="radio"
            :name="field_name"
            :value="option.value"
            :checked="modelValue === option.value"
            :required="required"
            @change="$emit('update:modelValue', option.value)"
            class="radio-input"
          />
          <span class="radio-label">{{ option.label }}</span>
        </label>
      </div>
    </fieldset>
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

const normalizedOptions = computed(() => {
  if (!props.options) return []

  return props.options.map(opt => {
    if (typeof opt === 'string') {
      return { value: opt, label: opt }
    }
    return opt
  })
})

defineEmits(['update:modelValue'])
</script>

<style scoped>
.radio-field fieldset {
  border: none;
  padding: 0;
  margin: 0;
}

.field-label {
  font-weight: 500;
  color: #374151;
  font-size: 14px;
  display: block;
  margin-bottom: 8px;
}

.radio-options {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.radio-option {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px 0;
}

.radio-option:hover:not(.disabled) .radio-label {
  color: #3b82f6;
}

.radio-option.disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.radio-input {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #3b82f6;
}

.radio-input:disabled {
  cursor: not-allowed;
}

.radio-label {
  font-size: 14px;
  color: inherit;
  transition: color 0.2s;
}
</style>