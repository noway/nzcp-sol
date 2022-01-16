pragma solidity ^0.7.0;

import "hardhat/console.sol";

contract NZCP {
    string private greeting;

    string public constant x = "zRR-XGsCp12Vvbgui4DD6O6cqmhfPuXMhi1OxPl8760";
    string public constant y = "Iv5SU6FuW-TRYh5_GOrJlcV_gpF_GpFQhCOD8LSk3T0";

    // constructor(string memory _greeting) {
    //     console.log("Deploying a NZCP with greeting:", _greeting);
    //     greeting = _greeting;
    // }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }

    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function verifyGreeting(string memory _greeting) public view returns (bool) {
        return compareStrings(greeting, _greeting);
    }
    
    // TODO: get v from signature
    function verifySignature(bytes32 messageHash, bytes32 r, bytes32 s, uint8 v) public view returns (bool) {
        address signer = ecrecover(messageHash, v, r, s);
        console.log("Signer:", signer);
        return true;
        // return compareStrings(greeting, _greeting);
    }
}
