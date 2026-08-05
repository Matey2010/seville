import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private struct Arguments {
  let source: URL
  let output: URL

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
  }
}

private let iconSizes = [16, 32, 64, 128, 256, 512, 1024]

guard let arguments = Arguments(Array(CommandLine.arguments.dropFirst())) else {
  FileHandle.standardError.write(
    Data("Usage: swift tool/generate_macos_icons.swift --source PATH --output AppIcon.appiconset\n".utf8)
  )
  exit(64)
}

guard FileManager.default.fileExists(atPath: arguments.source.path) else {
  FileHandle.standardError.write(Data("Icon source does not exist: \(arguments.source.path)\n".utf8))
  exit(66)
}

func bitmapContext(width: Int, height: Int) -> CGContext? {
  guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
  return CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  )
}

func appKitSVGImage(from url: URL, maximumExtent: Int) -> CGImage? {
  guard
    url.pathExtension.lowercased() == "svg",
    let image = NSImage(contentsOf: url),
    image.size.width > 0,
    image.size.height > 0
  else {
    return nil
  }

  let scale = min(
    CGFloat(maximumExtent) / image.size.width,
    CGFloat(maximumExtent) / image.size.height
  )
  let width = max(1, Int((image.size.width * scale).rounded()))
  let height = max(1, Int((image.size.height * scale).rounded()))
  guard let context = bitmapContext(width: width, height: height) else {
    return nil
  }
  context.clear(CGRect(x: 0, y: 0, width: width, height: height))
  context.interpolationQuality = .high

  let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = graphicsContext
  image.draw(
    in: CGRect(x: 0, y: 0, width: width, height: height),
    from: .zero,
    operation: .copy,
    fraction: 1,
    respectFlipped: true,
    hints: [.interpolation: NSImageInterpolation.high]
  )
  NSGraphicsContext.restoreGraphicsState()
  return context.makeImage()
}

let imageIOSource = CGImageSourceCreateWithURL(arguments.source as CFURL, nil)
let imageIODecoded = imageIOSource.flatMap {
  CGImageSourceCreateThumbnailAtIndex(
    $0,
    0,
    [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: 1024,
    ] as CFDictionary
  )
}
guard
  let decodedImage = imageIODecoded
    ?? appKitSVGImage(from: arguments.source, maximumExtent: 1024)
else {
  FileHandle.standardError.write(
    Data(
      "Could not decode the icon source as a raster image, first-page PDF, or SVG: \(arguments.source.path)\n".utf8
    )
  )
  exit(65)
}

func squareImage(from image: CGImage, size: Int) -> CGImage? {
  guard let context = bitmapContext(width: size, height: size) else { return nil }
  context.clear(CGRect(x: 0, y: 0, width: size, height: size))
  context.interpolationQuality = .high

  let widthScale = CGFloat(size) / CGFloat(image.width)
  let heightScale = CGFloat(size) / CGFloat(image.height)
  let scale = min(widthScale, heightScale)
  let width = CGFloat(image.width) * scale
  let height = CGFloat(image.height) * scale
  let destination = CGRect(
    x: (CGFloat(size) - width) / 2,
    y: (CGFloat(size) - height) / 2,
    width: width,
    height: height
  )
  context.draw(image, in: destination)
  return context.makeImage()
}

func writePNG(_ image: CGImage, to url: URL) -> Bool {
  guard let destination = CGImageDestinationCreateWithURL(
    url as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
  ) else {
    return false
  }
  CGImageDestinationAddImage(destination, image, nil)
  return CGImageDestinationFinalize(destination)
}

do {
  try FileManager.default.createDirectory(
    at: arguments.output,
    withIntermediateDirectories: true
  )
} catch {
  FileHandle.standardError.write(Data("Could not create \(arguments.output.path): \(error)\n".utf8))
  exit(73)
}

guard let master = squareImage(from: decodedImage, size: 1024) else {
  FileHandle.standardError.write(Data("Could not allocate the 1024x1024 icon canvas.\n".utf8))
  exit(70)
}

for size in iconSizes {
  let image = size == 1024 ? master : squareImage(from: master, size: size)
  let output = arguments.output.appendingPathComponent("app_icon_\(size).png")
  guard let image, writePNG(image, to: output) else {
    FileHandle.standardError.write(Data("Could not write \(output.path)\n".utf8))
    exit(74)
  }
}

let contents = """
{
  "images" : [
    { "filename" : "app_icon_16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "app_icon_32.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "app_icon_32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "app_icon_64.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "app_icon_128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "app_icon_256.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "app_icon_256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "app_icon_512.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "app_icon_512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "app_icon_1024.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""

do {
  try Data("\(contents)\n".utf8).write(
    to: arguments.output.appendingPathComponent("Contents.json"),
    options: .atomic
  )
} catch {
  FileHandle.standardError.write(Data("Could not write Contents.json: \(error)\n".utf8))
  exit(74)
}

print("Generated macOS icon catalog: \(arguments.output.path)")
