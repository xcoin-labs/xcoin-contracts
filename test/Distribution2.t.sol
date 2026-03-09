// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test} from "forge-std/Test.sol";
import {Distribution2} from "../src/Distribution2.sol";
import {XCoin} from "../src/XCoin.sol";
import {Deploy2} from "../script/Deploy2.s.sol";

contract Distribution2Test is Test {
    XCoin private s_xcoin;
    Distribution2 private s_distribution2;
    uint256 private constant INITIAL_SUPPLY = 10_000_000_000 ether;
    uint256 private constant DISTRIBUTION_AMOUNT = (INITIAL_SUPPLY * 99) / 100;
    uint256 private constant EXPIRY = 1829088000; // date -u -d "2027-12-18" +%s

    // Owner
    address private s_ownerAddress;
    uint256 private s_ownerPrivateKey;

    modifier expired() {
        _expire();
        _;
    }

    function setUp() external {
        // Deploy XCoin
        s_xcoin = new XCoin();

        // Run Deploy2 script
        Deploy2 deploy2 = new Deploy2();
        s_distribution2 = deploy2.run(address(s_xcoin), EXPIRY);

        // Fund Distribution2 contract
        s_xcoin.transfer(address(s_distribution2), DISTRIBUTION_AMOUNT);

        // Make new owner to facilitate signing claim message
        (s_ownerAddress, s_ownerPrivateKey) = makeAddrAndKey("new owner");
        vm.prank(s_distribution2.owner());
        s_distribution2.transferOwnership(s_ownerAddress);
    }

    function test_NameAndVersion() external view {
        (, string memory name, string memory version, , , , ) = s_distribution2
            .eip712Domain();
        assertEq(name, "Distribution2");
        assertEq(version, "1.0.0");
    }

    function test_Owner() external view {
        assertEq(s_distribution2.owner(), s_ownerAddress);
    }

    function test_TokenAddress() external view {
        assertEq(s_distribution2.getToken(), address(s_xcoin));
    }

    function test_DistributionAmount() external view {
        assertEq(s_distribution2.getBalance(), DISTRIBUTION_AMOUNT);
        assertEq(
            s_xcoin.balanceOf(address(s_distribution2)),
            DISTRIBUTION_AMOUNT
        );
    }

    function test_Expiry() external view {
        assertEq(s_distribution2.getExpiry(), EXPIRY);
        assertEq(s_distribution2.isExpired(), false);
    }

    function test_CanExpire() external expired {
        assertEq(s_distribution2.isExpired(), true);
    }

    function test_CanClaim() external {
        (address account, uint256 amount, bytes memory signature) = _getClaimer(
            "claimer",
            1_000 ether
        );

        // Initial state
        assertEq(s_xcoin.balanceOf(account), 0);
        assertEq(s_distribution2.getClaimStatus(account), false);
        assertEq(s_distribution2.getBalance(), DISTRIBUTION_AMOUNT);

        vm.expectEmit(true, false, false, true);
        emit Distribution2.Claimed(account, amount);
        s_distribution2.claim(account, amount, signature);

        // Final state
        assertEq(s_xcoin.balanceOf(account), amount);
        assertEq(s_distribution2.getClaimStatus(account), true);
        assertEq(s_distribution2.getBalance(), DISTRIBUTION_AMOUNT - amount);
    }

    function test_CannotClaimTwice() external {
        (address account, uint256 amount, bytes memory signature) = _getClaimer(
            "claimer",
            1_000 ether
        );
        s_distribution2.claim(account, amount, signature);
        vm.expectRevert(
            abi.encodeWithSelector(
                Distribution2.Distribution2__AlreadyClaimed.selector,
                account
            )
        );
        s_distribution2.claim(account, amount, signature);
    }

    function test_NoZeroAmount() external {
        (address account, uint256 amount, bytes memory signature) = _getClaimer(
            "claimer",
            0
        );
        vm.expectRevert(Distribution2.Distribution2__ZeroAmount.selector);
        s_distribution2.claim(account, amount, signature);
    }

    function test_CannotClaimIfExpired() external expired {
        (address account, uint256 amount, bytes memory signature) = _getClaimer(
            "claimer",
            1_000 ether
        );
        vm.expectRevert(Distribution2.Distribution2__Expired.selector);
        s_distribution2.claim(account, amount, signature);
    }

    function test_CannotClaimIfSignatureInvalid() external {
        uint256 amount = 1_000 ether;
        (address account, uint256 privateKey) = makeAddrAndKey("claimer");
        assert(privateKey != s_ownerPrivateKey);
        bytes memory signature = _getSignature(account, amount, privateKey);
        vm.expectRevert(
            abi.encodeWithSelector(
                Distribution2.Distribution2__InvalidSignature.selector,
                account,
                s_ownerAddress
            )
        );
        s_distribution2.claim(account, amount, signature);
    }

    function test_CannotClaimIfInsufficientToken() external {
        // Drain token
        (
            address account_,
            uint256 amount_,
            bytes memory signature_
        ) = _getClaimer("previous claimers", s_distribution2.getBalance());
        s_distribution2.claim(account_, amount_, signature_);
        assertEq(s_distribution2.getBalance(), 0);

        // Claim reverts
        (address account, uint256 amount, bytes memory signature) = _getClaimer(
            "claimer",
            1_000 ether
        );
        vm.expectRevert(Distribution2.Distribution2__InsufficentToken.selector);
        s_distribution2.claim(account, amount, signature);
    }

    function test_ClaimRemainingToken() external {
        // Previous claimers
        uint256 remainingToken = 500 ether;
        (
            address account_,
            uint256 amount_,
            bytes memory signature_
        ) = _getClaimer(
                "previous claimers",
                s_distribution2.getBalance() - remainingToken
            );
        s_distribution2.claim(account_, amount_, signature_);
        assertEq(s_distribution2.getBalance(), remainingToken);

        // Claim remainingToken
        (address account, uint256 amount, bytes memory signature) = _getClaimer(
            "claimer",
            1_000 ether
        );
        vm.expectEmit(true, false, false, true);
        emit Distribution2.Claimed(account, remainingToken);
        s_distribution2.claim(account, amount, signature);
        assertEq(s_xcoin.balanceOf(account), remainingToken);
        assertEq(s_distribution2.getBalance(), 0);
    }

    function test_CanWithdraw() external expired {
        address treasury = makeAddr("treasury");

        // Initial state
        assertEq(s_distribution2.getBalance(), DISTRIBUTION_AMOUNT);
        assertEq(s_xcoin.balanceOf(treasury), 0);

        vm.prank(s_distribution2.owner());
        s_distribution2.withdraw(treasury);

        // Final state
        assertEq(s_distribution2.getBalance(), 0);
        assertEq(s_xcoin.balanceOf(treasury), DISTRIBUTION_AMOUNT);
    }

    function test_CannotWithdrawIfNotOwner() external expired {
        address treasury = makeAddr("treasury");
        assert(msg.sender != s_distribution2.owner());
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(this)
            )
        );
        s_distribution2.withdraw(treasury);
    }

    function test_CannotWithdrawIfNotExpired() external {
        address treasury = makeAddr("treasury");
        vm.prank(s_distribution2.owner());
        vm.expectRevert(Distribution2.Distribution2__NotExpired.selector);
        s_distribution2.withdraw(treasury);
    }

    function test_CannotWithdrawIfInsufficientToken() external {
        // Drain token
        (
            address account_,
            uint256 amount_,
            bytes memory signature_
        ) = _getClaimer("previous claimers", s_distribution2.getBalance());
        s_distribution2.claim(account_, amount_, signature_);
        assertEq(s_distribution2.getBalance(), 0);

        _expire();

        // Wtihdrawal reverts
        address treasury = makeAddr("treasury");
        vm.prank(s_distribution2.owner());
        vm.expectRevert(Distribution2.Distribution2__InsufficentToken.selector);
        s_distribution2.withdraw(treasury);
    }

    function _getClaimer(
        string memory name_,
        uint256 amount_
    )
        private
        returns (address account, uint256 amount, bytes memory signature)
    {
        account = makeAddr(name_);
        amount = amount_;
        signature = _getSignature(account, amount, s_ownerPrivateKey);
    }

    function _getSignature(
        address account,
        uint256 amount,
        uint256 privateKey
    ) private view returns (bytes memory) {
        bytes32 hash = s_distribution2.hashClaimMessage(account, amount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        return abi.encodePacked(r, s, v);
    }

    function _expire() private {
        vm.warp(EXPIRY + 1);
        vm.roll(EXPIRY + 1);
    }
}
