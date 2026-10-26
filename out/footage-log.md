# Footage log

Built from frames sampled every 3 s, so every timecode is ±1.5 s. Before
locking a cut, re-check each in/out point frame by frame.

## Things that are true of all four files

**The files**

| File | Length | Size | Audio |
|---|---|---|---|
| `Starter-wallet-demo.mp4` | 2:01 | 1784×1080 | AAC track: check it, mute it under the voice-over |
| `starter_swaps_bridge.mp4` | 1:39 | 1778×1080 | none |
| `starter_pay.mp4` | 1:18 | 1778×1080 | none |
| `starter_earn.mp4` | 1:06 | 1778×1080 | none |

**How they look**
- The background is **pure black**, and the phone frame is baked into the
  video.
- There are already automatic zooms and pans (Screen Studio style), with
  motion blur on the transitions.
- The macOS mouse pointer is visible and can't be removed. Tap ripples should
  sit on the pointer's clicks.
- The size is not 16:9. Scale the video to a height of 1080 and centre it on a
  1920×1080 **black** stage.
- **Put overlays in the empty black space beside the phone.** Most frames
  leave about 40–60% of the width empty, which is the natural place for module
  chips, callouts and the quote graphics.

**Two different builds of the app**
- The wallet video comes from an earlier, testnet build:
  - It shows **Ethereum (Sepolia)** and 4 tokens.
  - Swap and Buy are greyed out, and there's no Earn button.
- The other three videos come from the `swaps` build:
  - They show **Ethereum mainnet**, plus POL and USDT on Solana.
  - All five actions are available (Send, Swap, Receive, Earn, Buy).
- Viewers will see the home screen change between chapters. Label it on screen
  ("Testnet" in chapter 1, "Mainnet" from chapter 2 on) or explain it once in
  the narration.

## Suggested chapter order

The order follows the balance shown on screen and the clock in the status bar:

| Chapter | Clock | Balance at start → end |
|---|---|---|
| Swap | 13:11 | $19.18 → $19.15 |
| Earn | 13:29 | $19.08 |
| Buy | 13:39 | $19.08 → **$65.69** |

**Wallet → Swap & Bridge → Earn → Buy** keeps the balance consistent across
chapters. It also ends on the biggest jump in balance, and the demo-only buy
credit has no later chapter to contradict it.

---

## 1. `Starter-wallet-demo.mp4`: two phones, one wallet each

**The story:** the left phone creates a new wallet. The right phone imports an
existing one that holds $98.90. Then the right phone sends 1 USDT to the left
phone without paying gas, and both balances update.

| In → Out | Phone | What happens | Edit | Sensitive |
|---|---|---|---|---|
| 0:00–0:05 | both | Welcome on both phones: "Self-custodial. Multi-chain. Your keys, your coins." | keep 2–3 s | |
| 0:05–0:08 | L | Zoom: tap **Create New Wallet** | keep | |
| 0:08–0:11 | L | Reveal Recovery Phrase (motion blur) | keep | |
| 0:11–0:19 | L | **The 12 recovery words, fully readable**, then "Copy to clipboard" → "Copied", then **I Have Saved My Phrase** | 1.5× | **BLUR the words from 0:09 to 0:20** |
| 0:20–0:37 | L | Create a password (step 3 of 4), type twice, Continue | 3× | dots only, OK |
| 0:38–0:41 | L | "Backup your wallet to the cloud" | keep | |
| 0:41–0:44 | L | Zoom: choose the cloud provider, **Google Drive / iCloud** | keep (hero) | |
| 0:45–0:47 | L | Backup To Cloud | keep | |
| 0:48–0:53 | L | Home: $0.00, tokens BTC (Testnet), USDT (Sepolia), USDT0 (Arbitrum), USDT (Polygon) | keep 3 s | |
| 0:54–0:56 | R | Import: "Enter recovery phrase", choice of 12 or 24 words | keep | |
| 0:56–0:59 | R | Words pasted in, **already shown as orange bars in the recording** | keep | check every frame for a flash of real words |
| 0:59–1:08 | R | Create a password | 3× | |
| 1:09–1:13 | R | Cloud backup: "I Prefer To Backup Manually" | 2× | |
| 1:14–1:18 | R | Home: **$98.90** (99 USDT on Sepolia) | keep (hero) | |
| 1:18–1:26 | L | **Receive**: BTC (Testnet) QR, then switch to USDT on Ethereum (Sepolia), then copy the address | keep | full address and QR are visible (testnet, so this is fine) |
| 1:27–1:33 | R | Send, then "Send USDT": paste the address, amount screen | 1.5× | |
| 1:33–1:39 | R | Amount 1 USDT, then Review | keep | |
| 1:39–1:44 | R | Zoom on Review: **Network fee: Free, "gasless · sponsored"**, Total 1 USDT, then Confirm | keep (hero) | |
| 1:45–1:50 | R | **Sent**: "1 USDT was sent on Ethereum (Sepolia)", tx hash, **View on Etherscan** | keep | |
| 1:51–1:59 | both | Zoom on the token list; the left phone still shows $0.00 | cut or 3× | |
| 2:00–2:01 | both | **Left $1.00 · Right $97.90** | hold 2 s (hero) | |

## 2. `starter_swaps_bridge.mp4`: one same-chain swap, then one cross-chain bridge

| In → Out | What happens | Edit | Note |
|---|---|---|---|
| 0:00–0:08 | Unlock: "Welcome back", enter password, Unlock Wallet | 3× or 2 s | can illustrate "app lock" |
| 0:09–0:14 | Home **$19.18**: Send · Swap · Receive · Earn · Buy; BTC, USDT (Eth), USDT0 (Arb), POL, USDT (Polygon), USDT (Solana) | keep, tap Swap | |
| 0:15–0:26 | Swap: Sell POL → Buy USDT (Polygon), token picker, type **50**, Get Quote | 2× | |
| 0:27–0:30 | **Quote: 4.420441 USDT.** "Route: Symbiosis (best of compared quotes)" · Minimum received 4.376236 USDT · "Unavailable: Rhino.fi does not support this destination chain" | keep (hero) | real figures for the quote-race graphic |
| 0:30–0:32 | Provider list: Automatic · LI.FI · Symbiosis · 0x · Rhino.fi | keep | |
| 0:33–0:40 | Swap, then "Swap submitted", provider Symbiosis, **View on Polygonscan** | 1.5× | |
| 0:42–0:51 | Home: **POL 56.25 → 5.80 · USDT Polygon 11.97 → 16.39**, total $19.15 | keep the update | |
| 0:54–0:57 | Token list close-up | cut | |
| 0:57–1:12 | Bridge setup: Sell USDT (**Polygon**) → Buy USDT (**Ethereum**), amount **15**, Get Quote | 2× | |
| 1:15–1:20 | **Quote: 14.943675 USDT.** "Route: LI.FI (best of compared quotes)" · "Unavailable: 0x: 0x only swaps on one chain" · provider list open | keep (hero) | |
| 1:21–1:29 | Submitting…, then "Swap submitted", View on Polygonscan, then Back to Wallet | 2× | |
| 1:30–1:39 | Home: **USDT Ethereum 0.27 → 15.21 · USDT Polygon 16.39 → 1.39** | keep (hero) | |

## 3. `starter_earn.mp4`: Morpho vaults on Ethereum mainnet

| In → Out | What happens | Edit | Note |
|---|---|---|---|
| 0:00–0:03 | Home $19.08, tap Earn | keep 2 s | |
| 0:03–0:05 | "Loading positions…" | 4× | |
| 0:06–0:11 | Three cards: **sky.money USDT Savings, APY 3.03%** (0.100004 USDT) · **USDT Risk Capital, APY 1.72%** · **Borrow against XAUt** (0 XAUt). Footer: "Borrowing is available once you have XAUt collateral." | keep (hero) | |
| 0:12–0:20 | Savings vault: type **2**, tap Deposit | 1.5× | |
| 0:21–0:24 | Confirmation: "Deposit 2 USDT into sky.money USDT Savings. **Approvals are sent first if needed. Gas is sponsored.**" Confirm / Cancel | keep (hero) | |
| 0:24–0:33 | Submitting, then "Submitted" with the tx hash | 2× | |
| 0:36–0:38 | Earn list: deposit now **2.100004 USDT** | keep | |
| 0:39–0:44 | Withdraw **1**: confirmation "Withdraw 1 USDT from sky.money USDT Savings" | keep | |
| 0:45–0:53 | Submitting, then Submitted | 2× | |
| 0:54–0:56 | Back on the list, **still showing 2.100004** (not refreshed yet) | cut | don't claim the balance dropped |
| 0:57–1:03 | "Borrow against XAUt": Collateral 0 XAUt, Borrowed 0 USDT, Deposit XAUt Collateral | keep 3 s | **no borrow is performed**; narrate it as an available feature |

## 4. `starter_pay.mp4`: buy USDT through Transak (staging)

| In → Out | What happens | Edit | Note |
|---|---|---|---|
| 0:00–0:03 | Home $19.08, tap Buy | keep 2 s | |
| 0:03–0:08 | "Buy USDT": choose currency (**EUR / USD**, USD picked), network Ethereum · Arbitrum · Polygon | keep | |
| 0:08–0:14 | Amount **50 USD**, Get Quote | 2× | |
| 0:15–0:19 | Quote: "You receive about **46.65 USDT**", fee 3.35 USD, Continue to Transak | keep (hero) | |
| 0:20–0:32 | **global-stg.transak.com**, blank page loading | cut or 8× | |
| 0:33–0:46 | Transak "Confirm your order": Buying 46.65 USDT for 50 USD · VISA ****6245 · to wallet 0x38a996…daC91110 · Ethereum · 1–3 minutes, then Confirm order | 1.5× | staging test card; blur is optional |
| 0:46–0:56 | Visa Secure spinner | 8× | |
| 0:57–0:59 | "Crypto is on the way" | keep | |
| 1:00–1:09 | Order: Payment received → Sending crypto; details (fee 3.35 USD, Processing) | 2× | |
| 1:10–1:17 | Back in the app: **$65.69, USDT Ethereum 15.21 → 61.86** | keep (hero) | **demo-only credit kept in memory**; must carry a "Staging · demo credit" tag |

## Sensitive items

| What | Where | What to do |
|---|---|---|
| Recovery phrase (12 words) | wallet 0:09–0:20 | **Must blur**: a mask over the word grid on the zoomed and un-zoomed frames, following the zoom |
| Imported phrase | wallet 0:56–0:59 | Already redacted (orange bars). Check every frame |
| Wallet addresses, tx hashes, QR codes | all files | Public on-chain data, so they can stay. Blur them if you'd rather not tie these addresses to you |
| VISA ****6245 | pay 0:33–0:46 | Staging test card. Blur optional |
| Passwords | wallet, swap unlock | Only dots appear. OK |

## Runtime budget

| Part | Edited length |
|---|---|
| Open, intro, architecture | ~0:30 |
| Wallet | ~0:55 |
| Swap & bridge | ~0:45 |
| Earn | ~0:30 |
| Buy | ~0:27 |
| Outro | ~0:15 |
| **Total** | **~3:20** |

To reach about 2:30, drop the import-password and receive-BTC beats in the
wallet chapter, and the unlock and token-picker beats in the swap chapter.
