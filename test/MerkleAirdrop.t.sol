// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Test} from "forge-std/Test.sol";

contract Whitelist {

    bytes32 public merkleRoot;

    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
    }

    function checkInWhitelist(bytes32[] calldata proof, uint64 maxAllowanceToMint) view public returns (bool) {
        bytes32 leaf = keccak256(abi.encode(msg.sender, maxAllowanceToMint));
        bool verified = MerkleProof.verify(proof, merkleRoot, leaf);
        return verified;
    }
    
}

contract MerkleAirDropTest is Test {
    function setUp() external  {}

    function testMerklrProof() external {
        string[] memory res = new string[](8);
        res[0] = "node";
        res[1] = "test/script/merkleAirdrop.js";
        res[2] = Strings.toHexString(address(1));
        res[3] = Strings.toHexString(address(2));
        res[4] = Strings.toHexString(address(3));
        res[5] = Strings.toHexString(address(4));
        res[6] = "root";
        bytes32 root = bytes32(vm.ffi(res));

        bytes32[] memory proof = new bytes32[](2);
        res[6] = "proof";
        res[7] = "0"; // proof index
        proof[0] = bytes32(vm.ffi(res));
        
        res[7] = "1"; // proof index
        proof[1] = bytes32(vm.ffi(res));

        Whitelist whitelist = new Whitelist(root);
        vm.prank(address(2));
        assertEq(whitelist.checkInWhitelist(proof, 2), true);
        assertEq(whitelist.merkleRoot(), root);

    }
}