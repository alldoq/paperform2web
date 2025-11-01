<template>
  <svg
    :width="size"
    :height="size"
    viewBox="0 0 100 100"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <defs>
      <linearGradient id="logoGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" style="stop-color:#1e3a8a;stop-opacity:1" />
        <stop offset="100%" style="stop-color:#3b82f6;stop-opacity:1" />
      </linearGradient>
    </defs>

    <!-- Background -->
    <rect x="8" y="8" width="84" height="84" rx="20" fill="url(#logoGradient)"/>

    <!-- Multiple Document/Page icons - stacked effect -->
    <g transform="translate(37, 22)">
      <!-- Back page (third layer) -->
      <path
        d="M 4 4 L 24 4 L 30 10 L 30 38 L 4 38 Z"
        fill="white"
        opacity="0.4"
      />

      <!-- Middle page (second layer) -->
      <path
        d="M 2 2 L 22 2 L 28 8 L 28 36 L 2 36 Z"
        fill="white"
        opacity="0.6"
      />

      <!-- Front page (first layer) with details -->
      <path
        d="M 0 0 L 20 0 L 26 6 L 26 34 L 0 34 Z"
        fill="white"
        opacity="0.95"
      />
      <!-- Folded corner on front page -->
      <path
        d="M 20 0 L 20 6 L 26 6 Z"
        fill="white"
        opacity="0.7"
      />
      <!-- Form lines on front page -->
      <line x1="4" y1="12" x2="22" y2="12" stroke="#3b82f6" stroke-width="1.5" opacity="0.8"/>
      <line x1="4" y1="18" x2="22" y2="18" stroke="#3b82f6" stroke-width="1.5" opacity="0.8"/>
      <line x1="4" y1="24" x2="18" y2="24" stroke="#3b82f6" stroke-width="1.5" opacity="0.8"/>
    </g>

    <!-- "P2W" text - centered at bottom with proper spacing -->
    <text x="50" y="78" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="white" text-anchor="middle" dominant-baseline="middle">P2W</text>
  </svg>
</template>

<script setup>
defineProps({
  size: {
    type: [String, Number],
    default: 48
  }
})
</script>
