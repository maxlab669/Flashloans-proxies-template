// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Diamond} from "src/proxy/diamond/Diamond.sol";
import {IDiamond} from "src/proxy/diamond/interfaces/IDiamond.sol";
import {IDiamondCut} from "src/proxy/diamond/interfaces/IDiamondCut.sol";
import {LibDiamond} from "src/proxy/diamond/libraries/LibDiamond.sol";
import {IERC173} from "src/proxy/diamond/interfaces/IERC173.sol";
import {DiamondCutFacet} from "src/proxy/diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "src/proxy/diamond/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "src/proxy/diamond/facets/OwnershipFacet.sol";
import {Facet1} from "src/proxy/diamond/facets/Test1Facet.sol";
import {Facet2} from "src/proxy/diamond/facets/Test2Facet.sol";

contract DiamondTest is Test{
    Diamond public diamond;

    function setUp() external {}

    function testDiamond() external {
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](4);
        address facetAddress;
        bytes4[] memory functionSelectors;
        IDiamond.FacetCutAction action = IDiamond.FacetCutAction.Add;
        bytes memory initCode;

        {
            facetAddress = address(new OwnershipFacet());
            functionSelectors = new bytes4[](2);
            functionSelectors[0] = OwnershipFacet.transferOwnership.selector;
            functionSelectors[1] = OwnershipFacet.owner.selector;
            facetCuts[0] = IDiamond.FacetCut(facetAddress, action, functionSelectors);

            facetAddress = address(new DiamondLoupeFacet());
            functionSelectors = new bytes4[](5);
            functionSelectors[0] = DiamondLoupeFacet.facets.selector;
            functionSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
            functionSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
            functionSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
            functionSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
            facetCuts[1] = IDiamond.FacetCut(facetAddress, action, functionSelectors);

            facetAddress = address(new DiamondCutFacet());
            functionSelectors = new bytes4[](1);
            functionSelectors[0] = DiamondCutFacet.diamondCut.selector;
            facetCuts[2] = IDiamond.FacetCut(facetAddress, action, functionSelectors);

            facetAddress = address(new Facet1());
            functionSelectors = new bytes4[](2);
            functionSelectors[0] = Facet1.setFacet1Storage.selector;
            functionSelectors[1] = Facet1.getFacet1Storage.selector;
            facetCuts[3] = IDiamond.FacetCut(facetAddress, action, functionSelectors);


            initCode = abi.encodeWithSelector(Facet1.setFacet1Storage.selector, 55);
            Diamond.DiamondArgs memory diamondArgs = Diamond.DiamondArgs(address(this), facetAddress, initCode);

            diamond = new Diamond(facetCuts, diamondArgs);

            assertEq(OwnershipFacet(address(diamond)).owner(), address(this));
            assertEq(Facet1(address(diamond)).getFacet1Storage().value, 55);
            Facet1(address(diamond)).setFacet1Storage(99);
            assertEq(Facet1(address(diamond)).getFacet1Storage().value, 99);


            assertEq(DiamondLoupeFacet(address(diamond)).facets().length, 4);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[3].facetAddress, facetAddress);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[3].functionSelectors.length, 2);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[3].functionSelectors[0], functionSelectors[0]);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[3].functionSelectors[1], functionSelectors[1]);

            assertEq(DiamondLoupeFacet(address(diamond)).facets()[2].functionSelectors.length, 1);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[1].functionSelectors.length, 5);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[0].functionSelectors.length, 2);
        }

        {
            facetAddress = address(new Facet2());
            functionSelectors = new bytes4[](2);
            functionSelectors[0] = Facet2.setFacet2Storage.selector;
            functionSelectors[1] = Facet2.getFacet2Storage.selector;
            facetCuts = new IDiamondCut.FacetCut[](1);
            facetCuts[0] = IDiamond.FacetCut(facetAddress, action, functionSelectors);

            initCode = abi.encodeWithSelector(Facet2.setFacet2Storage.selector, address(this));
            DiamondCutFacet(address(diamond)).diamondCut(facetCuts, facetAddress, initCode);

            assertEq(Facet2(address(diamond)).getFacet2Storage().value, address(this));

            assertEq(DiamondLoupeFacet(address(diamond)).facets().length, 5);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[4].facetAddress, facetAddress);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[4].functionSelectors.length, 2);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[4].functionSelectors[0], functionSelectors[0]);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[4].functionSelectors[1], functionSelectors[1]);
        }

        {
            vm.prank(address(1));
            vm.expectRevert("Not owner");
            Facet2(address(diamond)).setFacet2Storage(address(1));

            Facet2(address(diamond)).setFacet2Storage(address(0xdead));
            assertEq(Facet2(address(diamond)).getFacet2Storage().value, address(0xdead));

            OwnershipFacet(address(diamond)).transferOwnership(address(this));
            assertEq(OwnershipFacet(address(diamond)).owner(), address(this));
        }

        // cut, remove a sig of Facet2
        {
            action = IDiamond.FacetCutAction.Remove;
            functionSelectors = new bytes4[](1);
            functionSelectors[0] = Facet2.getFacet2Storage.selector;
            facetCuts = new IDiamondCut.FacetCut[](1);
            facetCuts[0] = IDiamond.FacetCut(address(0), action, functionSelectors);

            DiamondCutFacet(address(diamond)).diamondCut(facetCuts, address(0), "");
            assertEq(DiamondLoupeFacet(address(diamond)).facets().length, 5);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[4].facetAddress, facetAddress);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[4].functionSelectors.length, 1);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[4].functionSelectors[0], Facet2.setFacet2Storage.selector);
        }
        
        // replace, replace a sig's facet from  Facet2 to this contract
        // not recommended as the storrage of this contract is not proper and could clash
        // and you should have a function in this contract that you call at diamond
        {
            action = IDiamond.FacetCutAction.Replace;
            functionSelectors = new bytes4[](1);
            functionSelectors[0] = Facet2.setFacet2Storage.selector;
            facetCuts = new IDiamondCut.FacetCut[](1);
            facetCuts[0] = IDiamond.FacetCut(address(this), action, functionSelectors);

            DiamondCutFacet(address(diamond)).diamondCut(facetCuts, address(0), "");
            assertEq(DiamondLoupeFacet(address(diamond)).facets().length, 5);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[4].facetAddress, address(this));
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[4].functionSelectors.length, 1);
            assertEq(DiamondLoupeFacet(address(diamond)).facets()[4].functionSelectors[0], Facet2.setFacet2Storage.selector);
        }
        
    }


}

