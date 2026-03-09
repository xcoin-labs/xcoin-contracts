// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Distribution2} from "../src/Distribution2.sol";

/**
 * @title Deploy2
 * @author XCoin Labs
 * @notice Distribution2 contract deployment script.
 * @dev Deploy inherits foundry's Script.
 */
contract Deploy2 is Script {
    function run(
        address xcoin,
        uint256 expiry
    ) external returns (Distribution2 distribution2) {
        vm.startBroadcast();
        console.log("Deployer:", msg.sender);
        console.log("XCoin address:", xcoin);
        console.log("Expiry:", expiry);

        // Deploy contract
        distribution2 = new Distribution2(xcoin, expiry);
        console.log("Deployed Distribution2:", address(distribution2));

        vm.stopBroadcast();

        // return distribution2; // return is implicit
    }
}
