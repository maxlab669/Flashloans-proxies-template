// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Counter} from "src/uups/Counter.sol";
import {Counter2} from "src/uups/Counter2.sol";
import "forge-std/Test.sol";

interface IERC1967Proxy {
    function owner() external view returns (address);
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

// forge script script/DeployTransparent.s.sol:DeployTransparent --private-key $KEY  --rpc-url https://rpc.ankr.com/eth_goerli -vvvv  --verify --etherscan-api-key $API --broadcast
contract UupsProxyTest is Test {
    ERC1967Proxy public proxy;
    Counter public counter;
    Counter2 public counter2;

    address public constant owner = address(0xdead);

    function setUp() external {}

    function testUups() external {
        vm.startPrank(owner);

        counter = new Counter();
        assertEq(counter.number(), 0);

        bytes memory initializeData = abi.encodeWithSelector(Counter.initialize.selector, 88);
        proxy = new ERC1967Proxy(address(counter), initializeData);

        assertEq(IERC1967Proxy(address(proxy)).owner(), owner);
        assertEq(Counter(address(proxy)).number(), 88);

        vm.stopPrank();

        vm.expectRevert("Ownable: caller is not the owner");
        IERC1967Proxy(address(proxy)).upgradeTo(address(this));

        vm.startPrank(owner);

        counter2 = new Counter2();
        assertEq(counter2.number(), 0);

        bytes memory data = abi.encodeWithSelector(Counter2.decrement.selector);
        IERC1967Proxy(address(proxy)).upgradeToAndCall(address(counter2), data);

        assertEq(IERC1967Proxy(address(proxy)).owner(), owner);
        assertEq(Counter(address(proxy)).number(), 88 - 1);

        vm.stopPrank();

        counter2.increment();
        assertEq(counter2.number(), 1);
        assertEq(Counter2(address(proxy)).number(), 88 - 1);

        Counter2(address(proxy)).increment();
        assertEq(Counter2(address(proxy)).number(), 88);
        assertEq(counter2.number(), 1);

        Counter2(address(proxy)).setNumber(1e18);
        assertEq(Counter2(address(proxy)).number(), 1e18);

        vm.expectRevert("Ownable: caller is not the owner");
        IERC1967Proxy(address(proxy)).upgradeTo(address(this));
    }
}
