// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/protocol/PoolManager.sol";
import "../src/protocol/FBTCOracle.sol";
import "../test/mock/MockAggregator.sol";
import "../test/mock/MockERC20.sol";
import "../src/protocol/library/type/DataTypes.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract Supply is Script {
    function run() external {
        address FBTC0 = vm.envAddress("FBTC0"); // Replace with actual address
        address user = vm.envAddress("USER_ADDRESS"); // Replace with actual address
        address proxy = vm.envAddress("PROXY"); // Replace with actual address

        console.log(MockERC20(address(FBTC0)).balanceOf(user));
        // vm.startBroadcast();
        // PoolManager(address(proxy)).supply(1500000);
        // console.log("Supply success");
        // vm.stopBroadcast();
    }
}
