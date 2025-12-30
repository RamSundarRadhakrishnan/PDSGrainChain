// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PDSWarehouse.sol";

abstract contract PDSAudit is PDSWarehouse {
    event QualityChecked(uint256 indexed batchId, address indexed auditor, uint256 qualityScore, bool pass_);

    function qualityCheck(uint256 batchId, uint256 qualityScore, bool pass_) external onlyRole(Role.AUDITOR) {
        Batch storage b = batches[batchId];
        Inbound storage i = inbounds[batchId];
        require(b.state == BatchState.WAREHOUSE_RECEIVED, "state");
        require(i.received && i.warehouse == b.warehouse, "inbound");

        b.auditor = msg.sender;
        b.qualityScore = qualityScore;
        b.qualityPass = pass_;

        if (pass_) b.state = BatchState.QUALITY_PASSED;
        else b.state = BatchState.QUALITY_FAILED;

        emit QualityChecked(batchId, msg.sender, qualityScore, pass_);
    }
}