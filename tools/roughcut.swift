// Assembles the 720p rough cut: footage and cards from the playbook plus the
// narration files. There are no overlays or music.
//
//   swiftc -O tools/roughcut.swift -o out/roughcut-bin && out/roughcut-bin .
//
// Run from demo/, after tools/voice.rb and the storyboard renderer (for
// out/cards/*.png). Writes out/roughcut.mp4, out/roughcut.srt and
// out/ROUGHCUT.md.
//
// When a narration line is longer than its picture (up to the next line, within
// the chapter), the last frame of that stretch is held until the line ends.
// ROUGHCUT.md lists every hold, so you can trim the line or slow the footage.
import AVFoundation
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
func url(_ p: String) -> URL { root.appendingPathComponent(p) }
typealias J = [String: Any]
func d(_ v: Any?) -> Double { (v as? NSNumber)?.doubleValue ?? 0 }
func s(_ v: Any?) -> String { v as? String ?? "" }
func t(_ seconds: Double) -> CMTime { CMTime(seconds: seconds, preferredTimescale: 600) }

let pb = try! JSONSerialization.jsonObject(with: Data(contentsOf: url("out/playbook.json"))) as! J
let manifest = try! JSONSerialization.jsonObject(with: Data(contentsOf: url("out/voice/manifest.json"))) as! J
let voices = manifest["segments"] as! [String: J]
let sources = pb["sources"] as! J
let segments = pb["segments"] as! [J]
let renderSize = CGSize(width: 1280, height: 720)
let lead = 0.25, tail = 0.35

// MARK: timing (with automatic holds)

func baseDuration(_ seg: J) -> Double {
  s(seg["kind"]) == "card" ? d(seg["duration"]) : (d(seg["out"]) - d(seg["in"])) / d(seg["speed"])
}
var hold = segments.map { d($0["hold"]) }
var autoHold = Array(repeating: 0.0, count: segments.count)
for (i, seg) in segments.enumerated() {
  guard let v = voices[s(seg["id"])] else { continue }
  var j = i
  while j + 1 < segments.count, segments[j + 1]["narration"] == nil, s(segments[j + 1]["chapter"]) == s(seg["chapter"]) { j += 1 }
  let room = (i...j).reduce(0.0) { $0 + baseDuration(segments[$1]) + hold[$1] }
  let extra = lead + d(v["seconds"]) + tail - room
  if extra > 0 { hold[j] += extra; autoHold[j] += extra }
}

// MARK: card stills → 1-second clips

func stillClip(_ png: URL, _ out: URL) {
  try? FileManager.default.removeItem(at: out)
  let img = NSImage(contentsOf: png)!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
  let w = try! AVAssetWriter(outputURL: out, fileType: .mp4)
  let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: Int(renderSize.width), AVVideoHeightKey: Int(renderSize.height),
  ])
  let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: Int(renderSize.width), kCVPixelBufferHeightKey as String: Int(renderSize.height),
  ])
  w.add(input); w.startWriting(); w.startSession(atSourceTime: .zero)
  var pb: CVPixelBuffer?
  CVPixelBufferCreate(nil, Int(renderSize.width), Int(renderSize.height), kCVPixelFormatType_32ARGB, nil, &pb)
  CVPixelBufferLockBaseAddress(pb!, [])
  let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pb!), width: Int(renderSize.width), height: Int(renderSize.height), bitsPerComponent: 8,
                      bytesPerRow: CVPixelBufferGetBytesPerRow(pb!), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
  ctx.draw(img, in: CGRect(origin: .zero, size: renderSize))
  CVPixelBufferUnlockBaseAddress(pb!, [])
  for (n, time) in [CMTime.zero, t(0.5), t(1.0)].enumerated() {
    while !input.isReadyForMoreMediaData { usleep(1000) }
    adaptor.append(pb!, withPresentationTime: time); _ = n
  }
  input.markAsFinished()
  let done = DispatchSemaphore(value: 0)
  w.endSession(atSourceTime: t(1.0)); w.finishWriting { done.signal() }; done.wait()
}

// MARK: composition

let comp = AVMutableComposition()
let vTrack = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
let aTrack = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: vTrack)
var assets: [String: AVURLAsset] = [:]
func asset(_ u: URL) -> AVURLAsset { if let a = assets[u.path] { return a }; let a = AVURLAsset(url: u); assets[u.path] = a; return a }

var cursor = CMTime.zero
var voiceCursor = CMTime.zero
var srt: [(Double, Double, String)] = []
/// Output-time windows to blur, with rects in 720p pixels (top-left origin).
var blurs: [(Double, Double, CGRect)] = []
var report = "# Rough cut\n\nFootage, cards and narration only, with the recovery-phrase blur applied. There are no overlays or music. Check the blur frame by frame before sharing.\n\n"
report += "Voice engine: **\(s(manifest["engine"]))**.\n\n| # | Segment | Start | Length | Auto-hold | Voice |\n|---|---|---|---|---|---|\n"
try? FileManager.default.createDirectory(at: url("out/cards"), withIntermediateDirectories: true)

for (i, seg) in segments.enumerated() {
  let id = s(seg["id"])
  let isCard = s(seg["kind"]) == "card"
  let srcURL: URL
  let range: CMTimeRange
  if isCard {
    srcURL = url("out/cards/\(id).mp4")
    stillClip(url("out/cards/\(id).png"), srcURL)
    range = CMTimeRange(start: .zero, end: t(1.0))
  } else {
    srcURL = url(s(sources[s(seg["source"])]))
    range = CMTimeRange(start: t(d(seg["in"])), end: t(d(seg["out"])))
  }
  let a = asset(srcURL)
  let track = a.tracks(withMediaType: .video)[0]
  let start = cursor
  let base = baseDuration(seg)

  try! vTrack.insertTimeRange(range, of: track, at: cursor)
  vTrack.scaleTimeRange(CMTimeRange(start: cursor, duration: range.duration), toDuration: t(base))
  cursor = cursor + t(base)
  if hold[i] > 0.01 {
    // Freeze: one frame from the end of the range, stretched over the hold.
    let frame = CMTimeRange(start: range.end - t(1.0 / 30), duration: t(1.0 / 30))
    try! vTrack.insertTimeRange(frame, of: track, at: cursor)
    vTrack.scaleTimeRange(CMTimeRange(start: cursor, duration: frame.duration), toDuration: t(hold[i]))
    cursor = cursor + t(hold[i])
  }

  // Fit the source height to 720 and centre it on the black stage.
  let size = track.naturalSize
  let scale = renderSize.height / size.height
  let tx = (renderSize.width - size.width * scale) / 2
  layer.setTransform(CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: tx, y: 0)), at: start)

  // Blur keyframes are in source time and source-normalized coordinates; map them to the cut.
  for b in seg["blur"] as? [J] ?? [] {
    let r = (b["rect"] as! [Any]).map { d($0) }
    let from = max(d(b["from"]), d(seg["in"])), to = min(d(b["to"]), d(seg["out"]))
    guard to > from else { continue }
    let w = size.width * scale
    // A window that runs to the segment's out point also covers its freeze-frame hold.
    let end = start.seconds + (to - d(seg["in"])) / d(seg["speed"]) + (to >= d(seg["out"]) ? hold[i] : 0)
    blurs.append((start.seconds + (from - d(seg["in"])) / d(seg["speed"]), end,
                  CGRect(x: tx + r[0] * w, y: r[1] * renderSize.height, width: (r[2] - r[0]) * w, height: (r[3] - r[1]) * renderSize.height)))
  }

  var voiceNote = "–"
  if let v = voices[id] {
    let va = asset(url(s(v["file"])))
    let vt = va.tracks(withMediaType: .audio)[0]
    let at = CMTimeMaximum(start + t(lead), voiceCursor)
    if at > voiceCursor { try! aTrack.insertEmptyTimeRange(CMTimeRange(start: voiceCursor, end: at)) }
    try! aTrack.insertTimeRange(CMTimeRange(start: .zero, duration: va.duration), of: vt, at: at)
    voiceCursor = at + va.duration + t(0.15)
    srt.append((at.seconds, (at + va.duration).seconds, s(v["text"])))
    voiceNote = String(format: "%.1fs", d(v["seconds"]))
  }
  report += String(format: "| %d | `%@` | %@ | %.1fs | %@ | %@ |\n", i + 1, id, fmt(start.seconds), (cursor - start).seconds,
                   autoHold[i] > 0.01 ? String(format: "**+%.1fs**", autoHold[i]) : "", voiceNote)
}
if cursor > voiceCursor { try! aTrack.insertEmptyTimeRange(CMTimeRange(start: voiceCursor, end: cursor)) }

func fmt(_ x: Double) -> String { String(format: "%d:%04.1f", Int(x) / 60, x.truncatingRemainder(dividingBy: 60)) }

let instruction = AVMutableVideoCompositionInstruction()
instruction.timeRange = CMTimeRange(start: .zero, duration: cursor)
instruction.layerInstructions = [layer]
instruction.backgroundColor = NSColor.black.cgColor
let vc = AVMutableVideoComposition()
vc.renderSize = renderSize
vc.frameDuration = CMTime(value: 1, timescale: 30)
vc.instructions = [instruction]

// MARK: export

func exportMovie(_ asset: AVAsset, _ composition: AVVideoComposition, to out: URL) {
  try? FileManager.default.removeItem(at: out)
  let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720)!
  export.outputURL = out
  export.outputFileType = .mp4
  export.videoComposition = composition
  let done = DispatchSemaphore(value: 0)
  export.exportAsynchronously { done.signal() }
  done.wait()
  guard export.status == .completed else { fatalError("export failed: \(String(describing: export.error))") }
}

// Pass 1 assembles the cut; pass 2 pixelates and blurs the sensitive regions.
let raw = url("out/roughcut-noblur.mp4")
let out = url("out/roughcut.mp4")
exportMovie(comp, vc, to: raw)
let rawAsset = AVURLAsset(url: raw)
let blurComposition = AVMutableVideoComposition(asset: rawAsset) { request in
  var image = request.sourceImage
  let now = request.compositionTime.seconds
  for (from, to, r) in blurs where from <= now && now < to {
    // CoreImage is bottom-left based.
    let rr = CGRect(x: r.minX, y: renderSize.height - r.maxY, width: r.width, height: r.height)
    let hidden = image.cropped(to: rr).clampedToExtent()
      .applyingFilter("CIPixellate", parameters: ["inputScale": 18, "inputCenter": CIVector(x: rr.minX, y: rr.minY)])
      .applyingGaussianBlur(sigma: 10).cropped(to: rr)
    image = hidden.composited(over: image)
  }
  request.finish(with: image, context: nil)
}
exportMovie(rawAsset, blurComposition, to: out)
try? FileManager.default.removeItem(at: raw)

// MARK: captions and report

func srtTime(_ x: Double) -> String {
  let ms = Int((x * 1000).rounded())
  return String(format: "%02d:%02d:%02d,%03d", ms / 3_600_000, ms / 60_000 % 60, ms / 1000 % 60, ms % 1000)
}
// One cue per sentence, timed by word count, so no cue is too long to read.
var cues: [String] = []
for (a, b, text) in srt {
  var sentences: [String] = []
  text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { sub, _, _, _ in
    if let sub = sub?.trimmingCharacters(in: .whitespaces), !sub.isEmpty { sentences.append(sub) }
  }
  let words = sentences.map { Double($0.split(separator: " ").count) }
  let total = words.reduce(0, +)
  var at = a
  for (sentence, w) in zip(sentences, words) {
    let end = at + (b - a) * w / total
    cues.append("\(cues.count + 1)\n\(srtTime(at)) --> \(srtTime(end))\n\(sentence)\n")
    at = end
  }
}
try! cues.joined(separator: "\n").write(to: url("out/roughcut.srt"), atomically: true, encoding: .utf8)

let added = autoHold.reduce(0, +)
report += String(format: "\n**Runtime: %@.** The planned picture was %@; automatic holds added %.1fs so every line fits.\n", fmt(cursor.seconds), fmt(cursor.seconds - added), added)
try! report.write(to: url("out/ROUGHCUT.md"), atomically: true, encoding: .utf8)
print(String(format: "roughcut.mp4  %@  (auto-holds +%.1fs)", fmt(cursor.seconds), added))
