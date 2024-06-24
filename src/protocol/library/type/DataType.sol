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
     * @param DEFAULT_MAX_WITHDRAW_RATE The default maximum withdrawal rate (e.g., 50%).
     * @param DEFAULT_BORROWED_TIMESTAMP The default borrowed timestamp.
     * @param DEFAULT_INTEREST_RATE The default interest rate (e.g., 5%).
     * @param DEFAULT_LTV The default loan-to-value ratio (e.g., 5%).
     * @param PROTOCAL_FEE_INTEREST_RATE The protocol fee ratio.
     * @param USDT The ERC20 USDT contract.
     * @param FBTC0 The ERC20 FBTC0 contract.
     * @param FBTC1 The interface for the FBTC1 contract.
     * @param FBTCOracle The interface for the FBTC Oracle contract.
     * @param AvalonUSDTVault The address of the Avalon USDT vault.
     * @param AntaphaUSDTVault The address of the Antapha USDT vault.
     */
    struct PoolManagerConfig {
        uint256 DEFAULT_MAX_WITHDRAW_RATE;
        uint256 DEFAULT_BORROWED_TIMESTAMP;
        uint256 DEFAULT_INTEREST_RATE;
        uint256 DEFAULT_LTV;
        uint256 PROTOCAL_FEE_INTEREST_RATE;
        IERC20 USDT;
        IERC20 FBTC0;
        IFBTC1 FBTC1;
        IFBTCOracle FBTCOracle;
        address AvalonUSDTVault;
        address AntaphaUSDTVault;
    }

    /**
     * @dev Structure to hold the configuration of a user's pool.
     * @param init A boolean indicating whether the user's pool is initialized.
     * @param interestRate The interest rate for the user's pool.
     * @param loanToValue The loan-to-value ratio for the user's pool.
     * @param maxWithdrawRate The maximum withdrawal rate for the user's pool.
     */
    struct UserPoolConfig {
        bool init;
        uint256 interestRate;
        uint256 loanToValue;
        uint256 maxWithdrawRate;
    }

    /**
     * @dev Structure to hold the reserve information of a user's pool.
     * @param borrowedTimeStamp The timestamp when the user last borrowed.
     * @param totalSupply The total supply in the user's pool.
     * @param totalBorrowed The total amount borrowed from the user's pool.
     * @param inBorrowing The amount currently in borrowing.
     * @param inWithdrawing The amount currently in withdrawing.
     */
    struct UserPoolReserveInformation {
        uint40 borrowedTimeStamp;
        uint256 totalSupply;
        uint256 totalBorrowed;
        uint256 inBorrowing;
        uint256 inWithdrawing;
    }
}
