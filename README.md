# FHE Speeding Check (Zama FHEVM)

A privacy-preserving speed compliance checker powered by **Zama FHEVM**.
Both **speed** and **limit** are encrypted on the client, sent to the contract, and only a single **flag** is returned:

* `1` → **Over the limit**
* `0` → **Within limit**

No raw numbers are revealed on-chain. The frontend renders an original, horizontal speedometer UI that visualizes your current inputs; the contract logic remains private.

---

## ✨ Features

* **Fully homomorphic flow**: speed & limit are encrypted; contract computes `speed > limit` privately.
* **Two result modes**:

  * **Private**: result decryptable only by the caller (`userDecrypt` with EIP‑712 signing).
  * **Public**: result is globally decryptable (`publicDecrypt`).
* **Original UI**: horizontal gauge with live needle, red limit marker & red danger area beyond limit.
* **Auto-scaling**: gauge adapts (60/80/100…/300+) so both speed and limit fit nicely.
* **Verbose console logs**: all important steps tagged as `[UI/n]` (encryption, tx, events, decryption, gauge updates).
* **No deprecated libs**: uses only the official **`@zama-fhe/relayer-sdk`** (CDN) and the on‑chain FHEVM primitives.

---

## 🧠 Smart Contract (Deployed)

* **Network**: Sepolia
* **Address**: `0x23Ffbaf9AcF0808E74Ecc75DdCBc151f073f1c43`
* **Interface (excerpt)**

  * `checkSpeed(bytes32 speedExt, bytes32 limitExt, bytes proof)` → `bytes32 overCt`
  * `checkSpeedPublic(bytes32 speedExt, bytes32 limitExt, bytes proof)` → `bytes32 overCt`
  * `event SpeedChecked(address user, bytes32 resultHandle, bool isPublic)`

> Inputs are `euint16`; output is `ebool` (1/0). Only the flag is revealed (privately or publicly).

---

## 📁 Project Layout

```
frontend/
  public/
    index.html   ← open this (served via a static server)
```

No build step is strictly required; `index.html` loads the Relayer SDK and ethers via CDN.

---

## ⚙️ Requirements

* **Node.js** ≥ 18 (for running a local static server)
* **Git** (optional, to clone the repo)
* **MetaMask** in your browser
* **Sepolia ETH** on your wallet for tx gas

---

## 🚀 Installation & Run (Local)

### Option A — Quick serve (recommended)

```bash
# From the repo root
npx serve frontend/public -p 5173 --cors
# then open http://localhost:5173
```

Alternative static servers:

```bash
npx http-server frontend/public -p 5173 --cors
# or
python3 -m http.server 5173 -d frontend/public
```

> The page includes COOP/COEP headers in meta; hosting via a local HTTP server avoids cross‑origin isolation issues.

### Option B — GitHub Pages

Host `/frontend/public` as your site root (or copy `index.html` into the Pages root). No build needed.

---

## 🔧 Configuration

Open `frontend/public/index.html` and adjust the constants if needed:

```js
const CONTRACT_ADDRESS = "0x23Ffbaf9AcF0808E74Ecc75DdCBc151f073f1c43";
const KMS_ADDRESS      = "0x1364cBBf2cDF5032C47d8226a6f6FBD2AFCDacAC"; // Sepolia KMS
const RELAYER_URL      = "https://relayer.testnet.zama.cloud";
const GATEWAY_URL      = "https://gateway.sepolia.zama.ai/";
```

Other network guards (Sepolia chain id) and ABI are already in place.

---

## 🕹️ Usage

1. **Start** a static server and open the app.
2. Click **Connect Wallet**. The app auto-guards the Sepolia network.
3. Enter **Speed** and **Limit** integers (0–65535).
4. (Optional) Toggle **Publish result**:

   * ON → anyone can decrypt (uses `checkSpeedPublic`).
   * OFF → only you can decrypt (uses `checkSpeed` + `userDecrypt`).
5. Click **Check Speed**. Watch the console for `[UI/n]` logs.
6. Use **Last Result** to re-decrypt the most recent handle.

> The gauge is purely visual for your inputs; only the 1/0 result leaves the browser as FHE ciphertext.

---

## 🧱 Tech Stack

* **Solidity** + **Zama FHEVM** (contract side)
* **Relayer SDK**: `@zama-fhe/relayer-sdk` (CDN: `0.1.2`)
* **ethers v6** for JSON‑RPC
* Plain **HTML/CSS/JS**, no build tooling required

---

## 🛡️ Security & Privacy Notes

* Inputs are encrypted client‑side; the contract receives only ciphertexts.
* The contract computes `speed > limit` and returns an **encrypted** boolean.
* Choose between **public** vs **private** decryption paths.
* No plaintext speed/limit or counts are stored on‑chain.

---

## 🧩 Troubleshooting

* **MetaMask not found** → install MetaMask and refresh.
* **Wrong network** → the app prompts Sepolia; confirm the switch.
* **`KMS contract not found`** → verify `KMS_ADDRESS` for Sepolia.
* **`Result handle not found in logs`** → ensure the deployed address & ABI match your contract.
* **`SDK add16 not available`** → use Relayer SDK `>= 0.1.2`.
* **COOP/COEP / Mixed content warnings** → run via a **local HTTP server**, not `file://`.

---

## 📝 License

MIT — feel free to use and adapt. Please keep the attribution to Zama FHEVM where appropriate.

---
