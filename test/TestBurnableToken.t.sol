// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BurnableToken} from "../src/BurnableToken.sol";
import {DeployTokens} from "../script/DeployTokens.s.sol";

contract TestingBurnableToken is Test {
    BurnableToken public burnableToken;

    address public owner = address(1);
    address public authorize1 = address(2);
    address public user = address(3);

    function setUp() public {
        DeployTokens deployer = new DeployTokens();
        (, burnableToken, , , ) = deployer.run();
    }

    function test_authorizeByOnlyOwner() public {
        vm.startPrank(owner);
        burnableToken.authorize(authorize1);
        vm.stopPrank();

        bool authorizedOrNot = burnableToken.authorizedUsers(authorize1);
        assertEq(authorizedOrNot, true);
    }

    function test_notAuthorizedUser() public {
        vm.expectRevert();
        vm.startPrank(user);
        burnableToken.authorize(authorize1);
        vm.stopPrank();
    }

    function test_mintByOwner() public {
        vm.startPrank(owner);
        burnableToken.mint(owner, 10 * (10 ** 18));
        vm.stopPrank();

        console.log(burnableToken.balanceOf(owner));

        assertEq(burnableToken.balanceOf(owner), 10 * (10 ** 18));
    }

    function test_mintByAuthorizedUser() public {
        //authorizing the user
        vm.startPrank(owner);
        burnableToken.authorize(authorize1);
        vm.stopPrank();

        //minting by authorized user
        vm.startPrank(authorize1);
        burnableToken.mint(authorize1, 10 * (10 ** 18));
        vm.stopPrank();

        console.log(burnableToken.balanceOf(authorize1));

        assertEq(burnableToken.balanceOf(authorize1), 10 * (10 ** 18));
    }

    function test_mintByUser() public {
        vm.expectRevert();
        vm.startPrank(user);
        burnableToken.mint(authorize1, 10 * (10 ** 18));
        vm.stopPrank();
    }

    function test_mintingEmit() public {
        uint256 amount = 10 * (10 ** 18);

        vm.startPrank(owner);

        // Expect the Minted event
        vm.expectEmit(true, true, true, true);
        emit BurnableToken.Minted(owner, owner, amount);

        // Mint tokens
        burnableToken.mint(owner, amount);

        vm.stopPrank();
    }

    function test_burnFromTokenHolder() public {
        vm.startPrank(owner);
        burnableToken.mint(owner, 10 * (10 ** 18));
        vm.stopPrank();

        uint256 burnedAmount = 5 * (10 ** 18);

        vm.startPrank(owner);
        burnableToken.burn(owner, burnedAmount);
        vm.stopPrank();

        uint256 ownerHoldingAmount = burnableToken.balanceOf(owner);

        assertEq(ownerHoldingAmount, 5 * (10 ** 18));
    }

    function test_BurningEmit() public {
        uint256 initialBalance = 10 * (10 ** 18);
        vm.prank(owner);
        burnableToken.mint(owner, initialBalance);

        uint256 burnedAmount = 5 * (10 ** 18);

        // Expect the Burned event
        vm.expectEmit(true, true, true, true);
        emit BurnableToken.Burned(owner, burnedAmount);

        vm.startPrank(owner);
        burnableToken.burn(owner, burnedAmount);
        vm.stopPrank();
    }

    function test_revokeAuthorization() public {
        vm.prank(owner);
        burnableToken.authorize(authorize1);

        vm.prank(authorize1);
        burnableToken.mint(authorize1, 10 * (10 ** 18));

        vm.prank(owner);
        burnableToken.revokeAuthorization(authorize1);

        vm.prank(authorize1);
        vm.expectRevert();
        burnableToken.mint(authorize1, 10 * (10 ** 18));
    }

    function test_onlyOwnerCanRevokeAuthorization() public {
        vm.prank(owner);
        burnableToken.authorize(authorize1);

        vm.prank(authorize1);
        burnableToken.mint(authorize1, 10 * (10 ** 18));

        vm.prank(user);
        vm.expectRevert();
        burnableToken.revokeAuthorization(authorize1);
    }
}
