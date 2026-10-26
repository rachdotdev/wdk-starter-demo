# WDK Starter Wallet: Final Demo Video Production Prompt

> Paste everything below the line into Claude Code (or another agent) that can
> read the raw recordings in `demo/raw/`. It is written so the agent analyzes
> the footage first, then plans, then builds. Nothing ships until a human
> approves the plan.

---

## 1. Role and goal

You are a product-video director and motion designer. Turn four raw screen
recordings of the **WDK Starter Wallet (React Native)** into one polished,
narrated demo video. The narrator is **Emilio**, the WDK agent (see
`demo/assets/emilio.webp`).

The video has two jobs:

- Show developers that the starter is a complete, working, self-custodial
  wallet built on Tether's WDK, covering wallet, swap/bridge, buy and earn.
- Show them that each feature is a WDK module they can plug into their own app.

**Rule: never fake the product.** Every app frame comes from the recordings.
You may add framing, zooms, callouts, diagrams and captions on top, but you may
never redraw or invent UI, balances, rates, or transaction results.

## 2. Inputs

| File | Content (verify by watching) |
|---|---|
| `demo/raw/Starter-wallet-demo.mp4` | Core wallet: onboarding, recovery phrase, password, cloud backup, balances, accounts, receive, send, activity |
| `demo/raw/starter_swaps_bridge.mp4` | Swap and cross-chain bridge with provider comparison |
| `demo/raw/starter_pay.mp4` | Buy USDT with EUR through Transak |
| `demo/raw/starter_earn.mp4` | Morpho vaults: deposit and withdraw, and XAUt collateral with a USDT borrow |
| `demo/assets/emilio.webp` | Narrator character (black and charcoal armor, neon-orange glow, "WDK tether." chest plate) |

Source of truth for features: the repo (`swaps` branch), mainly `README.md`,
`wdk.config.js`, `src/app/**` and `src/wdk/**`.

## 3. Step 1: analyze the footage

> **Done.** The log is in `demo/out/footage-log.md`. Read it first: it
> covers the timecodes, cuts, hero moments, blur ranges and runtime budget.
> The key findings are below. Use the steps after them only to re-check in/out
> points frame by frame.
>
> **The recordings**
> - Each is about 1780×1080 with a **pure black background**, a baked-in
>   phone frame, automatic zooms with motion blur, and a visible macOS mouse
>   pointer.
> - Put them on a 1920×1080 **black** stage, and use the empty black space
>   beside the phone for overlays.
>
> **Two builds**
> - The wallet video is a testnet build: Ethereum (Sepolia), 4 tokens, and no
>   Swap, Earn or Buy buttons.
> - Swap, Earn and Buy are from a mainnet build: Ethereum mainnet, POL, and
>   USDT on Solana.
> - Tag each chapter "Testnet" or "Mainnet".
>
> **Chapter order:** Wallet → Swap & Bridge → **Earn → Buy**. That order
> keeps the on-screen balance consistent and ends on $65.69.
>
> **Blur:** the recovery words at **wallet 0:09–0:20** must be blurred.

Re-check procedure:

For each video:

1. Probe it with `ffprobe`: duration, resolution, fps, orientation, and whether
   it has audio.
2. Run scene detection (`ffmpeg -vf "select='gt(scene,0.25)',showinfo"`) and
   take a frame every 1 to 2 s. Look at the frames.
3. Build a **footage log**: `timestamp in → out | screen name | what happens |
   keep / trim / speed-up | sensitive?`.
4. Mark the **dead time** that needs cutting or speeding up (2x to 8x with a
   small "⏩" badge): spinners, loading quotes, waiting for confirmations, typing.
5. Mark **sensitive frames**:
   - Recovery phrase words
   - Password entry
   - Full wallet addresses and QR codes, if the user wants them hidden
   - API keys and email addresses
   - Notifications from other apps

   Recovery phrase words must always be blurred or pixelated, even on testnet.
6. Find the **hero moments** that each get a zoom and a callout:
   - Balance total
   - "Automatic" quote comparison and the winning route
   - "Gas is sponsored"
   - Success screen with the explorer link
   - Vault APY
   - USDT credited after the buy

Update `demo/out/footage-log.md` with any corrections.

## 4. Facts the narration must get right

Use only these facts, and confirm each one against the code.

**Wallet**
- Self-custodial: keys are generated on the device and never leave it.
- Create or import a wallet with a 12- or 24-word recovery phrase.
- The app password protects the keys with real envelope encryption.
- Encrypted cloud backup to iCloud or Google Drive, on either platform, using
  the user's own password.
- Multi-network balances with USD values:
  - Wallet video (testnet build): Bitcoin (testnet), Ethereum (**Sepolia**),
    Arbitrum and Polygon.
  - Swap, Earn and Buy videos (mainnet build): Ethereum **mainnet**,
    Arbitrum, Polygon (USDT and POL), and USDT on **Solana**.
  - The Ethereum network is set through an env var
    (`EXPO_PUBLIC_EVM_ETHEREUM_NETWORK_LABEL`).
- Multiple accounts on one wallet.
- Receive: QR code, copy and share.
- Send: native and ERC-20 tokens (USDT/USDT0), with a real fee quote and a
  block explorer link.
- Activity comes from the **WDK Indexer API**, with filters.

**Gasless**
- EVM accounts use `@tetherto/wdk-wallet-evm-7702-gasless` (EIP-7702 with a
  bundler and paymaster).
- The UI says: "Gas is sponsored".

**Swap and bridge** (WDK "swidge" protocols)
- Four providers: **LI.FI, Symbiosis, 0x and Rhino.fi**.
- In **Automatic** mode the app quotes all four in parallel and picks the
  highest output.
- A provider that fails is left out, and the rest still compete.
- The user can also pin one provider.
- Covers same-chain swaps and cross-chain bridges between Ethereum, Arbitrum
  and Polygon.

**Buy (the "pay" video)**
- USDT with **EUR or USD** through **Transak**
  (`@transak/wdk-protocol-fiat-transak`). The recording uses USD: 50 USD →
  about 46.65 USDT on Ethereum, with a 3.35 USD fee.
- Pick the network (Ethereum, Arbitrum or Polygon), get a quote, then complete
  the purchase in the Transak widget.
- ⚠️ This runs in Transak **STAGING**, and the credited USDT is a **demo-only,
  in-memory credit** (`src/state/demoCredit.ts`).
- Do **not** claim the USDT arrived on-chain. Use wording like "In this demo
  build, the purchase is reflected right away", or add an on-screen "Staging /
  demo" tag.

**Earn**
- **Morpho** lending through WDK.
- Vaults: "sky.money USDT Savings" and "sky.money USDT Risk Capital", each
  with a live APY.
- "Borrow against XAUt": deposit XAUt (Tether Gold) as collateral, then borrow
  USDT.
  - The recording only **shows the screen**, with 0 collateral. No borrow
    happens, so present it as available, not as something done.
- Recorded on Ethereum mainnet:
  - Savings APY is 3.03% and Risk Capital APY is 1.72%. Show these as "APY at
    time of recording".
  - Deposit 2 USDT (0.10 → 2.10), then withdraw 1 USDT.
  - The withdrawal result is **not** shown refreshed, so don't claim the new
    balance.
- Every action shows a summary, and nothing is sent before Confirm.
- Approvals are sent first if needed, and gas is sponsored.

**Status**
- Alpha, open source, reference app.
- Add a small persistent "Alpha · testnets + small mainnet amounts" note, or
  show it once in the outro.

**Don't**
- Invent TVL, user numbers or chain counts.
- Use the words "safe", "guaranteed", "risk-free" or "best rates", or give any
  financial advice.
- Say that APY is guaranteed.

## 5. Narrator: Emilio, the WDK agent

**Persona**
- A helpful, sharp, slightly playful AI agent who lives inside WDK and gives
  developers a tour.
- Confident but not salesy.
- Short sentences. Talks to developers as peers.
- One light joke at most per chapter.

**On screen**
- Emilio appears in the intro and outro, plus a small corner badge when he
  "talks" during chapters.
- Corner badge: a circular crop of the head with the orange visor glow pulsing
  to the voice amplitude (audio-reactive).
- Optional: a subtle idle float and an eye-blink loop made from the still
  image. No lip-sync is needed, because the visor has no mouth.

**AI voice (ElevenLabs or similar)**
- Male, mid-range, warm, clear diction.
- 155 to 165 words per minute.
- A very light synthetic or radio texture is fine. It must stay natural, not
  "robot voice".
- Suggested settings: stability 0.45, similarity 0.8, style 0.2.
- Generate audio per segment, so timing can be fixed one segment at a time.
- Export WAV at 48 kHz, normalized to -16 LUFS.

**Signature lines** (use one or two, don't overuse)
- "One toolkit. Every chain. Your keys."
- "Build the wallet. Keep the keys."

## 6. Format and length

**Master cut**
- 16:9, 1920×1080, 30 or 60 fps (match the source).
- Target length **2:30 to 3:15**.

**Social cutdowns**
- 9:16, 1080×1920: 45 to 60 s, one per chapter, plus a 30 s highlight reel.

**App footage**
- Place the phone recording in a clean device frame (rounded corners and a
  soft shadow; no fake brand bezels needed).
- Background: **pure black (#000)**, because the recordings have an opaque
  black background.
- Any orange glow or grid goes only in the margins outside the video, or is
  composited with `mix-blend-mode: screen` so the black stays seamless.

**Brand**
- Black and charcoal, with neon orange (about #FF5A1F) as the single accent,
  matching Emilio. Use white text.
- Fonts: a geometric sans for titles (e.g. Space Grotesk or Inter Tight) and a
  monospace for package names (JetBrains Mono).

**Captions**
- Burned-in captions on the social cuts.
- An SRT file for the master.
- Max 2 lines, 42 characters per line.

**Music**
- Royalty-free, minimal electronic, about 100 to 115 BPM.
- Duck it -12 dB under the voice.

**Sound design**
- Soft UI ticks on taps, a whoosh on chapter transitions, and a subtle "ding"
  on success screens.

## 7. Structure (timecodes come from the footage log)

Source timecodes are written `file@mm:ss`. Target length is about **3:20**.
The footage log lists what to drop for a 2:30 cut.

| # | Section | ~Out time | Source cuts | Visual layer |
|---|---|---|---|---|
| 0 | Cold open | 0:00–0:08 | Hero frames: `wallet@1:41` (Free · sponsored), `swap@0:28` (Symbiosis quote), `earn@0:07` (APY cards), `pay@1:12` ($65.69) | Kinetic text "Wallet. Swap. Earn. Buy." |
| 1 | Emilio intro | 0:08–0:20 | Emilio still, light reveal | Name card "Emilio · WDK agent"; WDK + tether logos |
| 2 | Architecture | 0:20–0:32 | Animated diagram | App (React Native) → WDK worklet (keys stay here) → wallet modules (BTC, EVM-7702 gasless, Solana) + protocol modules (swidge, lending, fiat) → chains |
| 3 | Ch. 1: Your wallet · **Testnet** | 0:32–1:27 | `wallet@0:02–0:08` create · `0:08–0:20` phrase (**blur**, 1.5×) · `0:20–0:37` password (3×) · `0:38–0:47` cloud backup · `0:48–0:51` home · `0:54–1:00` import · `1:00–1:13` (3×) · `1:14–1:17` $98.90 · `1:18–1:26` receive · `1:27–1:39` send · `1:39–1:44` review · `1:45–1:50` sent · `2:00–2:01` both balances | Label the two phones "New wallet" and "Imported wallet". A blur with the label "🔒 never leaves the device". Chips `wdk-wallet-btc` and `wdk-wallet-evm-7702-gasless`. A dashed arc from the right phone to the left with "1 USDT" when Sent appears. A "Network fee: Free" callout |
| 4 | Ch. 2: Swap & bridge · **Mainnet** | 1:27–2:12 | `swap@0:09–0:14` home · `0:15–0:26` (2×) · `0:27–0:32` quote and provider list · `0:33–0:40` (1.5×) · `0:44–0:51` balances · `0:57–1:12` (2×) · `1:15–1:20` bridge quote · `1:21–1:29` (2×) · `1:30–1:39` balances | **Quote race** with 4 provider lanes. Swap: Symbiosis wins at 4.420441 USDT and Rhino.fi is marked "unsupported route". Bridge: LI.FI wins at 14.943675 USDT and 0x is marked "same-chain only". Show only these real outcomes, not invented numbers for the other providers. Polygon → Ethereum chain arc. Before/after balance counters (POL 56.25 → 5.80, USDT Polygon 11.97 → 16.39, USDT Eth 0.27 → 15.21) |
| 5 | Ch. 3: Earn · **Mainnet** | 2:12–2:42 | `earn@0:00–0:02` · `0:06–0:11` cards · `0:12–0:20` (1.5×) · `0:21–0:24` confirm · `0:24–0:33` (2×) · `0:36–0:38` 2.10 USDT · `0:39–0:44` withdraw · `0:57–1:03` XAUt screen | Callouts for "APY 3.03% / 1.72%" (labelled "at time of recording"), "Gas is sponsored", and "Nothing is sent until you confirm". Chip `wdk-protocol-lending-morpho`. Mini-diagram XAUt → collateral → USDT, marked "available" |
| 6 | Ch. 4: Buy · **Transak staging** | 2:42–3:08 | `pay@0:00–0:02` · `0:03–0:19` (2× for the typing) · `0:20–0:32` (cut) · `0:33–0:46` (1.5×) · `0:46–0:56` (8×) · `0:57–1:09` (2×) · `1:10–1:17` | Flow graphic: 50 USD → Transak → 46.65 USDT → your wallet. Chip `@transak/wdk-protocol-fiat-transak`. Persistent tag "Staging · demo credit". Balance counter $19.08 → $65.69 |
| 7 | Outro / CTA | 3:08–3:22 | Emilio and the end card | "Fork the starter", with github.com/rachdotdev/wdk-starter-demo, docs.wdk.tether.io, and an "Alpha" note |

**Module chips**: small monospace labels that slide in next to the phone when
a feature appears. Examples:

- `@tetherto/wdk-wallet-evm-7702-gasless`
- `wdk-protocol-swidge-*`
- `@transak/wdk-protocol-fiat-transak`
- `wdk-protocol-lending-morpho`
- `WDK Indexer API`

**Tap indicators**: an orange ripple at each tap. Infer the tap positions from
frame changes, or ask the user for them.

## 8. Narration for Emilio (timed to the footage)

Each line sits on the clip it describes. Speaking speed is about 160 words
per minute.

> **[Cold open · 0:00]** Wallet. Swap. Earn. Buy. One app, built on one
> toolkit.
>
> **[Intro · 0:08]** Hi, I'm Emilio, your agent inside WDK, Tether's Wallet
> Development Kit. This is the WDK Starter Wallet: an open-source React
> Native app you can fork and make your own.
>
> **[Architecture · 0:20]** Here's the idea. Your app talks to WDK, and WDK
> runs in its own worklet on the device. That's where the keys live, and they
> never leave. Every chain and every protocol is a module you plug in.
>
> **[Wallet: create · 0:32]** Two phones. On the left, a brand-new wallet:
> twelve words, generated on the device. We blurred them; you should never
> share yours.
>
> **[Wallet: password and backup · 0:44]** A password encrypts everything
> locally. Then back it up, encrypted, to Google Drive or iCloud. Your choice.
>
> **[Wallet: import · 0:55]** On the right, an existing wallet, imported from
> its recovery phrase. The balance is already there: ninety-eight dollars and
> ninety cents, on testnet.
>
> **[Wallet: send · 1:05]** Left phone: Receive, and copy the address. Right
> phone: send one USDT. Look at the fee. Free. Gas is sponsored, thanks to
> EIP-7702.
>
> **[Wallet: result · 1:22]** Sent. And both balances update, one dollar
> over.
>
> **[Swap · 1:27]** Now, on mainnet. Let's swap fifty POL for USDT. In
> Automatic mode I ask LI.FI, Symbiosis, 0x and Rhino.fi at once, and the best
> quote wins. This time, it's Symbiosis.
>
> **[Swap: result · 1:45]** Submitted, and the balances follow.
>
> **[Bridge · 1:50]** Same screen, different chain. Fifteen USDT from Polygon
> to Ethereum. Zero-x only swaps on one chain, so it sits this one out. LI.FI
> takes the route.
>
> **[Bridge: result · 2:05]** Fifteen USDT, now on Ethereum.
>
> **[Earn · 2:12]** Idle USDT? Put it to work. These are Morpho vaults, with
> live APY. I'll deposit two USDT. You always see a summary first:
> approvals, if needed, and gas is sponsored.
>
> **[Earn: withdraw and XAUt · 2:28]** Withdrawing works the same way. And
> if you hold Tether Gold, you can use it as collateral to borrow USDT.
>
> **[Buy · 2:42]** Need more USDT? Pick an amount, in euros or dollars, and a
> network. Fifty dollars gets about forty-six sixty-five USDT. Transak handles
> payment and checks.
>
> **[Buy: result · 3:00]** This demo runs on Transak's staging environment,
> so the purchase shows up right away.
>
> **[Outro · 3:08]** Wallet, swaps, yield and fiat, all self-custodial. Fork
> it, swap modules in or out, and ship your own. Build the wallet. Keep the
> keys.

About 400 words, roughly 2:30 of voice in a 3:20 cut. That leaves room for
the music, the hero holds and the chapter cards. For a 2:30 cut, drop the
"password and backup", "import" and "withdraw" lines.

## 9. Toolchain (recommended)

**Remotion (React)** is the main option, because the team already writes React.

- One `<Composition>` per aspect ratio.
- Each segment is a `<Sequence>` with `<OffthreadVideo>`, using trim and
  playback rate from the footage log.
- Overlays (callouts, chips, ripples, diagrams, captions) are components.
- Timing comes from the narration audio length of each segment.

**Other tools**
- **ElevenLabs API**: one request per segment, saved to
  `demo/out/voice/<id>.wav`.
- **ffmpeg**: probing, scene detection, blur masks (`boxblur` on a rectangle
  over the timed range) and the final loudness pass (`loudnorm`).
- **Optional**: Whisper for word-level timestamps, to drive karaoke-style
  captions.

**Concepts borrowed from the references**

- **ndemo**: a YAML playbook where each segment has `id`, `narration`,
  `intent` and source clip and timecodes, and each segment can be rendered and
  reviewed on its own.
- **Paralect product-demo**: the real UI sits in a framed window on a soft
  background, with a drawn pointer layer on top. Here, that pointer is the tap
  ripple.

The plan lives in `demo/playbook.yaml`. A segment looks like this:

```yaml
segments:
  - id: swap-auto-quote
    chapter: swap
    source: raw/starter_swaps_bridge.mp4
    in: "00:00:12.4"
    out: "00:00:31.0"
    speed: [{ from: "00:00:15.0", to: "00:00:24.0", rate: 4 }]
    narration: "In Automatic mode I ask LI.FI, Symbiosis, 0x and Rhino.fi at the same time…"
    overlays:
      - { type: chip, text: "wdk-protocol-swidge-*", at: "+0.5s" }
      - { type: zoom, region: "quote-card", at: "+6s", scale: 1.6 }
      - { type: badge, text: "Gas sponsored", at: "+9s" }
    blur: []
```

## 10. Process and checkpoints

1. Footage log (done: `demo/out/footage-log.md`). Re-check the blur range and in/out points.
2. `playbook.yaml` and the storyboard. **Done.**
   - `demo/playbook.yaml` lists the 42 segments in order (Wallet → Swap →
     Earn → Buy), with in/out points, speeds, blur keyframes, overlays and
     narration.
   - `demo/out/STORYBOARD.md` has one frame per segment
     (`demo/out/storyboard/*.jpg`) plus the timing per chapter. It currently
     runs **3:27**.
   - The playbook is the source of truth: re-render the storyboard after every
     edit, with:
     ```bash
     cd demo && ruby -ryaml -rjson -e 'puts JSON.generate(YAML.load_file("playbook.yaml"))' > out/playbook.json && swiftc -O tools/storyboard.swift -o out/storyboard-bin && out/storyboard-bin .
     ```
   - The outro shows `github.com/rachdotdev/wdk-starter-demo`.
   - Before the real render, check the blur keyframes frame by frame, or
     replace them with a tracked mask.
3. Voice and rough cut. **Done, with a scratch voice.**
   - `tools/voice.rb` writes one file per narrated segment to `out/voice/`.
     - With `ELEVENLABS_API_KEY` and `ELEVENLABS_VOICE_ID` set, it uses
       ElevenLabs, with the voice settings from the playbook.
     - Without them, it uses the macOS voice "Reed" as a **timing-only
       scratch track**.
     - Delete `out/voice/` to regenerate.
   - `tools/roughcut.swift` (AVFoundation, no ffmpeg needed) assembles
     `out/roughcut.mp4` at 1280×720:
     - footage, cards and voice, plus `out/roughcut.srt`;
     - the recovery-phrase blur is applied;
     - when a line is longer than its picture, the last frame is held, and
       `out/ROUGHCUT.md` lists every hold.
   - With the scratch voice the cut runs 3:49: the planned 3:27 plus 21.5 s of
     holds. Re-run both tools after recording Emilio's real voice.
   - Commands:
     ```bash
     cd demo && ruby tools/voice.rb && swiftc -O tools/roughcut.swift -o out/roughcut-bin && out/roughcut-bin .
     ```
4. Overlays, music, sound effects and captions, then render the 1080p master.
5. 9:16 cutdowns, SRT, a thumbnail (Emilio and the phone with the swap screen,
   title "Fork a full wallet in minutes"), and a YouTube description with
   chapters.

## 11. Quality checklist before final render

- [ ] No recovery phrase, password, key or private email is visible in any frame.
- [ ] Every number on screen comes from the footage.
- [ ] Testnet, staging and demo-only items are labeled.
- [ ] Voice levels are consistent; integrated loudness is -14 LUFS for web,
  with true peak at or below -1 dBTP.
- [ ] Captions match the final voice.
- [ ] Brand colors and fonts are consistent; nothing sits near the 9:16 UI edges.
- [ ] Every claim matches the "Facts" section above.
- [ ] Emilio's image is used without distortion.
