//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {L1BossBridge} from "../../src/L1BossBridge.sol";
import {L1Token} from "../../src/L1Token.sol";
import {L1Vault} from "../../src/L1Vault.sol";
import {Handler} from "../Invariant/Handler.t.sol";
import {IERC20} from "openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract Invariant is StdInvariant, Test {
    L1BossBridge bridge;
    L1Vault vault;
    IERC20 token;
    Handler handler;

    address deployer = makeAddr("deployer");
    Account operator = makeAccount("operator");

    function setUp() public {
        vm.startPrank(deployer);
        token = new ERC20Mock();
        bridge = new L1BossBridge(token);
        vault = bridge.vault();

        bridge.setSigner(operator.addr, true);
        console.log(bridge.owner());

        handler = new Handler(bridge, address(token), address(vault));
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = Handler.depositTokensToL2.selector;
        selectors[1] = Handler.withdrawTokensToL1.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );

        targetContract(address(handler));
        vm.stopPrank();
    }

    function statefulFuzz_DepositLimit() public {
        assertEq(handler.expectedDepositLimit(), handler.actualDepositLimit());
    }

    function statefulFuzz_withdrawTokensToL1() public {
        assertEq(handler.vaultInitialBalance(), handler.vaultActualBalance());
        console.log(handler.vaultInitialBalance());
        console.log(handler.vaultActualBalance());
        assertEq(handler.userInitialBalance(), handler.userActualBalance());
        console.log(handler.userInitialBalance());
        console.log(handler.userActualBalance());
    }
}
