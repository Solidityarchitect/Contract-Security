//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {L1BossBridge} from "../../src/L1BossBridge.sol";
import {L1Token} from "../../src/L1Token.sol";
import {L1Vault} from "../../src/L1Vault.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {IERC20} from "openzeppelin/contracts/interfaces/IERC20.sol";
import {MessageHashUtils} from "openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract Handler is Test {
    event Deposit(address from, address to, uint256 amount);

    L1BossBridge public bridge;
    L1Vault public vault;
    ERC20Mock public token;

    uint256 public expectedDepositLimit;
    uint256 public actualDepositLimit;
    uint256 public vaultInitialBalance;
    uint256 public userInitialBalance;

    uint256 public vaultActualBalance;
    uint256 public userActualBalance;

    address user = makeAddr("user");
    address userInL2 = makeAddr("userInL2");
    Account operator = makeAccount("operator");

    constructor(L1BossBridge _bridge, address _token, address _vault) {
        bridge = _bridge;
        token = ERC20Mock(_token);
        vault = L1Vault(_vault);
    }

    function depositTokensToL2() public {
        token.mint(user, 1000e18);
        vm.startPrank(user);
        expectedDepositLimit = 100_000 ether;
        uint256 depositAmount = 10e18;
        token.approve(address(bridge), depositAmount);
        vm.expectEmit(address(bridge));
        emit Deposit(user, userInL2, depositAmount);
        bridge.depositTokensToL2(user, userInL2, depositAmount);
        actualDepositLimit = bridge.DEPOSIT_LIMIT();
        vm.stopPrank();
    }

    function withdrawTokensToL1() public {
        vaultInitialBalance = 1000e18;
        userInitialBalance = 100e18;
        deal(address(token), address(vault), vaultInitialBalance);
        deal(address(token), address(user), userInitialBalance);

        vm.startPrank(user);
        token.approve(address(bridge), type(uint256).max);
        vm.expectEmit(address(bridge));
        emit Deposit(user, userInL2, userInitialBalance);
        bridge.depositTokensToL2(user, userInL2, userInitialBalance);
        console2.log("vault balance is:", token.balanceOf(address(vault)));

        (uint8 v, bytes32 r, bytes32 s) = _signMessage(
            _getTokenWithdrawalMessage(user, userInitialBalance),
            operator.key
        );

        bridge.withdrawTokensToL1(user, userInitialBalance, v, r, s);
        vaultActualBalance = token.balanceOf(address(vault));
        userActualBalance = token.balanceOf(user);
    }

    /**
     * Mocks part of the off-chain mechanism where there operator approves requests for withdrawals by signing them.
     * Although not coded here (for simplicity), you can safely assume that our operator refuses to sign any withdrawal
     * request from an account that never originated a transaction containing a successful deposit.
     */
    function _signMessage(
        bytes memory message,
        uint256 privateKey
    ) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        return
            vm.sign(
                privateKey,
                MessageHashUtils.toEthSignedMessageHash(keccak256(message))
            );
    }

    function _getTokenWithdrawalMessage(
        address recipient,
        uint256 amount
    ) private view returns (bytes memory) {
        return
            abi.encode(
                address(token), // target
                0, // value
                abi.encodeCall(
                    IERC20.transferFrom,
                    (address(vault), recipient, amount)
                ) // data
            );
    }
}
