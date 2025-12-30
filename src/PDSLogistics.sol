// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PDSAudit.sol";

abstract contract PDSLogistics is PDSAudit {
    event DistributorReleaseRequested(uint256 indexed batchId, address indexed distributor, uint256 qtyKg);
    event WarehouseReleaseApproved(uint256 indexed batchId);
    event DispatchedToDistributor(uint256 indexed batchId, address indexed shipper, uint256 qtyKg);
    event DistributorReceived(uint256 indexed batchId, uint256 receivedQtyKg);
    event DistributorVerified(uint256 indexed batchId);

    event FPSReleaseRequested(uint256 indexed batchId, address indexed fps, uint256 qtyKg);
    event FPSReleaseApproved(uint256 indexed batchId);
    event DispatchedToFPS(uint256 indexed batchId, address indexed shipper, uint256 qtyKg);
    event FPSReceived(uint256 indexed batchId, uint256 receivedQtyKg);
    event FPSVerified(uint256 indexed batchId);

    event BatchClosed(uint256 indexed batchId);

    function requestReleaseToDistributor(uint256 batchId, uint256 qtyKg) external onlyRole(Role.DISTRIBUTOR) {
        Batch storage b = batches[batchId];
        require(b.state == BatchState.WAREHOUSE_STORED, "state");
        require(qtyKg > 0 && qtyKg <= b.quantityKg, "qty");

        ReleaseRequest storage r = distRequests[batchId];
        require(!r.exists, "exists");

        distRequests[batchId] = ReleaseRequest({
            batchId: batchId,
            requester: msg.sender,
            fromAddr: b.warehouse,
            toAddr: msg.sender,
            qtyKg: qtyKg,
            exists: true,
            approved: false
        });

        b.distributor = msg.sender;
        b.state = BatchState.RELEASE_REQUESTED_TO_DISTRIBUTOR;

        emit DistributorReleaseRequested(batchId, msg.sender, qtyKg);
    }

    function approveReleaseToDistributor(uint256 batchId) external onlyRole(Role.WAREHOUSE) {
        Batch storage b = batches[batchId];
        ReleaseRequest storage r = distRequests[batchId];
        require(b.warehouse == msg.sender, "warehouse");
        require(b.state == BatchState.RELEASE_REQUESTED_TO_DISTRIBUTOR, "state");
        require(r.exists && !r.approved, "req");

        r.approved = true;
        b.state = BatchState.RELEASE_APPROVED;

        emit WarehouseReleaseApproved(batchId);
    }

    function dispatchToDistributor(uint256 batchId) external onlyRole(Role.SHIPPER) {
        Batch storage b = batches[batchId];
        ReleaseRequest storage r = distRequests[batchId];
        Shipment storage s = distShipments[batchId];

        require(b.state == BatchState.RELEASE_APPROVED, "state");
        require(r.exists && r.approved, "req");
        require(!s.pickedUp && !s.delivered, "shipped");

        distShipments[batchId] = Shipment({
            batchId: batchId,
            shipper: msg.sender,
            fromAddr: r.fromAddr,
            toAddr: r.toAddr,
            qtyKg: r.qtyKg,
            pickedUp: true,
            delivered: false
        });

        b.shipperDist = msg.sender;
        b.state = BatchState.DISPATCHED_TO_DISTRIBUTOR;

        emit DispatchedToDistributor(batchId, msg.sender, r.qtyKg);
    }

    function confirmDistributorReceipt(uint256 batchId, uint256 receivedQtyKg) external onlyRole(Role.DISTRIBUTOR) {
        Batch storage b = batches[batchId];
        Shipment storage s = distShipments[batchId];
        require(b.distributor == msg.sender, "dist");
        require(b.state == BatchState.DISPATCHED_TO_DISTRIBUTOR, "state");
        require(s.pickedUp && !s.delivered && s.toAddr == msg.sender, "ship");
        require(receivedQtyKg == s.qtyKg && receivedQtyKg > 0, "qty");

        s.delivered = true;
        b.state = BatchState.DISTRIBUTOR_RECEIVED;

        emit DistributorReceived(batchId, receivedQtyKg);
    }

    function verifyAtDistributor(uint256 batchId) external onlyRole(Role.DISTRIBUTOR) {
        Batch storage b = batches[batchId];
        require(b.distributor == msg.sender, "dist");
        require(b.state == BatchState.DISTRIBUTOR_RECEIVED, "state");
        b.state = BatchState.DISTRIBUTOR_VERIFIED;
        emit DistributorVerified(batchId);
    }

    function requestReleaseToFPS(uint256 batchId, uint256 qtyKg) external onlyRole(Role.FAIR_PRICE_SHOP) {
        Batch storage b = batches[batchId];
        require(b.state == BatchState.DISTRIBUTOR_VERIFIED, "state");
        require(qtyKg > 0 && qtyKg <= b.quantityKg, "qty");

        ReleaseRequest storage r = fpsRequests[batchId];
        require(!r.exists, "exists");

        fpsRequests[batchId] = ReleaseRequest({
            batchId: batchId,
            requester: msg.sender,
            fromAddr: b.distributor,
            toAddr: msg.sender,
            qtyKg: qtyKg,
            exists: true,
            approved: false
        });

        b.shop = msg.sender;
        b.state = BatchState.FPS_RELEASE_REQUESTED;

        emit FPSReleaseRequested(batchId, msg.sender, qtyKg);
    }

    function approveReleaseToFPS(uint256 batchId) external onlyRole(Role.DISTRIBUTOR) {
        Batch storage b = batches[batchId];
        ReleaseRequest storage r = fpsRequests[batchId];
        require(b.distributor == msg.sender, "dist");
        require(b.state == BatchState.FPS_RELEASE_REQUESTED, "state");
        require(r.exists && !r.approved, "req");

        r.approved = true;
        b.state = BatchState.FPS_RELEASE_APPROVED;

        emit FPSReleaseApproved(batchId);
    }

    function dispatchToFPS(uint256 batchId) external onlyRole(Role.SHIPPER) {
        Batch storage b = batches[batchId];
        ReleaseRequest storage r = fpsRequests[batchId];
        Shipment storage s = fpsShipments[batchId];

        require(b.state == BatchState.FPS_RELEASE_APPROVED, "state");
        require(r.exists && r.approved, "req");
        require(!s.pickedUp && !s.delivered, "shipped");

        fpsShipments[batchId] = Shipment({
            batchId: batchId,
            shipper: msg.sender,
            fromAddr: r.fromAddr,
            toAddr: r.toAddr,
            qtyKg: r.qtyKg,
            pickedUp: true,
            delivered: false
        });

        b.shipperFps = msg.sender;
        b.state = BatchState.DISPATCHED_TO_FPS;

        emit DispatchedToFPS(batchId, msg.sender, r.qtyKg);
    }

    function confirmFPSReceipt(uint256 batchId, uint256 receivedQtyKg) external onlyRole(Role.FAIR_PRICE_SHOP) {
        Batch storage b = batches[batchId];
        Shipment storage s = fpsShipments[batchId];
        require(b.shop == msg.sender, "fps");
        require(b.state == BatchState.DISPATCHED_TO_FPS, "state");
        require(s.pickedUp && !s.delivered && s.toAddr == msg.sender, "ship");
        require(receivedQtyKg == s.qtyKg && receivedQtyKg > 0, "qty");

        s.delivered = true;
        b.state = BatchState.FPS_RECEIVED;

        emit FPSReceived(batchId, receivedQtyKg);
    }

    function verifyAtFPS(uint256 batchId) external onlyRole(Role.FAIR_PRICE_SHOP) {
        Batch storage b = batches[batchId];
        require(b.shop == msg.sender, "fps");
        require(b.state == BatchState.FPS_RECEIVED, "state");
        b.state = BatchState.FPS_VERIFIED;
        emit FPSVerified(batchId);
    }

    function closeBatch(uint256 batchId) external onlyRole(Role.FAIR_PRICE_SHOP) {
        Batch storage b = batches[batchId];
        require(b.shop == msg.sender, "fps");
        require(b.state == BatchState.FPS_VERIFIED, "state");
        b.state = BatchState.BATCH_CLOSED;
        emit BatchClosed(batchId);
    }
}