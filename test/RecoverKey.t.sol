// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ImpersonatorTwo} from "../src/ImpersonatorTwo.sol";

// Recovers the owner's private key d from two signatures that reused the same
// nonce k (same r). All arithmetic is mod n, the secp256k1 curve order.
//
//   s1 = k^-1 * (h1 + r*d)   (mod n)
//   s2 = k^-1 * (h2 + r*d)   (mod n)
//
//   k = (h1 - h2) / (s1 - s2)         (mod n)
//   d = (s1*k - h1) / r               (mod n)
contract RecoverKeyTest is Test {
    ImpersonatorTwo instance;

    // secp256k1 group order n (prime).
    uint256 constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    // Known values from the factory.
    address constant ADMIN = 0xADa4aFfe581d1A31d7F75E1c5a3A98b2D4C40f68;
    address constant OWNER = 0x03E2cf81BBE61D1fD1421aFF98e8605a5A9e953a;

    uint256 constant R = 0xe5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40;
    uint256 constant S1 = 0x70026fc30e4e02a15468de57155b080f405bd5b88af05412a9c3217e028537e3; // switchLock
    uint256 constant S2 = 0x4c3ac03b268ae1d2aca1201e8a936adf578a8b95a49986d54de87cd0ccb68a79; // setAdmin

    function setUp() public {
        instance = new ImpersonatorTwo();
    }

    // --- modular arithmetic helpers (mod n) ---

    // a - b  (mod n), result always in [0, n)
    function subMod(uint256 a, uint256 b) internal pure returns (uint256) {
        a %= N;
        b %= N;
        return addmod(a, N - b, N);
    }

    // modular inverse via Fermat's little theorem: a^(n-2) mod n, using the
    // modexp precompile at address 0x05. Valid because n is prime.
    function invMod(uint256 a) internal view returns (uint256 result) {
        uint256 e = N - 2;
        assembly {
            let p := mload(0x40)
            mstore(p, 0x20)             // length of base
            mstore(add(p, 0x20), 0x20)  // length of exponent
            mstore(add(p, 0x40), 0x20)  // length of modulus
            mstore(add(p, 0x60), a)     // base
            mstore(add(p, 0x80), e)     // exponent
            mstore(add(p, 0xa0), N)     // modulus
            if iszero(staticcall(gas(), 0x05, p, 0xc0, p, 0x20)) { revert(0, 0) }
            result := mload(p)
        }
    }

    function test_recoverKey() public view {
        // Rebuild the two signed messages (see ComputeHashes.t.sol for the why).
        bytes32 h1b = instance.hash_message(string(abi.encodePacked("lock", "0")));
        bytes32 h2b = instance.hash_message(string(abi.encodePacked("admin", "1", ADMIN)));

        uint256 h1 = uint256(h1b) % N;
        uint256 h2 = uint256(h2b) % N;

        // k = (h1 - h2) / (s1 - s2)  (mod n)
        uint256 k = mulmod(subMod(h1, h2), invMod(subMod(S1, S2)), N);

        // d = (s1*k - h1) / r  (mod n)
        uint256 d = mulmod(subMod(mulmod(S1, k, N), h1), invMod(R), N);

        console.log("recovered k:");
        console.logBytes32(bytes32(k));
        console.log("recovered d (private key):");
        console.logBytes32(bytes32(d));

        address recovered = vm.addr(d);
        console.log("address(d):", recovered);
        console.log("expected owner:", OWNER);

        assertEq(recovered, OWNER, "recovered key does not match owner");
    }
}
