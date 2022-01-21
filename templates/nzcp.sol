pragma solidity ^0.8.11;

import "./EllipticCurve.sol";
import "./Strings.sol";


/* CBOR types */
#define MAJOR_TYPE_INT 0
#define MAJOR_TYPE_NEGATIVE_INT 1
#define MAJOR_TYPE_BYTES 2
#define MAJOR_TYPE_STRING 3
#define MAJOR_TYPE_ARRAY 4
#define MAJOR_TYPE_MAP 5
#define MAJOR_TYPE_TAG 6
#define MAJOR_TYPE_CONTENT_FREE 7

/*
 "key-1" public key published here:
 https://nzcp.covid19.health.nz/.well-known/did.json
 Does not suppose to change unless NZ MoH leaks their private key
*/
#define EXAMPLE_X 0xCD147E5C6B02A75D95BDB82E8B80C3E8EE9CAA685F3EE5CC862D4EC4F97CEFAD
#define EXAMPLE_Y 0x22FE5253A16E5BE4D1621E7F18EAC995C57F82917F1A9150842383F0B4A4DD3D

/* 
 "z12Kf7UQ" public key published here:
 https://nzcp.identity.health.nz/.well-known/did.json
 Does not suppose to change unless NZ MoH leaks their private key
*/
#define LIVE_X 0x0D008A26EB2A32C4F4BBB0A3A66863546907967DC0DDF4BE6B2787E0DBB9DAD7
#define LIVE_Y 0x971816CEC2ED548F1FA999933CFA3D9D9FA4CC6B3BC3B5CEF3EAD453AF0EC662

/*
 27 bytes to skip the ["Signature1", headers, buffer0] start of ToBeSigned
 And get to the CWT claims straight away
*/
#define CLAIMS_SKIP 27

/* keccak256(abi.encodePacked("vc")) */
#define VC_KECCAK256 0x6ec613b793842434591077d5267660b73eca3bb163edb2574938d0a1b9fed380

/* keccak256(abi.encodePacked("credentialSubject")) */
#define CREDENTIAL_SUBJECT_KECCAK256 0xf888b25396a7b641f052b4f483e19960c8cb98c3e8f094f00faf41fffd863fda

/* keccak256(abi.encodePacked("givenName")) */
#define GIVEN_NAME_KECCAK256 0xa3f2ad40900c663841a16aacd4bc622b021d6b2548767389f506dbe65673c3b9

/* keccak256(abi.encodePacked("familyName")) */
#define FAMILY_NAME_KECCAK256 0xd7aa1fd5ef0cc1f1e7ce8b149fdb61f373714ea1cc3ad47c597f4d3e554d10a4

/* keccak256(abi.encodePacked("dob")) */
#define DOB_KECCAK256 0x635ec02f32ae461b745f21d9409955a9b5a660b486d30e7b5d4bfda4a75dec80

/* Path to get to the credentialSubject map inside CWT claims */
#define CREDENTIAL_SUBJECT_PATH [bytes32(VC_KECCAK256), bytes32(CREDENTIAL_SUBJECT_KECCAK256)]

/* CREDENTIAL_SUBJECT_PATH.length - 1 */
#define CREDENTIAL_SUBJECT_PATH_LENGTH_MINUS_1 1

error InvalidSignature();
error PassExpired();
error UnexpectedCBORType();
error UnsupportedCBORUint();

#define revert_if(a, b) if (a) revert b()

/// @title NZCP
/// @author noway421.eth
/// @notice New Zealand COVID Pass verifier implementation in Solidity
/// - Verifies NZCP pass and returns the credential subject (givenName, familyName, dob)
/// - Reverts transaction if pass is invalid.
/// - To save gas, the full pass URI is not passed into the contract, but merely the ToBeSigned value.
/// - The definition of ToBeSigned can be found here: https://datatracker.ietf.org/doc/html/rfc8152#section-4.4 

// TODO: try other hashing funcs
contract NZCP is EllipticCurve, Strings {

    struct Stream {
        bytes buffer;
        uint pos;
    }

    function decodeUint(Stream memory stream, uint v) private pure returns (uint) {
        uint x = v & 31;
        if (x <= 23) {
            return x;
        }
        else if (x == 24) {
            uint8 value = uint8(stream.buffer[stream.pos++]);
            return value;
        }
        // Commented out to save gas
        // else if (x == 25) { // 16-bit
        //     uint16 value;
        //     value = uint16(uint8(buffer[pos++])) << 8;
        //     value |= uint16(uint8(buffer[pos++]));
        //     return (pos, value);
        // }
        else if (x == 26) { // 32-bit
            uint32 value;
            value = uint32(uint8(stream.buffer[stream.pos++])) << 24;
            value |= uint32(uint8(stream.buffer[stream.pos++])) << 16;
            value |= uint32(uint8(stream.buffer[stream.pos++])) << 8;
            value |= uint32(uint8(stream.buffer[stream.pos++]));
            return value;
        }
        else {
            revert UnsupportedCBORUint();
        }
    }

    function decodeString(Stream memory stream, uint len) private pure returns (string memory) {
        string memory str = new string(len);

        uint strptr;
        // 32 is the length of the string header
        assembly { strptr := add(str, 32) }
        
        uint bufferptr;
        // 32 is the length of the string header
        uint pos = stream.pos;
        bytes memory buffer = stream.buffer;
        assembly { bufferptr := add(add(buffer, 32), pos) }

        memcpy(strptr, bufferptr, len);

        stream.pos += len;

        return str;
    }

    function skipValue(Stream memory stream) private pure {
        (uint cbortype, uint v) = readType(stream);

        uint value;
        if (cbortype == MAJOR_TYPE_INT) {
            value = decodeUint(stream, v);
            return;
        }
        // Commented out to save gas
        // else if (cbortype == MAJOR_TYPE_NEGATIVE_INT) {
        //     value = decodeUint(stream, v);
        //     return;
        // }
        // Commented out to save gas
        // else if (cbortype == MAJOR_TYPE_BYTES) {
        //     value = decodeUint(stream, v);
        //     pos += value;
        //     return;
        // }
        else if (cbortype == MAJOR_TYPE_STRING) {
            value = decodeUint(stream, v);
            stream.pos += value;
            return;
        }
        else if (cbortype == MAJOR_TYPE_ARRAY) {
            value = decodeUint(stream, v);
            for (uint i = 0; i++ < value;) {
                skipValue(stream);
            }
            return;
        }
        // Commented out to save gas
        // else if (cbortype == MAJOR_TYPE_MAP) {
        //     value = decodeUint(stream, v);
        //     for (uint i = 0; i++ < value;) {
        //         skipValue(stream);
        //         skipValue(stream);
        //     }
        //     return;
        // }
        else {
            revert UnexpectedCBORType();
        }
    }

    function readType(Stream memory stream) private pure returns (uint, uint) {
        uint v = uint8(stream.buffer[stream.pos++]);
        return (v >> 5, v);
    }

    function readStringValue(Stream memory stream) private pure returns (string memory) {
        (uint value, uint v) = readType(stream);
        revert_if(value != MAJOR_TYPE_STRING, UnexpectedCBORType);
        value = decodeUint(stream, v);
        string memory str = decodeString(stream, value);
        return str;
    }

    function readMapLength(Stream memory stream) private pure returns (uint) {
        (uint value, uint v) = readType(stream);
        revert_if(value != MAJOR_TYPE_MAP, UnexpectedCBORType);
        value = decodeUint(stream, v);
        return value;
    }

    // Recursively searches the position of credential subject in the CWT claims
    // Side effects: reverts transaction if pass is expired.
    function findCredSubj(Stream memory stream, uint pathindex) private view {
        uint maplen = readMapLength(stream);

        for (uint i = 0; i++ < maplen;) {
            (uint cbortype, uint v) = readType(stream);

            uint value = decodeUint(stream, v);
            if (cbortype == MAJOR_TYPE_INT) {
                if (value == 4) {
                    (cbortype, v) = readType(stream);
                    revert_if(cbortype != MAJOR_TYPE_INT, UnexpectedCBORType);

                    uint exp = decodeUint(stream, v);
                     // check if pass expired
                    revert_if(block.timestamp >= exp, PassExpired);
                }
                // We do not check for whether pass is active, since we assume
                // That the NZ MoH only issues active passes
                else {
                    skipValue(stream); // skip value
                }
            }
            else if (cbortype == MAJOR_TYPE_STRING) {
                string memory key = decodeString(stream, value);

                if (keccak256(abi.encodePacked(key)) == CREDENTIAL_SUBJECT_PATH[pathindex]) {
                    if (pathindex >= CREDENTIAL_SUBJECT_PATH_LENGTH_MINUS_1) {
                        return;
                    }
                    else {
                        return findCredSubj(stream, pathindex + 1);
                    }
                }
                else {
                    skipValue(stream); // skip value
                }
            }
            else {
                revert UnexpectedCBORType();
            }
        }
    }

    function decodeCredSubj(Stream memory stream) private pure returns (string memory, string memory, string memory) {
        uint maplen;
        maplen = readMapLength(stream);

        string memory givenName;
        string memory familyName;
        string memory dob;

        string memory key;
        for (uint i = 0; i++ < maplen;) {
            key = readStringValue(stream);

            if (keccak256(abi.encodePacked(key)) == GIVEN_NAME_KECCAK256) {
                givenName = readStringValue(stream);
            }
            else if (keccak256(abi.encodePacked(key)) == FAMILY_NAME_KECCAK256) {
                familyName = readStringValue(stream);
            }
            else if (keccak256(abi.encodePacked(key)) == DOB_KECCAK256) {
                dob = readStringValue(stream);
            }
            else {
                skipValue(stream); // skip value
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

        Stream memory stream = Stream(ToBeSigned, CLAIMS_SKIP); 
        findCredSubj(stream, 0);
        return decodeCredSubj(stream);
    }
}
