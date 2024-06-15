// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MintableToken} from "../src/MintableToken.sol";
import {BurnableToken} from "../src/BurnableToken.sol";

contract DeployTokens is Script {
    function run() external returns (MintableToken, BurnableToken) {
        address owner = address(1);

        vm.startBroadcast(owner);
        MintableToken mintableToken = new MintableToken("Bunny", "BUN");
        BurnableToken burnableToken = new BurnableToken("Rabbit", "RB");
        vm.stopBroadcast();

        return (mintableToken, burnableToken);
    }
}
