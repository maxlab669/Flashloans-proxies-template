// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {AaveV3Borrower} from "src/flashloan/AaveV3Borrower.sol";
import {IPoolAddressesProvider} from "src/flashloan/interfaces/IPoolAddressesProvider.sol";

contract FlashloanTest is Test {
    string constant RPC = "https://rpc.flashbots.net";
    address public borrower;
    bool public isFlashloanReceivedSuccessfully;

    function setUp() external{
        vm.createSelectFork(RPC, 18262896); // 02 oct 2023
    }

    fallback() external {}
    
    // call from AaveV3Borrower
    function receiveCall(address token, uint amount, uint premium) external payable{
        assertEq(IERC20(token).balanceOf(borrower), amount);

        deal(token, address(this), premium);
        IERC20(token).transfer(borrower, premium);
        isFlashloanReceivedSuccessfully = true;

        assertEq(IERC20(token).balanceOf(borrower), amount + premium);
    }

    function testAaveV3Flashloan() external {
        address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        // https://docs.aave.com/developers/deployed-contracts/v3-mainnet/ethereum-mainnet
        address aaveV3PoolAddressProviderMainnet = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;

        AaveV3Borrower aaveV3Borrower = new AaveV3Borrower(IPoolAddressesProvider(aaveV3PoolAddressProviderMainnet));
        borrower = address(aaveV3Borrower);

        address borrowToken = USDC;
        uint borrowAmount = 100 * (10 ** IERC20(borrowToken).decimals());
        uint msgValue = 1 ether;
        vm.deal(borrower, msgValue);
        uint balanceBefore = address(this).balance;

        bytes memory data = abi.encode(address(this), msgValue);
        aaveV3Borrower.requestFlashLoan(borrowToken, borrowAmount, data);
        assertTrue(isFlashloanReceivedSuccessfully);
        assertEq(address(this).balance, msgValue + balanceBefore);
    }

}