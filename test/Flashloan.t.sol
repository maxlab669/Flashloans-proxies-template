// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {AaveV2Borrower} from "src/flashloan/AaveV2Borrower.sol";
import {ILendingPoolAddressesProvider} from "src/flashloan/interfaces/IAaveV2Interfaces.sol";
import {AaveV3Borrower} from "src/flashloan/AaveV3Borrower.sol";
import {IPoolAddressesProvider} from "src/flashloan/interfaces/IAaveV3Interfaces.sol";

contract FlashloanTest is Test {
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    string constant RPC = "https://rpc.flashbots.net";
    
    address public borrower;
    bool public isFlashloanReceivedSuccessfully;

    function setUp() external{
        vm.createSelectFork(RPC, 18262896); // 02 oct 2023
    }

    fallback() external {}
    
    // call from Borrowers
    function receiveCall(
        address[] calldata tokens, 
        uint256[] calldata amounts, 
        uint256[] calldata premiums
    ) external payable{
        uint i = 0;
        for (; i < tokens.length; ) {
            assertEq(IERC20(tokens[i]).balanceOf(borrower), amounts[i]);

            deal(tokens[i], address(this), premiums[i]);
            IERC20(tokens[i]).transfer(borrower, premiums[i]);

            assertEq(IERC20(tokens[i]).balanceOf(borrower), amounts[i] + premiums[i]);
            unchecked {
                ++i;
            }
        }

        isFlashloanReceivedSuccessfully = true;
    }

    function testAaveV2Flashloan() external {
        // https://docs.aave.com/developers/v/2.0/deployed-contracts/deployed-contracts
        address aaveV2LendingPoolAddressesProvider = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;

        AaveV2Borrower aaveV2Borrower = 
            new AaveV2Borrower(ILendingPoolAddressesProvider(aaveV2LendingPoolAddressesProvider));
        borrower = address(aaveV2Borrower);

        address[] memory  borrowTokens = new address[](4);
        uint256[] memory borrowAmounts = new uint256[](4);
        borrowTokens[0] = USDC;
        borrowTokens[1] = DAI;
        borrowTokens[2] = WETH;
        borrowTokens[3] = WBTC;
        // borrowTokens[4] = USDT;  internal reverts
        borrowAmounts[0] = 100 * (10 ** IERC20(borrowTokens[0]).decimals());
        borrowAmounts[1] = 100 * (10 ** IERC20(borrowTokens[1]).decimals());
        borrowAmounts[2] = 10 * (10 ** IERC20(borrowTokens[2]).decimals());
        borrowAmounts[3] = 10 * (10 ** IERC20(borrowTokens[3]).decimals());

        uint msgValue = 1 ether;
        vm.deal(borrower, msgValue);
        uint balanceBefore = address(this).balance;

        bytes memory data = abi.encode(address(this), msgValue);
        aaveV2Borrower.requestFlashLoan(borrowTokens, borrowAmounts, data);
        assertTrue(isFlashloanReceivedSuccessfully);
        assertEq(address(this).balance, msgValue + balanceBefore);
    }

    function testAaveV3Flashloan() external {
        // https://docs.aave.com/developers/deployed-contracts/v3-mainnet/ethereum-mainnet
        address aaveV3PoolAddressProviderMainnet = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;

        AaveV3Borrower aaveV3Borrower = new AaveV3Borrower(IPoolAddressesProvider(aaveV3PoolAddressProviderMainnet));
        borrower = address(aaveV3Borrower);

        address[] memory  borrowTokens = new address[](4);
        uint256[] memory borrowAmounts = new uint256[](4);
        borrowTokens[0] = USDC;
        borrowTokens[1] = DAI;
        borrowTokens[2] = WETH;
        borrowTokens[3] = WBTC;
        // borrowTokens[4] = USDT;  internal reverts
        borrowAmounts[0] = 100 * (10 ** IERC20(borrowTokens[0]).decimals());
        borrowAmounts[1] = 100 * (10 ** IERC20(borrowTokens[1]).decimals());
        borrowAmounts[2] = 10 * (10 ** IERC20(borrowTokens[2]).decimals());
        borrowAmounts[3] = 10 * (10 ** IERC20(borrowTokens[3]).decimals());

        uint msgValue = 1 ether;
        vm.deal(borrower, msgValue);
        uint balanceBefore = address(this).balance;

        bytes memory data = abi.encode(address(this), msgValue);
        aaveV3Borrower.requestFlashLoan(borrowTokens, borrowAmounts, data);
        assertTrue(isFlashloanReceivedSuccessfully);
        assertEq(address(this).balance, msgValue + balanceBefore);
    }

}