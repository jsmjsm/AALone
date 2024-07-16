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

contract borrow is Script {
    function run() external {
        address FBTC0 = vm.envAddress("FBTC0"); // Replace with actual address
        address user = vm.envAddress("USER_ADDRESS"); // Replace with actual address
        address proxy = vm.envAddress("PROXY"); // Replace with actual address
        address USDT = vm.envAddress("USDT"); // Replace with actual addresss
        address avalonUSDTVault = vm.envAddress("AVALON_USDT_VAULT");
        address antaphaUSDTVault = vm.envAddress("ANTAPHA_USDT_VAULT");

        DataTypes.UserPoolReserveInformation memory reserveInfo = PoolManager(
            address(proxy)
        ).getUserPoolReserveInformation(user);

        console.log(reserveInfo.timeStampIndex);
        console.log(reserveInfo.collateral);
        console.log(reserveInfo.debt);
        console.log(reserveInfo.claimableUSDT);
        console.log(reserveInfo.claimableBTC);

        console.log(MockERC20(USDT).balanceOf(user));
        console.log(MockERC20(USDT).balanceOf(avalonUSDTVault));
        console.log(MockERC20(USDT).balanceOf(antaphaUSDTVault));
        console.log(PoolManager(address(proxy)).getProtocolProfitUnclaimed());
    }
}
