// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "../protocol/library/type/DataTypes.sol";

interface IPoolManager {
    event PoolCreated(
        address indexed user,
        DataTypes.UserPoolConfig userPoolConfig
    );
    event Supply(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );

    event Borrow(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );

    event ClaimUSDT(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );
    event Repay(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );
    event Liquidation(address indexed user, uint256 collateral, uint256 debt);
    event Withdraw(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );
    event RequestMintFBTC0(
        uint256 amount,
        bytes32 depositTxid,
        uint256 outputIndex
    );
    event ClaimBTC(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );
}
