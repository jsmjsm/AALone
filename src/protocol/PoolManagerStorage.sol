// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./library/type/DataType.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title PoolManagerStorage
 * @dev Storage contract for managing pool-related data and access control.
 */
contract PoolManagerStorage is AccessControl {
    uint256 public constant DENOMINATOR = 10000;
    bytes32 public constant POOL_ADMIN_ROLE = keccak256("POOL_ADMIN");
    bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN");
    bytes32 public constant LIQUIDATION_ADMIN_ROLE =
        keccak256("LIQUIDATION_ADMIN");

    // Configuration data for the pool manager
    DataTypes.PoolManagerConfig internal _poolManagerConfig;
    // Protocol profit accumulated
    uint256 internal _protocalProfit;

    // Mapping of user addresses to their pool reserve information
    mapping(address => DataTypes.UserPoolReserveInformation)
        internal _userPoolReserveInformation;
    // Mapping of user addresses to their pool configuration
    mapping(address => DataTypes.UserPoolConfig) internal _userPoolConfig;

    /**
     * @dev Sets the configuration for the pool manager.
     * @param configInput The configuration data for the pool manager.
     * Requirements:
     * - The caller must have the POOL_ADMIN_ROLE.
     */
    function setPoolManagerConfig(
        DataTypes.PoolManagerConfig calldata configInput
    ) external onlyRole(POOL_ADMIN_ROLE) {
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
    ) external onlyRole(POOL_ADMIN_ROLE) {
        _userPoolConfig[user] = configInput;
    }

    /**
     * @dev Claims the accumulated protocol earnings.
     * Requirements:
     * - The caller must have the POOL_ADMIN_ROLE.
     */
    function claimProtocolEarnings() external onlyRole(POOL_ADMIN_ROLE) {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        poolManagerConfig.USDT.transfer(msg.sender, _protocalProfit);
    }
}
