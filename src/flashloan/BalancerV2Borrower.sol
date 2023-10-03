// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVault, IFlashLoanRecipient} from "./interfaces/IBalancerV2Interfaces.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

contract BalancerV2Borrower is Ownable, IFlashLoanRecipient {
    using SafeERC20 for IERC20;
    IVault private constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    receive() external payable {}

    function transferOutEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function transferOutTokens(address[] calldata tokens) external onlyOwner {
        uint i = 0;
        for (; i < tokens.length; ) {
            uint balance = IERC20(tokens[i]).balanceOf(address(this));
            IERC20(tokens[i]).transfer(owner(), balance);

            unchecked {
                ++i;
            }
        }
    }

    function requestFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external onlyOwner{
      vault.flashLoan(this, tokens, amounts, userData);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == address(vault), "Wrong call");

        // logic
        {
            (address target, uint256 value) = abi.decode(userData, (address, uint256));
            bytes memory txData =  
                abi.encodeWithSignature("receiveCall(address[],uint256[],uint256[])", tokens, amounts, feeAmounts);

            (bool success,) = target.call{value : value}(txData);
            require(success, "target call failed");
        }

        // return funds
        uint i = 0;
        for (; i < tokens.length; ) {
            uint256 totalAmount = amounts[i] + feeAmounts[i];
            IERC20(tokens[i]).safeTransfer(address(vault), totalAmount);

            unchecked {
                ++i;
            }
        }
    }
}