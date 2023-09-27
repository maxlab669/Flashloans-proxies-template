// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ProxyAdmin} from "lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Box} from "src/transparent/Box.sol";
import {Box2} from "src/transparent/Box2.sol";
import "lib/forge-std/src/Test.sol";

// forge script script/DeployTransparent.s.sol:DeployTransparent --private-key $KEY  --rpc-url https://rpc.ankr.com/eth_goerli -vvvv  --verify --etherscan-api-key $API --broadcast
contract TransparentProxyTest is Test {
    ITransparentUpgradeableProxy public proxy;
    ProxyAdmin public proxyAdmin;
    Box public box;
    Box2 public box2;

    address public constant owner = address(0xdead);

    function setUp() external {}

    function testTransparent() external {
        vm.startPrank(owner);

        box = new Box();
        assertEq(box.retrieve(), 0);

        proxyAdmin = new ProxyAdmin();
        assertEq(proxyAdmin.owner(), owner);

        bytes memory initializeData = abi.encodeWithSelector(Box.store.selector, 99);
        proxy = ITransparentUpgradeableProxy(
            address(new TransparentUpgradeableProxy(address(box), address(proxyAdmin), initializeData))
        );

        assertEq(Box(address(proxy)).retrieve(), 99);
        assertEq(proxyAdmin.getProxyAdmin(proxy), address(proxyAdmin));
        assertEq(proxyAdmin.getProxyImplementation(proxy), address(box));

        vm.stopPrank();

        vm.expectRevert("Ownable: caller is not the owner");
        proxyAdmin.upgrade(proxy, address(this));

        ///// upgrading ////

        vm.startPrank(owner);

        box2 = new Box2();
        assertEq(box2.retrieve(), 0);
        assertEq(box2.lack(), 0);

        bytes memory data = abi.encodeWithSelector(Box2.increment.selector);
        proxyAdmin.upgradeAndCall(proxy, address(box2), data);

        assertEq(Box(address(proxy)).retrieve(), 99 + 1);
        assertEq(proxyAdmin.getProxyAdmin(proxy), address(proxyAdmin));
        assertEq(proxyAdmin.getProxyImplementation(proxy), address(box2));

        Box2(address(proxy)).lackincrement();
        assertEq(Box2(address(proxy)).lack(), 1);

        Box2(address(proxy)).increment();
        assertEq(Box2(address(proxy)).retrieve(), 99 + 1 + 1);

        vm.stopPrank();

        vm.expectRevert("Ownable: caller is not the owner");
        proxyAdmin.upgrade(proxy, address(this));

        Box2(address(proxy)).store(1e18);
        assertEq(Box2(address(proxy)).retrieve(), 1e18);

        box2.increment();
        assertEq(box2.retrieve(), 1);
        assertEq(Box2(address(proxy)).retrieve(), 1e18);
    }
}
