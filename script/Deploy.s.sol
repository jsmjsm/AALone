// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/protocol/PoolManager.sol";
import "../src/protocol/FBTCOracle.sol";
import "../src/protocol/library/type/DataTypes.sol";

contract DeployMyContract is Script {
    function run() external {
        address initialOwner = address(this); // Replace with actual address
        AggregatorInterface assetSource = AggregatorInterface(address(this)); // Replace with actual address
        address usdtAddress = address(this); // Replace with actual address
        address fbtc0Address = address(this); // Replace with actual address
        address fbtc1Address = address(this); // Replace with actual address
        address avalonUSDTVault = address(this); // Replace with actual address
        address antaphaUSDTVault = address(this); // Replace with actual address
        uint256 DEFAULT_MAX_WITHDRAW_RATE = 0.05 * 1e18; // Example value
        uint256 DEFAULT_POOL_INTEREST_RATE = 0.03 * 1e18; // Example value
        uint256 DEFAULT_LTV = 0.75 * 1e18; // Example value
        uint256 PROTOCAL_FEE_INTEREST_RATE = 0.01 * 1e18; // Example value

        // Deploy FBTCOracle
        vm.startBroadcast();
        FBTCOracle fbtcOracle = new FBTCOracle(assetSource, initialOwner);
        vm.stopBroadcast();

        // Print FBTCOracle address for reference
        console.log("FBTCOracle deployed at:", address(fbtcOracle));

        DataTypes.PoolManagerConfig memory poolManagerConfig = DataTypes
            .PoolManagerConfig({
                DEFAULT_MAX_WITHDRAW_RATE: DEFAULT_MAX_WITHDRAW_RATE,
                DEFAULT_POOL_INTEREST_RATE: DEFAULT_POOL_INTEREST_RATE,
                DEFAULT_LTV: DEFAULT_LTV,
                PROTOCAL_FEE_INTEREST_RATE: PROTOCAL_FEE_INTEREST_RATE,
                USDT: IERC20(usdtAddress),
                FBTC0: IERC20(fbtc0Address),
                FBTC1: IFBTC1(fbtc1Address),
                FBTCOracle: IFBTCOracle(address(fbtcOracle)),
                AvalonUSDTVault: vm.envAddress("AVALON_USDT_VAULT"),
                AntaphaUSDTVault: vm.envAddress("ANTAPHA_USDT_VAULT")
            });

        vm.startBroadcast();

        PoolManager poolManager = new PoolManager(
            poolManagerConfig,
            initialOwner
        );

        vm.stopBroadcast();

        // Print PoolManager address for reference
        console.log("PoolManager deployed at:", address(poolManager));
    }
}
