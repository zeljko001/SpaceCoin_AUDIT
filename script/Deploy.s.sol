//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {ICO} from "../src/ICO.sol";
import {SpaceCoin} from "../src/SpaceCoin.sol";

contract Deploy is Script {

    address treasuryAccount = 0xB3B02E7767bF65d5693a2056C417eC4E3e876Eb7; //1
    address[] private allowList = [0x30C816eB8F5701b12687269F2601Cb6ff8A20510, 0x87F9139461e3781B011d18094f19Bc3f86876cF3];//2,3
    // following 2 lines are used for testing.
    // address treasuryAccount = address(1); //1
    // address[] private allowList = [address(2), address(3)];//2,3

    function run() external returns (SpaceCoin, ICO){
        vm.startBroadcast();
        SpaceCoin spaceCoin = new SpaceCoin(treasuryAccount, allowList);
        ICO icoContract = ICO(spaceCoin.getIcoContractAddress());
        vm.stopBroadcast();
        return (spaceCoin, icoContract);
    }
}