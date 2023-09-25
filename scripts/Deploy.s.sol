// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967Proxy.sol";

import {Script} from "forge-std/src/Script.sol";
import {Counter} from "src/Counter.sol";


contract DeployUUPS {

    function run() external {
        vm.startBroadcast();
        
        vm.stopBroadcast();
    }

    function deployProxy() internal {

    }

    function deployCounter() internal {

    }


}