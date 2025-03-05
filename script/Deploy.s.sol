// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {XCoin} from "../src/XCoin.sol";
import {Distribution} from "../src/Distribution.sol";

/**
 * @title Deploy
 * @author XCoin Labs
 * @notice XCoin and Distribution contract deployment script.
 * @dev Deploy inherits foundry's Script.
 * Steps:
 * 1. Deploy XCoin
 * 2. Deploy Distribution
 * 3. Transfer 99% of XCoin's total supply to Distribution
 */
contract Deploy is Script {
    function run() external returns (XCoin xcoin, Distribution distribution) {
        vm.startBroadcast();
        console.log("Deployer:", msg.sender);

        // Deploy contracts
        xcoin = new XCoin();
        console.log("Deployed XCoin:", address(xcoin));
        distribution = new Distribution(address(xcoin));
        console.log("Deployed Distribution:", address(distribution));

        // Transfer 99% of total supply to distribution contract
        uint256 distributionAmount = (xcoin.totalSupply() * 99) / 100;
        xcoin.transfer(address(distribution), distributionAmount);
        console.log(
            "Transferred %s to %s",
            distributionAmount,
            address(distribution)
        );
        vm.stopBroadcast();

        return (xcoin, distribution);
    }
}
