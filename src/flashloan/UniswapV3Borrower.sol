// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "src/interfaces/IERC20.sol";
import {IUniswapV3Pool, PoolAddress} from "src/flashloan/interfaces/IUniswapV3Interfaces.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapV3Borrower is Ownable {
    using SafeERC20 for IERC20;

    struct FlashCallbackData {
        uint amount0;
        uint amount1;
        address caller;
        bytes targetCallData;
    }

    address private constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    IERC20 private immutable token0;
    IERC20 private immutable token1;
    IUniswapV3Pool private immutable pool;

    constructor(address _token0, address _token1, uint24 _fee) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        pool = IUniswapV3Pool(getPool(_token0, _token1, _fee));
    }

    function getPool(address _token0, address _token1, uint24 _fee) public pure returns (address) {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(_token0, _token1, _fee);
        return PoolAddress.computeAddress(FACTORY, poolKey);
    }

    function flashSwap(uint amount0, uint amount1, bytes calldata data) external onlyOwner{
        IUniswapV3Pool(pool).flash(address(this), amount0, amount1, data);
    }

    function uniswapV3FlashCallback(
        uint fee0,
        uint fee1,
        bytes calldata data
    ) external {
        FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));
        require(msg.sender == address(pool), "not pool");
        require(decoded.caller == owner(), "not sender");

        (address target, uint256 value) = abi.decode(decoded.targetCallData, (address, uint256));

        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory premiums = new uint256[](1);

        assets[0] = fee0 > 0 ? address(token0) : address(token1);
        amounts[0] = fee0 > 0 ? decoded.amount0 : decoded.amount1;
        premiums[0] = fee0 > 0 ? fee0 : fee1;

        // logic
        {
            bytes memory txData =  
                abi.encodeWithSignature("receiveCall(address[],uint256[],uint256[])", assets, amounts, premiums);

            (bool success,) = target.call{value : value}(txData);
            require(success, "target call failed");
        }

        // repay
        uint totalAmount = amounts[0] + premiums[0];
        IERC20(assets[0]).transfer(address(pool), totalAmount);

    }
}




