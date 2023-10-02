// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFlashLoanSimpleReceiver, IPool} from "./interfaces/IFlashLoanSimpleReceiver.sol";
import {IPoolAddressesProvider} from "./interfaces/IPoolAddressesProvider.sol";

contract AaveV3Borrower is Ownable, IFlashLoanSimpleReceiver{
    IPoolAddressesProvider public override ADDRESSES_PROVIDER;
    IPool public override POOL;

    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        POOL = IPool(provider.getPool());
    }

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

    function changePool(IPoolAddressesProvider provider) external onlyOwner {
        ADDRESSES_PROVIDER = provider;
        POOL = IPool(provider.getPool());
    }

    function requestFlashLoan(address _token, uint256 _amount, bytes calldata params) external payable onlyOwner{
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }
    

    function  executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    )  external override returns (bool) {
        require(initiator == address(this), "wrong initiator");
        require(msg.sender == address(POOL), "wrong caller");

        // logic
        {
            (address target, uint256 value) = abi.decode(params, (address, uint256));
            bytes memory txData =  
                abi.encodeWithSignature("receiveCall(address,uint256,uint256)", asset, amount, premium);

            (bool success,) = target.call{value : value}(txData);
            require(success, "target call failed");
        }
        
        uint256 totalAmount = amount + premium;
        IERC20(asset).approve(address(POOL), totalAmount);

        

        return true;
    }
}
