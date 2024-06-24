// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./PoolManagerStorage.sol";
import "./library/math/MathUtils.sol";
import "./library/math/WadRayMath.sol";

/**
 * @title PoolManager
 * @dev Manages liquidity pools and related operations.
 */
contract PoolManager is PoolManagerStorage {
    using WadRayMath for uint256;
    using MathUtils for uint256;

    /**
     * @dev Constructor to initialize the pool manager configuration.
     * @param poolManagerConfig The configuration parameters for the pool manager.
     */
    constructor(DataTypes.PoolManagerConfig memory poolManagerConfig) {
        _poolManagerConfig = poolManagerConfig;
    }

    /**
     * @dev Creates a new liquidity pool.
     * Requirements:
     * - The caller must have the POOL_ADMIN_ROLE.
     * - The pool must not have been initialized.
     */
    function createPool() external onlyRole(POOL_ADMIN_ROLE) {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        DataTypes.UserPoolConfig storage userPoolConfig = _userPoolConfig[
            msg.sender
        ];
        require(!userPoolConfig.init, "Pool already initialized");
        userPoolConfig.init = true;
        userPoolConfig.interestRate = poolManagerConfig.DEFAULT_INTEREST_RATE;
        userPoolConfig.maxWithdrawRate = poolManagerConfig
            .DEFAULT_MAX_WITHDRAW_RATE;
        userPoolConfig.loanToValue = poolManagerConfig.DEFAULT_LTV;
    }

    /**
     * @dev Supplies tokens to the pool.
     * @param amount The amount of tokens to supply.
     * Requirements:
     * - The pool must have been initialized.
     */
    function supply(uint256 amount) external {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        DataTypes.UserPoolConfig storage userPoolConfig = _userPoolConfig[
            msg.sender
        ];
        DataTypes.UserPoolReserveInformation
            storage userPoolReserveInformation = _userPoolReserveInformation[
                msg.sender
            ];

        require(userPoolConfig.init, "Pool not initialized");

        poolManagerConfig.FBTC0.transferFrom(msg.sender, address(this), amount);

        userPoolReserveInformation.totalSupply += amount;
    }

    /**
     * @dev Requests a loan from the pool.
     * @param amount The amount of the loan requested.
     * Requirements:
     * - The pool must have been initialized.
     * - The requested amount must not exceed the allowable loan-to-value ratio.
     */
    function requestBorrow(uint256 amount) external {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        DataTypes.UserPoolConfig storage userPoolConfig = _userPoolConfig[
            msg.sender
        ];
        DataTypes.UserPoolReserveInformation
            storage userPoolReserveInformation = _userPoolReserveInformation[
                msg.sender
            ];

        require(userPoolConfig.init, "Pool not initialized");
        require(
            calculateMaxBorrowAmount(
                userPoolConfig.loanToValue,
                userPoolReserveInformation.totalSupply,
                userPoolReserveInformation.inBorrowing,
                poolManagerConfig.FBTCOracle.getAssetPrice()
            ) >= amount,
            "Requested amount exceeds allowable loanToValue"
        );

        poolManagerConfig.FBTC1.mintLockedFbtcRequest(amount);
        userPoolReserveInformation.inBorrowing += amount;
    }

    /**
     * @dev Borrows tokens from the pool.
     * @param amount The amount of tokens to borrow.
     * Requirements:
     * - The pool must have been initialized.
     * - The amount to borrow must not exceed the inBorrowing amount.
     */
    function borrow(uint256 amount) external {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        DataTypes.UserPoolConfig storage userPoolConfig = _userPoolConfig[
            msg.sender
        ];
        DataTypes.UserPoolReserveInformation
            storage userPoolReserveInformation = _userPoolReserveInformation[
                msg.sender
            ];

        require(userPoolConfig.init, "Pool not initialized");
        require(
            userPoolReserveInformation.inBorrowing >= amount,
            "Insufficient inBorrowing amount"
        );

        updateDebt(msg.sender);
        userPoolReserveInformation.totalBorrowed += amount;
        userPoolReserveInformation.inBorrowing -= amount;
        poolManagerConfig.USDT.transferFrom(
            poolManagerConfig.AvalonUSDTVault,
            msg.sender,
            amount
        );
    }

    /**
     * @dev Repays borrowed tokens.
     * @param amount The amount of tokens to repay.
     * Requirements:
     * - The pool must have been initialized.
     */
    function repay(uint256 amount) external payable {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        DataTypes.UserPoolConfig storage userPoolConfig = _userPoolConfig[
            msg.sender
        ];
        DataTypes.UserPoolReserveInformation
            storage userPoolReserveInformation = _userPoolReserveInformation[
                msg.sender
            ];

        require(userPoolConfig.init, "Pool not initialized");

        (uint256 fee1, uint256 fee2) = updateDebt(msg.sender);

        poolManagerConfig.USDT.transferFrom(
            msg.sender,
            poolManagerConfig.AntaphaUSDTVault,
            fee1
        );
        poolManagerConfig.USDT.transferFrom(msg.sender, address(this), fee2);

        userPoolReserveInformation.totalBorrowed -= amount;
    }

    /**
     * @dev Liquidates a user's pool reserve information.
     * @param user The address of the user whose pool reserve information is to be liquidated.
     * @param userPoolReserveInformation The user's pool reserve information to be updated.
     * Requirements:
     * - The caller must have the LIQUIDATION_ADMIN_ROLE.
     */
    function liquidate(
        address user,
        DataTypes.UserPoolReserveInformation memory userPoolReserveInformation
    ) external onlyRole(LIQUIDATION_ADMIN_ROLE) {
        _userPoolReserveInformation[user] = userPoolReserveInformation;
    }

    /**
     * @dev Requests a withdrawal from the pool.
     * @param amount The amount to withdraw.
     * Requirements:
     * - The pool must have been initialized.
     * - The requested amount must not exceed the maximum allowable withdraw amount.
     */
    function requestWithdraw(uint256 amount) external {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        DataTypes.UserPoolConfig memory userPoolConfig = _userPoolConfig[
            msg.sender
        ];
        DataTypes.UserPoolReserveInformation
            storage userPoolReserveInformation = _userPoolReserveInformation[
                msg.sender
            ];

        require(userPoolConfig.init, "Pool not initialized");
        require(
            calculateMaxWithdrawAmount(
                userPoolConfig.maxWithdrawRate,
                userPoolReserveInformation.totalSupply,
                userPoolReserveInformation.inBorrowing,
                poolManagerConfig.FBTCOracle.getAssetPrice()
            ) >= amount,
            "Exceed withdraw limit"
        );

        userPoolReserveInformation.totalSupply -= amount;
        userPoolReserveInformation.inWithdrawing += amount;
    }

    /**
     * @dev Confirms the minting of FBTC0 tokens.
     * @param amount The amount of FBTC0 tokens.
     * @param depositTxid The transaction ID of the deposit.
     * @param outputIndex The output index of the deposit transaction.
     */
    function confirmMintFBTC0(
        uint256 amount,
        bytes32 depositTxid,
        uint256 outputIndex
    ) external {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;

        poolManagerConfig.FBTC1.redeemFbtcRequest(
            amount,
            depositTxid,
            outputIndex
        );
    }

    /**
     * @dev Withdraws tokens from the pool.
     * @param amount The amount of tokens to withdraw.
     * Requirements:
     * - The pool must have been initialized.
     */
    function withdraw(uint256 amount) external {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        DataTypes.UserPoolConfig memory userPoolConfig = _userPoolConfig[
            msg.sender
        ];
        DataTypes.UserPoolReserveInformation
            storage userPoolReserveInformation = _userPoolReserveInformation[
                msg.sender
            ];

        require(userPoolConfig.init, "Pool not initialized");
        userPoolReserveInformation.inWithdrawing -= amount;
        poolManagerConfig.FBTC0.transferFrom(address(this), msg.sender, amount);
    }

    /**
     * @dev Gets the user's pool reserve information.
     * @param user The address of the user.
     * @return reserveAfterUpdateDebt The user's pool reserve information after updating the debt.
     */
    function getUserPoolReserveInformation(
        address user
    )
        external
        view
        returns (
            DataTypes.UserPoolReserveInformation memory reserveAfterUpdateDebt
        )
    {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        DataTypes.UserPoolConfig memory userPoolConfig = _userPoolConfig[user];
        DataTypes.UserPoolReserveInformation
            memory userPoolReserveInformation = _userPoolReserveInformation[
                user
            ];
        reserveAfterUpdateDebt.borrowedTimeStamp = userPoolReserveInformation
            .borrowedTimeStamp;
        reserveAfterUpdateDebt.totalSupply = userPoolReserveInformation
            .totalSupply;
        reserveAfterUpdateDebt.inBorrowing = userPoolReserveInformation
            .inBorrowing;
        reserveAfterUpdateDebt.inWithdrawing = userPoolReserveInformation
            .inWithdrawing;
        reserveAfterUpdateDebt.totalBorrowed = userPoolReserveInformation
            .totalBorrowed
            .rayMul(
                MathUtils.calculateLinearInterest(
                    userPoolConfig.interestRate +
                        poolManagerConfig.PROTOCAL_FEE_INTEREST_RATE,
                    userPoolReserveInformation.borrowedTimeStamp
                )
            );
    }

    //------------------------internal functions------------------------
    /**
     * @dev Updates the user's debt.
     * @param user The address of the user.
     * @return feeForPool The fee for the user's interest rate.
     * @return feeForProtocal The fee for the protocol's fee ratio.
     */
    function updateDebt(
        address user
    ) internal returns (uint256 feeForPool, uint256 feeForProtocal) {
        // Load the pool manager configuration into memory
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        // Load the user's pool configuration into memory
        DataTypes.UserPoolConfig memory userPoolConfig = _userPoolConfig[user];
        // Load the user's pool reserve information into storage
        DataTypes.UserPoolReserveInformation
            storage userPoolReserveInformation = _userPoolReserveInformation[
                user
            ];

        // Calculate the fee for the pool based on the user's interest rate and borrowed timestamp
        feeForPool = userPoolReserveInformation.totalBorrowed.rayMul(
            MathUtils.calculateLinearInterest(
                userPoolConfig.interestRate,
                userPoolReserveInformation.borrowedTimeStamp
            )
        );

        // Calculate the fee for the protocol based on the protocol fee interest rate and borrowed timestamp
        feeForProtocal = userPoolReserveInformation.totalBorrowed.rayMul(
            MathUtils.calculateLinearInterest(
                poolManagerConfig.PROTOCAL_FEE_INTEREST_RATE,
                userPoolReserveInformation.borrowedTimeStamp
            )
        );

        // Update the total borrowed amount by adding both fees
        userPoolReserveInformation.totalBorrowed += feeForPool + feeForProtocal;
        // Update the borrowed timestamp to the current block timestamp
        userPoolReserveInformation.borrowedTimeStamp = uint40(block.timestamp);
    }

    /**
     * @dev Calculates the maximum withdrawable amount.
     * @param maxWithdrawRate The maximum withdrawal rate.
     * @param totalSupply The total supply in the pool.
     * @param inBorrowing The amount currently in borrowing.
     * @param FBTC0Price The price of the FBTC0 token.
     * @return The maximum amount that can be withdrawn.
     */
    function calculateMaxWithdrawAmount(
        uint256 maxWithdrawRate,
        uint256 totalSupply,
        uint256 inBorrowing,
        uint256 FBTC0Price
    ) internal view returns (uint256) {
        if (inBorrowing == 0) {
            return totalSupply;
        } else {
            return
                ((totalSupply * FBTC0Price - inBorrowing) * maxWithdrawRate) /
                DENOMINATOR;
        }
    }

    /**
     * @dev Calculates the maximum borrowable amount.
     * @param loanToValue The loan-to-value ratio.
     * @param totalSupply The total supply in the pool.
     * @param inBorrowing The amount currently in borrowing.
     * @param FBTC0Price The price of the FBTC0 token.
     * @return The maximum amount that can be borrowed.
     */
    function calculateMaxBorrowAmount(
        uint256 loanToValue,
        uint256 totalSupply,
        uint256 inBorrowing,
        uint256 FBTC0Price
    ) internal view returns (uint256) {
        return
            (totalSupply * FBTC0Price * loanToValue) /
            DENOMINATOR -
            inBorrowing;
    }
}
