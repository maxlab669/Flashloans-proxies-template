// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IFlashLoanReceiver, ILendingPoolAddressesProvider, ILendingPool} 
    from "src/flashloan/interfaces/IAaveV2Interfaces.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AaveV2Borrower is Ownable, IFlashLoanReceiver {
    using SafeERC20 for IERC20;

    ILendingPoolAddressesProvider public override ADDRESSES_PROVIDER;
    ILendingPool public override LENDING_POOL;

    constructor(ILendingPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        LENDING_POOL = ILendingPool(provider.getLendingPool());
    }

    function requestFlashLoan(
        address[] calldata assets,
        uint256[] calldata amounts, 
        bytes calldata params
    ) external payable onlyOwner{
        address receiverAddress = address(this);
        uint256[] memory interestRateModes = new uint256[](assets.length);
        address onBehalfOf = address(this);
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            interestRateModes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        require(initiator == address(this), "wrong initiator");
        require(msg.sender == address(LENDING_POOL), "wrong caller");

        // logic
        {
            (address target, uint256 value) = abi.decode(params, (address, uint256));
            bytes memory txData =  
                abi.encodeWithSignature("receiveCall(address[],uint256[],uint256[])", assets, amounts, premiums);

            (bool success,) = target.call{value : value}(txData);
            require(success, "target call failed");
        }

        // approving to return funds
        uint i = 0;
        for (; i < assets.length; ) {
            uint256 totalAmount = amounts[i] + premiums[i];
            IERC20(assets[i]).safeApprove(address(LENDING_POOL), totalAmount);

            unchecked {
                ++i;
            }
        }

        return true;
    }

}