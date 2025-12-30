// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PDSState.sol";
import "../src/PDSGrainChain.sol";

contract GasLifecycleTest is Test {
    PDSGrainChain c;

    address owner = address(this);
    address farmer = address(0x1);
    address procurement = address(0x2);
    address warehouse = address(0x3);
    address auditor = address(0x4);
    address distributor = address(0x5);
    address shipper = address(0x6);
    address fps = address(0x7);

    function setUp() public {
        c = new PDSGrainChain();

        c.registerEntity(farmer, PDSState.Role.FARMER);
        c.registerEntity(procurement, PDSState.Role.PROCUREMENT);
        c.registerEntity(warehouse, PDSState.Role.WAREHOUSE);
        c.registerEntity(auditor, PDSState.Role.AUDITOR);
        c.registerEntity(distributor, PDSState.Role.DISTRIBUTOR);
        c.registerEntity(shipper, PDSState.Role.SHIPPER);
        c.registerEntity(fps, PDSState.Role.FAIR_PRICE_SHOP);
    }

    function test_gas_end_to_end_lifecycle() public {
        uint256 id;

        vm.prank(farmer);
        id = c.createBatch("Wheat", 1735084800, 1000);

        vm.prank(procurement);
        c.validateForProcurement(id, 1000, 2500);

        vm.prank(procurement);
        c.purchaseGrain(id);

        vm.prank(procurement);
        c.dispatchToWarehouse(id, warehouse, 1000);

        vm.prank(warehouse);
        c.receiveAtWarehouse(id, 995);

        vm.prank(auditor);
        c.qualityCheck(id, 87, true);

        vm.prank(warehouse);
        c.markStored(id);

        vm.prank(distributor);
        c.requestReleaseToDistributor(id, 995);

        vm.prank(warehouse);
        c.approveReleaseToDistributor(id);

        vm.prank(shipper);
        c.dispatchToDistributor(id);

        vm.prank(distributor);
        c.confirmDistributorReceipt(id, 995);

        vm.prank(distributor);
        c.verifyAtDistributor(id);

        vm.prank(fps);
        c.requestReleaseToFPS(id, 995);

        vm.prank(distributor);
        c.approveReleaseToFPS(id);

        vm.prank(shipper);
        c.dispatchToFPS(id);

        vm.prank(fps);
        c.confirmFPSReceipt(id, 995);

        vm.prank(fps);
        c.verifyAtFPS(id);

        vm.prank(fps);
        c.closeBatch(id);
    }
}