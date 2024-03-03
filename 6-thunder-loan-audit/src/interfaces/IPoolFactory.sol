// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

// e this is probably the interface to work with poolfactory.sol from tswap
// q why are we using tswap ?
// a we need it to get the value of a token to calculate the fee!
interface IPoolFactory {
    function getPool(address tokenAddress) external view returns (address);
}

// ✅
