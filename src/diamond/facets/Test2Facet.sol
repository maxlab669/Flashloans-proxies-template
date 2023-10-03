// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "src/diamond/libraries/LibDiamond.sol";
import "forge-std/Test.sol";

contract Facet2 {
    struct Facet2Storage {
        address value;
    } 

    bytes32 private constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.facet2.storage");

    function setFacet2Storage(address value) external {
        bytes32 position = keccak256("diamond.standard.diamond.storage");
        LibDiamond.DiamondStorage storage ds;
        assembly {
            ds.slot := position
        }
        require(msg.sender == ds.contractOwner, "Not owner");

        Facet2Storage storage s = getStorage();
        s.value = value;
    }

    function getStorage() private pure returns (Facet2Storage storage s) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function getFacet2Storage() public pure returns (Facet2Storage memory) {
        Facet2Storage storage s;
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
        return s;
    }

}