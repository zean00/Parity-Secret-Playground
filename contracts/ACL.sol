pragma solidity ^0.4.11;

contract SSPermissions {

    mapping(address => bool) authorized;
    
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier _isOwner() {
        require(msg.sender == owner);
        _;
    } 

    // TODO: add document specific check
    function checkPermissions(address user, bytes32 document) public returns (bool) {
        return authorized[user];
    }

    function addAuth(address user) public _isOwner {
        authorized[user] = true;
    }

    function removeAuth(address user) public _isOwner {
        authorized[user] = false;
    }
}
