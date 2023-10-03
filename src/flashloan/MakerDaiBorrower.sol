// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC3156FlashBorrower, IERC3156FlashLender} from "src/flashloan/interfaces/IMakerDaiInterfaces.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MakerDaiBorrower is Ownable, IERC3156FlashBorrower{
    using SafeERC20 for IERC20;

    IERC3156FlashLender lender;

    constructor (address lender_) {
        lender = IERC3156FlashLender(lender_);
    }

    /// @dev Initiate a flash loan
    function flashBorrow(address token, uint256 amount, bytes calldata data) public {
        uint256 allowance = IERC20(token).allowance(address(this), address(lender));
        uint256 fee = lender.flashFee(token, amount);
        uint256 repayment = amount + fee;
        IERC20(token).approve(address(lender), allowance + repayment);
        lender.flashLoan(this, token, amount, data);
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(lender), "not pool");
        require(initiator == address(this), "not initiator");

        (address target, uint256 value) = abi.decode(data, (address, uint256));

        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory premiums = new uint256[](1);

        assets[0] = token;
        amounts[0] = amount;
        premiums[0] = fee;

        // logic
        {
            bytes memory txData =  
                abi.encodeWithSignature("receiveCall(address[],uint256[],uint256[])", assets, amounts, premiums);

            (bool success,) = target.call{value : value}(txData);
            require(success, "target call failed");
        }


        // repay
        IERC20(token).transfer(initiator, amount + fee);
    
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}