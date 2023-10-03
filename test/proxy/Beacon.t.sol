// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {BeaconProxy} from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import {IBeacon} from "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";
import {UpgradeableBeacon} from "openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Box} from "src/proxy/transparent/Box.sol";
import {Box2} from "src/proxy/transparent/Box2.sol";
 
contract BeaconTest is Test{
    UpgradeableBeacon public beacon;
    BeaconProxy public beaconProxy;
    Box public box;
    Box2 public box2;
    function setUp() external {}

    function testBeacon() external {
        // new beacon proxy, beacon, implementation
        {
            box = new Box();
            beacon = new UpgradeableBeacon(address(box));

            bytes memory initializationCode = abi.encodeWithSelector(Box.store.selector, 1e18);
            beaconProxy = new BeaconProxy(address(beacon), initializationCode);

            assertEq(beacon.implementation(), address(box));
            assertEq(beacon.owner(), address(this));
            assertEq(Box(address(beaconProxy)).retrieve(), 1e18);
            Box(address(beaconProxy)).store(2e18);
            assertEq(Box(address(beaconProxy)).retrieve(), 2e18);
        }

        // new implementation, beacon upgrade to new implementation
        {
            box2 = new Box2();
            beacon.upgradeTo(address(box2));

            assertEq(beacon.implementation(), address(box2));
            assertEq(beacon.owner(), address(this));
            assertEq(Box2(address(beaconProxy)).retrieve(), 2e18);
            Box2(address(beaconProxy)).store(3e18);
            assertEq(Box2(address(beaconProxy)).retrieve(), 3e18);

            assertEq(Box2(address(beaconProxy)).lack(), 0);
            Box2(address(beaconProxy)).increment();
            Box2(address(beaconProxy)).lackincrement();
            assertEq(Box2(address(beaconProxy)).retrieve(), 3e18 + 1);
            assertEq(Box2(address(beaconProxy)).lack(), 1);
        }

        // new beacon proxy
        {
            bytes memory initializationCode = abi.encodeWithSelector(Box2.lackincrement.selector);
            beaconProxy = new BeaconProxy(address(beacon), initializationCode);

            assertEq(beacon.implementation(), address(box2));
            assertEq(beacon.owner(), address(this));
            assertEq(Box(address(beaconProxy)).retrieve(), 0);
            Box(address(beaconProxy)).store(55);
            assertEq(Box(address(beaconProxy)).retrieve(), 55);

            assertEq(Box2(address(beaconProxy)).lack(), 1);
            Box2(address(beaconProxy)).store(1e18);
            Box2(address(beaconProxy)).lackincrement();
            assertEq(Box2(address(beaconProxy)).retrieve(), 1e18);
            assertEq(Box2(address(beaconProxy)).lack(), 2);
        }
    }

}