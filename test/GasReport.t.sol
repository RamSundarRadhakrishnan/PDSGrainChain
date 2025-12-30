// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PDSState.sol";
import "../src/PDSGrainChain.sol";

contract GasStatsTest is Test {
    function _runOne(PDSGrainChain c,
        address farmer, address procurement, address warehouse, address auditor,
        address distributor, address shipper, address fps
    ) internal {
        uint256 id;

        vm.prank(farmer); id = c.createBatch("Wheat", 1735084800, 1000);
        vm.prank(procurement); c.validateForProcurement(id, 1000, 2500);
        vm.prank(procurement); c.purchaseGrain(id);
        vm.prank(procurement); c.dispatchToWarehouse(id, warehouse, 1000);
        vm.prank(warehouse); c.receiveAtWarehouse(id, 995);
        vm.prank(auditor); c.qualityCheck(id, 87, true);
        vm.prank(warehouse); c.markStored(id);
        vm.prank(distributor); c.requestReleaseToDistributor(id, 995);
        vm.prank(warehouse); c.approveReleaseToDistributor(id);
        vm.prank(shipper); c.dispatchToDistributor(id);
        vm.prank(distributor); c.confirmDistributorReceipt(id, 995);
        vm.prank(distributor); c.verifyAtDistributor(id);
        vm.prank(fps); c.requestReleaseToFPS(id, 995);
        vm.prank(distributor); c.approveReleaseToFPS(id);
        vm.prank(shipper); c.dispatchToFPS(id);
        vm.prank(fps); c.confirmFPSReceipt(id, 995);
        vm.prank(fps); c.verifyAtFPS(id);
        vm.prank(fps); c.closeBatch(id);
    }

    function test_gas_stats_20_runs() public {
        uint256 N = 20;
        uint256[] memory totals = new uint256[](N);

        address farmer = address(0x1);
        address procurement = address(0x2);
        address warehouse = address(0x3);
        address auditor = address(0x4);
        address distributor = address(0x5);
        address shipper = address(0x6);
        address fps = address(0x7);

        for (uint256 k=0; k<N; k++) {
            PDSGrainChain c = new PDSGrainChain();
            c.registerEntity(farmer, PDSState.Role.FARMER);
            c.registerEntity(procurement, PDSState.Role.PROCUREMENT);
            c.registerEntity(warehouse, PDSState.Role.WAREHOUSE);
            c.registerEntity(auditor, PDSState.Role.AUDITOR);
            c.registerEntity(distributor, PDSState.Role.DISTRIBUTOR);
            c.registerEntity(shipper, PDSState.Role.SHIPPER);
            c.registerEntity(fps, PDSState.Role.FAIR_PRICE_SHOP);

            uint256 g0 = gasleft();
            _runOne(c, farmer, procurement, warehouse, auditor, distributor, shipper, fps);
            uint256 g1 = gasleft();

            totals[k] = g0 - g1;
        }

        // sort
        for (uint256 i=0; i<N; i++) {
            for (uint256 j=i+1; j<N; j++) {
                if (totals[j] < totals[i]) {
                    (totals[i], totals[j]) = (totals[j], totals[i]);
                }
            }
        }

        uint256 median = totals[N/2];
        uint256 p90 = totals[(N*90 + 99)/100 - 1]; // ceil(0.9N)-1

        emit log_named_uint("median_total_gas", median);
        emit log_named_uint("p90_total_gas", p90);
    }
}