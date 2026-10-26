// Renders one storyboard frame per playbook segment, plus STORYBOARD.md.
//
//   ruby -ryaml -rjson -e 'puts JSON.generate(YAML.load_file("playbook.yaml"))' > out/playbook.json
//   swiftc -O tools/storyboard.swift -o out/storyboard-bin && out/storyboard-bin .
//
// Run from demo/. Every overlay in a segment is drawn at once; the real render
// animates them in at their `t`. Fonts fall back to system fonts.
import AVFoundation
import AppKit
import CoreImage

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let outDir = root.appendingPathComponent("out/storyboard")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let pb = try! JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("out/playbook.json"))) as! [String: Any]

typealias J = [String: Any]
func d(_ v: Any?) -> Double { (v as? NSNumber)?.doubleValue ?? 0 }
func s(_ v: Any?) -> String { v as? String ?? "" }
func pt(_ v: Any?) -> CGPoint? { guard let a = v as? [Any], a.count == 2 else { return nil }; return CGPoint(x: d(a[0]), y: d(a[1])) }

func color(_ hex: String, _ alpha: CGFloat = 1) -> NSColor {
  var v: UInt64 = 0; Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&v)
  return NSColor(srgbRed: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: alpha)
}
let brand = pb["brand"] as! J
let ACCENT = color(s(brand["accent"])), TEXT = color(s(brand["text"])), MUTED = color(s(brand["muted"])), OK = color(s(brand["success"]))
let WARN = color("#FFC24B"), CARD = color("#141416", 0.92), LINE = color("#2A2A2E")
func sans(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
  NSFont(name: weight == .bold ? "SpaceGrotesk-Bold" : "SpaceGrotesk-Regular", size: size) ?? .systemFont(ofSize: size, weight: weight)
}
func mono(_ size: CGFloat) -> NSFont { NSFont(name: "JetBrainsMono-Regular", size: size) ?? NSFont(name: "Menlo", size: size)! }

let W = 1920.0, H = 1080.0
let wpm = d((pb["meta"] as! J)["words_per_minute"])
let sources = pb["sources"] as! J
let chapters = Dictionary(uniqueKeysWithValues: (pb["chapters"] as! [J]).map { (s($0["id"]), $0) })
let emilio = NSImage(contentsOf: root.appendingPathComponent(s((pb["narrator"] as! J)["image"])))?.cgImage(forProposedRect: nil, context: nil, hints: nil)

// MARK: frames

var generators: [String: AVAssetImageGenerator] = [:]
func frame(_ source: String, _ t: Double) -> CGImage {
  let g = generators[source] ?? {
    let g = AVAssetImageGenerator(asset: AVURLAsset(url: root.appendingPathComponent(s(sources[source]))))
    g.appliesPreferredTrackTransform = true
    g.requestedTimeToleranceBefore = .zero; g.requestedTimeToleranceAfter = .zero
    generators[source] = g; return g
  }()
  return try! g.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil)
}

/// Horizontal extent of the non-black content (the phones), as 0…1 of the frame width.
func contentSpan(_ img: CGImage) -> (Double, Double) {
  let w = 240, h = Int(Double(w) * Double(img.height) / Double(img.width))
  let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
  let p = ctx.data!.bindMemory(to: UInt8.self, capacity: w * h * 4)
  var lo = w, hi = 0
  for x in 0..<w {
    var lit = 0
    for y in stride(from: 0, to: h, by: 2) { let i = (y * w + x) * 4; if Int(p[i]) + Int(p[i + 1]) + Int(p[i + 2]) > 90 { lit += 1 } }
    if lit > h / 20 { lo = min(lo, x); hi = max(hi, x) }
  }
  return lo > hi ? (0.4, 0.6) : (Double(lo) / Double(w), Double(hi + 1) / Double(w))
}

let ci = CIContext()
func blurred(_ img: CGImage, rects: [CGRect]) -> CGImage {
  guard !rects.isEmpty else { return img }
  var out = CIImage(cgImage: img)
  let ext = out.extent
  for r in rects {
    // Playbook rects are top-left based; CoreImage is bottom-left.
    let rr = CGRect(x: r.minX * ext.width, y: (1 - r.maxY) * ext.height, width: r.width * ext.width, height: r.height * ext.height)
    let pix = out.cropped(to: rr).clampedToExtent()
      .applyingFilter("CIPixellate", parameters: ["inputScale": 28, "inputCenter": CIVector(x: rr.minX, y: rr.minY)])
      .applyingGaussianBlur(sigma: 14).cropped(to: rr)
    out = pix.composited(over: out)
  }
  return ci.createCGImage(out, from: ext)!
}

// MARK: drawing helpers (top-left origin)

var ctx: CGContext!
func newCanvas() {
  ctx = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.translateBy(x: 0, y: H); ctx.scaleBy(x: 1, y: -1)
  NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
  fill(CGRect(x: 0, y: 0, width: W, height: H), .black)
}
func fill(_ r: CGRect, _ c: NSColor, radius: CGFloat = 0) {
  ctx.setFillColor(c.cgColor); ctx.addPath(CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)); ctx.fillPath()
}
func stroke(_ r: CGRect, _ c: NSColor, radius: CGFloat = 0, width: CGFloat = 2) {
  ctx.setStrokeColor(c.cgColor); ctx.setLineWidth(width); ctx.addPath(CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)); ctx.strokePath()
}
func image(_ img: CGImage, _ r: CGRect) {
  ctx.saveGState(); ctx.translateBy(x: r.minX, y: r.maxY); ctx.scaleBy(x: 1, y: -1)
  ctx.draw(img, in: CGRect(x: 0, y: 0, width: r.width, height: r.height)); ctx.restoreGState()
}
func attrs(_ f: NSFont, _ c: NSColor, align: NSTextAlignment = .left) -> [NSAttributedString.Key: Any] {
  let p = NSMutableParagraphStyle(); p.alignment = align; p.lineBreakMode = .byWordWrapping
  return [.font: f, .foregroundColor: c, .paragraphStyle: p]
}
@discardableResult
func text(_ str: String, _ f: NSFont, _ c: NSColor, x: Double, y: Double, width: Double, align: NSTextAlignment = .left) -> Double {
  let a = NSAttributedString(string: str, attributes: attrs(f, c, align: align))
  let h = a.boundingRect(with: NSSize(width: width, height: 2000), options: [.usesLineFragmentOrigin]).height
  a.draw(with: NSRect(x: x, y: y, width: width, height: h + 2), options: [.usesLineFragmentOrigin])
  return ceil(h)
}
func textHeight(_ str: String, _ f: NSFont, _ width: Double) -> Double {
  ceil(NSAttributedString(string: str, attributes: attrs(f, TEXT)).boundingRect(with: NSSize(width: width, height: 2000), options: [.usesLineFragmentOrigin]).height)
}
func card(_ r: CGRect) {
  fill(r, CARD, radius: 18)
  fill(CGRect(x: r.minX, y: r.minY + 16, width: 5, height: r.height - 32), ACCENT, radius: 2.5)
}
func textWidth(_ str: String, _ f: NSFont) -> Double { NSAttributedString(string: str, attributes: [.font: f]).size().width }
func pill(_ str: String, _ f: NSFont, fg: NSColor, bg: NSColor, border: NSColor? = nil, x: Double, y: Double) -> CGRect {
  let w = textWidth(str, f) + 28, h = f.pointSize + 18
  let x = min(x, W - 24 - w)  // keep long chips on the stage
  let r = CGRect(x: x, y: y, width: w, height: h)
  fill(r, bg, radius: h / 2); if let b = border { stroke(r, b, radius: h / 2, width: 1.5) }
  text(str, f, fg, x: x + 14, y: y + 8, width: w)
  return r
}
func emilioBadge(x: Double, y: Double, size: Double) {
  guard let e = emilio else { return }
  ctx.saveGState()
  ctx.addEllipse(in: CGRect(x: x, y: y, width: size, height: size)); ctx.clip()
  fill(CGRect(x: x, y: y, width: size, height: size), color("#1A1A1C"))
  // Head crop: the top ~40% of the portrait.
  let iw = size * 2.1, ih = iw * Double(e.height) / Double(e.width)
  image(e, CGRect(x: x + size / 2 - iw / 2, y: y - size * 0.05, width: iw, height: ih))
  ctx.restoreGState()
  ctx.setStrokeColor(ACCENT.cgColor); ctx.setLineWidth(3); ctx.strokeEllipse(in: CGRect(x: x, y: y, width: size, height: size))
}

// MARK: overlays (side panel)

struct Panel { var x: Double; var y: Double; var w: Double }

func drawOverlay(_ o: J, _ panel: inout Panel, _ src: CGRect) {
  let px = panel.x, w = panel.w
  func srcPoint(_ p: CGPoint) -> CGPoint { CGPoint(x: src.minX + p.x * src.width, y: src.minY + p.y * src.height) }
  switch s(o["type"]) {
  case "chip":
    let r = pill(s(o["text"]), mono(17), fg: ACCENT, bg: color("#1A0D08"), border: ACCENT, x: px, y: panel.y)
    panel.y = r.maxY + 14
  case "badge":
    let st = s(o["style"])
    let c = st == "success" ? OK : st == "warn" ? WARN : MUTED
    let r = pill(s(o["text"]), sans(19, .bold), fg: c, bg: CARD, border: c.withAlphaComponent(0.6), x: px, y: panel.y)
    panel.y = r.maxY + 14
  case "callout", "counter":
    let isCounter = s(o["type"]) == "counter"
    let top = panel.y, inner = w - 44
    let h = isCounter
      ? 20 + textHeight(s(o["label"]).uppercased(), sans(15, .bold), inner) + 6 + 50 + 16
      : 20 + textHeight(s(o["title"]), sans(30, .bold), inner) + 6 + (o["body"] != nil ? textHeight(s(o["body"]), sans(20), inner) : 0) + 20
    let r = CGRect(x: px, y: top, width: w, height: h)
    card(r)
    var y = top + 20
    if isCounter {
      y += text(s(o["label"]).uppercased(), sans(15, .bold), MUTED, x: px + 22, y: y, width: inner) + 6
      let line = NSMutableAttributedString(string: s(o["from"]), attributes: attrs(sans(30), MUTED))
      line.append(NSAttributedString(string: "  →  ", attributes: attrs(sans(30), ACCENT)))
      line.append(NSAttributedString(string: s(o["to"]), attributes: attrs(sans(38, .bold), TEXT)))
      line.draw(at: NSPoint(x: px + 22, y: y))
    } else {
      y += text(s(o["title"]), sans(30, .bold), TEXT, x: px + 22, y: y, width: inner) + 6
      if o["body"] != nil { text(s(o["body"]), sans(20), MUTED, x: px + 22, y: y, width: inner) }
    }
    if let tp = pt(o["target"]) {
      let p = srcPoint(tp)
      let from = CGPoint(x: p.x < r.minX ? r.minX : r.maxX, y: r.midY)
      ctx.setStrokeColor(ACCENT.cgColor); ctx.setLineWidth(2.5); ctx.setLineDash(phase: 0, lengths: [8, 6])
      ctx.move(to: from); ctx.addLine(to: p); ctx.strokePath(); ctx.setLineDash(phase: 0, lengths: [])
      fill(CGRect(x: p.x - 9, y: p.y - 9, width: 18, height: 18), ACCENT, radius: 9)
      stroke(CGRect(x: p.x - 18, y: p.y - 18, width: 36, height: 36), ACCENT.withAlphaComponent(0.5), radius: 18, width: 3)
    }
    panel.y = r.maxY + 16
  case "race":
    let lanes = o["lanes"] as! [J]
    let top = panel.y
    let titleH = textHeight(s(o["title"]), sans(18, .bold), w - 44)
    let r = CGRect(x: px, y: top, width: w, height: 20 + titleH + 12 + Double(lanes.count) * 44 + 12)
    card(r)
    var y = top + 20
    y += text(s(o["title"]), sans(18, .bold), MUTED, x: px + 22, y: y, width: w - 44) + 12
    for (i, lane) in lanes.enumerated() {
      let st = s(lane["status"])
      let barX = px + 150, barW = w - 172
      text(s(lane["name"]), sans(22, st == "win" ? .bold : .regular), st == "unavailable" ? MUTED : TEXT, x: px + 22, y: y + 4, width: 125)
      fill(CGRect(x: barX, y: y + 6, width: barW, height: 26), LINE, radius: 13)
      if st == "win" {
        fill(CGRect(x: barX, y: y + 6, width: barW, height: 26), ACCENT, radius: 13)
        text("★ " + s(lane["value"]), sans(17, .bold), .black, x: barX + 12, y: y + 9, width: barW - 24)
      } else if st == "compared" {
        fill(CGRect(x: barX, y: y + 6, width: barW * (0.55 + 0.1 * Double(i % 2)), height: 26), color("#5A5A60"), radius: 13)
        text("compared", sans(15), TEXT, x: barX + 12, y: y + 10, width: barW - 24)
      } else {
        text("✕ " + s(lane["note"]), sans(16), WARN, x: barX + 12, y: y + 10, width: barW - 24)
      }
      y += 44
    }
    panel.y = r.maxY + 16
  case "flow":
    let steps = (o["steps"] as! [Any]).map { s($0) }
    var x = px, y = panel.y
    if o["text"] != nil { y += text(s(o["text"]), sans(18, .bold), ACCENT, x: px, y: y, width: w) + 8 }
    for (i, st) in steps.enumerated() {
      let wd = textWidth(st, sans(20, .bold)) + 28
      if i > 0 {
        // Wrap before the arrow, so a line never ends on one.
        if x + 40 + wd > px + w { x = px; y += 56 }
        else { text("→", sans(24, .bold), ACCENT, x: x + 8, y: y + 4, width: 30); x += 40 }
      }
      x = pill(st, sans(20, .bold), fg: TEXT, bg: CARD, border: LINE, x: x, y: y).maxX
    }
    panel.y = y + 60
  default: break
  }
}

func drawPositioned(_ o: J, _ src: CGRect) {
  func sp(_ p: CGPoint) -> CGPoint { CGPoint(x: src.minX + p.x * src.width, y: src.minY + p.y * src.height) }
  switch s(o["type"]) {
  case "label":
    guard let a = pt(o["at"]) else { return }
    let p = sp(a), f = sans(24, .bold)
    _ = pill(s(o["text"]), f, fg: .black, bg: ACCENT, x: p.x - (textWidth(s(o["text"]), f) + 28) / 2, y: p.y - 21)
  case "ripple":
    guard let a = pt(o["at"]) else { return }
    let p = sp(a)
    for (r, al) in [(16.0, 0.9), (30.0, 0.55), (46.0, 0.25)] {
      ctx.setStrokeColor(ACCENT.withAlphaComponent(al).cgColor); ctx.setLineWidth(4)
      ctx.strokeEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
  case "arc":
    guard let a = pt(o["from"]), let b = pt(o["to"]) else { return }
    let p0 = sp(a), p1 = sp(b), c = CGPoint(x: (p0.x + p1.x) / 2, y: min(p0.y, p1.y) - 220)
    ctx.setStrokeColor(ACCENT.cgColor); ctx.setLineWidth(5); ctx.setLineDash(phase: 0, lengths: [14, 10])
    ctx.move(to: p0); ctx.addQuadCurve(to: p1, control: c); ctx.strokePath(); ctx.setLineDash(phase: 0, lengths: [])
    fill(CGRect(x: p1.x - 10, y: p1.y - 10, width: 20, height: 20), ACCENT, radius: 10)
    let f = sans(26, .bold)
    _ = pill(s(o["text"]), f, fg: .black, bg: ACCENT, x: c.x - (textWidth(s(o["text"]), f) + 28) / 2, y: (p0.y + c.y) / 2 - 30)
  default: break
  }
}

// MARK: chrome shared by every frame

func chrome(_ seg: J, index: Int, start: Double, dur: Double, voice: Double, room: Double) {
  let ch = chapters[s(seg["chapter"])] ?? [:]
  // Storyboard metadata strip (not part of the video).
  let src = seg["source"] != nil ? "  ·  \(s(seg["source"])) \(fmt(d(seg["in"])))–\(fmt(d(seg["out"])))  ·  \(d(seg["speed"]))×" : ""
  text(String(format: "%02d  %@   %@–%@ (%.1fs)%@", index, s(seg["id"]), fmt(start), fmt(start + dur), dur, src), mono(16), color("#6A6A70"), x: 24, y: 18, width: 1400)
  if let tag = ch["tag"] as? String {
    let f = sans(18, .bold), w = textWidth(tag, f) + 28
    _ = pill(tag, f, fg: s(seg["chapter"]) == "buy" ? WARN : TEXT, bg: CARD, border: LINE, x: W - w - 28, y: 18)
  }
  if seg["chapter_card"] as? Bool == true, let title = ch["title"] as? String {
    fill(CGRect(x: 0, y: 0, width: W, height: H), color("#000000", 0.35))
    text(title, sans(84, .bold), TEXT, x: 0, y: H / 2 - 60, width: W, align: .center)
    fill(CGRect(x: W / 2 - 60, y: H / 2 + 50, width: 120, height: 6), ACCENT, radius: 3)
    text("CHAPTER CARD · 1.2 s, then the clip continues", mono(14), MUTED, x: 0, y: H / 2 + 72, width: W, align: .center)
  }
  if let n = seg["narration"] as? String {
    let capW = 1240.0, x = (W - capW) / 2
    let a = NSAttributedString(string: n, attributes: attrs(sans(30), TEXT, align: .center))
    let h = a.boundingRect(with: NSSize(width: capW - 60, height: 400), options: [.usesLineFragmentOrigin]).height
    let r = CGRect(x: x, y: H - 60 - h - 28, width: capW, height: h + 28)
    fill(r, color("#000000", 0.72), radius: 14)
    a.draw(with: NSRect(x: x + 30, y: r.minY + 14, width: capW - 60, height: h + 2), options: [.usesLineFragmentOrigin])
    emilioBadge(x: 36, y: H - 150, size: 112)
    let over = voice > room + 0.05
    let note = over ? "  ⚠ longer than the picture before the next line" : room > dur + 0.05 ? String(format: "  · runs on over silent segments (%.1fs room)", room) : ""
    text(String(format: "voice ≈ %.1fs / clip %.1fs%@", voice, dur, note), mono(15), over ? WARN : color("#6A6A70"), x: x, y: H - 52, width: capW)
  }
}

func fmt(_ t: Double) -> String { String(format: "%d:%04.1f", Int(t) / 60, t.truncatingRemainder(dividingBy: 60)) }

// MARK: cards

func drawCard(_ seg: J) {
  switch s(seg["card"]) {
  case "montage":
    let frames = seg["frames"] as! [J]
    let tw = 600.0, th = tw * 1080 / 1784, gap = 24.0
    let x0 = (W - (tw * 2 + gap)) / 2, y0 = 150.0
    for (i, f) in frames.enumerated() {
      let r = CGRect(x: x0 + Double(i % 2) * (tw + gap), y: y0 + Double(i / 2) * (th + gap), width: tw, height: th)
      image(frame(s(f["source"]), d(f["t"])), r); stroke(r, LINE, radius: 6, width: 2)
    }
    text(s(seg["title"]), sans(56, .bold), TEXT, x: 0, y: 64, width: W, align: .center)
  case "emilio":
    if let e = emilio {
      let h = 900.0, w = h * Double(e.width) / Double(e.height)
      image(e, CGRect(x: 250, y: 80, width: w, height: h))
    }
    text(s(seg["title"]), sans(120, .bold), TEXT, x: 1060, y: 330, width: 800)
    fill(CGRect(x: 1066, y: 480, width: 140, height: 8), ACCENT, radius: 4)
    text(s(seg["subtitle"]).uppercased(), sans(34, .bold), ACCENT, x: 1066, y: 510, width: 800)
    text("Light reveal: visor and chest glow fade up, slow push-in.", mono(16), MUTED, x: 1066, y: 580, width: 700)
  case "architecture":
    func box(_ t: String, _ sub: String, _ r: CGRect, hot: Bool = false) {
      fill(r, CARD, radius: 16); stroke(r, hot ? ACCENT : LINE, radius: 16, width: hot ? 3 : 2)
      text(t, sans(28, .bold), TEXT, x: r.minX, y: r.minY + 22, width: r.width, align: .center)
      text(sub, mono(16), MUTED, x: r.minX + 16, y: r.minY + 64, width: r.width - 32, align: .center)
    }
    func arrow(_ x: Double, _ y0: Double, _ y1: Double) {
      ctx.setStrokeColor(ACCENT.cgColor); ctx.setLineWidth(3); ctx.move(to: CGPoint(x: x, y: y0)); ctx.addLine(to: CGPoint(x: x, y: y1)); ctx.strokePath()
      ctx.setFillColor(ACCENT.cgColor); ctx.move(to: CGPoint(x: x - 9, y: y1 - 12)); ctx.addLine(to: CGPoint(x: x + 9, y: y1 - 12)); ctx.addLine(to: CGPoint(x: x, y: y1)); ctx.fillPath()
    }
    text("How the starter is built", sans(44, .bold), TEXT, x: 0, y: 60, width: W, align: .center)
    box("Your app", "React Native · Expo", CGRect(x: 760, y: 150, width: 400, height: 110))
    arrow(960, 260, 320)
    box("WDK worklet", "@tetherto/wdk-react-native-core · keys live here, never leave", CGRect(x: 560, y: 320, width: 800, height: 120), hot: true)
    arrow(760, 440, 520); arrow(1160, 440, 520)
    box("Wallet modules", "wdk-wallet-btc · wdk-wallet-evm-7702-gasless · wdk-wallet-solana", CGRect(x: 300, y: 520, width: 620, height: 130))
    box("Protocol modules", "swidge: LI.FI · Symbiosis · 0x · Rhino.fi\nlending: Morpho · fiat: Transak", CGRect(x: 1000, y: 520, width: 620, height: 150))
    arrow(960, 690, 760)
    box("Chains", "Bitcoin · Ethereum · Arbitrum · Polygon · Solana", CGRect(x: 560, y: 760, width: 800, height: 110))
  case "outro":
    if let e = emilio {
      let h = 760.0, w = h * Double(e.width) / Double(e.height)
      image(e, CGRect(x: 1180, y: 160, width: w, height: h))
    }
    text(s(seg["title"]), sans(96, .bold), TEXT, x: 140, y: 250, width: 1000)
    fill(CGRect(x: 146, y: 380, width: 140, height: 8), ACCENT, radius: 4)
    var y = 420.0
    for l in seg["lines"] as? [Any] ?? [] { y += text(s(l), mono(30), ACCENT, x: 146, y: y, width: 1000) + 14 }
    text("Build the wallet. Keep the keys.", sans(40, .bold), TEXT, x: 146, y: y + 30, width: 1000)
    text(s(seg["footnote"]), sans(20), MUTED, x: 146, y: y + 100, width: 1000)
  default: break
  }
}

// MARK: main

var md = "# Storyboard\n\nOne frame per playbook segment, rendered from `playbook.yaml` by `tools/storyboard.swift`. Every overlay is shown at once; in the video they animate in at their `t`. Fonts are system fallbacks.\n\n"
md += "| # | Segment | Out time | Length | Voice | Frame |\n|---|---|---|---|---|---|\n"
var clock = 0.0
var chapterTotals: [(String, Double, Double)] = []
let segments = pb["segments"] as! [J]
func duration(_ seg: J) -> Double {
  s(seg["kind"]) == "card" ? d(seg["duration"]) : (d(seg["out"]) - d(seg["in"])) / max(d(seg["speed"]), 0.01) + d(seg["hold"])
}
for (i, seg) in segments.enumerated() {
  let isCard = s(seg["kind"]) == "card"
  let dur = duration(seg)
  var room = dur
  for next in segments.dropFirst(i + 1) {
    if next["narration"] != nil || s(next["chapter"]) != s(seg["chapter"]) { break }
    room += duration(next)
  }
  let words = (seg["narration"] as? String)?.split(separator: " ").count ?? 0
  let voice = Double(words) / wpm * 60
  newCanvas()
  if isCard {
    drawCard(seg)
  } else {
    let raw = frame(s(seg["source"]), d(seg["key"]))
    let key = d(seg["key"])
    let rects = (seg["blur"] as? [J] ?? []).filter { d($0["from"]) <= key && key <= d($0["to"]) }.map { b -> CGRect in
      let r = (b["rect"] as! [Any]).map { d($0) }; return CGRect(x: r[0], y: r[1], width: r[2] - r[0], height: r[3] - r[1])
    }
    let img = blurred(raw, rects: rects)
    let sw = H * Double(img.width) / Double(img.height)
    let src = CGRect(x: (W - sw) / 2, y: 0, width: sw, height: H)
    image(img, src)
    for r in rects {
      let rr = CGRect(x: src.minX + r.minX * src.width, y: r.minY * H, width: r.width * src.width, height: r.height * H)
      stroke(rr, WARN, radius: 6, width: 2)
      text("BLUR", mono(14), WARN, x: rr.minX + 6, y: rr.minY + 6, width: 80)
    }
    // Side panel in the wider black area beside the phones.
    let (lo, hi) = contentSpan(img)
    let leftFree = src.minX + lo * src.width, rightFree = W - (src.minX + hi * src.width)
    // Shrink the panel to the free space; below 340px it overlaps the phone edge.
    let free = max(leftFree, rightFree)
    let pw = min(500, max(free - 80, 340))
    var panel = rightFree >= leftFree
      ? Panel(x: W - pw - 48, y: 120, w: pw)
      : Panel(x: 48, y: 120, w: pw)
    let overlays = seg["overlays"] as? [J] ?? []
    for o in overlays where ["label", "ripple", "arc"].contains(s(o["type"])) { drawPositioned(o, src) }
    for o in overlays where !["label", "ripple", "arc"].contains(s(o["type"])) { drawOverlay(o, &panel, src) }
    if seg["hero"] as? Bool == true { _ = pill("HERO · hold / zoom", mono(14), fg: ACCENT, bg: .clear, border: ACCENT, x: 24, y: 48) }
  }
  chrome(seg, index: i + 1, start: clock, dur: dur, voice: voice, room: room)
  let name = String(format: "%02d_%@.jpg", i + 1, s(seg["id"]))
  let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
  try! rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82])!.write(to: outDir.appendingPathComponent(name))
  md += String(format: "| %d | `%@` | %@ | %.1fs | %@ | ![](storyboard/%@) |\n", i + 1, s(seg["id"]), fmt(clock), dur, words > 0 ? String(format: "%.1fs", voice) : "–", name)
  let ch = s(seg["chapter"])
  if chapterTotals.last?.0 == ch { chapterTotals[chapterTotals.count - 1].1 += dur; chapterTotals[chapterTotals.count - 1].2 += voice }
  else { chapterTotals.append((ch, dur, voice)) }
  clock += dur
}
md += "\n## Chapter timing\n\n| Chapter | Picture | Voice | Slack |\n|---|---|---|---|\n"
for (ch, pic, v) in chapterTotals { md += String(format: "| %@ | %.1fs | %.1fs | %+.1fs |\n", ch, pic, v, pic - v) }
md += String(format: "\n**Total runtime: %@** (target %@).\n", fmt(clock), s((pb["meta"] as! J)["target_runtime"]))
try! md.write(to: root.appendingPathComponent("out/STORYBOARD.md"), atomically: true, encoding: .utf8)
print(String(format: "rendered %d frames, runtime %@", segments.count, fmt(clock)))
for (ch, pic, v) in chapterTotals { print(String(format: "  %-7@ picture %5.1fs  voice %5.1fs", ch, pic, v)) }
