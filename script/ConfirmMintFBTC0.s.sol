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

contract ConfirmMintFBTC0 is Script {
    function run() external {
        address FBTC0 = vm.envAddress("FBTC0"); // Replace with actual address
        address user = vm.envAddress("USER_ADDRESS"); // Replace with actual address
        address proxy = vm.envAddress("PROXY"); // Replace with actual address

        vm.startBroadcast();
        PoolManager(address(proxy)).confirmMintFBTC0(
            495347,
            bytes32(
                0xcd731a2eba545379d7d37e1a747ac442b83982fa4feb326892734e1dc9d63d62
            ),
            0
        );
        console.log("RequestBorrow success");
        vm.stopBroadcast();
    }
}
