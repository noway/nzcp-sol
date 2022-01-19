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


    string[] private needles = ["vc", "credentialSubject"];

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

    function decodeCBORUint(bytes memory buffer, uint pos, uint v) private pure returns (uint, uint) {
        uint x = v & 31;
        if (x <= 23) {
            return (pos, x);
        }
        else if (x == 24) {
            uint value = uint8(buffer[pos]);
            pos++;
            return (pos, value);
        }
        // TODO: handle 25
        else if (x == 26) { // 32-bit
            uint32 value;
            value = uint8(buffer[pos]) << 24;
            pos++;
            value |= uint8(buffer[pos]) << 16;
            pos++;
            value |= uint8(buffer[pos]) << 8;
            pos++;
            value |= uint8(buffer[pos]);
            pos++;
            return (pos, value);
        }
        else {
            // console.log("x is not in supported range", x);
            require(false, "x is not in supported range");
        }
    }
    function decodeString(bytes memory buffer, uint pos, uint len) private pure returns (uint, string memory) {
        string memory str = new string(len);

        uint strptr;
        assembly { strptr := add(str, 32) }
        
        uint skip = 32 + pos;
        uint bufferptr;
        assembly { bufferptr := add(buffer, skip) }

        memcpy(strptr, bufferptr, len);

        return (pos + len, str);
    }

    function skipCBORValue(bytes memory buffer, uint pos) private view returns (uint) {
        uint v;
        uint cbor_type;
        (pos, cbor_type, v) = readType(buffer, pos);

        if (cbor_type == MAJOR_TYPE_INT) {
            uint value;
            (pos, value) = decodeCBORUint(buffer, pos, v);
            // console.log("skipping MAJOR_TYPE_INT", value);
            return pos;
        }
        else if (cbor_type == MAJOR_TYPE_NEGATIVE_INT) {
            // console.log("skipping MAJOR_TYPE_NEGATIVE_INT");
            uint value;
            (pos, value) = decodeCBORUint(buffer, pos, v);
            value = ~value;
            return pos;
        }
        else if (cbor_type == MAJOR_TYPE_BYTES) {
            // console.log("skipping MAJOR_TYPE_BYTES");
            uint len;
            (pos, len) = decodeCBORUint(buffer, pos, v);
            pos += len;
            return pos;
        }
        else if (cbor_type == MAJOR_TYPE_STRING) {
            // console.log("skipping MAJOR_TYPE_STRING");
            uint len;
            (pos, len) = decodeCBORUint(buffer, pos, v);
            // console.log("string len", len);
            pos += len;
            return pos;
        }
        else if (cbor_type == MAJOR_TYPE_ARRAY) {
            // console.log("skipping MAJOR_TYPE_ARRAY");
            uint len;
            (pos, len) = decodeCBORUint(buffer, pos, v);
            // console.log("array len", len);
            for (uint i = 0; i < len; i++) {
                pos = skipCBORValue(buffer, pos);
            }
            return pos;
        }
        else if (cbor_type == MAJOR_TYPE_MAP) {
            // TODO: not tested
            // console.log("skipping MAJOR_TYPE_MAP");
            uint len;
            (pos, len) = decodeCBORUint(buffer, pos, v);
            // console.log("map len", len);
            for (uint i = 0; i < len; i++) {
                pos = skipCBORValue(buffer, pos);
                pos = skipCBORValue(buffer, pos);
            }
            return pos;
        }
        else {
            require(false, "this cbor_type is not supported");
        }
    }

    // TODO: a macro
    function readType(bytes memory buffer, uint pos) private pure returns (uint, uint, uint) {
        uint v = uint8(buffer[pos]);
        pos++;
        uint cbor_type = v >> 5;
        return (pos, cbor_type, v);
    }

    function readStringValue(bytes memory buffer, uint pos) private pure returns (uint, string memory) {
        uint v;
        uint cbor_type;
        (pos, cbor_type, v) = readType(buffer, pos);
        require(cbor_type == MAJOR_TYPE_STRING, "cbor_type expected to be string");
        uint value_len;
        (pos, value_len) = decodeCBORUint(buffer, pos, v);
        return decodeString(buffer, pos, value_len);
    }

    function readMapLength(bytes memory buffer, uint pos) private pure returns (uint, uint) {
        uint v;
        uint cbor_type;
        (pos, cbor_type, v) = readType(buffer, pos);
        require(cbor_type == MAJOR_TYPE_MAP, "cbor_type expected to be map");
        uint map_len;
        (pos, map_len) = decodeCBORUint(buffer, pos, v);
        return (pos, map_len);
    }

    function searchCBORTree(bytes memory buffer, uint pos, uint needle_pos) private view returns (uint) {
        uint map_len;
        (pos, map_len) = readMapLength(buffer, pos);

        for (uint256 i = 0; i < map_len; i++) {
            uint v;
            uint cbor_type;
            (pos, cbor_type, v) = readType(buffer, pos);

            if (cbor_type == MAJOR_TYPE_INT) {
                uint int_key;
                (pos, int_key) = decodeCBORUint(buffer, pos, v);
                // console.log("got int key!!", int_key);
                pos = skipCBORValue(buffer, pos); // skip value
            }
            else if (cbor_type == MAJOR_TYPE_STRING) {
                uint len;
                (pos, len) = decodeCBORUint(buffer, pos, v);

                string memory key;
                (pos, key) = decodeString(buffer, pos, len);
                // console.log("got to string!!", key);
                if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked(needles[needle_pos]))) {
                    if (needle_pos + 1 >= needles.length) { // TODO: macro
                        // console.log("found all needles");
                        return pos;
                    }
                    else {
                        // console.log("about to parse:", needles[needle_pos]);
                        return searchCBORTree(buffer, pos, needle_pos + 1);
                    }
                }
                else {
                    // console.log("skipping string key", key);
                    pos = skipCBORValue(buffer, pos); // skip value
                }
            }
            else {
                require(false, "map key is of an supported type");
            }
        }
    }

    function decodeCredentialSubject(bytes memory buffer, uint pos) public view returns (string memory, string memory, string memory) {
        uint map_len;
        (pos, map_len) = readMapLength(buffer, pos);

        string memory givenName;
        string memory familyName;
        string memory dob;

        for (uint256 i = 0; i < map_len; i++) {
            uint v;
            uint cbor_type;
            (pos, cbor_type, v) = readType(buffer, pos);
            if (cbor_type == MAJOR_TYPE_STRING) {
                uint len;
                (pos, len) = decodeCBORUint(buffer, pos, v);

                string memory key;
                (pos, key) = decodeString(buffer, pos, len);
                // console.log("got to string!!", key);

                if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("givenName"))) {
                    // console.log("found givenName");
                    (pos, givenName) = readStringValue(buffer, pos);
                }
                else if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("familyName"))) {
                    // console.log("found familyName");
                    (pos, familyName) = readStringValue(buffer, pos);
                }
                else if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("dob"))) {
                    // console.log("found dob");                    
                    (pos, dob) = readStringValue(buffer, pos);
                }
                else {
                    // console.log("skipping string key", key);
                    pos = skipCBORValue(buffer, pos); // skip value
                }
            }
            else {
                require(false, "map key is of an supported type");
            }
        }
        return (givenName, familyName, dob);
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
        return verifySignature(sha256(buffer), rs, is_example);
    }

    function parseToBeSignedBuffer(bytes memory buffer, uint[2] memory rs, bool is_example) public view returns (bool) {

        uint skip = 27; // 27 bytes for ["Signature1", headers, buffer0] // TODO: macro

        uint credentialSubjectPos = searchCBORTree(buffer, skip, 0);

        string memory givenName;
        string memory familyName;
        string memory dob;
        (givenName, familyName, dob) = decodeCredentialSubject(buffer, credentialSubjectPos);

        console.log("givenName:", givenName);
        console.log("familyName:", familyName);
        console.log("dob:", dob);


        return verifyToBeSignedBuffer(buffer, rs, is_example);
    }
}
