// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Distribution
 * @author XCoin Labs
 * @notice ERC20 token distribution contract.
 * @dev Distribution inherits OpenZeppelin's EIP712 and Ownable contracts.
 * Distributes ERC20 tokens using owner's signature.
 * Conditions:
 * - Users can claim tokens based on validity and availability
 * - Owner can withdraw remaining tokens at expiry
 */
contract Distribution is EIP712, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    struct Claim {
        address account;
        uint256 amount;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    bytes32 private constant CLAIM_TYPE_HASH =
        keccak256("Claim(address account,uint256 amount)");
    uint256 private constant VALIDITY = 52 weeks;
    uint256 private immutable i_expiry;
    IERC20 private immutable i_token;
    mapping(address account => bool claimed) private s_claimed;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Claimed(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Distribution__AlreadyClaimed(address);
    error Distribution__ZeroAmount();
    error Distribution__InvalidSignature(
        address actualSigner,
        address expectedSigner
    );
    error Distribution__Expired();
    error Distribution__NotExpired();
    error Distribution__InsufficentToken();

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Sets EIP712 `name` and `version`.
     * Sets `owner` as msg.sender.
     * Sets immutable variable `i_expiry` as block.timestamp + `VALIDITY`.
     * Sets immutable variable `i_token` as ERC20 token to distribute.
     */
    constructor(
        address token
    ) EIP712("Distribution", "1.0.0") Ownable(msg.sender) {
        i_expiry = block.timestamp + VALIDITY;
        i_token = IERC20(token);
    }

    /**
     * @dev Claims a fixed `amount` of token to an `account`.
     *
     * Conditions:
     * - One-time claim
     * - Non-zero amount
     * - Not expired
     * - Valid signature (signed by contract owner)
     * - Sufficient token balance
     *
     * Emits a `Claimed` event.
     */
    function claim(
        address account,
        uint256 amount,
        bytes memory signature
    ) external {
        // One-time claim
        if (s_claimed[account]) {
            revert Distribution__AlreadyClaimed(account);
        }

        // Non-zero amount
        if (amount == 0) {
            revert Distribution__ZeroAmount();
        }

        // Not expired
        if (_isExpired()) {
            revert Distribution__Expired();
        }

        // Valid signature
        bytes32 hash = _hashClaimMessage(account, amount);
        address signer = ECDSA.recover(hash, signature);
        if (signer != owner()) {
            revert Distribution__InvalidSignature(signer, owner());
        }

        // Sufficient balance
        uint256 balance = i_token.balanceOf(address(this));
        if (balance <= 0) {
            revert Distribution__InsufficentToken();
        }
        uint256 claimAmount = amount > balance ? balance : amount;

        s_claimed[account] = true;
        emit Claimed(account, claimAmount);
        i_token.safeTransfer(account, claimAmount);
    }

    /**
     * @dev Withdraws the remaining tokens to an `account`.
     *
     * Conditions:
     * - Owner
     * - Contract is expired
     * - Sufficient token balance
     *
     * Emits a `Withdrawn` event.
     */
    function withdraw(address account) external onlyOwner {
        // Expired
        if (!_isExpired()) {
            revert Distribution__NotExpired();
        }

        // Sufficient balance
        uint256 balance = i_token.balanceOf(address(this));
        if (balance <= 0) {
            revert Distribution__InsufficentToken();
        }

        emit Withdrawn(account, balance);
        i_token.safeTransfer(account, balance);
    }

    /**
     * @dev Returns the ERC20 token address.
     * @return Token address
     */
    function getToken() external view returns (address) {
        return address(i_token);
    }

    /**
     * @dev Returns the claim status of an `account`.
     * @param account User address
     * @return Claim status
     */
    function getClaimStatus(address account) external view returns (bool) {
        return s_claimed[account];
    }

    /**
     * @dev Returns the token balance of this contract.
     * @return Token balance
     */
    function getBalance() external view returns (uint256) {
        return i_token.balanceOf(address(this));
    }

    /**
     * @dev Returns distribution period.
     * @return Distribution period in seconds
     */
    function getValidity() external pure returns (uint256) {
        return VALIDITY;
    }

    /**
     * @dev Returns distribution expiry.
     * @return Distribution expiry in seconds since Unix epoch
     */
    function getExpiry() external view returns (uint256) {
        return i_expiry;
    }

    /**
     * @dev Returns distribution expiry status.
     * @return Distribution expiry status
     */
    function isExpired() external view returns (bool) {
        return _isExpired();
    }

    /**
     * @dev Constructs a `Claim` message using `account` and `amount`; and returns its EIP712 hash.
     * @param account User address
     * @param amount Token amount
     * @return Claim message hash
     */
    function hashClaimMessage(
        address account,
        uint256 amount
    ) external view returns (bytes32) {
        return _hashClaimMessage(account, amount);
    }

    /**
     * @dev Returns distribution expiry status.
     * @return Distribution expiry status
     */
    function _isExpired() private view returns (bool) {
        return block.timestamp > i_expiry;
    }

    /**
     * @dev Constructs a `Claim` message using `account` and `amount`; and returns its EIP712 hash.
     * @param account User address
     * @param amount Token amount
     * @return Claim message hash
     */
    function _hashClaimMessage(
        address account,
        uint256 amount
    ) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        CLAIM_TYPE_HASH,
                        Claim({account: account, amount: amount})
                    )
                )
            );
    }
}
