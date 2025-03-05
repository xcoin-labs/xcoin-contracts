// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title XCoin (XCOIN)
 * @author XCoin Labs
 * @notice XCoin (XCOIN) is an ERC20 token.
 * @dev XCoin inherits OpenZeppelin's ERC20 contract.
 * Properties:
 * - name: XCoin
 * - symbol: XCOIN
 * - decimals: 18
 * - totalSupply: 10,000,000,000 * 1e18
 */
contract XCoin is ERC20 {
    uint256 private constant INITIAL_SUPPLY = 10_000_000_000 ether;

    /**
     * @dev Sets ERC20 `name` and `symbol`.
     * Mints `INITIAL_SUPPLY` to msg.sender.
     * Since no further minting is implemented, total supply equals inital supply.
     */
    constructor() ERC20("XCoin", "XCOIN") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /**
     * @dev Returns the initial token supply.
     * @return Initial token supply
     */
    function initialSupply() external pure returns (uint256) {
        return INITIAL_SUPPLY;
    }
}
