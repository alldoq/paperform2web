import { Socket } from 'phoenix'

class WebSocketService {
  constructor() {
    this.socket = null
    this.channels = new Map()
    this.connected = false
  }

  connect() {
    if (this.socket && this.connected) {
      return Promise.resolve()
    }

    return new Promise((resolve, reject) => {
      // Create socket connection
      this.socket = new Socket('/socket', {
        params: {},
        reconnectAfterMs: (tries) => [1000, 5000, 10000][tries - 1] || 10000
      })

      this.socket.onOpen(() => {
        console.log('WebSocket connected')
        this.connected = true
        resolve()
      })

      this.socket.onError((error) => {
        console.error('WebSocket connection error:', error)
        this.connected = false
        reject(error)
      })

      this.socket.onClose(() => {
        console.log('WebSocket disconnected')
        this.connected = false
      })

      // Connect to the socket
      this.socket.connect()
    })
  }

  disconnect() {
    if (this.socket) {
      this.socket.disconnect()
      this.channels.clear()
      this.connected = false
    }
  }

  subscribeToDocument(documentId, callbacks = {}) {
    if (!this.socket || !this.connected) {
      console.error('WebSocket not connected')
      return null
    }

    const channelTopic = `document:${documentId}`

    // Check if we're already subscribed to this document
    if (this.channels.has(channelTopic)) {
      return this.channels.get(channelTopic)
    }

    const channel = this.socket.channel(channelTopic, {})

    // Handle successful join
    channel.join()
      .receive('ok', (response) => {
        console.log(`Joined document channel: ${documentId}`, response)
        if (callbacks.onJoin) {
          callbacks.onJoin(response)
        }
      })
      .receive('error', (response) => {
        console.error(`Failed to join document channel: ${documentId}`, response)
        if (callbacks.onError) {
          callbacks.onError(response)
        }
      })

    // Listen for document updates
    channel.on('document_updated', (payload) => {
      console.log('Document updated:', payload)
      if (callbacks.onDocumentUpdate) {
        callbacks.onDocumentUpdate(payload)
      }
    })

    // Listen for status updates
    channel.on('status_updated', (payload) => {
      console.log('Document status updated:', payload)
      if (callbacks.onStatusUpdate) {
        callbacks.onStatusUpdate(payload)
      }
    })

    // Handle channel errors
    channel.onError((error) => {
      console.error(`Channel error for document ${documentId}:`, error)
      if (callbacks.onError) {
        callbacks.onError(error)
      }
    })

    // Handle channel close
    channel.onClose(() => {
      console.log(`Channel closed for document ${documentId}`)
      this.channels.delete(channelTopic)
      if (callbacks.onClose) {
        callbacks.onClose()
      }
    })

    this.channels.set(channelTopic, channel)
    return channel
  }

  unsubscribeFromDocument(documentId) {
    const channelTopic = `document:${documentId}`
    const channel = this.channels.get(channelTopic)

    if (channel) {
      channel.leave()
      this.channels.delete(channelTopic)
      console.log(`Unsubscribed from document: ${documentId}`)
    }
  }

  // Send a message to a document channel
  sendMessage(documentId, event, payload = {}) {
    const channelTopic = `document:${documentId}`
    const channel = this.channels.get(channelTopic)

    if (channel) {
      return new Promise((resolve, reject) => {
        channel.push(event, payload)
          .receive('ok', resolve)
          .receive('error', reject)
      })
    } else {
      return Promise.reject(new Error(`Not subscribed to document: ${documentId}`))
    }
  }

  // Get document status via WebSocket
  getDocumentStatus(documentId) {
    return this.sendMessage(documentId, 'get_status')
  }

  // Ping the channel to test connection
  ping(documentId) {
    return this.sendMessage(documentId, 'ping', { message: 'Hello from client' })
  }
}

// Create singleton instance
const webSocketService = new WebSocketService()

export default webSocketService