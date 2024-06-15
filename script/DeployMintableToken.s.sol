// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MintableToken} from "../src/MintableToken.sol";

contract DeployMintableToken is Script {
    function run() external returns (MintableToken) {
        address owner = address(1);
        vm.startBroadcast(owner);
        MintableToken mintableToken = new MintableToken("Bunny", "BUN");
        vm.stopBroadcast();

        return mintableToken;
    }
}
