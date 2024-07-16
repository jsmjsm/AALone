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

contract Approve is Script {
    function run() external {
        address token = vm.envAddress("USDT"); // Replace with actual addresss
        vm.startBroadcast();
        MockERC20(address(token)).approve(
            vm.envAddress("PROXY"),
            type(uint256).max
        );
        console.log("Approve success");
        vm.stopBroadcast();
    }
}
