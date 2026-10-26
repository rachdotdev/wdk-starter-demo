# Generates one narration file per playbook segment into out/voice/.
#
#   ruby tools/voice.rb            # run from demo/
#
# With ELEVENLABS_API_KEY and ELEVENLABS_VOICE_ID set, it uses ElevenLabs
# (the voice settings come from playbook.yaml → narrator.voice). Without them
# it uses the macOS `say` voice as a scratch track, for timing only.
# Existing files are kept; delete out/voice/ to regenerate everything.
require "yaml"
require "json"
require "net/http"
require "uri"
require "fileutils"

pb = YAML.load_file("playbook.yaml")
voice = pb.dig("narrator", "voice") || {}
key = ENV["ELEVENLABS_API_KEY"].to_s
voice_id = ENV["ELEVENLABS_VOICE_ID"].to_s
eleven = !key.empty? && !voice_id.empty?
scratch_voice = ENV.fetch("SCRATCH_VOICE", "Reed (English (US))")
FileUtils.mkdir_p("out/voice")

def duration(path)
  # afinfo prints "estimated duration: 3.123 sec"
  `afinfo "#{path}"`[/estimated duration: ([\d.]+)/, 1].to_f
end

manifest = { "engine" => eleven ? "elevenlabs" : "macos-say (#{scratch_voice})", "segments" => {} }
pb["segments"].each do |seg|
  text = seg["narration"] or next
  id = seg["id"]
  path = "out/voice/#{id}.#{eleven ? 'mp3' : 'aiff'}"
  unless File.exist?(path)
    if eleven
      uri = URI("https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}?output_format=mp3_44100_128")
      req = Net::HTTP::Post.new(uri, "xi-api-key" => key, "Content-Type" => "application/json")
      req.body = JSON.generate(
        text: text,
        model_id: ENV.fetch("ELEVENLABS_MODEL", "eleven_multilingual_v2"),
        voice_settings: { stability: voice["stability"], similarity_boost: voice["similarity"], style: voice["style"] }
      )
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
      abort "ElevenLabs #{res.code} for #{id}: #{res.body[0, 200]}" unless res.is_a?(Net::HTTPSuccess)
      File.binwrite(path, res.body)
    else
      # `say` rate is words per minute.
      system("say", "-v", scratch_voice, "-r", (voice["wpm"] || 160).to_s, "-o", path, text) or abort "say failed for #{id}"
    end
  end
  manifest["segments"][id] = { "file" => path, "seconds" => duration(path).round(2), "text" => text }
  puts format("%-20s %5.2fs", id, manifest["segments"][id]["seconds"])
end
File.write("out/voice/manifest.json", JSON.pretty_generate(manifest))
puts "engine: #{manifest['engine']}"
