// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PDSState.sol";

abstract contract PDSRoles is PDSState {
    event EntityRegistered(address indexed account, Role role);
    event EntityToggled(address indexed account, bool active);

    modifier onlyOwner() { require(msg.sender == owner, "owner"); _; }

    modifier onlyRole(Role r) {
        Entity memory e = entities[msg.sender];
        require(e.role == r && e.active, "role");
        _;
    }

    modifier onlyActive(address a) { require(entities[a].active, "inactive"); _; }

    function registerEntity(address account, Role role) external onlyOwner {
        require(role != Role.NONE, "role");
        entities[account] = Entity(role, true);
        emit EntityRegistered(account, role);
    }

    function toggleEntity(address account, bool active) external onlyOwner {
        require(entities[account].role != Role.NONE, "unknown");
        entities[account].active = active;
        emit EntityToggled(account, active);
    }
}