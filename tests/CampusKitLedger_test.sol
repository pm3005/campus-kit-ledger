// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Run this file in Remix's Solidity Unit Testing plugin.
import "remix_tests.sol";
import "../contracts/CampusKitLedger.sol";

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

contract CampusKitLedgerTest {
    CampusKitLedger private ledger;
    StudentWallet private student;

    function beforeEach() public {
        ledger = new CampusKitLedger(); // This test contract is the custodian.
        student = new StudentWallet();
        ledger.addItem("Camera tripod");
    }

    function testValidCheckoutAndReturn() public {
        student.request(ledger, 0);
        CampusKitLedger.Item memory item = ledger.getItem(0);
        assert(item.status == CampusKitLedger.Status.Requested);
        assert(item.requester == address(student));

        ledger.approveRequest(0);
        item = ledger.getItem(0);
        assert(item.status == CampusKitLedger.Status.Borrowed);
        assert(item.borrower == address(student));

        ledger.markReturned(0);
        item = ledger.getItem(0);
        assert(item.status == CampusKitLedger.Status.Available);
        assert(item.borrower == address(0));
        assert(ledger.itemCount() == 1);
    }

    function testInvalidEmptyName() public {
        try ledger.addItem("") {
            assert(false);
        } catch {
            assert(ledger.itemCount() == 1);
        }
    }

    function testInvalidRepeatedRequest() public {
        student.request(ledger, 0);
        try ledger.requestItem(0) {
            assert(false);
        } catch {
            CampusKitLedger.Item memory item = ledger.getItem(0);
            assert(item.status == CampusKitLedger.Status.Requested);
        }
    }

    function testInvalidItemId() public {
        try student.request(ledger, 99) {
            assert(false);
        } catch {
            assert(ledger.itemCount() == 1);
        }
    }

    function testUnauthorizedAdd() public {
        try student.add(ledger, "Laptop") {
            assert(false);
        } catch {
            assert(ledger.itemCount() == 1);
        }
    }

    function testUnauthorizedApproval() public {
        student.request(ledger, 0);
        try student.approve(ledger, 0) {
            assert(false);
        } catch {
            CampusKitLedger.Item memory item = ledger.getItem(0);
            assert(item.status == CampusKitLedger.Status.Requested);
        }
    }

    function testUnauthorizedReturn() public {
        student.request(ledger, 0);
        ledger.approveRequest(0);
        try student.markReturned(ledger, 0) {
            assert(false);
        } catch {
            CampusKitLedger.Item memory item = ledger.getItem(0);
            assert(item.status == CampusKitLedger.Status.Borrowed);
        }
    }
}
