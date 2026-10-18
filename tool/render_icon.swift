import AppKit

let root = URL(fileURLWithPath: "ios/Runner/Assets.xcassets/AppIcon.appiconset")
let contents = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("Contents.json"))) as! [String: Any]
for item in contents["images"] as! [[String: String]] {
  guard let filename = item["filename"], let nominal = item["size"], let scale = item["scale"],
        let edge = Double(nominal.components(separatedBy: "x")[0]),
        let multiplier = Double(scale.replacingOccurrences(of: "x", with: "")) else { continue }
  let pixels = Int(edge * multiplier)
  let context = CGContext(data:nil,width:pixels,height:pixels,bitsPerComponent:8,
    bytesPerRow:pixels*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext:context,flipped:false)
  context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
  NSColor(calibratedRed: 0.094, green: 0.239, blue: 0.231, alpha: 1).setFill()
  NSRect(x: 0,y: 0,width: 1024,height: 1024).fill()
  let mark = NSBezierPath()
  mark.move(to: NSPoint(x: 512,y: 790))
  mark.line(to: NSPoint(x: 235,y: 560))
  mark.line(to: NSPoint(x: 512,y: 330))
  mark.line(to: NSPoint(x: 789,y: 560))
  mark.close()
  mark.lineWidth = 55
  mark.lineJoinStyle = .round
  NSColor(calibratedRed: 0.96, green: 0.95, blue: 0.93, alpha: 1).setStroke()
  mark.stroke()
  let base = NSBezierPath()
  base.move(to: NSPoint(x: 235,y: 415))
  base.line(to: NSPoint(x: 512,y: 185))
  base.line(to: NSPoint(x: 789,y: 415))
  base.lineWidth = 55
  base.lineJoinStyle = .round
  base.lineCapStyle = .round
  NSColor(calibratedRed: 0.87, green: 0.39, blue: 0.23, alpha: 1).setStroke()
  base.stroke()
  NSGraphicsContext.restoreGraphicsState()
  let bitmap = NSBitmapImageRep(cgImage:context.makeImage()!)
  try bitmap.representation(using: .png,properties: [:])!.write(to: root.appendingPathComponent(filename))
}
