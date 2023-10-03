// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "src/interfaces/IERC20.sol";
import {IUniswapV2Callee, IUniswapV2Factory, IUniswapV2Pair} from "src/flashloan/interfaces/IUniswapV2Interfaces.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapV2Borrower is Ownable, IUniswapV2Callee {
    using SafeERC20 for IERC20;

    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // mainnet

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
    IUniswapV2Pair private immutable pair;

    constructor(address tokenA, address tokenB) {
        pair = IUniswapV2Pair(factory.getPair(tokenA, tokenB));
    }

    function flashSwap(uint amount0, uint amount1, bytes calldata data) external onlyOwner{
        pair.swap(amount0, amount1, address(this), data);
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");

        (address target, uint256 value) = abi.decode(data, (address, uint256));

        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory premiums = new uint256[](1);

        assets[0] = amount0 > 0 ? IUniswapV2Pair(pair).token0() : IUniswapV2Pair(pair).token1();
        amounts[0] = amount0 > 0 ? amount0 : amount1;
        // about 0.3% fee, +1 to round up
        premiums[0] = amount0 > 0 ? (amount0 * 3) / 997 + 1 : (amount1 * 3) / 997 + 1 ;

        // logic
        {
            bytes memory txData =  
                abi.encodeWithSignature("receiveCall(address[],uint256[],uint256[])", assets, amounts, premiums);

            (bool success,) = target.call{value : value}(txData);
            require(success, "target call failed");
        }

        // Repay
        uint amountToRepay = amounts[0] + premiums[0];
        IERC20(assets[0]).safeTransfer(address(pair), amountToRepay);
    }
}

