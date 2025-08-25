# FHE Weight Trend (Zama FHEVM)

A minimal, privacy-first **“weight tracker without the weight”** built on **Zama’s FHEVM**. Each user submits their weight as an encrypted `euint16`. The contract stores only the encrypted current weight and returns an **encrypted trend** when a new value is submitted:

* `0` = **DOWN** (↓)
* `1` = **SAME** (→, also used for the first submission)
* `2` = **UP** (↑)

No raw weights are revealed on-chain. The trend result is made **publicly decryptable** for a simple UI.

---

## ✨ Features

* **Fully homomorphic flow** using `@fhevm/solidity` (official Zama library only)
* Private storage of the user’s current weight (`euint16`)
* On submit: encrypted comparison with previous weight → public trend (0/1/2)
* Optional functions to let a user decrypt their own current weight (via EIP‑712)
* Clean, CDN-only frontend using **Zama Relayer SDK** + **ethers v6**

---

## 🧱 Tech Stack

* **Solidity** (`@fhevm/solidity`) — encrypted types and FHE operations
* **Zama Relayer SDK** (browser, via CDN) — encryption, EIP‑712 user decryption, public decryption
* **ethers v6** — contract calls
* **Hardhat** (contracts) — compile/deploy
* Network: **Sepolia**

---

## ⚙️ Smart Contract

Contract: `FHEWeightTrend` (Sepolia)

```txt
Address: 0xfbe76c2f2944e73816f23947961a0cbc610bf386
KMS:     0x1364cBBf2cDF5032C47d8226a6f6FBD2AFCDacAC
```

### Key storage & logic

* `mapping(address => euint16) _lastWeight;`
* `mapping(address => bool) _hasWeight;`
* On `submitWeight(...)`, the contract compares the new encrypted value to the stored one and emits the trend as ciphertext (publicly decryptable).

### Public interface

* `submitWeight(externalEuint16 weightExt, bytes proof) returns (euint8)` — returns encrypted trend; emits `WeightSubmitted(address user, bytes32 trendHandle)`.
* `hasWeight(address user) view returns (bool)` — whether the user has ever submitted a weight.
* `getMyWeightHandle() view returns (bytes32)` — your current weight ciphertext handle (for private decryption via Relayer SDK).
* `makeMyWeightPublic()` — opt‑in to public decryption of your current weight.

> **FHE rules** followed: no FHE ops in view/pure; proper ACL via `FHE.allowThis`, `FHE.allow`, and public trend via `FHE.makePubliclyDecryptable`.

---

## 🖥️ Frontend

* Single-page static app (no build needed) under:

```
frontend/public/index.html
```

* Uses CDN scripts:

  * `https://cdn.zama.ai/relayer-sdk-js/0.1.2/relayer-sdk-js.js`
  * `https://cdn.jsdelivr.net/npm/ethers@6.15.0/+esm`

### Hard‑coded frontend constants

Inside `frontend/public/index.html` you’ll see these constants — adjust if you redeploy:

```js
const CONTRACT_ADDRESS = "0xfbe76c2f2944e73816f23947961a0cbc610bf386";
const KMS_ADDRESS      = "0x1364cBBf2cDF5032C47d8226a6f6FBD2AFCDacAC";
const RELAYER_URL      = "https://relayer.testnet.zama.cloud";
const GATEWAY_URL      = "https://gateway.sepolia.zama.ai/";
```

> The page is served with `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` via meta tags; open it over `http(s)://`, not via `file://`.

---

## 🚀 Getting Started

### Prerequisites

* Node.js 18+ (for running a dev static server)
* A browser wallet (MetaMask)
* Sepolia ETH for gas

### Quick run (static hosting)

Use any static server to serve `frontend/public`:

```bash
# from repo root
npx serve frontend/public -l 5173
# or
npx http-server frontend/public -p 5173 --cors
# or
python3 -m http.server 5173 --directory frontend/public
```

Open: `http://localhost:5173` and:

1. **Connect Wallet** (the app will switch to Sepolia).
2. Enter an **integer weight** (`0..65535`).
3. Click **Submit & Compare** → read the **Trend** (↓ / → / ↑).

---

## 🔐 Relayer SDK Notes (frontend)

* Encryption: `relayer.createEncryptedInput(CONTRACT_ADDRESS, user).add16(weight)` → `{ handles, inputProof }`.
* Submit: `contract.submitWeight(handles[0], inputProof)`.
* Trend decryption (public): `relayer.publicDecrypt([trendHandle])` → `0|1|2`.
* (Optional) Private decryption of your weight: `relayer.userDecrypt(...)` with EIP‑712 signature.

**Do not** use deprecated/unsupported packages (e.g. `@fhevm-js/relayer`).

---

## 📁 Repo Structure

```
├─ contracts/
│  └─ FHEWeightTrend.sol
├─ frontend/
│  └─ public/
│     └─ index.html  # CDN-only SPA
├─ hardhat.config.ts (or .js)
└─ README.md
```

---

## 🧪 Local Contract (optional)

If you want to develop the contract yourself:

```bash
npm i
npx hardhat compile
# deploy to Sepolia with your script, then update CONTRACT_ADDRESS in index.html
```

> Remember: keep using only `@fhevm/solidity/lib/FHE.sol` and configure network via `SepoliaConfig`.


## 📝 License

MIT — feel free to use and adapt.

