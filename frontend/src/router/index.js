import { createRouter, createWebHistory } from 'vue-router'
import Landing from '../views/Landing.vue'
import Home from '../views/Home.vue'
import FormPreview from '../views/FormPreview.vue'
import Register from '../views/Register.vue'
import Login from '../views/Login.vue'
import ConfirmEmail from '../views/ConfirmEmail.vue'
import DocumentEdit from '../views/DocumentEdit.vue'
import SharedForm from '../views/SharedForm.vue'
import { authApi } from '../services/api.js'

const routes = [
  {
    path: '/',
    name: 'Landing',
    component: Landing
  },
  {
    path: '/register',
    name: 'Register',
    component: Register
  },
  {
    path: '/login',
    name: 'Login',
    component: Login
  },
  {
    path: '/confirm/:token',
    name: 'ConfirmEmail',
    component: ConfirmEmail
  },
  {
    path: '/upload',
    name: 'Home',
    component: Home,
    meta: { requiresAuth: true }
  },
  {
    path: '/documents/:id',
    name: 'DocumentEdit',
    component: DocumentEdit,
    meta: { requiresAuth: true }
  },
  {
    path: '/preview/:id',
    name: 'FormPreview',
    component: FormPreview
  },
  {
    path: '/share/:token',
    name: 'SharedForm',
    component: SharedForm
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navigation guard to check authentication
router.beforeEach(async (to, from, next) => {
  if (to.meta.requiresAuth) {
    try {
      const response = await authApi.getCurrentUser()
      if (response.data && response.data.user) {
        // User is authenticated
        next()
      } else {
        // User is not authenticated, redirect to login
        next({ name: 'Login', query: { redirect: to.fullPath } })
      }
    } catch (error) {
      // Authentication check failed, redirect to login
      next({ name: 'Login', query: { redirect: to.fullPath } })
    }
  } else {
    // Route doesn't require auth
    next()
  }
})

export default router
