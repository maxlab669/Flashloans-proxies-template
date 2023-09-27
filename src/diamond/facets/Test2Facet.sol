// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test2Facet {
    function test2Func1() external {}

    function test2Func2() external {}

    function test2Func3() external {}

    function test2Func4() external {}

    function test2Func5() external {}

    function test2Func6() external {}

    function test2Func7() external {}

    function test2Func8() external {}

    function test2Func9() external {}

    function test2Func10() external {}

    function test2Func11() external {}

    function test2Func12() external {}

    function test2Func13() external {}

    function test2Func14() external {}

    function test2Func15() external {}

    function test2Func16() external {}

    function test2Func17() external {}

    function test2Func18() external {}

    function test2Func19() external {}

    function test2Func20() external {}
}

import {LibDiamond} from "src/diamond/libraries/LibDiamond.sol";
import "lib/forge-std/src/Test.sol";

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