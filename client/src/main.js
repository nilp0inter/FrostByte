import './main.css'
import { Elm } from './Main.elm'

// Initialize Elm application
const app = Elm.Main.init({
  node: document.getElementById('app'),
  flags: {
    currentDate: new Date().toISOString().split('T')[0],
    appHost: window.location.host
  }
})

// SVG to PNG conversion port
app.ports.requestSvgToPng.subscribe(async ({ svgId, requestId, width, height }) => {
  try {
    // Wait for next frame to ensure SVG is rendered
    await new Promise(resolve => requestAnimationFrame(resolve))

    const svgElement = document.getElementById(svgId)
    if (!svgElement) {
      app.ports.receivePngResult.send({
        requestId,
        dataUrl: null,
        error: 'SVG element not found: ' + svgId
      })
      return
    }

    // Serialize SVG to string
    const serializer = new XMLSerializer()
    const svgString = serializer.serializeToString(svgElement)

    // Create blob and object URL
    const svgBlob = new Blob([svgString], { type: 'image/svg+xml;charset=utf-8' })
    const url = URL.createObjectURL(svgBlob)

    // Load SVG as image
    const img = new Image()
    img.onload = () => {
      // Create canvas and draw image
      const canvas = document.createElement('canvas')
      canvas.width = width
      canvas.height = height
      const ctx = canvas.getContext('2d')

      // White background
      ctx.fillStyle = 'white'
      ctx.fillRect(0, 0, width, height)

      // Draw SVG image
      ctx.drawImage(img, 0, 0, width, height)

      // Export as PNG data URL
      const dataUrl = canvas.toDataURL('image/png')
      URL.revokeObjectURL(url)

      app.ports.receivePngResult.send({
        requestId,
        dataUrl,
        error: null
      })
    }

    img.onerror = () => {
      URL.revokeObjectURL(url)
      app.ports.receivePngResult.send({
        requestId,
        dataUrl: null,
        error: 'Failed to load SVG as image'
      })
    }

    img.src = url
  } catch (e) {
    app.ports.receivePngResult.send({
      requestId,
      dataUrl: null,
      error: e.message
    })
  }
})

// Register service worker for PWA (optional)
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    // Service worker registration can be added here for offline support
  })
}
