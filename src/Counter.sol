// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract Counter is UUPSUpgradeable, OwnableUpgradeable{
    uint256 public number;

    function initialize(uint256 newNumber) public initializer {
        number = newNumber;
    
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    // override the virtual
   function _authorizeUpgrade(address) internal override onlyOwner {}
}
