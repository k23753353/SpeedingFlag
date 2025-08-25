// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, ebool, euint8, euint16, externalEuint16 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/**
 * @title FHEWeightTrend
 * @notice Personal "weight tracker without weight".
 *         Stores only encrypted weight per user (euint16).
 *         On submit compares with previous and returns encrypted trend:
 *         0 = ↓, 1 = → (incl. first submit), 2 = ↑.
 */
contract FHEWeightTrend is SepoliaConfig {
    function version() external pure returns (string memory) {
        return "FHEWeightTrend/1.0.1-sepolia";
    }

    event WeightSubmitted(address indexed user, bytes32 trendHandle);

    mapping(address => euint16) private _lastWeight;
    mapping(address => bool)    private _hasWeight;

    function submitWeight(
        externalEuint16 weightExt,
        bytes calldata proof
    ) external returns (euint8 trendCt) {
        require(proof.length > 0, "Empty proof");

        euint16 newW = FHE.fromExternal(weightExt, proof);

        euint8 trend;
        if (_hasWeight[msg.sender]) {
            euint16 oldW = _lastWeight[msg.sender];

            ebool isUp   = FHE.gt(newW, oldW);
            ebool isSame = FHE.eq(newW, oldW);

            // 0=DOWN, 1=SAME, 2=UP
            euint8 downCode = FHE.asEuint8(0);
            euint8 sameCode = FHE.asEuint8(1);
            euint8 upCode   = FHE.asEuint8(2);

            // trend = isSame ? 1 : (isUp ? 2 : 0)
            euint8 upOrDown = FHE.select(isUp, upCode, downCode);
            trend = FHE.select(isSame, sameCode, upOrDown);
        } else {
            trend = FHE.asEuint8(1); // first submit → "→"
            _hasWeight[msg.sender] = true;
        }

        _lastWeight[msg.sender] = newW;
        FHE.allowThis(newW);         // контракт переиспользует в будущих tx
        FHE.allow(newW, msg.sender); // юзер сможет userDecrypt(...)

        FHE.allow(trend, msg.sender);       // юзер может userDecrypt(...)
        FHE.makePubliclyDecryptable(trend); // для publicDecrypt(...) на фронте

        emit WeightSubmitted(msg.sender, FHE.toBytes32(trend));
        return trend;
    }

    function hasWeight(address user) external view returns (bool) {
        return _hasWeight[user];
    }

    function getMyWeightHandle() external view returns (bytes32) {
        if (!_hasWeight[msg.sender]) return bytes32(0);
        return FHE.toBytes32(_lastWeight[msg.sender]);
    }

    function makeMyWeightPublic() external {
        require(_hasWeight[msg.sender], "No weight");
        FHE.makePubliclyDecryptable(_lastWeight[msg.sender]);
    }
}
