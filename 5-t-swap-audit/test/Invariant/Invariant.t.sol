//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";
import { Handler } from "../Invariant/Handler.t.sol";

contract Invariant is StdInvariant, Test {
    ERC20Mock poolToken;
    ERC20Mock weth;

    PoolFactory factory;
    TSwapPool pool;
    Handler handler;

    int256 constant STARTING_X = 100e18; // Starting ERC20 / poolToken
    int256 constant STARTING_Y = 50e18; // Starting WETH

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        // Create those initial x & y balances
        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        // Deposit into the pool, give the starting X & Y balances
        pool.deposit(uint256(STARTING_Y), uint256(STARTING_Y), uint256(STARTING_X), uint64(block.timestamp));
        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
        targetContract(address(handler));
    }

    function statefulFuzz_constantProductFormulaStaysTheSameX() public {
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }

    function statefulFuzz_constantProductFormulaStaysTheSameY() public {
        assertEq(handler.actualDeltaY(), handler.expectedDeltaY());
    }
}
