// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ImpersonatorTwo} from "../src/ImpersonatorTwo.sol";

// Reconstructs the two messages the owner signed, exactly as the factory's
// setup sequence produced them, and computes their eth-signed hashes h1, h2.
//
// Factory call order (see ImpersonatorTwoFactory.createInstance):
//   1. switchLock(SWITCH_LOCK_SIG)  -> runs while nonce == 0  => message "lock0"
//   2. setAdmin(SET_ADMIN_SIG, ADMIN) -> runs while nonce == 1 => message "admin1" + ADMIN
contract ComputeHashesTest is Test {
    ImpersonatorTwo instance;

    // The admin address baked into the factory's setAdmin call.
    address constant ADMIN = 0xADa4aFfe581d1A31d7F75E1c5a3A98b2D4C40f68;

    // The two signatures, as stored in the factory. Same r, different s.
    bytes32 constant R = 0xe5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40;
    bytes32 constant S1 = 0x70026fc30e4e02a15468de57155b080f405bd5b88af05412a9c3217e028537e3; // switchLock
    bytes32 constant S2 = 0x4c3ac03b268ae1d2aca1201e8a936adf578a8b95a49986d54de87cd0ccb68a79; // setAdmin
    uint8 constant V = 27;

    function setUp() public {
        instance = new ImpersonatorTwo();
    }

    function test_computeHashes() public view {
        // Message 1: switchLock while nonce == 0  => abi.encodePacked("lock", "0")
        string memory message1 = string(abi.encodePacked("lock", "0"));

        // Message 2: setAdmin while nonce == 1  => abi.encodePacked("admin", "1", ADMIN)
        string memory message2 = string(abi.encodePacked("admin", "1", ADMIN));

        // Hash them the same way the contract does.
        bytes32 h1 = instance.hash_message(message1);
        bytes32 h2 = instance.hash_message(message2);

        console.log("message1 (lock):");
        console.log(message1);
        console.logBytes32(h1);

        console.log("message2 (setAdmin):");
        console.logBytes(bytes(message2));
        console.logBytes32(h2);

        console.log("--- signature components ---");
        console.log("r  (shared):");
        console.logBytes32(R);
        console.log("s1 (lock):");
        console.logBytes32(S1);
        console.log("s2 (admin):");
        console.logBytes32(S2);
        console.log("v:", V);
    }
}
