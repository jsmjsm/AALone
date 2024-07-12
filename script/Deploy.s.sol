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

contract DeployMyContract is Script {
    function run() external {
        address user = vm.envAddress("USER_ADDRESS"); // Replace with actual address
        address initialOwner = vm.envAddress("OWNER"); // Replace with actual address
        address fbtc0Address = vm.envAddress("FBTC0"); // Replace with actual address
        address fbtc1Address = vm.envAddress("FBTC1"); // Replace with actual address
        address avalonUSDTVault = vm.envAddress("AVALON_USDT_VAULT");
        address antaphaUSDTVault = vm.envAddress("ANTAPHA_USDT_VAULT");
        uint256 DEFAULT_LIQUIDATION_THRESHOLD = 5000; // Example value
        uint256 DEFAULT_POOL_INTEREST_RATE = 1000; // Example value
        uint256 DEFAULT_LTV = 7500;
        uint256 PROTOCAL_FEE_INTEREST_RATE = 100; // Example value

        vm.startBroadcast();
        MockERC20 usdt = new MockERC20("Tether USD", "USDT", 6);
        console.log("USDT deployed at:", address(usdt));
        usdt.mint(user, 1000000000000 * 10 ** 6); // Mint 1,000,000 USDT to initialOwner
        console.log("Mint success, user USDT balance", usdt.balanceOf(user));
        vm.stopBroadcast();

        vm.startBroadcast();
        AggregatorMock mockAggregator = new AggregatorMock();
        mockAggregator.setLatestAnswer(60000 * 1e8); // Assuming 8 decimals for price feed
        console.log("AggregatorMock deployed at:", address(mockAggregator));
        console.logInt(mockAggregator.latestAnswer());
        console.logUint(mockAggregator.decimals());
        vm.stopBroadcast();

        // Deploy FBTCOracle
        vm.startBroadcast();
        FBTCOracle fbtcOracle = new FBTCOracle(mockAggregator, initialOwner);
        console.log("FBTCOracle deployed at:", address(fbtcOracle));
        console.logUint(fbtcOracle.getAssetPrice());
        console.logUint(fbtcOracle.decimals());
        vm.stopBroadcast();

        DataTypes.PoolManagerConfig memory poolManagerConfig = DataTypes
            .PoolManagerConfig({
                DEFAULT_LIQUIDATION_THRESHOLD: DEFAULT_LIQUIDATION_THRESHOLD,
                DEFAULT_POOL_INTEREST_RATE: DEFAULT_POOL_INTEREST_RATE,
                DEFAULT_LTV: DEFAULT_LTV,
                PROTOCAL_FEE_INTEREST_RATE: PROTOCAL_FEE_INTEREST_RATE,
                USDT: usdt,
                FBTC0: IERC20(fbtc0Address),
                FBTC1: IFBTC1(fbtc1Address),
                FBTCOracle: IFBTCOracle(address(fbtcOracle)),
                AvalonUSDTVault: avalonUSDTVault,
                AntaphaUSDTVault: antaphaUSDTVault
            });

        vm.startBroadcast();

        // Deploy ProxyAdmin contract
        ProxyAdmin proxyAdmin = new ProxyAdmin(initialOwner);
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));

        // Deploy logic contract
        PoolManager poolManager = new PoolManager();
        console.log(
            "PoolManager logic contract deployed at:",
            address(poolManager)
        );

        // Initialize data
        bytes memory data = abi.encodeWithSignature(
            "initialize(address)",
            initialOwner
        );

        // Deploy TransparentUpgradeableProxy contract
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(poolManager),
            address(proxyAdmin),
            data
        );
        console.log("Proxy deployed at:", address(proxy));

        PoolManager(address(proxy)).setPoolManagerConfig(poolManagerConfig);
        console.log("Proxy setConfig success");
        vm.stopBroadcast();
    }
}
