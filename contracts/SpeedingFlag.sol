// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/* ✅ Only official Zama FHE library */
import { FHE, ebool, euint16, externalEuint16 } from "@fhevm/solidity/lib/FHE.sol";
/* ✅ Sepolia config — on-chain addresses for KMS/Oracle/ACL */
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/**
 * @title SpeedingFlag
 * @notice Private speeding check:
 *         - Inputs: encrypted speed and encrypted limit (same units).
 *         - Output: encrypted flag (1=over limit, 0=ok).
 *         - No counters or logs of plaintext values; nothing else revealed.
 *
 * Frontend:
 *   • Use Relayer SDK `createEncryptedInput(...)` to produce external handles + `proof`.
 *   • Call `checkSpeed(...)` to get a private result (caller-only `userDecrypt`).
 *   • Or call `checkSpeedPublic(...)` to mark the result publicly decryptable.
 *
 * Units:
 *   • Choose any integer unit consistently (e.g., km/h or mph, scaled if needed).
 *   • Type here is euint16 (0..65535). Increase to euint32 if you need larger ranges.
 */
contract SpeedingFlag is SepoliaConfig {
    /* ───────────────────────── Events ───────────────────────── */
    /// @dev Emitted on each check; carries only ciphertext handle(s).
    event SpeedChecked(address indexed user, bytes32 resultHandle, bool isPublic);

    function version() external pure returns (string memory) {
        return "SpeedingFlag/1.0.0-sepolia";
    }

    /**
     * @notice Private result (caller can decrypt via Relayer `userDecrypt`).
     * @param speedExt  encrypted speed (external handle)
     * @param limitExt  encrypted limit (external handle)
     * @param proof     integrity proof from Relayer SDK
     * @return overCt   ebool ciphertext: 1 = speed > limit, 0 = otherwise
     */
    function checkSpeed(
        externalEuint16 speedExt,
        externalEuint16 limitExt,
        bytes calldata proof
    ) external returns (ebool overCt) {
        require(proof.length > 0, "Empty proof");

        // Deserialize external encrypted inputs (attestation verified inside)
        euint16 speed = FHE.fromExternal(speedExt, proof);
        euint16 limit = FHE.fromExternal(limitExt, proof);

        // over = (speed > limit)
        ebool over = FHE.gt(speed, limit);

        // ACL: only caller may decrypt the per-call result (keeps it private)
        FHE.allow(over, msg.sender);

        emit SpeedChecked(msg.sender, FHE.toBytes32(over), false);
        return over;
    }

    /**
     * @notice Same as `checkSpeed` but marks the result as publicly decryptable
     *         (anyone can read with `publicDecrypt`).
     */
    function checkSpeedPublic(
        externalEuint16 speedExt,
        externalEuint16 limitExt,
        bytes calldata proof
    ) external returns (ebool overCt) {
        require(proof.length > 0, "Empty proof");

        euint16 speed = FHE.fromExternal(speedExt, proof);
        euint16 limit = FHE.fromExternal(limitExt, proof);
        ebool over = FHE.gt(speed, limit);

        // Caller can decrypt privately as well (optional but convenient)
        FHE.allow(over, msg.sender);

        // Make globally decryptable (public flag only; inputs remain private)
        FHE.makePubliclyDecryptable(over);

        emit SpeedChecked(msg.sender, FHE.toBytes32(over), true);
        return over;
    }

    /**
     * @notice Convenience variant: accepts raw bytes32 external handles.
     *         Identical semantics to `checkSpeed`.
     */
    function checkSpeedRaw(
        bytes32 speedExtRaw,
        bytes32 limitExtRaw,
        bytes calldata proof
    ) external returns (ebool overCt) {
        require(speedExtRaw != bytes32(0) && limitExtRaw != bytes32(0), "Empty handle");
        require(proof.length > 0, "Empty proof");

        externalEuint16 speedExt = externalEuint16.wrap(speedExtRaw);
        externalEuint16 limitExt = externalEuint16.wrap(limitExtRaw);

        euint16 speed = FHE.fromExternal(speedExt, proof);
        euint16 limit = FHE.fromExternal(limitExt, proof);
        ebool over = FHE.gt(speed, limit);

        FHE.allow(over, msg.sender);

        emit SpeedChecked(msg.sender, FHE.toBytes32(over), false);
        return over;
    }
}
