// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IPyth} from "src/interfaces/oracle/IPyth.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract PythNetworkTest is Test {
    string constant RPC =  // https://chainlist.org/
        "https://arbitrum.llamarpc.com"; 
        // "https://rpc.ankr.com/arbitrum";

    IPyth internal pyth;

    function setUp() external {
        // https://docs.pyth.network/documentation/pythnet-price-feeds/evm
        pyth = IPyth(0xff1a0f4744e8582DF1aE09D5611b887B6a12925C); // arbitum
        vm.createSelectFork(RPC, 137402532); // 04 oct 2023
    }

    function testPythNetwork() external {
        // https://pyth.network/developers/price-feed-ids
        bytes32 id = 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43; // BTC-USD
        IPyth.Price memory price =  pyth.getPriceUnsafe(id);

        assertEq(price.publishTime, 1696413498);
        assertEq(uint256(uint64(price.price)), 2762374000000);
    }

    function testPythPriceUpdate() external {
        // https://pyth.network/developers/price-feed-ids
        bytes32 id = 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43; // BTC-USD

        IPyth.Price memory price =  pyth.getPriceUnsafe(id);
        assertEq(uint256(uint64(price.price)), 2762374000000);
        assertEq(price.publishTime, 1696413498);
        console.log('btc price on 4th oct 2023: ', uint256(uint64(price.price)));
        console.log('published at ', price.publishTime);

        string[] memory res = new string[](3);
        res[0] = "node";
        res[1] = "test/script/pythScript.js";
        res[2] = Strings.toHexString(uint256(id));

        bytes[] memory updateData = new bytes[](1);
        updateData[0] = vm.ffi(res);

        uint ethFee = pyth.getUpdateFee(updateData);
        vm.deal(address(this), ethFee);
        assertEq(ethFee, 1 wei);

        pyth.updatePriceFeeds{value : ethFee}(updateData);

        price =  pyth.getPriceUnsafe(id);
        console.log('btc price now: ', uint256(uint64(price.price)));
        console.log('published at ', price.publishTime);
    }

}