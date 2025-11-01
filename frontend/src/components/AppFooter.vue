<template>
  <footer class="footer">
    <div class="container">
      <div class="footer-content">
        <div class="footer-brand">
          <Logo :size="80" />
          <div class="footer-text">
            <h3>Paperform2Web</h3>
            <p>Transform PDFs and photos into interactive web forms</p>
          </div>
        </div>
        <div class="footer-copyright">
          <p>&copy; 2025 Paperform2Web. All rights reserved.</p>
        </div>
      </div>
    </div>
  </footer>
</template>

<script setup>
import Logo from './Logo.vue'
</script>

<style scoped>
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
}

.footer {
  background: #1f2937;
  padding: 40px 0;
}

.footer-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.footer-brand {
  display: flex;
  align-items: center;
  gap: 16px;
}

.footer-text h3 {
  margin: 0 0 4px 0;
  color: #ffffff;
  font-size: 18px;
  font-weight: 700;
}

.footer-text p {
  margin: 0;
  color: #9ca3af;
  font-size: 14px;
}

.footer-copyright p {
  margin: 0;
  color: #6b7280;
  font-size: 14px;
}

@media (max-width: 768px) {
  .footer-content {
    flex-direction: column;
    gap: 20px;
    text-align: center;
  }
}
</style>
