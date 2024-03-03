// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// @audit-info the IThunderLoan contract should be implented by the ThunderLoan contract!
interface IThunderLoan {
    // q is the token, the token that's being borrowed?
    // a yes!
    // @audit-info low/informational
    // q amount is the amount of tokens? yes!
    function repay(address token, uint256 amount) external;
}
