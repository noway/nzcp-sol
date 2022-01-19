pragma solidity ^0.8.11;

import "hardhat/console.sol";
import "./EllipticCurve.sol";

// NZCP implementation in Solidity
// - Verifies NZCP pass and returns credential subject.
// - Reverts transaction if pass is invalid.
// - To save gas, the full pass URI is not passed into the contract, but merely the ToBeSignedBuffer.
contract NZCP is EllipticCurve {

    // CBOR types
    // TODO: make a macro
    uint private constant MAJOR_TYPE_INT = 0;
    uint private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint private constant MAJOR_TYPE_BYTES = 2;
    uint private constant MAJOR_TYPE_STRING = 3;
    uint private constant MAJOR_TYPE_ARRAY = 4;
    uint private constant MAJOR_TYPE_MAP = 5;
    uint private constant MAJOR_TYPE_TAG = 6;
    uint private constant MAJOR_TYPE_CONTENT_FREE = 7;

    // "key-1" public key published here:
    // https://nzcp.covid19.health.nz/.well-known/did.json
    // Doesn't suppose to change unless MoH leaks their private key
    uint256 public constant EXAMPLE_X = 0xCD147E5C6B02A75D95BDB82E8B80C3E8EE9CAA685F3EE5CC862D4EC4F97CEFAD;
    uint256 public constant EXAMPLE_Y = 0x22FE5253A16E5BE4D1621E7F18EAC995C57F82917F1A9150842383F0B4A4DD3D;

    // "z12Kf7UQ" public key published here:
    // https://nzcp.identity.health.nz/.well-known/did.json
    // Doesn't suppose to change unless MoH leaks their private key
    uint256 public constant LIVE_X = 0x0D008A26EB2A32C4F4BBB0A3A66863546907967DC0DDF4BE6B2787E0DBB9DAD7;
    uint256 public constant LIVE_Y = 0x971816CEC2ED548F1FA999933CFA3D9D9FA4CC6B3BC3B5CEF3EAD453AF0EC662;

    // 27 bytes to skip the ["Signature1", headers, buffer0] start of ToBeSignedBuffer
    // And get to the CWT claims straight away
    uint private claims_skip = 27; // TODO: make a macro macro
    
    // Path to get to the credentialSubject map inside CWT claims
    string[] private credential_subject_path = ["vc", "credentialSubject"];

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
            uint8 value = uint8(buffer[pos]);
            pos++;
            return (pos, value);
        }
        // TODO: handle 25
        else if (x == 26) { // 32-bit
            uint32 value;
            value = uint32(uint8(buffer[pos])) << 24;
            pos++;
            value |= uint32(uint8(buffer[pos])) << 16;
            pos++;
            value |= uint32(uint8(buffer[pos])) << 8;
            pos++;
            value |= uint32(uint8(buffer[pos]));
            pos++;
            return (pos, value);
        }
        else {
            require(false, "x is not in supported range");
        }
    }

    function decodeString(bytes memory buffer, uint pos, uint len) private pure returns (uint, string memory) {
        string memory str = new string(len);

        uint strptr;
        // 32 is the length of the string header
        assembly { strptr := add(str, 32) }
        
        // 32 is the length of the string header
        uint skip = 32 + pos;
        uint bufferptr;
        assembly { bufferptr := add(buffer, skip) }

        memcpy(strptr, bufferptr, len);

        return (pos + len, str);
    }

    function skipCBORValue(bytes memory buffer, uint pos) private view returns (uint) {
        uint v;
        uint cbortype;
        (pos, cbortype, v) = readType(buffer, pos);
        // TODO: remove unused branches

        if (cbortype == MAJOR_TYPE_INT) {
            uint value;
            (pos, value) = decodeCBORUint(buffer, pos, v);
            return pos;
        }
        else if (cbortype == MAJOR_TYPE_NEGATIVE_INT) {
            uint value;
            (pos, value) = decodeCBORUint(buffer, pos, v);
            value = ~value; // TODO: not neccessary
            return pos;
        }
        else if (cbortype == MAJOR_TYPE_BYTES) {
            uint len;
            (pos, len) = decodeCBORUint(buffer, pos, v);
            pos += len;
            return pos;
        }
        else if (cbortype == MAJOR_TYPE_STRING) {
            uint len;
            (pos, len) = decodeCBORUint(buffer, pos, v);
            pos += len;
            return pos;
        }
        else if (cbortype == MAJOR_TYPE_ARRAY) {
            uint len;
            (pos, len) = decodeCBORUint(buffer, pos, v);
            for (uint i = 0; i < len; i++) {
                pos = skipCBORValue(buffer, pos);
            }
            return pos;
        }
        else if (cbortype == MAJOR_TYPE_MAP) {
            // TODO: not tested
            uint len;
            (pos, len) = decodeCBORUint(buffer, pos, v);
            for (uint i = 0; i < len; i++) {
                pos = skipCBORValue(buffer, pos);
                pos = skipCBORValue(buffer, pos);
            }
            return pos;
        }
        else {
            require(false, "this cbortype is not supported");
        }
    }

    // TODO: make a macro
    function readType(bytes memory buffer, uint pos) private pure returns (uint, uint, uint) {
        uint v = uint8(buffer[pos]);
        pos++;
        uint cbortype = v >> 5;
        return (pos, cbortype, v);
    }

    function readStringValue(bytes memory buffer, uint pos) private pure returns (uint, string memory) {
        uint v;
        uint cbortype;
        (pos, cbortype, v) = readType(buffer, pos);
        require(cbortype == MAJOR_TYPE_STRING, "cbortype expected to be string");
        uint value_len;
        (pos, value_len) = decodeCBORUint(buffer, pos, v);
        return decodeString(buffer, pos, value_len);
    }

    function readMapLength(bytes memory buffer, uint pos) private pure returns (uint, uint) {
        uint v;
        uint cbortype;
        (pos, cbortype, v) = readType(buffer, pos);
        require(cbortype == MAJOR_TYPE_MAP, "cbortype expected to be map");
        uint maplen;
        (pos, maplen) = decodeCBORUint(buffer, pos, v);
        return (pos, maplen);
    }

    // Recursively searches the position of credential subject in the CWT claims
    // Side effects: reverts transaction if pass is expired.
    function findCredentialSubject(bytes memory buffer, uint pos, uint needle_pos) private view returns (uint) {
        uint maplen;
        (pos, maplen) = readMapLength(buffer, pos);

        for (uint i = 0; i < maplen; i++) {
            uint v;
            uint cbortype;
            (pos, cbortype, v) = readType(buffer, pos);

            if (cbortype == MAJOR_TYPE_INT) {
                uint key;
                (pos, key) = decodeCBORUint(buffer, pos, v);
                if (key == 4) {
                    uint v2;
                    uint cbor_type2;
                    (pos, cbor_type2, v2) = readType(buffer, pos);
                    require(cbor_type2 == MAJOR_TYPE_INT, "cbortype expected to be integer");

                    uint exp;
                    (pos, exp) = decodeCBORUint(buffer, pos, v2);
                    require(block.timestamp < exp, "Pass expired"); // check if pass expired
                }
                // We do not check for whether pass is active, since we assume
                // That New Zealand Ministry of Health only issues active passes
                else {
                    pos = skipCBORValue(buffer, pos); // skip value
                }
            }
            else if (cbortype == MAJOR_TYPE_STRING) {
                uint strlen;
                (pos, strlen) = decodeCBORUint(buffer, pos, v);

                string memory key;
                (pos, key) = decodeString(buffer, pos, strlen);
                if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked(credential_subject_path[needle_pos]))) {
                    if (needle_pos + 1 >= credential_subject_path.length) { // TODO: macro
                        return pos;
                    }
                    else {
                        return findCredentialSubject(buffer, pos, needle_pos + 1);
                    }
                }
                else {
                    pos = skipCBORValue(buffer, pos); // skip value
                }
            }
            else {
                require(false, "map key is of an supported type");
            }
        }
    }

    function readCredentialSubject(bytes memory buffer, uint pos) private view returns (string memory, string memory, string memory) {
        uint maplen;
        (pos, maplen) = readMapLength(buffer, pos);

        string memory givenName;
        string memory familyName;
        string memory dob;

        for (uint i = 0; i < maplen; i++) {
            uint v;
            uint cbortype;
            (pos, cbortype, v) = readType(buffer, pos);
            if (cbortype == MAJOR_TYPE_STRING) {
                uint strlen;
                (pos, strlen) = decodeCBORUint(buffer, pos, v);

                string memory key;
                (pos, key) = decodeString(buffer, pos, strlen);

                if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("givenName"))) {
                    (pos, givenName) = readStringValue(buffer, pos);
                }
                else if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("familyName"))) {
                    (pos, familyName) = readStringValue(buffer, pos);
                }
                else if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("dob"))) {
                    (pos, dob) = readStringValue(buffer, pos);
                }
                else {
                    pos = skipCBORValue(buffer, pos); // skip value
                }
            }
            else {
                require(false, "map key is of an supported type");
            }
        }
        return (givenName, familyName, dob);
    }


    // Verifies NZCP message hash signature
    // Returns true if signature is valid, reverts transaction otherwise
    function verifySignature(bytes32 messageHash, uint256[2] memory rs, bool is_example) public pure returns (bool) {
        if (is_example) {
            require(validateSignature(messageHash, rs, [EXAMPLE_X, EXAMPLE_Y]), "Invalid signature");
            return true;
        }
        else {
            require(validateSignature(messageHash, rs, [LIVE_X, LIVE_Y]),  "Invalid signature");
            return true;
        }
    }

    // Verifies NZCP ToBeSignedBuffer
    // Returns true if signature is valid, reverts transaction otherwise
    function verifyToBeSignedBuffer(bytes memory buffer, uint256[2] memory rs, bool is_example) public pure returns (bool) {
        return verifySignature(sha256(buffer), rs, is_example);
    }

    // Parses ToBeSignedBuffer and returns the credential subject
    // Returns credential subject if pass is valid, reverts transaction otherwise
    function parseAndVerifyToBeSignedBuffer(bytes memory buffer, uint256[2] memory rs, bool is_example) public view 
        returns (string memory, string memory, string memory) {

        uint credentialSubjectPos = findCredentialSubject(buffer, claims_skip, 0);

        (string memory givenName, string memory familyName, string memory dob) = readCredentialSubject(buffer, credentialSubjectPos);

        verifyToBeSignedBuffer(buffer, rs, is_example);

        return (givenName, familyName, dob);
    }
}
