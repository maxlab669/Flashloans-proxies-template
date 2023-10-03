// This is a file copied from https://github.com/DODOEX/dodo-example/blob/main/solidity/contracts/DODOFlashloan.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import {IERC20} from "src/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
interface IDODO {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
}

contract DodoV2Borrower is Ownable{
    using SafeERC20 for IERC20;

    struct FlashCallbackData {
        address flashLoanPool;
        address loanToken;
        uint256 loanAmount;
        bytes targetCallData;
    }

    function dodoFlashLoan(
        address flashLoanPool, //You will make a flashloan from this DODOV2 pool
        uint256 loanAmount,
        address loanToken,
        bytes calldata data
    ) external onlyOwner {
        address flashLoanBase = IDODO(flashLoanPool)._BASE_TOKEN_();
        if (flashLoanBase == loanToken) {
            IDODO(flashLoanPool).flashLoan(loanAmount, 0, address(this), data);
        } else {
            IDODO(flashLoanPool).flashLoan(0, loanAmount, address(this), data);
        }
    }

    //Note: CallBack function executed by DODOV2(DVM) flashLoan pool
    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    //Note: CallBack function executed by DODOV2(DPP) flashLoan pool
    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    //Note: CallBack function executed by DODOV2(DSP) flashLoan pool
    function DSPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function _flashLoanCallBack(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) internal {
        FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));

        (address target, uint256 value) = abi.decode(decoded.targetCallData, (address, uint256));

        require(sender == address(this) , "wrong sender");
        require(msg.sender == decoded.flashLoanPool, "wrong caller");

        require(
            decoded.loanAmount == IERC20(decoded.loanToken).balanceOf(address(this)),
            "The loanAmount and the current balance should be the same!"
        );

        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory premiums = new uint256[](1);

        assets[0] = decoded.loanToken;
        amounts[0] = decoded.loanAmount;
        premiums[0] = 0;

        // logic
        {
            bytes memory txData =  
                abi.encodeWithSignature("receiveCall(address[],uint256[],uint256[])", assets, amounts, premiums);

            (bool success,) = target.call{value : value}(txData);
            require(success, "target call failed");
        }

        //Return funds
        IERC20(decoded.loanToken).transfer(decoded.flashLoanPool, decoded.loanAmount);
    }
}
