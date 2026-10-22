// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Run this file in Remix's Solidity Unit Testing plugin.
import "remix_tests.sol";
import "../contracts/CampusKitLedger.sol";
import "./StudentWallet.sol";

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
        Assert.ok(item.status == CampusKitLedger.Status.Requested, "Request should set Requested status");
        Assert.ok(item.requester == address(student), "Requester should be the student");

        ledger.approveRequest(0);
        item = ledger.getItem(0);
        Assert.ok(item.status == CampusKitLedger.Status.Borrowed, "Approval should set Borrowed status");
        Assert.ok(item.borrower == address(student), "Borrower should be the student");

        ledger.markReturned(0);
        item = ledger.getItem(0);
        Assert.ok(item.status == CampusKitLedger.Status.Available, "Return should make item Available");
        Assert.ok(item.borrower == address(0), "Return should clear the borrower");
        Assert.ok(ledger.itemCount() == 1, "Item count should stay one");
    }

    function testInvalidEmptyName() public {
        try ledger.addItem("") {
            Assert.ok(false, "Empty item name should revert");
        } catch {
            Assert.ok(ledger.itemCount() == 1, "Invalid item should not be added");
        }
    }

    function testInvalidRepeatedRequest() public {
        student.request(ledger, 0);
        try ledger.requestItem(0) {
            Assert.ok(false, "Repeated request should revert");
        } catch {
            CampusKitLedger.Item memory item = ledger.getItem(0);
            Assert.ok(item.status == CampusKitLedger.Status.Requested, "Item should remain Requested");
        }
    }

    function testInvalidItemId() public {
        try student.request(ledger, 99) {
            Assert.ok(false, "Unknown item ID should revert");
        } catch {
            Assert.ok(ledger.itemCount() == 1, "Item count should stay one");
        }
    }

    function testUnauthorizedAdd() public {
        try student.add(ledger, "Laptop") {
            Assert.ok(false, "Student must not add an item");
        } catch {
            Assert.ok(ledger.itemCount() == 1, "Item count should stay one");
        }
    }

    function testUnauthorizedApproval() public {
        student.request(ledger, 0);
        try student.approve(ledger, 0) {
            Assert.ok(false, "Student must not approve a request");
        } catch {
            CampusKitLedger.Item memory item = ledger.getItem(0);
            Assert.ok(item.status == CampusKitLedger.Status.Requested, "Item should remain Requested");
        }
    }

    function testUnauthorizedReturn() public {
        student.request(ledger, 0);
        ledger.approveRequest(0);
        try student.markReturned(ledger, 0) {
            Assert.ok(false, "Student must not mark an item returned");
        } catch {
            CampusKitLedger.Item memory item = ledger.getItem(0);
            Assert.ok(item.status == CampusKitLedger.Status.Borrowed, "Item should remain Borrowed");
        }
    }
}
