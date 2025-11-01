<template>
  <div class="landing-page">
    <!-- Navigation Header -->
    <header class="nav-header">
      <div class="container nav-container">
        <div class="nav-brand">
          <Logo :size="72" />
          <span class="brand-name">Paperform2Web</span>
        </div>
        <nav class="nav-links">
          <button @click="scrollToFeatures" class="nav-link">Features</button>
          <template v-if="isLoggedIn">
            <router-link to="/upload" class="nav-link">Dashboard</router-link>
            <button @click="handleLogout" class="btn btn-nav-primary">Logout</button>
          </template>
          <template v-else>
            <router-link to="/login" class="nav-link">Sign In</router-link>
            <button @click="navigateToRegister" class="btn btn-nav-primary">Get Started</button>
          </template>
        </nav>
      </div>
    </header>

    <!-- Hero Section -->
    <section class="hero">
      <div class="hero-background">
        <div class="parallax-image"></div>
        <div class="gradient-overlay"></div>
        <div class="gradient-orb orb-1"></div>
        <div class="gradient-orb orb-2"></div>
        <div class="gradient-orb orb-3"></div>
      </div>

      <div class="container hero-content">
        <div class="hero-text">
          <h1 class="hero-title">
            <span class="gradient-text">PDF & Photo to Web Form</span>
          </h1>
          <p class="hero-subtitle">
            Transform your PDFs, handwritten forms, and paper documents into beautiful, interactive web forms. Share with colleagues, track submissions, and analyze responses—all in one place.
          </p>
          <div class="hero-buttons">
            <button @click="navigateToRegister" class="btn btn-primary btn-large">
              <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
              </svg>
              Sign Up Free
            </button>
            <button @click="navigateToUpload" class="btn btn-secondary btn-large">
              <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
              </svg>
              Try Now
            </button>
            <button @click="scrollToFeatures" class="btn btn-tertiary btn-large">
              <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Learn More
            </button>
          </div>
          <div class="hero-stats">
            <div class="stat">
              <div class="stat-value">< 30s</div>
              <div class="stat-label">Average Processing Time</div>
            </div>
            <div class="stat">
              <div class="stat-value">10+</div>
              <div class="stat-label">Powerful Features</div>
            </div>
          </div>
        </div>

        <div class="hero-visual">
          <div class="visual-card">
            <div class="visual-header">
              <div class="visual-dots">
                <span></span><span></span><span></span>
              </div>
              <div class="visual-title">Document → Web Form</div>
            </div>
            <div class="visual-body">
              <div class="pdf-icon">
                <svg width="80" height="80" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" />
                </svg>
              </div>
              <div class="arrow-icon">
                <svg width="40" height="40" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                </svg>
              </div>
              <div class="form-preview">
                <div class="form-field"></div>
                <div class="form-field"></div>
                <div class="form-field short"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Features Section -->
    <section id="features" class="features">
      <div class="container">
        <div class="section-header">
          <h2 class="section-title">Powerful Features</h2>
          <p class="section-subtitle">Everything you need to create professional web forms from PDFs and photographed documents</p>
        </div>

        <div class="features-grid">
          <div class="feature-card" v-for="(feature, index) in features" :key="index">
            <div class="feature-icon" :style="{ background: feature.color }">
              <div v-html="feature.icon"></div>
            </div>
            <h3 class="feature-title">{{ feature.title }}</h3>
            <p class="feature-description">{{ feature.description }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- How It Works Section -->
    <section class="how-it-works">
      <div class="container">
        <div class="section-header">
          <h2 class="section-title">How It Works</h2>
          <p class="section-subtitle">Four simple steps to transform and analyze your forms</p>
        </div>

        <div class="steps">
          <div class="step" v-for="(step, index) in steps" :key="index">
            <div class="step-number">{{ index + 1 }}</div>
            <div class="step-content">
              <h3 class="step-title">{{ step.title }}</h3>
              <p class="step-description">{{ step.description }}</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Share & Analytics Section -->
    <section class="share-analytics-section">
      <div class="container">
        <div class="section-header">
          <h2 class="section-title">Share Forms & Track Results</h2>
          <p class="section-subtitle">Turn your paper forms into powerful web experiences that you can share and analyze</p>
        </div>

        <div class="share-features">
          <div class="share-feature">
            <div class="share-icon">
              <svg width="48" height="48" fill="currentColor" viewBox="0 0 20 20">
                <path d="M15 8a3 3 0 10-2.977-2.63l-4.94 2.47a3 3 0 100 4.319l4.94 2.47a3 3 0 10.895-1.789l-4.94-2.47a3.027 3.027 0 000-.74l4.94-2.47C13.456 7.68 14.19 8 15 8z"/>
              </svg>
            </div>
            <h3>Easy Sharing</h3>
            <p>Share your forms via email with a single click. Set expiration dates and control who can access your forms with password protection and access limits.</p>
          </div>

          <div class="share-feature">
            <div class="share-icon">
              <svg width="48" height="48" fill="currentColor" viewBox="0 0 20 20">
                <path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z"/>
              </svg>
            </div>
            <h3>Real-Time Analytics</h3>
            <p>Track form views, submissions, and completion rates. View detailed statistics about who accessed your forms and when they submitted their responses.</p>
          </div>

          <div class="share-feature">
            <div class="share-icon">
              <svg width="48" height="48" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clip-rule="evenodd"/>
              </svg>
            </div>
            <h3>Collect Responses</h3>
            <p>Gather form submissions from your team or clients. Export response data, manage submissions, and maintain a complete record of all form interactions.</p>
          </div>
        </div>

        <div class="code-export-feature">
          <div class="code-export-content">
            <h3>Easy HTML Export</h3>
            <p>Get your form as clean, embeddable HTML code. Copy the preview code with one click and paste it anywhere—your website, blog, or application. No complex integration required.</p>
            <div class="code-preview">
              <div class="code-header">
                <span>form.html</span>
                <button class="copy-btn">
                  <svg width="16" height="16" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M8 3a1 1 0 011-1h2a1 1 0 110 2H9a1 1 0 01-1-1z"/>
                    <path d="M6 3a2 2 0 00-2 2v11a2 2 0 002 2h8a2 2 0 002-2V5a2 2 0 00-2-2 3 3 0 01-3 3H9a3 3 0 01-3-3z"/>
                  </svg>
                  Copy
                </button>
              </div>
              <div class="code-body">
                <code>&lt;form class="paperform"&gt;
  &lt;input type="text" name="name" /&gt;
  &lt;input type="email" name="email" /&gt;
  ...
&lt;/form&gt;</code>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Feature Details Section -->
    <section class="feature-details">
      <div class="container">
        <div class="detail-item">
          <div class="detail-visual">
            <div class="detail-card">
              <div class="editor-mockup">
                <div class="editor-sidebar">
                  <div class="editor-section"></div>
                  <div class="editor-section"></div>
                  <div class="editor-section short"></div>
                </div>
                <div class="editor-preview">
                  <div class="preview-field"></div>
                  <div class="preview-field"></div>
                </div>
              </div>
            </div>
          </div>
          <div class="detail-content">
            <h3 class="detail-title">Visual Field Editor</h3>
            <p class="detail-description">
              Edit your form fields with our intuitive split-panel editor. See changes in real-time with live preview, adjust field types, add validation, and customize appearance—all without touching code.
            </p>
            <ul class="detail-list">
              <li>
                <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                Split-panel interface with live preview
              </li>
              <li>
                <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                7+ field types with validation options
              </li>
              <li>
                <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                Theme-aware styling
              </li>
            </ul>
          </div>
        </div>

        <div class="detail-item reverse">
          <div class="detail-visual">
            <div class="detail-card">
              <div class="pagination-mockup">
                <div class="page-indicator">Page 1 of 5</div>
                <div class="page-content">
                  <div class="page-field"></div>
                  <div class="page-field"></div>
                  <div class="page-field"></div>
                </div>
                <div class="page-buttons">
                  <div class="page-btn"></div>
                  <div class="page-btn"></div>
                </div>
              </div>
            </div>
          </div>
          <div class="detail-content">
            <h3 class="detail-title">Multi-Page Support</h3>
            <p class="detail-description">
              Process multi-page PDFs and photo sets with automatic pagination. Each page or photo becomes a separate form page with smooth navigation controls. Perfect for complex forms and applications.
            </p>
            <ul class="detail-list">
              <li>
                <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                Automatic page detection
              </li>
              <li>
                <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                Navigation controls with page indicators
              </li>
              <li>
                <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                Fields preserved across pages
              </li>
            </ul>
          </div>
        </div>

        <div class="detail-item">
          <div class="detail-visual">
            <div class="detail-card">
              <div class="drag-drop-mockup">
                <div class="field-list">
                  <div class="draggable-field">
                    <div class="drag-handle">⋮⋮</div>
                    <div class="field-content">Email</div>
                  </div>
                  <div class="draggable-field">
                    <div class="drag-handle">⋮⋮</div>
                    <div class="field-content">Phone</div>
                  </div>
                  <div class="draggable-field">
                    <div class="drag-handle">⋮⋮</div>
                    <div class="field-content">Message</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="detail-content">
            <h3 class="detail-title">Drag & Drop Reordering</h3>
            <p class="detail-description">
              Easily reorganize your form fields with intuitive drag-and-drop functionality. Reorder fields, group related inputs, and create the perfect form flow for your users.
            </p>
            <ul class="detail-list">
              <li>
                <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                Visual drag handles
              </li>
              <li>
                <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                Real-time preview updates
              </li>
              <li>
                <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
                Instant save with undo support
              </li>
            </ul>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA Section -->
    <section class="cta">
      <div class="container">
        <div class="cta-content">
          <h2 class="cta-title">Ready to Transform Your Forms?</h2>
          <p class="cta-subtitle">Start converting your PDFs and photographed forms into interactive web forms today. No credit card required.</p>
          <div class="cta-buttons">
            <button @click="navigateToRegister" class="btn btn-primary btn-large">
              <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
              </svg>
              Create Free Account
            </button>
            <router-link to="/login" class="btn btn-secondary-outline btn-large">
              Already have an account? Sign in
            </router-link>
          </div>
        </div>
      </div>
    </section>

    <!-- Footer -->
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
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import Logo from '../components/Logo.vue'
import { authApi } from '../services/api.js'

const router = useRouter()
const isLoggedIn = ref(false)
const currentUser = ref(null)

const navigateToUpload = () => {
  router.push('/upload')
}

const navigateToRegister = () => {
  router.push('/register')
}

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

// Parallax scroll effect
const handleParallaxScroll = () => {
  const parallaxElement = document.querySelector('.parallax-image')
  if (parallaxElement) {
    const scrolled = window.pageYOffset
    parallaxElement.style.transform = `translateY(${scrolled * 0.5}px)`
  }
}

onMounted(async () => {
  window.addEventListener('scroll', handleParallaxScroll)
  await checkAuth()
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleParallaxScroll)
})

const features = [
  {
    icon: '<svg width="32" height="32" fill="currentColor" viewBox="0 0 20 20"><path d="M13 7H7v6h6V7z"/><path fill-rule="evenodd" d="M7 2a1 1 0 012 0v1h2V2a1 1 0 112 0v1h2a2 2 0 012 2v2h1a1 1 0 110 2h-1v2h1a1 1 0 110 2h-1v2a2 2 0 01-2 2h-2v1a1 1 0 11-2 0v-1H9v1a1 1 0 11-2 0v-1H5a2 2 0 01-2-2v-2H2a1 1 0 110-2h1V9H2a1 1 0 010-2h1V5a2 2 0 012-2h2V2zM5 5h10v10H5V5z" clip-rule="evenodd"/></svg>',
    title: 'AI-Powered Extraction',
    description: 'Advanced AI automatically detects and extracts form fields from PDFs and photographed paper forms with high accuracy.',
    color: '#3b82f6'
  },
  {
    icon: '<svg width="32" height="32" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M3 5a2 2 0 012-2h10a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V5zm11 1H6v8h8V6z" clip-rule="evenodd"/></svg>',
    title: 'Visual Editor',
    description: 'Edit fields with an intuitive split-panel interface featuring live preview and theme customization.',
    color: '#6366f1'
  },
  {
    icon: '<svg width="32" height="32" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M6 2a2 2 0 00-2 2v12a2 2 0 002 2h8a2 2 0 002-2V7.414A2 2 0 0015.414 6L12 2.586A2 2 0 0010.586 2H6zm2 10a1 1 0 10-2 0v3a1 1 0 102 0v-3zm2-3a1 1 0 011 1v5a1 1 0 11-2 0v-5a1 1 0 011-1zm4-1a1 1 0 10-2 0v7a1 1 0 102 0V8z" clip-rule="evenodd"/></svg>',
    title: 'Multi-Page Documents',
    description: 'Automatically process multi-page PDFs and photo sets with pagination and page navigation controls.',
    color: '#0ea5e9'
  },
  {
    icon: '<svg width="32" height="32" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M3 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clip-rule="evenodd"/></svg>',
    title: 'Drag & Drop',
    description: 'Reorder form fields easily with drag-and-drop functionality for the perfect form flow.',
    color: '#8b5cf6'
  },
  {
    icon: '<svg width="32" height="32" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M4 2a2 2 0 00-2 2v11a3 3 0 106 0V4a2 2 0 00-2-2H4zm1 14a1 1 0 100-2 1 1 0 000 2zm5-1.757l4.9-4.9a2 2 0 000-2.828L13.485 5.1a2 2 0 00-2.828 0L10 5.757v8.486zM16 18H9.071l6-6H16a2 2 0 012 2v2a2 2 0 01-2 2z" clip-rule="evenodd"/></svg>',
    title: 'Customizable Themes',
    description: 'Choose from professionally designed themes or customize to match your brand perfectly.',
    color: '#6366f1'
  },
  {
    icon: '<svg width="32" height="32" fill="currentColor" viewBox="0 0 20 20"><path d="M10 12a2 2 0 100-4 2 2 0 000 4z"/><path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd"/></svg>',
    title: 'Live Preview',
    description: 'See your changes instantly with real-time preview in both edit and preview modes.',
    color: '#3b82f6'
  },
  {
    icon: '<svg width="32" height="32" fill="currentColor" viewBox="0 0 20 20"><path d="M15 8a3 3 0 10-2.977-2.63l-4.94 2.47a3 3 0 100 4.319l4.94 2.47a3 3 0 10.895-1.789l-4.94-2.47a3.027 3.027 0 000-.74l4.94-2.47C13.456 7.68 14.19 8 15 8z"/></svg>',
    title: 'Share & Collaborate',
    description: 'Share forms with colleagues via email with expiration dates and access control. Track who viewed and submitted.',
    color: '#0ea5e9'
  },
  {
    icon: '<svg width="32" height="32" fill="currentColor" viewBox="0 0 20 20"><path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z"/></svg>',
    title: 'Analytics & Insights',
    description: 'Track form submissions, view response analytics, and monitor share performance with detailed statistics.',
    color: '#8b5cf6'
  },
  {
    icon: '<svg width="32" height="32" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M2 5a2 2 0 012-2h12a2 2 0 012 2v2a2 2 0 01-2 2H4a2 2 0 01-2-2V5zm14 1a1 1 0 11-2 0 1 1 0 012 0zM2 13a2 2 0 012-2h12a2 2 0 012 2v2a2 2 0 01-2 2H4a2 2 0 01-2-2v-2zm14 1a1 1 0 11-2 0 1 1 0 012 0z" clip-rule="evenodd"/></svg>',
    title: 'Export Ready',
    description: 'Export your forms as embeddable HTML with one click. Copy the preview code directly or download as a complete HTML file for instant deployment.',
    color: '#3b82f6'
  }
]

const steps = [
  {
    title: 'Upload PDF or Photo',
    description: 'Drag and drop your PDF or photo of a paper form. Supports scanned documents, smartphone photos, and handwritten forms.'
  },
  {
    title: 'AI Processing',
    description: 'Our AI automatically detects form fields, labels, and structure from PDFs and photos in seconds. Get instant analysis.'
  },
  {
    title: 'Customize & Share',
    description: 'Edit fields, choose a theme, and share your form. Set access controls and track who views your forms.'
  },
  {
    title: 'Analyze & Export',
    description: 'View detailed statistics and analytics for form submissions. Export as HTML or copy the embed code for instant deployment.'
  }
]

const scrollToFeatures = () => {
  document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' })
}
</script>

<style scoped>
.landing-page {
  min-height: 100vh;
  background: #ffffff;
  overflow-x: hidden;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
}

/* Navigation Header */
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

/* Hero Section */
.hero {
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  overflow: hidden;
}

.hero-background {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
  z-index: 0;
  overflow: hidden;
}

.parallax-image {
  position: absolute;
  inset: 0;
  background-image: url('/images/hero-bg.png');
  background-size: cover;
  background-position: center;
  background-attachment: fixed;
  opacity: 0.5;
  will-change: transform;
}

.gradient-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(30, 58, 138, 0.5) 0%, rgba(59, 130, 246, 0.5) 100%);
  z-index: 1;
}

.gradient-orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(100px);
  opacity: 0.3;
  animation: float 20s infinite ease-in-out;
  z-index: 2;
}

.orb-1 {
  width: 500px;
  height: 500px;
  background: rgba(96, 165, 250, 0.3);
  top: -10%;
  left: -10%;
}

.orb-2 {
  width: 400px;
  height: 400px;
  background: rgba(147, 197, 253, 0.3);
  bottom: -10%;
  right: -10%;
  animation-delay: -10s;
}

.orb-3 {
  width: 450px;
  height: 450px;
  background: rgba(191, 219, 254, 0.3);
  top: 50%;
  left: 50%;
  animation-delay: -5s;
}

@keyframes float {
  0%, 100% { transform: translate(0, 0); }
  25% { transform: translate(30px, -30px); }
  50% { transform: translate(-20px, 20px); }
  75% { transform: translate(20px, 10px); }
}

.hero-content {
  position: relative;
  z-index: 10;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 60px;
  align-items: center;
  padding: 120px 24px;
}

.hero-title {
  font-size: 56px;
  font-weight: 800;
  line-height: 1.1;
  color: #ffffff;
  margin: 0 0 24px 0;
}

.gradient-text {
  display: block;
  color: #ffffff;
}

.hero-subtitle {
  font-size: 20px;
  line-height: 1.6;
  color: rgba(255, 255, 255, 0.9);
  margin: 0 0 40px 0;
}

.hero-buttons {
  display: flex;
  flex-wrap: nowrap;
  gap: 16px;
  margin-bottom: 60px;
  width: 100%;
  max-width: 900px;
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 24px;
  border-radius: 12px;
  font-weight: 600;
  font-size: 16px;
  border: none;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.btn-large {
  padding: 16px 32px;
  font-size: 18px;
  flex: 1;
  min-width: 0;
  white-space: nowrap;
}

.btn-primary {
  background: #ffffff;
  color: #1e40af;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.btn-secondary {
  background: rgba(255, 255, 255, 0.2);
  color: #ffffff;
  backdrop-filter: blur(10px);
  border: 2px solid rgba(255, 255, 255, 0.3);
}

.btn-secondary:hover {
  background: rgba(255, 255, 255, 0.3);
  border-color: rgba(255, 255, 255, 0.5);
}

.btn-tertiary {
  background: transparent;
  color: rgba(255, 255, 255, 0.9);
  border: 2px solid rgba(255, 255, 255, 0.2);
}

.btn-tertiary:hover {
  background: rgba(255, 255, 255, 0.1);
  border-color: rgba(255, 255, 255, 0.4);
}

.btn-secondary-outline {
  background: transparent;
  color: #ffffff;
  border: 2px solid rgba(255, 255, 255, 0.8);
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-secondary-outline:hover {
  background: rgba(255, 255, 255, 0.15);
  color: #ffffff;
  border-color: #ffffff;
}

.hero-stats {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 32px;
}

.stat {
  text-align: left;
}

.stat-value {
  font-size: 36px;
  font-weight: 800;
  color: #ffffff;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
}

.hero-visual {
  display: flex;
  justify-content: center;
  align-items: center;
}

.visual-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  width: 100%;
  max-width: 400px;
}

.visual-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e5e7eb;
}

.visual-dots {
  display: flex;
  gap: 6px;
}

.visual-dots span {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #d1d5db;
}

.visual-title {
  font-weight: 600;
  color: #1f2937;
}

.visual-body {
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding: 20px 0;
}

.pdf-icon {
  color: #ef4444;
}

.arrow-icon {
  color: #667eea;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.8; transform: scale(1.1); }
}

.form-preview {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100px;
}

.form-field {
  height: 12px;
  background: #e5e7eb;
  border-radius: 4px;
}

.form-field.short {
  width: 60%;
}

/* Sections */
section {
  padding: 100px 0;
}

.section-header {
  text-align: center;
  margin-bottom: 60px;
}

.section-title {
  font-size: 48px;
  font-weight: 800;
  color: #1f2937;
  margin: 0 0 16px 0;
}

.section-subtitle {
  font-size: 20px;
  color: #6b7280;
  margin: 0;
}

/* Features */
.features {
  background: #f9fafb;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 32px;
}

.feature-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 32px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  transition: all 0.3s;
}

.feature-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.15);
}

.feature-icon {
  width: 64px;
  height: 64px;
  border-radius: 12px;
  opacity: 0.95;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
  color: #ffffff;
}

.feature-title {
  font-size: 20px;
  font-weight: 700;
  color: #1f2937;
  margin: 0 0 12px 0;
}

.feature-description {
  font-size: 16px;
  line-height: 1.6;
  color: #6b7280;
  margin: 0;
}

/* How It Works */
.steps {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 32px;
  max-width: 1200px;
  margin: 0 auto;
}

.step {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.step-number {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #ffffff;
  font-size: 32px;
  font-weight: 800;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 24px;
  box-shadow: 0 8px 24px rgba(102, 126, 234, 0.4);
}

.step-title {
  font-size: 24px;
  font-weight: 700;
  color: #1f2937;
  margin: 0 0 12px 0;
}

.step-description {
  font-size: 16px;
  line-height: 1.6;
  color: #6b7280;
  margin: 0;
}

/* Share & Analytics Section */
.share-analytics-section {
  background: linear-gradient(180deg, #f9fafb 0%, #ffffff 100%);
  padding: 100px 0;
}

.share-features {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 48px;
  margin-top: 60px;
}

.share-feature {
  text-align: center;
  padding: 32px;
}

.share-icon {
  width: 80px;
  height: 80px;
  margin: 0 auto 24px;
  background: linear-gradient(135deg, #3b82f6 0%, #1e40af 100%);
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.share-feature h3 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin-bottom: 16px;
}

.share-feature p {
  font-size: 16px;
  line-height: 1.6;
  color: #6b7280;
}

.code-export-feature {
  margin-top: 80px;
  padding: 48px;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border-radius: 16px;
  border: 1px solid #e2e8f0;
}

.code-export-content h3 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin-bottom: 16px;
  text-align: center;
}

.code-export-content > p {
  font-size: 16px;
  line-height: 1.6;
  color: #6b7280;
  text-align: center;
  margin-bottom: 32px;
  max-width: 700px;
  margin-left: auto;
  margin-right: auto;
}

.code-preview {
  background: #1e293b;
  border-radius: 12px;
  overflow: hidden;
  max-width: 600px;
  margin: 0 auto;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
}

.code-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  background: #0f172a;
  border-bottom: 1px solid #334155;
}

.code-header span {
  font-size: 14px;
  color: #94a3b8;
  font-family: 'Monaco', 'Menlo', monospace;
}

.copy-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.copy-btn:hover {
  background: #2563eb;
  transform: translateY(-1px);
}

.code-body {
  padding: 20px;
  overflow-x: auto;
}

.code-body code {
  font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
  font-size: 14px;
  line-height: 1.8;
  color: #e2e8f0;
  display: block;
  white-space: pre;
}

.themes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 24px;
}

.theme-card {
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  transition: all 0.3s;
}

.theme-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.2);
}

.theme-preview {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 12px;
}

.theme-form {
  border: 2px solid;
  border-radius: 8px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.theme-field {
  height: 12px;
  border-radius: 4px;
}

.theme-button {
  height: 16px;
  border-radius: 6px;
  margin-top: 4px;
}

.theme-name {
  text-align: center;
  font-weight: 700;
  color: #ffffff;
  font-size: 16px;
}

/* Feature Details */
.detail-item {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 60px;
  align-items: center;
  margin-bottom: 100px;
}

.detail-item.reverse {
  direction: rtl;
}

.detail-item.reverse > * {
  direction: ltr;
}

.detail-item:last-child {
  margin-bottom: 0;
}

.detail-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 32px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.1);
}

.editor-mockup {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  min-height: 200px;
}

.editor-sidebar {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.editor-section {
  height: 40px;
  background: #f3f4f6;
  border-radius: 8px;
}

.editor-section.short {
  height: 24px;
}

.editor-preview {
  background: #f9fafb;
  border-radius: 8px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.preview-field {
  height: 32px;
  background: #e5e7eb;
  border-radius: 6px;
}

.pagination-mockup {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.page-indicator {
  text-align: center;
  font-weight: 600;
  color: #667eea;
  padding: 8px;
  background: #f3f4f6;
  border-radius: 8px;
}

.page-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px;
  background: #f9fafb;
  border-radius: 8px;
}

.page-field {
  height: 32px;
  background: #e5e7eb;
  border-radius: 6px;
}

.page-buttons {
  display: flex;
  gap: 12px;
  justify-content: center;
}

.page-btn {
  width: 80px;
  height: 36px;
  background: #667eea;
  border-radius: 8px;
}

.drag-drop-mockup {
  padding: 16px;
  background: #f9fafb;
  border-radius: 8px;
}

.field-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.draggable-field {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: #ffffff;
  border-radius: 8px;
  border: 2px solid #e5e7eb;
  cursor: move;
  transition: all 0.2s;
}

.draggable-field:hover {
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
}

.drag-handle {
  color: #9ca3af;
  font-size: 18px;
  font-weight: 700;
}

.field-content {
  flex: 1;
  font-weight: 600;
  color: #1f2937;
}

.detail-title {
  font-size: 36px;
  font-weight: 800;
  color: #1f2937;
  margin: 0 0 20px 0;
}

.detail-description {
  font-size: 18px;
  line-height: 1.6;
  color: #6b7280;
  margin: 0 0 24px 0;
}

.detail-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.detail-list li {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 16px;
  color: #4b5563;
}

.detail-list svg {
  color: #10b981;
  flex-shrink: 0;
}

/* CTA */
.cta {
  background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
  position: relative;
  overflow: hidden;
}

.cta::before {
  content: '';
  position: absolute;
  inset: 0;
  background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.05'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
  opacity: 0.4;
}

.cta-content {
  position: relative;
  text-align: center;
  padding: 60px 24px;
}

.cta-title {
  font-size: 48px;
  font-weight: 800;
  color: #ffffff;
  margin: 0 0 16px 0;
}

.cta-subtitle {
  font-size: 20px;
  color: rgba(255, 255, 255, 0.9);
  margin: 0 0 40px 0;
}

.cta-buttons {
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: center;
  max-width: 500px;
  margin: 0 auto;
}

/* Footer */
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

/* Responsive */
@media (max-width: 968px) {
  .container {
    padding: 0 20px;
  }

  /* Navigation */
  .nav-links {
    gap: 12px;
  }

  .nav-link:first-child {
    display: none;
  }

  .brand-name {
    font-size: 16px;
  }

  .btn-nav-primary {
    padding: 8px 16px;
    font-size: 13px;
  }

  /* Hero Section */
  .hero {
    min-height: auto;
    padding: 80px 0 60px;
  }

  .hero-content {
    grid-template-columns: 1fr;
    gap: 40px;
    padding: 40px 24px;
  }

  .hero-title {
    font-size: 36px;
  }

  .hero-subtitle {
    font-size: 18px;
  }

  .hero-buttons {
    flex-direction: column;
    max-width: 100%;
  }

  .btn-large {
    width: 100%;
    justify-content: center;
  }

  .hero-stats {
    grid-template-columns: 1fr 1fr;
    gap: 24px;
  }

  .hero-visual {
    display: none;
  }

  /* Sections */
  section {
    padding: 60px 0;
  }

  .section-title {
    font-size: 32px;
  }

  .section-subtitle {
    font-size: 18px;
  }

  /* Features */
  .features-grid {
    grid-template-columns: 1fr;
    gap: 24px;
  }

  /* Steps */
  .steps {
    grid-template-columns: 1fr;
    gap: 40px;
  }

  .step-number {
    width: 60px;
    height: 60px;
    font-size: 24px;
  }

  .step-title {
    font-size: 20px;
  }

  .step-description {
    font-size: 15px;
  }

  /* Share & Analytics */
  .share-features {
    grid-template-columns: 1fr;
    gap: 32px;
  }

  .code-export-feature {
    padding: 32px 24px;
  }

  /* Detail Items */
  .detail-item,
  .detail-item.reverse {
    grid-template-columns: 1fr;
    direction: ltr;
    gap: 40px;
    margin-bottom: 60px;
  }

  .detail-title {
    font-size: 28px;
  }

  .detail-description {
    font-size: 16px;
  }

  /* CTA */
  .cta-title {
    font-size: 36px;
  }

  .cta-subtitle {
    font-size: 18px;
  }

  /* Footer */
  .footer-content {
    flex-direction: column;
    gap: 24px;
    text-align: center;
  }
}

@media (max-width: 640px) {
  /* Extra small screens */
  .nav-header {
    padding: 12px 0;
  }

  .brand-name {
    display: none;
  }

  .nav-link {
    font-size: 14px;
  }

  .hero-title {
    font-size: 28px;
  }

  .hero-subtitle {
    font-size: 16px;
  }

  .hero-stats {
    grid-template-columns: 1fr;
  }

  .section-title {
    font-size: 28px;
  }

  .section-subtitle {
    font-size: 16px;
  }

  .feature-card {
    padding: 24px;
  }

  .cta-title {
    font-size: 28px;
  }

  .cta-subtitle {
    font-size: 16px;
  }

  .cta-buttons {
    width: 100%;
  }

  .btn-secondary-outline {
    width: 100%;
  }
}
</style>
