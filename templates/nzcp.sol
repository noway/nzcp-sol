pragma solidity ^0.8.11;

import "hardhat/console.sol";
import "./EllipticCurve.sol";

// NZCP implementation in Solidity
// - Verifies NZCP pass and returns credential subject.
// - Reverts transaction if pass is invalid.
// - To save gas, the full pass URI is not passed into the contract, but merely the ToBeSigned.
// - ToBeSigned is defined in https://datatracker.ietf.org/doc/html/rfc8152#section-4.4 


// CBOR types
#define MAJOR_TYPE_INT 0
#define MAJOR_TYPE_NEGATIVE_INT 1
#define MAJOR_TYPE_BYTES 2
#define MAJOR_TYPE_STRING 3
#define MAJOR_TYPE_ARRAY 4
#define MAJOR_TYPE_MAP 5
#define MAJOR_TYPE_TAG 6
#define MAJOR_TYPE_CONTENT_FREE 7

// "key-1" public key published here:
// https://nzcp.covid19.health.nz/.well-known/did.json
// Does not suppose to change unless NZ MoH leaks their private key
#define EXAMPLE_X 0xCD147E5C6B02A75D95BDB82E8B80C3E8EE9CAA685F3EE5CC862D4EC4F97CEFAD
#define EXAMPLE_Y 0x22FE5253A16E5BE4D1621E7F18EAC995C57F82917F1A9150842383F0B4A4DD3D

// "z12Kf7UQ" public key published here:
// https://nzcp.identity.health.nz/.well-known/did.json
// Does not suppose to change unless NZ MoH leaks their private key
#define LIVE_X 0x0D008A26EB2A32C4F4BBB0A3A66863546907967DC0DDF4BE6B2787E0DBB9DAD7
#define LIVE_Y 0x971816CEC2ED548F1FA999933CFA3D9D9FA4CC6B3BC3B5CEF3EAD453AF0EC662

// 27 bytes to skip the ["Signature1", headers, buffer0] start of ToBeSigned
// And get to the CWT claims straight away
#define CLAIMS_SKIP 27

// keccak256(abi.encodePacked("vc"))
#define vc_KECCAK256 0x6ec613b793842434591077d5267660b73eca3bb163edb2574938d0a1b9fed380
// keccak256(abi.encodePacked("credentialSubject"))
#define credentialSubject_KECCAK256 0xf888b25396a7b641f052b4f483e19960c8cb98c3e8f094f00faf41fffd863fda

// keccak256(abi.encodePacked("givenName"))
#define givenName_KECCAK256 0xa3f2ad40900c663841a16aacd4bc622b021d6b2548767389f506dbe65673c3b9
// keccak256(abi.encodePacked("familyName"))
#define familyName_KECCAK256 0xd7aa1fd5ef0cc1f1e7ce8b149fdb61f373714ea1cc3ad47c597f4d3e554d10a4
// keccak256(abi.encodePacked("dob"))
#define dob_KECCAK256 0x635ec02f32ae461b745f21d9409955a9b5a660b486d30e7b5d4bfda4a75dec80

// Path to get to the credentialSubject map inside CWT claims
#define CREDENTIAL_SUBJECT_PATH [bytes32(vc_KECCAK256), bytes32(credentialSubject_KECCAK256)]

// CREDENTIAL_SUBJECT_PATH.length - 1
#define CREDENTIAL_SUBJECT_PATH_LENGTH_MINUS_1 1

error InvalidSignature();
error PassExpired();
error UnexpectedCBORType();
error UnsupportedCBORUint();

#define revert_if(a, b) if (a) revert b()

contract NZCP is EllipticCurve {

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
        if (x <= 23) {
            return (pos, x);
        }
        else if (x == 24) {
            uint8 value = uint8(buffer[pos++]);
            return (pos, value);
        }
        /*
        // Commented out to save gas
        else if (x == 25) { // 16-bit
            uint16 value;
            value = uint16(uint8(buffer[pos++])) << 8;
            value |= uint16(uint8(buffer[pos++]));
            return (pos, value);
        }
        */
        else if (x == 26) { // 32-bit
            uint32 value;
            value = uint32(uint8(buffer[pos++])) << 24;
            value |= uint32(uint8(buffer[pos++])) << 16;
            value |= uint32(uint8(buffer[pos++])) << 8;
            value |= uint32(uint8(buffer[pos++]));
            return (pos, value);
        }
        else {
            revert UnsupportedCBORUint();
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

    function skipValue(bytes memory buffer, uint pos) private pure returns (uint) {
        uint v;
        uint cbortype;
        (pos, cbortype, v) = readType(buffer, pos);

        uint value;
        if (cbortype == MAJOR_TYPE_INT) {
            (pos, value) = decodeUint(buffer, pos, v);
            return pos;
        }
        /*
        // Commented out to save gas
        else if (cbortype == MAJOR_TYPE_NEGATIVE_INT) {
            (pos, value) = decodeUint(buffer, pos, v);
            return pos;
        }
        */
        /*
        // Commented out to save gas
        else if (cbortype == MAJOR_TYPE_BYTES) {
            (pos, value) = decodeUint(buffer, pos, v);
            pos += value;
            return pos;
        }
        */
        else if (cbortype == MAJOR_TYPE_STRING) {
            (pos, value) = decodeUint(buffer, pos, v);
            pos += value;
            return pos;
        }
        else if (cbortype == MAJOR_TYPE_ARRAY) {
            (pos, value) = decodeUint(buffer, pos, v);
            for (uint i = 0; i < value; i++) {
                pos = skipValue(buffer, pos);
            }
            return pos;
        }
        /*
        // Commented out to save gas
        else if (cbortype == MAJOR_TYPE_MAP) {
            (pos, value) = decodeUint(buffer, pos, v);
            for (uint i = 0; i < value; i++) {
                pos = skipValue(buffer, pos);
                pos = skipValue(buffer, pos);
            }
            return pos;
        }
        */
        else {
            revert UnexpectedCBORType();
        }
    }

    function readType(bytes memory buffer, uint pos) private pure returns (uint, uint, uint) {
        uint v = uint8(buffer[pos]);
        return (++pos, v >> 5, v);
    }

    function readStringValue(bytes memory buffer, uint pos) private pure returns (uint, string memory) {
        uint v;
        uint cbortype;
        (pos, cbortype, v) = readType(buffer, pos);
        revert_if(cbortype != MAJOR_TYPE_STRING, UnexpectedCBORType);
        uint valuelen;
        (pos, valuelen) = decodeUint(buffer, pos, v);
        return decodeString(buffer, pos, valuelen);
    }

    function readMapLength(bytes memory buffer, uint pos) private pure returns (uint, uint) {
        uint v;
        uint cbortype;
        (pos, cbortype, v) = readType(buffer, pos);
        revert_if(cbortype != MAJOR_TYPE_MAP, UnexpectedCBORType);
        uint maplen;
        (pos, maplen) = decodeUint(buffer, pos, v);
        return (pos, maplen);
    }

    // Recursively searches the position of credential subject in the CWT claims
    // Side effects: reverts transaction if pass is expired.
    function findCredSubj(bytes memory buffer, uint pos, uint pathindex) private view returns (uint) {
        uint maplen;
        (pos, maplen) = readMapLength(buffer, pos);

        for (uint i = 0; i < maplen; i++) {
            uint v;
            uint cbortype;
            (pos, cbortype, v) = readType(buffer, pos);

            if (cbortype == MAJOR_TYPE_INT) {
                uint key;
                (pos, key) = decodeUint(buffer, pos, v);
                if (key == 4) {
                    (pos, cbortype, v) = readType(buffer, pos);
                    revert_if(cbortype != MAJOR_TYPE_INT, UnexpectedCBORType);

                    uint exp;
                    (pos, exp) = decodeUint(buffer, pos, v);
                     // check if pass expired
                    revert_if(block.timestamp >= exp, PassExpired);
                }
                // We do not check for whether pass is active, since we assume
                // That the NZ MoH only issues active passes
                else {
                    pos = skipValue(buffer, pos); // skip value
                }
            }
            else if (cbortype == MAJOR_TYPE_STRING) {
                uint strlen;
                (pos, strlen) = decodeUint(buffer, pos, v);

                string memory key;
                (pos, key) = decodeString(buffer, pos, strlen);
                if (keccak256(abi.encodePacked(key)) == CREDENTIAL_SUBJECT_PATH[pathindex]) {
                    if (pathindex >= CREDENTIAL_SUBJECT_PATH_LENGTH_MINUS_1) {
                        return pos;
                    }
                    else {
                        return findCredSubj(buffer, pos, pathindex + 1);
                    }
                }
                else {
                    pos = skipValue(buffer, pos); // skip value
                }
            }
            else {
                revert UnexpectedCBORType();
            }
        }
    }

    function decodeCredSubj(bytes memory buffer, uint pos) private pure returns (string memory, string memory, string memory) {
        uint maplen;
        (pos, maplen) = readMapLength(buffer, pos);

        string memory givenName;
        string memory familyName;
        string memory dob;

        string memory key;
        for (uint i = 0; i < maplen; i++) {
            (pos, key) = readStringValue(buffer, pos);

            if (keccak256(abi.encodePacked(key)) == givenName_KECCAK256) {
                (pos, givenName) = readStringValue(buffer, pos);
            }
            else if (keccak256(abi.encodePacked(key)) == familyName_KECCAK256) {
                (pos, familyName) = readStringValue(buffer, pos);
            }
            else if (keccak256(abi.encodePacked(key)) == dob_KECCAK256) {
                (pos, dob) = readStringValue(buffer, pos);
            }
            else {
                pos = skipValue(buffer, pos); // skip value
            }
        }
        return (givenName, familyName, dob);
    }

    // Verifies NZCP message hash signature
    // Returns true if signature is valid, reverts transaction otherwise
    function verifySign(bytes32 messageHash, uint256[2] memory rs, bool isExample) public pure returns (bool) {
        if (isExample) {
            revert_if(!validateSignature(messageHash, rs, [EXAMPLE_X, EXAMPLE_Y]), InvalidSignature);
            return true;
        }
        else {
            revert_if(!validateSignature(messageHash, rs, [LIVE_X, LIVE_Y]),  InvalidSignature);
            return true;
        }
    }

    // Verifies signature, parses ToBeSigned and returns the credential subject
    // Returns credential subject if pass is valid, reverts transaction otherwise
    // https://datatracker.ietf.org/doc/html/rfc8152#section-4.4
    function readCredSubj(bytes memory ToBeSigned, uint256[2] memory rs, bool isExample) public view 
        returns (string memory, string memory, string memory) {

        verifySign(sha256(ToBeSigned), rs, isExample);

        return decodeCredSubj(ToBeSigned, findCredSubj(ToBeSigned, CLAIMS_SKIP, 0));
    }
}
