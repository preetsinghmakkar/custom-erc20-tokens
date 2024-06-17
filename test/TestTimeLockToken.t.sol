// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TimeLockToken} from "../src/TimeLockToken.sol";
import {DeployTokens} from "../script/DeployTokens.s.sol";

contract TestingBurnableToken is Test {
    TimeLockToken public timeLockToken;

    uint256 cappedAmount = 1000000000000000000000000000;
    uint256 testCapValue = 100000000000;
    address public contractAddress;
    address public owner = address(1);
    address public authorize1 = address(2);
    address public user = address(3);

    function setUp() public {
        DeployTokens deployer = new DeployTokens();
        (, , , , timeLockToken) = deployer.run();
        contractAddress = address(timeLockToken);
    }

    function test_authorizeByOnlyOwner() public {
        vm.startPrank(owner);
        timeLockToken.authorize(authorize1);
        vm.stopPrank();

        bool authorizedOrNot = timeLockToken.authorizedUsers(authorize1);
        assertEq(authorizedOrNot, true);
    }

    function test_notAuthorizedUser() public {
        vm.expectRevert();
        vm.startPrank(user);
        timeLockToken.authorize(authorize1);
        vm.stopPrank();
    }

    function test_mintByOwner() public {
        vm.startPrank(owner);
        timeLockToken.mint(owner, 10 * (10 ** 18));
        vm.stopPrank();

        console.log(timeLockToken.balanceOf(owner));

        assertEq(timeLockToken.balanceOf(owner), 10 * (10 ** 18));
    }

    function test_mintByAuthorizedUser() public {
        //authorizing the user
        vm.startPrank(owner);
        timeLockToken.authorize(authorize1);
        vm.stopPrank();

        //minting by authorized user
        vm.startPrank(authorize1);
        timeLockToken.mint(authorize1, 10 * (10 ** 18));
        vm.stopPrank();

        console.log(timeLockToken.balanceOf(authorize1));

        assertEq(timeLockToken.balanceOf(authorize1), 10 * (10 ** 18));
    }

    function test_mintByUser() public {
        vm.expectRevert();
        vm.startPrank(user);
        timeLockToken.mint(authorize1, 10 * (10 ** 18));
        vm.stopPrank();
    }

    function test_mintingEmit() public {
        uint256 amount = 10 * (10 ** 18);

        vm.startPrank(owner);

        // Expect the Minted event
        vm.expectEmit(true, true, true, true);
        emit TimeLockToken.Minted(owner, owner, amount);

        // Mint tokens
        timeLockToken.mint(owner, amount);

        vm.stopPrank();
    }

    function test_burnFromTokenHolder() public {
        vm.startPrank(owner);
        timeLockToken.mint(owner, 10 * (10 ** 18));
        vm.stopPrank();

        uint256 burnedAmount = 5 * (10 ** 18);

        vm.startPrank(owner);
        timeLockToken.burn(owner, burnedAmount);
        vm.stopPrank();

        uint256 ownerHoldingAmount = timeLockToken.balanceOf(owner);

        assertEq(ownerHoldingAmount, 5 * (10 ** 18));
    }

    function test_BurningEmit() public {
        uint256 initialBalance = 10 * (10 ** 18);
        vm.prank(owner);
        timeLockToken.mint(owner, initialBalance);

        uint256 burnedAmount = 5 * (10 ** 18);

        // Expect the Burned event
        vm.expectEmit(true, true, true, true);
        emit TimeLockToken.Burned(owner, burnedAmount);

        vm.startPrank(owner);
        timeLockToken.burn(owner, burnedAmount);
        vm.stopPrank();
    }

    function test_Pause() public {
        vm.startPrank(owner);
        timeLockToken.mint(owner, 10 * (10 ** 18));
        timeLockToken.pause();
        vm.stopPrank();

        assertEq(timeLockToken.paused(), true);

        vm.prank(owner);
        vm.expectRevert();
        timeLockToken.transfer(user, 1 * (10 ** 18));
    }

    function test_PauseOnlyOwner() public {
        vm.prank(user);
        vm.expectRevert();
        timeLockToken.pause();
    }

    function test_Unpause() public {
        vm.startPrank(owner);

        timeLockToken.mint(owner, 10 * (10 ** 18));

        timeLockToken.pause();

        timeLockToken.unpause();

        timeLockToken.transfer(user, 1 * (10 ** 18));
        vm.stopPrank();
        uint256 balanceOfUser = timeLockToken.balanceOf(user);

        assertEq(balanceOfUser, 1 * (10 ** 18));
    }

    function test_revokeAuthorization() public {
        vm.prank(owner);
        timeLockToken.authorize(authorize1);

        vm.prank(authorize1);
        timeLockToken.mint(authorize1, 10 * (10 ** 18));

        vm.prank(owner);
        timeLockToken.revokeAuthorization(authorize1);

        vm.prank(authorize1);
        vm.expectRevert();
        timeLockToken.mint(authorize1, 10 * (10 ** 18));
    }

    function test_onlyOwnerCanRevokeAuthorization() public {
        vm.prank(owner);
        timeLockToken.authorize(authorize1);

        vm.prank(authorize1);
        timeLockToken.mint(authorize1, 10 * (10 ** 18));

        vm.prank(user);
        vm.expectRevert();
        timeLockToken.revokeAuthorization(authorize1);
    }

    function test_capValue() public view {
        assertEq(timeLockToken.cap(), cappedAmount);
    }

    function test_ErrorMintMoreThanCapValue() public {
        vm.prank(owner);
        vm.expectRevert();
        timeLockToken.mint(authorize1, testCapValue * (10 ** 18));
    }

    function test_timeLock() public {
        vm.startPrank(owner);

        timeLockToken.mint(owner, 10 * (10 ** 18));

        timeLockToken.transfer(contractAddress, 1000000);

        timeLockToken.timeLock(owner, 1000000);

        uint256 ownerBalance = timeLockToken.balanceOf(contractAddress);
        console.log(ownerBalance);

        vm.expectRevert();
        timeLockToken.release();
    }

    function test_timeLockAfterRelease() public {
        vm.startPrank(owner);

        timeLockToken.mint(owner, 100000);

        console.log(timeLockToken.balanceOf(owner));

        timeLockToken.transfer(contractAddress, 1000);

        uint256 contractBalance = timeLockToken.balanceOf(contractAddress);
        console.log("Contract Balance before lock:", contractBalance);

        timeLockToken.timeLock(owner, 1000);

        // Instead of vm.sleep, use vm.warp to directly set the block.timestamp
        vm.warp(block.timestamp + 500); // Warp forward in time by 500 seconds
        console.log("After warp, timestamp:", block.timestamp);

        timeLockToken.release(); // Release tokens

        uint256 contractBalanceAfterRelease = timeLockToken.balanceOf(
            contractAddress
        );
        console.log(
            "Contract Balance before lock:",
            contractBalanceAfterRelease
        );
        console.log(timeLockToken.balanceOf(owner));
    }
}
