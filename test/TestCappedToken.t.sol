// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CappedToken} from "../src/CappedToken.sol";
import {DeployTokens} from "../script/DeployTokens.s.sol";

contract TestingBurnableToken is Test {
    CappedToken public cappedToken;

    uint256 cappedAmount = 1000000000000000000000000000;
    uint256 testCapValue = 100000000000;
    address public owner = address(1);
    address public authorize1 = address(2);
    address public user = address(3);

    function setUp() public {
        DeployTokens deployer = new DeployTokens();
        (, , , cappedToken, ) = deployer.run();
    }

    function test_authorizeByOnlyOwner() public {
        vm.startPrank(owner);
        cappedToken.authorize(authorize1);
        vm.stopPrank();

        bool authorizedOrNot = cappedToken.authorizedUsers(authorize1);
        assertEq(authorizedOrNot, true);
    }

    function test_notAuthorizedUser() public {
        vm.expectRevert();
        vm.startPrank(user);
        cappedToken.authorize(authorize1);
        vm.stopPrank();
    }

    function test_mintByOwner() public {
        vm.startPrank(owner);
        cappedToken.mint(owner, 10 * (10 ** 18));
        vm.stopPrank();

        console.log(cappedToken.balanceOf(owner));

        assertEq(cappedToken.balanceOf(owner), 10 * (10 ** 18));
    }

    function test_mintByAuthorizedUser() public {
        //authorizing the user
        vm.startPrank(owner);
        cappedToken.authorize(authorize1);
        vm.stopPrank();

        //minting by authorized user
        vm.startPrank(authorize1);
        cappedToken.mint(authorize1, 10 * (10 ** 18));
        vm.stopPrank();

        console.log(cappedToken.balanceOf(authorize1));

        assertEq(cappedToken.balanceOf(authorize1), 10 * (10 ** 18));
    }

    function test_mintByUser() public {
        vm.expectRevert();
        vm.startPrank(user);
        cappedToken.mint(authorize1, 10 * (10 ** 18));
        vm.stopPrank();
    }

    function test_mintingEmit() public {
        uint256 amount = 10 * (10 ** 18);

        vm.startPrank(owner);

        // Expect the Minted event
        vm.expectEmit(true, true, true, true);
        emit CappedToken.Minted(owner, owner, amount);

        // Mint tokens
        cappedToken.mint(owner, amount);

        vm.stopPrank();
    }

    function test_burnFromTokenHolder() public {
        vm.startPrank(owner);
        cappedToken.mint(owner, 10 * (10 ** 18));
        vm.stopPrank();

        uint256 burnedAmount = 5 * (10 ** 18);

        vm.startPrank(owner);
        cappedToken.burn(owner, burnedAmount);
        vm.stopPrank();

        uint256 ownerHoldingAmount = cappedToken.balanceOf(owner);

        assertEq(ownerHoldingAmount, 5 * (10 ** 18));
    }

    function test_BurningEmit() public {
        uint256 initialBalance = 10 * (10 ** 18);
        vm.prank(owner);
        cappedToken.mint(owner, initialBalance);

        uint256 burnedAmount = 5 * (10 ** 18);

        // Expect the Burned event
        vm.expectEmit(true, true, true, true);
        emit CappedToken.Burned(owner, burnedAmount);

        vm.startPrank(owner);
        cappedToken.burn(owner, burnedAmount);
        vm.stopPrank();
    }

    function test_Pause() public {
        vm.startPrank(owner);
        cappedToken.mint(owner, 10 * (10 ** 18));
        cappedToken.pause();
        vm.stopPrank();

        assertEq(cappedToken.paused(), true);

        vm.prank(owner);
        vm.expectRevert();
        cappedToken.transfer(user, 1 * (10 ** 18));
    }

    function test_PauseOnlyOwner() public {
        vm.prank(user);
        vm.expectRevert();
        cappedToken.pause();
    }

    function test_Unpause() public {
        vm.startPrank(owner);

        cappedToken.mint(owner, 10 * (10 ** 18));

        cappedToken.pause();

        cappedToken.unpause();

        cappedToken.transfer(user, 1 * (10 ** 18));
        vm.stopPrank();
        uint256 balanceOfUser = cappedToken.balanceOf(user);

        assertEq(balanceOfUser, 1 * (10 ** 18));
    }

    function test_revokeAuthorization() public {
        vm.prank(owner);
        cappedToken.authorize(authorize1);

        vm.prank(authorize1);
        cappedToken.mint(authorize1, 10 * (10 ** 18));

        vm.prank(owner);
        cappedToken.revokeAuthorization(authorize1);

        vm.prank(authorize1);
        vm.expectRevert();
        cappedToken.mint(authorize1, 10 * (10 ** 18));
    }

    function test_onlyOwnerCanRevokeAuthorization() public {
        vm.prank(owner);
        cappedToken.authorize(authorize1);

        vm.prank(authorize1);
        cappedToken.mint(authorize1, 10 * (10 ** 18));

        vm.prank(user);
        vm.expectRevert();
        cappedToken.revokeAuthorization(authorize1);
    }

    function test_capValue() public view {
        assertEq(cappedToken.cap(), cappedAmount);
    }

    function test_ErrorMintMoreThanCapValue() public {
        vm.prank(owner);
        vm.expectRevert();
        cappedToken.mint(authorize1, testCapValue * (10 ** 18));
    }
}
