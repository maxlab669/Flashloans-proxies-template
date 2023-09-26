// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ProxyAdmin} from "lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Script} from "../../lib/forge-std/src/Script.sol";
import {Box} from "src/transparent/Box.sol";
import {Box2} from "src/transparent/Box2.sol";

// forge script script/DeployTransparent.s.sol:DeployTransparent --private-key $KEY  --rpc-url https://rpc.ankr.com/eth_goerli -vvvv  --verify --etherscan-api-key $API --broadcast
contract DeployTransparent is Script {
    address public proxy;
    address public proxyAdmin;
    address public box;
    address public box2;

    function run() external {
        vm.startBroadcast();

        deployBox();
        deployProxyAdmin();
        deployProxy();

        // upgrading
        deployBox2();
        upgradeTo();

        vm.stopBroadcast();
    }

    function deployProxyAdmin() internal {
        proxyAdmin = address(new ProxyAdmin());
    }

    function deployBox() internal {
        box = address(new Box());
    }

    function deployProxy() internal {
        bytes memory initializeData = abi.encodeWithSelector(Box.store.selector, 2);
        proxy = address(new TransparentUpgradeableProxy(box, proxyAdmin, initializeData));
    }

    function deployBox2() internal {
        box2 = address(new Box2());
    }

    function upgradeTo() internal {
        bytes memory data = abi.encodeWithSelector(Box2.increment.selector);
        ProxyAdmin(proxyAdmin).upgradeAndCall(ITransparentUpgradeableProxy(proxy), box2, data);
    }
}
