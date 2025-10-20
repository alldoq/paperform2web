import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import FormPreview from '../views/FormPreview.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/preview/:id',
    name: 'FormPreview',
    component: FormPreview
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
