// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Campus Kit Ledger
/// @notice A simple public record of equipment requests and checkouts.
contract CampusKitLedger {
    address public immutable custodian;

    enum Status { Available, Requested, Borrowed }

    struct Item {
        string name;
        Status status;
        address requester;
        address borrower;
    }

    Item[] private items;

    event ItemAdded(uint256 indexed itemId, string name);
    event ItemRequested(uint256 indexed itemId, address indexed student);
    event RequestApproved(uint256 indexed itemId, address indexed student);
    event ItemReturned(uint256 indexed itemId, address indexed student);

    modifier onlyCustodian() {
        require(msg.sender == custodian, "Only custodian");
        _;
    }

    constructor() {
        custodian = msg.sender;
    }

    function itemCount() external view returns (uint256) {
        return items.length;
    }

    function getItem(uint256 itemId) external view returns (Item memory) {
        require(itemId < items.length, "Item does not exist");
        return items[itemId];
    }

    function addItem(string calldata name) external onlyCustodian {
        require(bytes(name).length > 0 && bytes(name).length <= 64, "Name must be 1-64 bytes");
        uint256 itemId = items.length;
        items.push(Item(name, Status.Available, address(0), address(0)));
        emit ItemAdded(itemId, name);
    }

    function requestItem(uint256 itemId) external {
        require(itemId < items.length, "Item does not exist");
        Item storage item = items[itemId];
        require(item.status == Status.Available, "Item is not available");
        item.status = Status.Requested;
        item.requester = msg.sender;
        emit ItemRequested(itemId, msg.sender);
    }

    function approveRequest(uint256 itemId) external onlyCustodian {
        require(itemId < items.length, "Item does not exist");
        Item storage item = items[itemId];
        require(item.status == Status.Requested, "No pending request");
        item.borrower = item.requester;
        item.requester = address(0);
        item.status = Status.Borrowed;
        emit RequestApproved(itemId, item.borrower);
    }

    /// @notice The custodian records a physical return after receiving the item.
    function markReturned(uint256 itemId) external onlyCustodian {
        require(itemId < items.length, "Item does not exist");
        Item storage item = items[itemId];
        require(item.status == Status.Borrowed, "Item is not borrowed");
        address previousBorrower = item.borrower;
        item.borrower = address(0);
        item.status = Status.Available;
        emit ItemReturned(itemId, previousBorrower);
    }
}
