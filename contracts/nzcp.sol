pragma solidity ^0.8.11;

import "hardhat/console.sol";
import "./EllipticCurve.sol";

contract NZCP is EllipticCurve {
    string private greeting;

    uint public constant EXAMPLE_X = 0xCD147E5C6B02A75D95BDB82E8B80C3E8EE9CAA685F3EE5CC862D4EC4F97CEFAD;
    uint public constant EXAMPLE_Y = 0x22FE5253A16E5BE4D1621E7F18EAC995C57F82917F1A9150842383F0B4A4DD3D;

    uint public constant LIVE_X = 0x0D008A26EB2A32C4F4BBB0A3A66863546907967DC0DDF4BE6B2787E0DBB9DAD7;
    uint public constant LIVE_Y = 0x971816CEC2ED548F1FA999933CFA3D9D9FA4CC6B3BC3B5CEF3EAD453AF0EC662;

    function verifySignature(bytes32 messageHash, uint[2] memory rs, bool is_example) public pure returns (bool) {
        if (is_example) {
            return validateSignature(messageHash, rs, [EXAMPLE_X, EXAMPLE_Y]);
        }
        else {
            return validateSignature(messageHash, rs, [LIVE_X, LIVE_Y]);
        }
    }

    function verifyToBeSignedBuffer(bytes memory buffer, uint[2] memory rs, bool is_example) public pure returns (bool) {
        bytes32 messageHash = sha256(buffer);
        return verifySignature(messageHash, rs, is_example);
    }
}
