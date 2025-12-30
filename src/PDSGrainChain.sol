// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PDSLogistics.sol";

contract PDSGrainChain is PDSLogistics {
    constructor() { owner = msg.sender; }
}