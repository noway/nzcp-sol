pragma solidity ^0.8.11;

import "hardhat/console.sol";
import "./EllipticCurve.sol";

contract NZCP is EllipticCurve {
    string private greeting;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;


    uint public constant EXAMPLE_X = 0xCD147E5C6B02A75D95BDB82E8B80C3E8EE9CAA685F3EE5CC862D4EC4F97CEFAD;
    uint public constant EXAMPLE_Y = 0x22FE5253A16E5BE4D1621E7F18EAC995C57F82917F1A9150842383F0B4A4DD3D;

    uint public constant LIVE_X = 0x0D008A26EB2A32C4F4BBB0A3A66863546907967DC0DDF4BE6B2787E0DBB9DAD7;
    uint public constant LIVE_Y = 0x971816CEC2ED548F1FA999933CFA3D9D9FA4CC6B3BC3B5CEF3EAD453AF0EC662;

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function decodeUint(bytes memory buffer, uint pos, uint v) private pure returns (uint, uint) {
        uint x = v & 31;
        // require(x <= 23); // only "small" uints are implemented
        if (x <= 23) {
            return (pos, x);
        }
        else if (x == 24) {
            pos++;
            return (pos, uint8(buffer[pos]));
        }
        else {
            require(false, "x is not in supported range");
        }
    }

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

    function parseToBeSignedBuffer(bytes memory buffer, uint[2] memory rs, bool is_example) public view returns (bool) {

        bytes memory claims = new bytes(buffer.length);
        uint claimsptr;
        assembly { claimsptr := add(claims, 32) }

        uint bufferptr;
        uint skip = 32 + 27; // buffer start + 27 bytes for ["Signature1", headers, buffer0]
        assembly { bufferptr := add(buffer, skip) }
        

        memcpy(claimsptr, bufferptr, buffer.length);


        uint current_pos = 0;

        uint v = uint8(claims[current_pos]);
        uint cbor_type = v >> 5;
        require(cbor_type == MAJOR_TYPE_MAP);
        uint x;
        (current_pos, x) = decodeUint(buffer, current_pos, v);
        require(x == 5); // only 5 map elements allowed; TODO: change?

        current_pos++;

        uint v1 = uint8(claims[current_pos]);
        uint cbor_type1 = v1 >> 5;
        require(cbor_type1 == MAJOR_TYPE_INT); // int
        uint key;
        (current_pos, key) = decodeUint(buffer, current_pos, v1);
        require(key == 1); // TODO: object key order shouldn't matter

        current_pos++;

        uint v2 = uint8(claims[current_pos]);
        uint cbor_type2 = v2 >> 5;
        require(cbor_type2 == MAJOR_TYPE_STRING); // string
        uint length = v & 31;
        console.log(length);


        


        // bytes32 messageHash = sha256(buffer);

        // bytes32 claims;
        // assembly {
        //     claims := mload(add(buffer, 27))
        // }

        // console.log(claims);

        // return verifyToBeSignedBuffer(buffer, rs, is_example);
        return true;
    }
}
