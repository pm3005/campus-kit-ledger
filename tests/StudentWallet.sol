// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/CampusKitLedger.sol";

// Gives tests a second caller so access rules can be checked.
contract StudentWallet {
    function request(CampusKitLedger ledger, uint256 id) external {
        ledger.requestItem(id);
    }

    function add(CampusKitLedger ledger, string calldata name) external {
        ledger.addItem(name);
    }

    function approve(CampusKitLedger ledger, uint256 id) external {
        ledger.approveRequest(id);
    }

    function markReturned(CampusKitLedger ledger, uint256 id) external {
        ledger.markReturned(id);
    }
}
