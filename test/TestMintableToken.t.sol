// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MintableToken} from "../src/MintableToken.sol";
import {DeployTokens} from "../script/DeployTokens.s.sol";

contract TestingMintableToken is Test {
    MintableToken public mintableToken;
    address public owner = address(1);
    address public authorize1 = address(2);
    address public user = address(3);

    function setUp() public {
        DeployTokens deployer = new DeployTokens();
        (mintableToken, , , , ) = deployer.run();
    }

    function test_authorizeByOnlyOwner() public {
        vm.startPrank(owner);
        mintableToken.authorize(authorize1);
        vm.stopPrank();

        bool authorizedOrNot = mintableToken.authorizedUsers(authorize1);
        assertEq(authorizedOrNot, true);
    }

    function test_notAuthorizedUser() public {
        vm.expectRevert();
        vm.startPrank(user);
        mintableToken.authorize(authorize1);
        vm.stopPrank();
    }

    function test_mintByOwner() public {
        vm.startPrank(owner);
        mintableToken.mint(owner, 10 * (10 ** 18));
        vm.stopPrank();

        console.log(mintableToken.balanceOf(owner));

        assertEq(mintableToken.balanceOf(owner), 10 * (10 ** 18));
    }

    function test_mintByAuthorizedUser() public {
        //authorizing the user
        vm.startPrank(owner);
        mintableToken.authorize(authorize1);
        vm.stopPrank();

        //minting by authorized user
        vm.startPrank(authorize1);
        mintableToken.mint(authorize1, 10 * (10 ** 18));
        vm.stopPrank();

        console.log(mintableToken.balanceOf(authorize1));

        assertEq(mintableToken.balanceOf(authorize1), 10 * (10 ** 18));
    }

    function test_mintByUser() public {
        vm.expectRevert();
        vm.startPrank(user);
        mintableToken.mint(authorize1, 10 * (10 ** 18));
        vm.stopPrank();
    }

    function test_mintingEmit() public {
        uint256 amount = 10 * (10 ** 18);

        vm.startPrank(owner);

        // Expect the Minted event
        vm.expectEmit(true, true, true, true);
        emit MintableToken.Minted(owner, owner, amount);

        // Mint tokens
        mintableToken.mint(owner, amount);

        vm.stopPrank();
    }

    function test_revokeAuthorization() public {
        vm.prank(owner);
        mintableToken.authorize(authorize1);

        vm.prank(authorize1);
        mintableToken.mint(authorize1, 10 * (10 ** 18));

        vm.prank(owner);
        mintableToken.revokeAuthorization(authorize1);

        vm.prank(authorize1);
        vm.expectRevert();
        mintableToken.mint(authorize1, 10 * (10 ** 18));
    }

    function test_onlyOwnerCanRevokeAuthorization() public {
        vm.prank(owner);
        mintableToken.authorize(authorize1);

        vm.prank(authorize1);
        mintableToken.mint(authorize1, 10 * (10 ** 18));

        vm.prank(user);
        vm.expectRevert();
        mintableToken.revokeAuthorization(authorize1);
    }
}
