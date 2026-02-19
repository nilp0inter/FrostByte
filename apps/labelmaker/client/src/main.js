import './main.css'
import { Elm } from './Main.elm'

// Initialize Elm application
const app = Elm.Main.init({
  node: document.getElementById('app'),
  flags: {
    currentDate: new Date().toISOString().split('T')[0]
  }
})

// Text measurement port for dynamic font sizing and word wrapping
app.ports.requestTextMeasure.subscribe(({
  requestId,
  text,
  fontFamily,
  maxFontSize,
  minFontSize,
  maxWidth
}) => {
  const canvas = document.createElement('canvas')
  const ctx = canvas.getContext('2d')

  // Helper function to word-wrap text
  const wrapText = (str, font) => {
    ctx.font = font
    const words = str.split(' ')
    const lines = []
    let currentLine = ''

    for (const word of words) {
      const testLine = currentLine ? currentLine + ' ' + word : word
      if (ctx.measureText(testLine).width <= maxWidth) {
        currentLine = testLine
      } else {
        if (currentLine) lines.push(currentLine)
        currentLine = word
      }
    }
    if (currentLine) lines.push(currentLine)
    return lines
  }

  // Find fitted font size, then wrap if still needed
  let fittedSize = maxFontSize
  ctx.font = `bold ${fittedSize}px ${fontFamily}`

  // Shrink font until it fits or reaches min size
  while (ctx.measureText(text).width > maxWidth && fittedSize > minFontSize) {
    fittedSize--
    ctx.font = `bold ${fittedSize}px ${fontFamily}`
  }

  // If at min size and still doesn't fit, wrap to multiple lines
  let lines = [text]
  if (ctx.measureText(text).width > maxWidth) {
    lines = wrapText(text, `bold ${fittedSize}px ${fontFamily}`)
  }

  app.ports.receiveTextMeasureResult.send({
    requestId,
    fittedFontSize: fittedSize,
    lines
  })
})

// Register service worker for PWA (optional)
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    // Service worker registration can be added here for offline support
  })
}
