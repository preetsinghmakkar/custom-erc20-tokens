// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PausableToken} from "../src/PausableToken.sol";
import {DeployTokens} from "../script/DeployTokens.s.sol";

contract TestingBurnableToken is Test {
    PausableToken public pausableToken;

    address public owner = address(1);
    address public authorize1 = address(2);
    address public user = address(3);

    function setUp() public {
        DeployTokens deployer = new DeployTokens();
        (, , pausableToken) = deployer.run();
    }

    function test_authorizeByOnlyOwner() public {
        vm.startPrank(owner);
        pausableToken.authorize(authorize1);
        vm.stopPrank();

        bool authorizedOrNot = pausableToken.authorizedUsers(authorize1);
        assertEq(authorizedOrNot, true);
    }

    function test_notAuthorizedUser() public {
        vm.expectRevert();
        vm.startPrank(user);
        pausableToken.authorize(authorize1);
        vm.stopPrank();
    }

    function test_mintByOwner() public {
        vm.startPrank(owner);
        pausableToken.mint(owner, 10 * (10 ** 18));
        vm.stopPrank();

        console.log(pausableToken.balanceOf(owner));

        assertEq(pausableToken.balanceOf(owner), 10 * (10 ** 18));
    }

    function test_mintByAuthorizedUser() public {
        //authorizing the user
        vm.startPrank(owner);
        pausableToken.authorize(authorize1);
        vm.stopPrank();

        //minting by authorized user
        vm.startPrank(authorize1);
        pausableToken.mint(authorize1, 10 * (10 ** 18));
        vm.stopPrank();

        console.log(pausableToken.balanceOf(authorize1));

        assertEq(pausableToken.balanceOf(authorize1), 10 * (10 ** 18));
    }

    function test_mintByUser() public {
        vm.expectRevert();
        vm.startPrank(user);
        pausableToken.mint(authorize1, 10 * (10 ** 18));
        vm.stopPrank();
    }

    function test_mintingEmit() public {
        uint256 amount = 10 * (10 ** 18);

        vm.startPrank(owner);

        // Expect the Minted event
        vm.expectEmit(true, true, true, true);
        emit PausableToken.Minted(owner, owner, amount);

        // Mint tokens
        pausableToken.mint(owner, amount);

        vm.stopPrank();
    }

    function test_burnFromTokenHolder() public {
        vm.startPrank(owner);
        pausableToken.mint(owner, 10 * (10 ** 18));
        vm.stopPrank();

        uint256 burnedAmount = 5 * (10 ** 18);

        vm.startPrank(owner);
        pausableToken.burn(owner, burnedAmount);
        vm.stopPrank();

        uint256 ownerHoldingAmount = pausableToken.balanceOf(owner);

        assertEq(ownerHoldingAmount, 5 * (10 ** 18));
    }

    function test_BurningEmit() public {
        uint256 initialBalance = 10 * (10 ** 18);
        vm.prank(owner);
        pausableToken.mint(owner, initialBalance);

        uint256 burnedAmount = 5 * (10 ** 18);

        // Expect the Burned event
        vm.expectEmit(true, true, true, true);
        emit PausableToken.Burned(owner, burnedAmount);

        vm.startPrank(owner);
        pausableToken.burn(owner, burnedAmount);
        vm.stopPrank();
    }

    function test_Pause() public {
        vm.startPrank(owner);
        pausableToken.mint(owner, 10 * (10 ** 18));
        pausableToken.pause();
        vm.stopPrank();

        assertEq(pausableToken.paused(), true);

        vm.prank(owner);
        vm.expectRevert();
        pausableToken.transfer(user, 1 * (10 ** 18));
    }

    function test_PauseOnlyOwner() public {
        vm.prank(user);
        vm.expectRevert();
        pausableToken.pause();
    }

    function test_Unpause() public {
        vm.startPrank(owner);

        pausableToken.mint(owner, 10 * (10 ** 18));

        pausableToken.pause();

        pausableToken.unpause();

        pausableToken.transfer(user, 1 * (10 ** 18));
        vm.stopPrank();
        uint256 balanceOfUser = pausableToken.balanceOf(user);

        assertEq(balanceOfUser, 1 * (10 ** 18));
    }

    function test_revokeAuthorization() public {
        vm.prank(owner);
        pausableToken.authorize(authorize1);

        vm.prank(authorize1);
        pausableToken.mint(authorize1, 10 * (10 ** 18));

        vm.prank(owner);
        pausableToken.revokeAuthorization(authorize1);

        vm.prank(authorize1);
        vm.expectRevert();
        pausableToken.mint(authorize1, 10 * (10 ** 18));
    }

    function test_onlyOwnerCanRevokeAuthorization() public {
        vm.prank(owner);
        pausableToken.authorize(authorize1);

        vm.prank(authorize1);
        pausableToken.mint(authorize1, 10 * (10 ** 18));

        vm.prank(user);
        vm.expectRevert();
        pausableToken.revokeAuthorization(authorize1);
    }
}
