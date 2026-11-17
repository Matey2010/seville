import CoreGraphics
import Foundation

private struct Arguments {
  let source: URL
  let output: URL
  let padding: CGFloat

  init?(_ values: [String]) {
    guard
      let sourceIndex = values.firstIndex(of: "--source"),
      values.indices.contains(sourceIndex + 1),
      let outputIndex = values.firstIndex(of: "--output"),
      values.indices.contains(outputIndex + 1)
    else {
      return nil
    }
    source = URL(fileURLWithPath: values[sourceIndex + 1])
    output = URL(fileURLWithPath: values[outputIndex + 1])

    if
      let paddingIndex = values.firstIndex(of: "--padding"),
      values.indices.contains(paddingIndex + 1),
      let parsedPadding = Double(values[paddingIndex + 1]),
      parsedPadding >= 0,
      parsedPadding < 0.5
    {
      padding = CGFloat(parsedPadding)
    } else {
      padding = 0.08
    }
  }
}

guard let arguments = Arguments(Array(CommandLine.arguments.dropFirst())) else {
  FileHandle.standardError.write(
    Data(
      "Usage: swift tool/center_pdf_icon.swift --source INPUT.pdf --output OUTPUT.pdf [--padding 0.08]\n".utf8
    )
  )
  exit(64)
}

guard
  let document = CGPDFDocument(arguments.source as CFURL),
  let page = document.page(at: 1)
else {
  FileHandle.standardError.write(Data("Could not read the first PDF page.\n".utf8))
  exit(65)
}

let pageBounds = page.getBoxRect(.mediaBox)
let sampleExtent = 2048
let bytesPerPixel = 4
let bytesPerRow = sampleExtent * bytesPerPixel
let byteCount = bytesPerRow * sampleExtent
let pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
pixels.initialize(repeating: 255, count: byteCount)
defer { pixels.deallocate() }

guard
  let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
  let sampleContext = CGContext(
    data: pixels,
    width: sampleExtent,
    height: sampleExtent,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  )
else {
  FileHandle.standardError.write(Data("Could not allocate the PDF analysis canvas.\n".utf8))
  exit(70)
}

sampleContext.setFillColor(CGColor(gray: 1, alpha: 1))
sampleContext.fill(CGRect(x: 0, y: 0, width: sampleExtent, height: sampleExtent))
let sampleBounds = CGRect(x: 0, y: 0, width: sampleExtent, height: sampleExtent)
let pageTransform = page.getDrawingTransform(
  .mediaBox,
  rect: sampleBounds,
  rotate: 0,
  preserveAspectRatio: true
)
sampleContext.concatenate(pageTransform)
sampleContext.drawPDFPage(page)

var minX = sampleExtent
var minY = sampleExtent
var maxX = -1
var maxY = -1
for y in 0..<sampleExtent {
  for x in 0..<sampleExtent {
    let offset = y * bytesPerRow + x * bytesPerPixel
    let red = pixels[offset]
    let green = pixels[offset + 1]
    let blue = pixels[offset + 2]
    if red < 245 || green < 245 || blue < 245 {
      minX = min(minX, x)
      minY = min(minY, y)
      maxX = max(maxX, x)
      maxY = max(maxY, y)
    }
  }
}

guard maxX >= minX, maxY >= minY else {
  FileHandle.standardError.write(Data("The PDF page contains no visible non-white artwork.\n".utf8))
  exit(65)
}

let inverseTransform = pageTransform.inverted()
let sampledArtwork = CGRect(
  x: minX,
  y: minY,
  width: maxX - minX + 1,
  height: maxY - minY + 1
)
let pageCornerA = CGPoint(x: sampledArtwork.minX, y: sampledArtwork.minY)
  .applying(inverseTransform)
let pageCornerB = CGPoint(x: sampledArtwork.maxX, y: sampledArtwork.maxY)
  .applying(inverseTransform)
let artworkBounds = CGRect(
  x: min(pageCornerA.x, pageCornerB.x),
  y: min(pageCornerA.y, pageCornerB.y),
  width: abs(pageCornerB.x - pageCornerA.x),
  height: abs(pageCornerB.y - pageCornerA.y)
)
let artworkExtent = max(artworkBounds.width, artworkBounds.height)
let outputExtent = artworkExtent * (1 + 2 * arguments.padding)
let artworkCenter = CGPoint(x: artworkBounds.midX, y: artworkBounds.midY)
let cropBounds = CGRect(
  x: artworkCenter.x - outputExtent / 2,
  y: artworkCenter.y - outputExtent / 2,
  width: outputExtent,
  height: outputExtent
)

do {
  try FileManager.default.createDirectory(
    at: arguments.output.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
} catch {
  FileHandle.standardError.write(Data("Could not create the output directory: \(error)\n".utf8))
  exit(73)
}

var outputBounds = CGRect(x: 0, y: 0, width: outputExtent, height: outputExtent)
guard
  let consumer = CGDataConsumer(url: arguments.output as CFURL),
  let outputContext = CGContext(consumer: consumer, mediaBox: &outputBounds, nil)
else {
  FileHandle.standardError.write(Data("Could not create the output PDF.\n".utf8))
  exit(73)
}

outputContext.beginPDFPage(nil)
outputContext.saveGState()
outputContext.translateBy(x: -cropBounds.minX, y: -cropBounds.minY)
outputContext.drawPDFPage(page)
outputContext.restoreGState()
outputContext.endPDFPage()
outputContext.closePDF()

print(
  "Centered first-page artwork in a \(Int(outputExtent.rounded()))x\(Int(outputExtent.rounded())) pt PDF with \(Int((arguments.padding * 100).rounded()))% padding."
)
