//  SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";

contract Factory {
    address public immutable implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function deployClone(uint256 index) external returns(address){
        bytes32 salt = keccak256(abi.encode(block.timestamp, index));
        return Clones.cloneDeterministic(implementation, salt);
    }
}

contract Implementation {
    uint private a;

    function set(uint _a) public { 
        a = _a;
    }

    function get() public returns(uint){ 
        return a;
    }
}

contract ClonesTest is Test {
    function setUp()  external {}

    function testClones() external {
        address implementation = address(new Implementation());
        Factory factory = new Factory(implementation);

        address newClone = factory.deployClone(0);
        bytes32 salt = keccak256(abi.encode(block.timestamp, 0));
        assertEq(newClone, Clones.predictDeterministicAddress(implementation, salt, address(factory)));

        Implementation(newClone).set(5);
        assertEq(Implementation(newClone).get(), 5);

        newClone = factory.deployClone(1);
        salt = keccak256(abi.encode(block.timestamp, 1));
        assertEq(newClone, Clones.predictDeterministicAddress(implementation, salt, address(factory)));

        Implementation(newClone).set(10);
        assertEq(Implementation(newClone).get(), 10);
    }
}