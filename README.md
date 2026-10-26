# WDK Starter Wallet: demo video

This repo holds the production plan for the narrated demo video of the
[WDK Starter Wallet](https://github.com/rachdotdev/wdk-starter-react-native/tree/swaps).
The video is presented by Emilio, the WDK agent.

| File | What it is |
|---|---|
| `DEMO_PROMPT.md` | The production brief: facts, narrator, format, structure, narration, toolchain and checklist |
| `playbook.yaml` | The edit plan, the source of truth: 42 segments with in/out points, speeds, blur, overlays and narration |
| `out/footage-log.md` | Timestamped log of the four raw recordings |
| `out/STORYBOARD.md` | One rendered frame per segment, with timing per chapter (currently 3:27) |
| `tools/storyboard.swift` | Renders the storyboard from the playbook (macOS) |
| `tools/voice.rb` | Narration per segment: ElevenLabs if its key is set, otherwise a macOS scratch voice |
| `tools/roughcut.swift` | Builds the 720p rough cut with voice, blur and SRT (`out/roughcut.mp4`, not in git), plus `out/ROUGHCUT.md` |
| `assets/emilio.webp` | Narrator artwork |

The raw recordings are not in git. Put them in `raw/`:

- `Starter-wallet-demo.mp4`
- `starter_swaps_bridge.mp4`
- `starter_pay.mp4`
- `starter_earn.mp4`

`DEMO_PROMPT.md` was written inside the starter repo, so its `demo/…` paths
point at the root of this repo.

## Re-render the storyboard

```bash
ruby -ryaml -rjson -e 'puts JSON.generate(YAML.load_file("playbook.yaml"))' > out/playbook.json
swiftc -O tools/storyboard.swift -o out/storyboard-bin && out/storyboard-bin .
```

## Build the rough cut

```bash
ruby tools/voice.rb
swiftc -O tools/roughcut.swift -o out/roughcut-bin && out/roughcut-bin .
```
