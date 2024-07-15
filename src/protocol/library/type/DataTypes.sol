// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../../../interfaces/IFBTC1.sol";
import "../../../interfaces/IOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DataTypes
 * @dev Library containing various data structures used in the pool management system.
 */
library DataTypes {
    /**
     * @dev Structure to hold the configuration of the Pool Manager.
     * @param DEFAULT_LIQUIDATION_THRESHOLD The default maximum withdrawal rate (e.g., 50%).
     * @param DEFAULT_POOL_INTEREST_RATE The default interest rate (e.g., 5%).
     * @param DEFAULT_LTV The default loan-to-value ratio (e.g., 5%).
     * @param PROTOCOL_FEE_INTEREST_RATE The protocol fee ratio.
     * @param USDT The ERC20 USDT contract.
     * @param FBTC0 The ERC20 FBTC0 contract.
     * @param FBTC1 The interface for the FBTC1 contract.
     * @param FBTCOracle The interface for the FBTC Oracle contract.
     * @param AvalonUSDTVault The address of the Avalon USDT vault.
     * @param AntaphaUSDTVault The address of the Antapha USDT vault.
     */
    struct PoolManagerConfig {
        uint256 DEFAULT_LIQUIDATION_THRESHOLD;
        uint256 DEFAULT_POOL_INTEREST_RATE;
        uint256 DEFAULT_LTV;
        uint256 PROTOCOL_FEE_INTEREST_RATE;
        IERC20 USDT;
        IERC20 FBTC0;
        IFBTC1 FBTC1;
        IFBTCOracle FBTCOracle;
        address AvalonUSDTVault;
        address AntaphaUSDTVault;
    }

    struct PoolManagerReserveInformation {
        uint256 userAmount;
        uint256 collateral;
        uint256 debt;
        uint256 claimableUSDT;
        uint256 claimableBTC;
    }

    /**
     * @dev Structure to hold the configuration of a user's pool.
     * @param init A boolean indicating whether the user's pool is initialized.
     * @param interestRate The interest rate for the user's pool.
     * @param loanToValue The loan-to-value ratio for the user's pool.
     * @param liquidationThreshold The maximum withdrawal rate for the user's pool.
     */
    struct UserPoolConfig {
        bool init;
        uint256 interestRate;
        uint256 loanToValue;
        uint256 liquidationThreshold;
    }

    /**
     * @dev Structure to hold the reserve information of a user's pool.
     * @param timeStampIndex The timestamp when the user last borrowed.
     * @param collateral The total supply in the user's pool.
     * @param debt The total amount borrowed from the user's pool.
     * @param claimableUSDT The amount currently in borrowing.
     * @param claimableBTC The amount currently in withdrawing.
     */
    struct UserPoolReserveInformation {
        uint40 timeStampIndex;
        uint256 collateral;
        uint256 debt;
        uint256 debtToProtocol;
        uint256 claimableUSDT;
        uint256 claimableBTC;
    }
}
