// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PDSBatches.sol";

abstract contract PDSProcurement is PDSBatches {
    event ProcurementValidated(uint256 indexed batchId, address indexed procurement, uint256 declaredQtyKg, uint256 pricePerKgPaise);
    event ProcurementPurchased(uint256 indexed batchId);

    function validateForProcurement(uint256 batchId, uint256 declaredQtyKg, uint256 pricePerKgPaise)
        external
        onlyRole(Role.PROCUREMENT)
    {
        Batch storage b = batches[batchId];
        require(b.farmer != address(0) && b.state == BatchState.CREATED, "state");
        require(declaredQtyKg > 0, "qty");

        purchases[batchId] = Purchase({
            batchId: batchId,
            procurement: msg.sender,
            declaredQtyKg: declaredQtyKg,
            pricePerKgPaise: pricePerKgPaise,
            validated: true,
            purchased: false
        });

        b.procurement = msg.sender;
        b.state = BatchState.PROCUREMENT_VALIDATED;

        emit ProcurementValidated(batchId, msg.sender, declaredQtyKg, pricePerKgPaise);
    }

    function purchaseGrain(uint256 batchId) external onlyRole(Role.PROCUREMENT) {
        Batch storage b = batches[batchId];
        Purchase storage p = purchases[batchId];
        require(b.state == BatchState.PROCUREMENT_VALIDATED, "state");
        require(p.validated && p.procurement == msg.sender, "purchase");
        p.purchased = true;
        b.state = BatchState.PROCUREMENT_PURCHASED;
        emit ProcurementPurchased(batchId);
    }
}