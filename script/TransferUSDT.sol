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

contract Transfer is Script {
    function run() external {
        address FBTC0 = vm.envAddress("FBTC0"); // Replace with actual address
        address to = vm.envAddress("AvalonUSDTVault");
        console.log(MockERC20(address(FBTC0)).balanceOf(msg.sender));
        vm.startBroadcast();
        MockERC20(address(FBTC0)).transfer(
            to,
            MockERC20(address(FBTC0)).balanceOf(msg.sender)
        );
        console.log("createPool success");
        vm.stopBroadcast();
    }
}
