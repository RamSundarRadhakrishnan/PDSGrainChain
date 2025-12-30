// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract PDSState {
    enum Role { NONE, FARMER, PROCUREMENT, WAREHOUSE, AUDITOR, DISTRIBUTOR, SHIPPER, FAIR_PRICE_SHOP }

    enum BatchState {
        CREATED,
        PROCUREMENT_VALIDATED,
        PROCUREMENT_PURCHASED,
        IN_TRANSIT_TO_WAREHOUSE,
        WAREHOUSE_RECEIVED,
        QUALITY_PASSED,
        QUALITY_FAILED,
        WAREHOUSE_STORED,
        RELEASE_REQUESTED_TO_DISTRIBUTOR,
        RELEASE_APPROVED,
        DISPATCHED_TO_DISTRIBUTOR,
        DISTRIBUTOR_RECEIVED,
        DISTRIBUTOR_VERIFIED,
        FPS_RELEASE_REQUESTED,
        FPS_RELEASE_APPROVED,
        DISPATCHED_TO_FPS,
        FPS_RECEIVED,
        FPS_VERIFIED,
        BATCH_CLOSED
    }

    struct Entity { Role role; bool active; }

    struct Batch {
        uint256 id;
        string crop;
        uint256 harvestDate;
        address farmer;
        address procurement;
        address warehouse;
        address auditor;
        address distributor;
        address shipperDist;
        address shipperFps;
        address shop;
        uint256 quantityKg;
        uint256 qualityScore;
        bool qualityPass;
        BatchState state;
    }

    struct Purchase {
        uint256 batchId;
        address procurement;
        uint256 declaredQtyKg;
        uint256 pricePerKgPaise;
        bool validated;
        bool purchased;
    }

    struct Inbound {
        uint256 batchId;
        address procurement;
        address warehouse;
        uint256 declaredQtyKg;
        uint256 receivedQtyKg;
        bool dispatched;
        bool received;
    }

    struct ReleaseRequest {
        uint256 batchId;
        address requester;
        address fromAddr;
        address toAddr;
        uint256 qtyKg;
        bool exists;
        bool approved;
    }

    struct Shipment {
        uint256 batchId;
        address shipper;
        address fromAddr;
        address toAddr;
        uint256 qtyKg;
        bool pickedUp;
        bool delivered;
    }

    address public owner;
    uint256 internal nextBatchId = 1;

    mapping(address => Entity) public entities;
    mapping(uint256 => Batch) public batches;
    mapping(uint256 => Purchase) public purchases;
    mapping(uint256 => Inbound) public inbounds;

    mapping(uint256 => ReleaseRequest) public distRequests;
    mapping(uint256 => ReleaseRequest) public fpsRequests;

    mapping(uint256 => Shipment) public distShipments;
    mapping(uint256 => Shipment) public fpsShipments;
}