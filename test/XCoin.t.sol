// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {XCoin} from "../src/XCoin.sol";
import {Deploy} from "../script/Deploy.s.sol";

contract XCoinTest is Test {
    uint256 private constant INITIAL_SUPPLY = 10_000_000_000 ether;
    XCoin private s_xcoin;

    function setUp() external {
        Deploy deploy = new Deploy();
        (s_xcoin, ) = deploy.run();
    }

    function test_Name() external view {
        assertEq(s_xcoin.name(), "XCoin");
    }

    function test_Symbol() external view {
        assertEq(s_xcoin.symbol(), "XCOIN");
    }

    function test_InitialSupply() external view {
        assertEq(s_xcoin.initialSupply(), INITIAL_SUPPLY);
    }

    function test_TotalSupply() external view {
        assertEq(s_xcoin.totalSupply(), INITIAL_SUPPLY);
    }

    function test_DeployerSupply() external view {
        assertEq(s_xcoin.balanceOf(msg.sender), (INITIAL_SUPPLY * 1) / 100);
    }
}
