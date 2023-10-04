// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {AggregatorV3Interface} from "src/interfaces/oracle/AggregatorV3Interface.sol";

contract ChainlinkFeedTest is Test {
    string constant RPC =  // https://chainlist.org/
        "https://rpc.ankr.com/eth"; 
        // "https://rpc.flashbots.net";

    AggregatorV3Interface internal dataFeed;

    function setUp() external {
        dataFeed = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c); // mainnet
        vm.createSelectFork(RPC, 18262896); // 02 oct 2023
    }

    function testChainlinkFeed() external {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();

        assertEq(timeStamp, 1696247723);
        assertEq(uint256(answer), 2823400000000);
    }

}