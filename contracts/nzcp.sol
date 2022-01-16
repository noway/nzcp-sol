pragma solidity ^0.8.11;

import "hardhat/console.sol";
import "./EllipticCurve.sol";

contract NZCP is EllipticCurve {
    string private greeting;

    string public constant x = "zRR-XGsCp12Vvbgui4DD6O6cqmhfPuXMhi1OxPl8760";
    string public constant y = "Iv5SU6FuW-TRYh5_GOrJlcV_gpF_GpFQhCOD8LSk3T0";

    constructor(string memory _greeting) {
        console.log("Deploying a NZCP with greeting:", _greeting);
        greeting = _greeting;
    }

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
    
    function verifySignature(bytes32 message, uint[2] memory rs, uint[2] memory Q) public view returns (bool) {
        bool isValid = validateSignature(message, rs, Q);
        return isValid;
    }
}
