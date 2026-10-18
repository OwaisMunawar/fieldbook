import AppKit
guard CommandLine.arguments.count == 2 else {
  fputs("Usage: swift tool/render_fixture.swift <output.png>\n", stderr)
  exit(1)
}
let size = NSSize(width: 1400, height: 1700)
let image = NSImage(size: size)
image.lockFocus()
NSColor(calibratedRed: 0.96, green: 0.95, blue: 0.91, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()
func text(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ bold: Bool = false) {
 let font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
 (value as NSString).draw(at: NSPoint(x:x,y:y),withAttributes:[.font:font,.foregroundColor:NSColor(calibratedRed:0.13,green:0.19,blue:0.19,alpha:1)])
}
text("FIELD OBSERVATION",100,1490,68,true)
text("NORTH WING / LEVEL 02",100,1380,38)
text("Inspection card 014",100,1300,34)
NSColor(calibratedRed:0.74,green:0.31,blue:0.17,alpha:1).setFill()
NSRect(x:100,y:1220,width:1200,height:8).fill()
text("01  NORTH STAIR",100,1080,40,true)
text("Handrail loose at north stair.",100,1000,42)
text("Check fixings before handover.",100,930,42)
text("02  EAST CORRIDOR",100,760,40,true)
text("Ceiling panel stained near door E2.",100,680,42)
text("Record moisture reading on revisit.",100,610,42)
text("03  SERVICE ROOM",100,440,40,true)
text("Access label is missing.",100,360,42)
text("Replace label and photograph result.",100,290,42)
text("SYNTHETIC TEST CARD / NOT A REAL SITE",100,110,27)
image.unlockFocus()
let data = NSBitmapImageRep(data:image.tiffRepresentation!)!.representation(using:.png,properties:[:])!
try data.write(to: URL(fileURLWithPath:CommandLine.arguments[1]))
