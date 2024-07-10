// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./PoolManagerStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title PoolManagerConfigurator
 */
contract PoolManagerConfigurator is PoolManagerStorage, OwnableUpgradeable {
    function initialize(address owner) public initializer {
        __Ownable_init(owner);
    }

    /**
     * @dev Sets the configuration for the pool manager.
     * @param configInput The configuration data for the pool manager.
     * Requirements:
     * - The caller must have the POOL_ADMIN_ROLE.
     */
    function setPoolManagerConfig(
        DataTypes.PoolManagerConfig calldata configInput
    ) external onlyOwner {
        _poolManagerConfig = configInput;
    }

    /**
     * @dev Sets the configuration for a user's pool.
     * @param user The address of the user.
     * @param configInput The configuration data for the user's pool.
     * Requirements:
     * - The caller must have the POOL_ADMIN_ROLE.
     */
    function setUserPoolConfig(
        address user,
        DataTypes.UserPoolConfig calldata configInput
    ) external onlyOwner {
        _userPoolConfig[user] = configInput;
    }

    /**
     * @dev Returns the pool manager configuration.
     * @return The pool manager configuration as a `DataTypes.PoolManagerConfig` struct.
     */
    function getPoolManagerConfig()
        external
        view
        returns (DataTypes.PoolManagerConfig memory)
    {
        return _poolManagerConfig;
    }

    /**
     * @dev Returns the unclaimed protocol profit.
     * @return The amount of unclaimed protocol profit.
     */
    function getProtocolProfitUnclaimed() external view returns (uint256) {
        return _protocalProfitUnclaimed;
    }

    /**
     * @dev Returns the accumulated protocol profit.
     * @return The total accumulated protocol profit.
     */
    function getProtocalProfitAccumulate() external view returns (uint256) {
        return _protocalProfitAccumulate;
    }

    /**
     * @dev Returns the user's pool reserve information.
     * @param user The address of the user.
     * @return The user's pool reserve information as a `DataTypes.UserPoolReserveInformation` struct.
     */
    function getUserPoolReserveInformation(
        address user
    )
        external
        view
        virtual
        returns (DataTypes.UserPoolReserveInformation memory)
    {
        return _userPoolReserveInformation[user];
    }

    /**
     * @dev Returns the user's pool configuration.
     * @param user The address of the user.
     * @return The user's pool configuration as a `DataTypes.UserPoolConfig` struct.
     */
    function getUserPoolConfig(
        address user
    ) external view returns (DataTypes.UserPoolConfig memory) {
        return _userPoolConfig[user];
    }
}
