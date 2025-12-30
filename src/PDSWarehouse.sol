// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PDSProcurement.sol";

abstract contract PDSWarehouse is PDSProcurement {
    event DispatchToWarehouse(uint256 indexed batchId, address indexed warehouse, uint256 declaredQtyKg);
    event WarehouseReceived(uint256 indexed batchId, uint256 receivedQtyKg);
    event WarehouseStored(uint256 indexed batchId);

    function dispatchToWarehouse(uint256 batchId, address warehouse, uint256 declaredQtyKg)
        external
        onlyRole(Role.PROCUREMENT)
        onlyActive(warehouse)
    {
        require(entities[warehouse].role == Role.WAREHOUSE, "warehouse");
        Batch storage b = batches[batchId];
        require(b.procurement == msg.sender && b.state == BatchState.PROCUREMENT_PURCHASED, "state");
        require(declaredQtyKg > 0, "qty");

        inbounds[batchId] = Inbound({
            batchId: batchId,
            procurement: msg.sender,
            warehouse: warehouse,
            declaredQtyKg: declaredQtyKg,
            receivedQtyKg: 0,
            dispatched: true,
            received: false
        });

        b.warehouse = warehouse;
        b.state = BatchState.IN_TRANSIT_TO_WAREHOUSE;

        emit DispatchToWarehouse(batchId, warehouse, declaredQtyKg);
    }

    function receiveAtWarehouse(uint256 batchId, uint256 receivedQtyKg) external onlyRole(Role.WAREHOUSE) {
        Batch storage b = batches[batchId];
        Inbound storage i = inbounds[batchId];
        require(b.warehouse == msg.sender && b.state == BatchState.IN_TRANSIT_TO_WAREHOUSE, "state");
        require(i.dispatched && i.warehouse == msg.sender, "inbound");
        require(receivedQtyKg > 0, "qty");

        i.receivedQtyKg = receivedQtyKg;
        i.received = true;

        b.quantityKg = receivedQtyKg;
        b.state = BatchState.WAREHOUSE_RECEIVED;

        emit WarehouseReceived(batchId, receivedQtyKg);
    }

    function markStored(uint256 batchId) external onlyRole(Role.WAREHOUSE) {
        Batch storage b = batches[batchId];
        require(b.warehouse == msg.sender && b.state == BatchState.QUALITY_PASSED, "state");
        b.state = BatchState.WAREHOUSE_STORED;
        emit WarehouseStored(batchId);
    }
}