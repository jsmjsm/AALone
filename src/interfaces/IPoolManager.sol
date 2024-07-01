// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "../protocol/library/type/DataTypes.sol";

interface IPoolManager {
    event PoolCreated(
        address indexed user,
        DataTypes.UserPoolConfig userPoolConfig
    );
    event TokensSupplied(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );

    event LoanRequested(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );

    event TokensBorrowed(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );
    event TokensRepaid(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );
    event Liquidation(
        address indexed user,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );
    event WithdrawalRequested(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );
    event MintFBTC0Confirmed(
        uint256 amount,
        bytes32 depositTxid,
        uint256 outputIndex
    );
    event TokensWithdrawn(
        address indexed user,
        uint256 amount,
        DataTypes.UserPoolReserveInformation userPoolReserveInformation
    );
}
