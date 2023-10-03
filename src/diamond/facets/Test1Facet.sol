// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Example library to show a simple example of diamond storage
library TestLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.test.storage");

    struct TestState {
        address myAddress;
        uint256 myNum;
    }

    function diamondStorage() internal pure returns (TestState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setMyAddress(address _myAddress) internal {
        TestState storage testState = diamondStorage();
        testState.myAddress = _myAddress;
    }

    function getMyAddress() internal view returns (address) {
        TestState storage testState = diamondStorage();
        return testState.myAddress;
    }
}


contract Facet1 {
    struct Facet1Storage {
        uint256 value;
    } 

    bytes32 private constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.facet1.storage");

    function setFacet1Storage(uint256 value) external {
        Facet1Storage storage s = getStorage();
        s.value = value;
    }

    function getStorage() private pure returns (Facet1Storage storage s) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function getFacet1Storage() public pure returns (Facet1Storage memory) {
        Facet1Storage storage s;
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
        return s;
    }

}

