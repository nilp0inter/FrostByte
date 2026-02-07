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
// When rotate=true: SVG is rendered with swapped dimensions (landscape display),
// then rotated 90° clockwise for the printer-expected portrait orientation.
// When rotate=false: SVG is rendered directly at width×height with no rotation.
app.ports.requestSvgToPng.subscribe(async ({ svgId, requestId, width, height, rotate }) => {
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
      let dataUrl

      if (rotate) {
        // Display dimensions (swapped for landscape)
        const displayWidth = height
        const displayHeight = width

        // Create canvas at display dimensions (landscape)
        const canvas = document.createElement('canvas')
        canvas.width = displayWidth
        canvas.height = displayHeight
        const ctx = canvas.getContext('2d')

        // White background
        ctx.fillStyle = 'white'
        ctx.fillRect(0, 0, displayWidth, displayHeight)

        // Draw SVG image in landscape
        ctx.drawImage(img, 0, 0, displayWidth, displayHeight)

        // Rotate 90° clockwise for print output (back to width×height)
        const rotatedCanvas = document.createElement('canvas')
        rotatedCanvas.width = width
        rotatedCanvas.height = height
        const rotatedCtx = rotatedCanvas.getContext('2d')

        // White background on rotated canvas
        rotatedCtx.fillStyle = 'white'
        rotatedCtx.fillRect(0, 0, width, height)

        // Rotate 90° clockwise: translate to right edge, then rotate
        rotatedCtx.translate(width, 0)
        rotatedCtx.rotate(Math.PI / 2)
        rotatedCtx.drawImage(canvas, 0, 0)

        dataUrl = rotatedCanvas.toDataURL('image/png')
      } else {
        // No rotation: render directly at width×height
        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = height
        const ctx = canvas.getContext('2d')

        // White background
        ctx.fillStyle = 'white'
        ctx.fillRect(0, 0, width, height)

        // Draw SVG image
        ctx.drawImage(img, 0, 0, width, height)

        dataUrl = canvas.toDataURL('image/png')
      }

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

// Text measurement port for dynamic font sizing and word wrapping
app.ports.requestTextMeasure.subscribe(({
  requestId,
  titleText,
  ingredientsText,
  fontFamily,
  titleFontSize,
  titleMinFontSize,
  smallFontSize,
  maxWidth,
  ingredientsMaxChars
}) => {
  const canvas = document.createElement('canvas')
  const ctx = canvas.getContext('2d')

  // Helper function to word-wrap text
  const wrapText = (text, font) => {
    ctx.font = font
    const words = text.split(' ')
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

  // Find fitted font size for title, then wrap if still needed
  let fittedSize = titleFontSize
  ctx.font = `bold ${fittedSize}px ${fontFamily}`

  // First, shrink font until it fits or reaches min size
  while (ctx.measureText(titleText).width > maxWidth && fittedSize > titleMinFontSize) {
    fittedSize--
    ctx.font = `bold ${fittedSize}px ${fontFamily}`
  }

  // If at min size and still doesn't fit, wrap to multiple lines
  let titleLines = [titleText]
  if (ctx.measureText(titleText).width > maxWidth) {
    titleLines = wrapText(titleText, `bold ${fittedSize}px ${fontFamily}`)
  }

  // Word-wrap ingredients text
  const truncatedIngredients = ingredientsText.length > ingredientsMaxChars
    ? ingredientsText.slice(0, ingredientsMaxChars - 3) + '...'
    : ingredientsText

  const ingredientLines = wrapText(truncatedIngredients, `${smallFontSize}px ${fontFamily}`)

  app.ports.receiveTextMeasureResult.send({
    requestId,
    titleFittedFontSize: fittedSize,
    titleLines,
    ingredientLines
  })
})

// Register service worker for PWA (optional)
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    // Service worker registration can be added here for offline support
  })
}
