// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MintableToken} from "../src/MintableToken.sol";
import {BurnableToken} from "../src/BurnableToken.sol";
import {PausableToken} from "../src/PausableToken.sol";
import {CappedToken} from "../src/CappedToken.sol";
import {TimeLockToken} from "../src/TimeLockToken.sol";

contract DeployTokens is Script {
    function run()
        external
        returns (
            MintableToken,
            BurnableToken,
            PausableToken,
            CappedToken,
            TimeLockToken
        )
    {
        uint256 cappedAmount = 1000000000000000000000000000;
        address owner = address(1);

        vm.startBroadcast(owner);
        MintableToken mintableToken = new MintableToken("Bunny", "BUN");
        BurnableToken burnableToken = new BurnableToken("Rabbit", "RB");
        PausableToken pausableToken = new PausableToken("Pigg", "PG");
        CappedToken cappedToken = new CappedToken("Deer", "Dr", cappedAmount);
        TimeLockToken timeLockToken = new TimeLockToken(
            "rhino",
            "rhn",
            cappedAmount
        );
        vm.stopBroadcast();

        return (
            mintableToken,
            burnableToken,
            pausableToken,
            cappedToken,
            timeLockToken
        );
    }
}
