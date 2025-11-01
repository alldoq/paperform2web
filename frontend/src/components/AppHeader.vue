<template>
  <header class="nav-header">
    <div class="container nav-container">
      <div class="nav-brand">
        <Logo :size="72" />
        <span class="brand-name">Paperform2Web</span>
      </div>
      <nav class="nav-links">
        <router-link to="/" class="nav-link">Home</router-link>
        <template v-if="isLoggedIn">
          <!-- Dashboard page navigation -->
          <template v-if="showDashboardNav">
            <button
              @click="$emit('page-change', 'home')"
              :class="[
                'nav-link-button',
                currentPage === 'home' ? 'active' : ''
              ]"
            >
              Upload
            </button>
            <button
              @click="$emit('page-change', 'processed')"
              :class="[
                'nav-link-button',
                currentPage === 'processed' ? 'active' : ''
              ]"
            >
              Processed Documents
            </button>
          </template>
          <template v-else>
            <router-link to="/upload" class="nav-link">Dashboard</router-link>
          </template>
          <button @click="handleLogout" class="btn btn-nav-primary">Logout</button>
        </template>
        <template v-else>
          <router-link to="/login" class="nav-link">Sign In</router-link>
          <router-link to="/register" class="btn btn-nav-primary">Get Started</router-link>
        </template>
      </nav>
    </div>
  </header>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import Logo from './Logo.vue'
import { authApi } from '../services/api.js'

const props = defineProps({
  showDashboardNav: {
    type: Boolean,
    default: false
  },
  currentPage: {
    type: String,
    default: 'home'
  }
})

defineEmits(['page-change'])

const router = useRouter()
const isLoggedIn = ref(false)
const currentUser = ref(null)

const checkAuth = async () => {
  try {
    const response = await authApi.getCurrentUser()
    if (response.data && response.data.user) {
      isLoggedIn.value = true
      currentUser.value = response.data.user
    }
  } catch (error) {
    isLoggedIn.value = false
    currentUser.value = null
  }
}

const handleLogout = async () => {
  try {
    await authApi.logout()
    isLoggedIn.value = false
    currentUser.value = null
    router.push('/')
  } catch (error) {
    console.error('Logout error:', error)
  }
}

onMounted(async () => {
  await checkAuth()
})
</script>

<style scoped>
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
}

.nav-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
  z-index: 100;
  padding: 20px 0;
}

.nav-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.nav-brand {
  display: flex;
  align-items: center;
  gap: 12px;
}

.brand-name {
  font-size: 20px;
  font-weight: 700;
  color: #1e3a8a;
}

.nav-links {
  display: flex;
  align-items: center;
  gap: 32px;
}

.nav-link {
  font-size: 16px;
  font-weight: 500;
  color: #4b5563;
  text-decoration: none;
  background: none;
  border: none;
  cursor: pointer;
  transition: color 0.2s;
}

.nav-link:hover {
  color: #1e3a8a;
}

.nav-link-button {
  font-size: 16px;
  font-weight: 500;
  color: #4b5563;
  text-decoration: none;
  background: none;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
  padding: 8px 16px;
  border-radius: 8px;
}

.nav-link-button:hover {
  color: #1e3a8a;
  background: #f3f4f6;
}

.nav-link-button.active {
  background: #dbeafe;
  color: #1e40af;
  border: 1px solid #bfdbfe;
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
}

.btn-nav-primary {
  background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
  color: white;
  padding: 10px 24px;
  border-radius: 8px;
  font-weight: 600;
  font-size: 15px;
  border: none;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-nav-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(30, 58, 138, 0.3);
}

@media (max-width: 968px) {
  .nav-links {
    gap: 12px;
  }

  .nav-link:first-child {
    display: none;
  }

  .btn-nav-primary {
    padding: 8px 16px;
    font-size: 14px;
  }
}
</style>
