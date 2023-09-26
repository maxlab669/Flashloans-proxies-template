// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Counter.sol";

contract Counter2 is Counter{

    function decrement() public {
        number--;
    }
}
