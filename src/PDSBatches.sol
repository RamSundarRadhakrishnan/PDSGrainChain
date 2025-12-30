// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PDSRoles.sol";

abstract contract PDSBatches is PDSRoles {
    event BatchCreated(uint256 indexed batchId, address indexed farmer, string crop, uint256 qtyKg);

    function createBatch(string calldata crop, uint256 harvestDate, uint256 qtyKg)
        external
        onlyRole(Role.FARMER)
        returns (uint256)
    {
        require(qtyKg > 0, "qty");
        uint256 id = nextBatchId++;

        batches[id] = Batch({
            id: id,
            crop: crop,
            harvestDate: harvestDate,
            farmer: msg.sender,
            procurement: address(0),
            warehouse: address(0),
            auditor: address(0),
            distributor: address(0),
            shipperDist: address(0),
            shipperFps: address(0),
            shop: address(0),
            quantityKg: qtyKg,
            qualityScore: 0,
            qualityPass: false,
            state: BatchState.CREATED
        });

        emit BatchCreated(id, msg.sender, crop, qtyKg);
        return id;
    }
}