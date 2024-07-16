// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/protocol/PoolManager.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract UpgradeScript is Script {
    function run() external {
        address proxyAdminAddress = vm.envAddress("PROXY_ADMIN_ADDRESS");
        address proxyAddress = vm.envAddress("PROXY");

        vm.startBroadcast();

        PoolManager poolManager = new PoolManager();
        console.log(
            "New poolManager implementation deployed to:",
            address(poolManager)
        );

        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(proxyAddress),
            address(poolManager),
            ""
        );
        console.log(
            "Proxy upgraded to new implementation:",
            address(poolManager)
        );

        vm.stopBroadcast();
    }
}
