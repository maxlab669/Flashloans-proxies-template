// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "../../lib/forge-std/src/Script.sol";
import {Counter} from "src/uups/Counter.sol";
import {Counter2} from "src/uups/Counter2.sol";

// forge script script/DeployUUPS.s.sol:DeployUUPS --private-key $KEY  --rpc-url https://rpc.ankr.com/eth_goerli -vvvv  --verify --etherscan-api-key $API --broadcast
contract DeployUUPS is Script {
    address public proxy;
    address public counter;
    address public counter2;

    function run() external {
        vm.startBroadcast();

        deployCounter();
        deployProxy();

        // // upgrading
        // deployCounter2();
        // upgradeTo();

        vm.stopBroadcast();
    }

    function deployCounter() internal {
        counter = address(new Counter());
    }

    function deployProxy() internal {
        bytes memory initializeData = abi.encodeWithSelector(Counter.initialize.selector, 2);
        proxy = address(new ERC1967Proxy(counter, initializeData));
    }

    function deployCounter2() internal {
        counter2 = address(new Counter2());
    }

    function upgradeTo() internal {
        Counter(proxy).upgradeTo(counter2);
    }
}
