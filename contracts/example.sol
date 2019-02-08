pragma solidity ^0.4.11;

contract SSPermissions {
    address alice = alicer;
    address bob = bobr;

  /// Both Alice and Bob can access any document
    function checkPermissions(address user, bytes32 document) constant returns (bool) {
        if (user == alice || user == bob) return true;
        return false;
    }
}
