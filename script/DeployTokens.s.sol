// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MintableToken} from "../src/MintableToken.sol";
import {BurnableToken} from "../src/BurnableToken.sol";
import {PausableToken} from "../src/PausableToken.sol";

contract DeployTokens is Script {
    function run()
        external
        returns (MintableToken, BurnableToken, PausableToken)
    {
        address owner = address(1);

        vm.startBroadcast(owner);
        MintableToken mintableToken = new MintableToken("Bunny", "BUN");
        BurnableToken burnableToken = new BurnableToken("Rabbit", "RB");
        PausableToken pausableToken = new PausableToken("Pigg", "PG");
        vm.stopBroadcast();

        return (mintableToken, burnableToken, pausableToken);
    }
}
