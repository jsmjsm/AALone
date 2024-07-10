// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "./PoolManagerConfigurator.sol";
import "./library/math/MathUtils.sol";
import "./library/math/WadRayMath.sol";
import "../interfaces/IPoolManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title PoolManager
 * @dev Manages liquidity pools and related operations.
 */
contract PoolManager is PoolManagerConfigurator, IPoolManager, Test {
    using WadRayMath for uint256;
    using MathUtils for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Creates a new liquidity pool.
     * Requirements:
     * - The caller must have the POOL_ADMIN_ROLE.
     * - The pool must not have been initialized.
     */
    function createPool(address user) external onlyOwner {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        DataTypes.UserPoolConfig storage userPoolConfig = _userPoolConfig[user];
        require(!userPoolConfig.init, "Pool already initialized");
        userPoolConfig.init = true;
        userPoolConfig.interestRate = poolManagerConfig
            .DEFAULT_POOL_INTEREST_RATE;
        userPoolConfig.maxWithdrawRate = poolManagerConfig
            .DEFAULT_MAX_WITHDRAW_RATE;
        userPoolConfig.loanToValue = poolManagerConfig.DEFAULT_LTV;
        emit PoolCreated(user, userPoolConfig);
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

        poolManagerConfig.FBTC0.safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        poolManagerConfig.FBTC0.approve(
            address(poolManagerConfig.FBTC1),
            amount
        );
        poolManagerConfig.FBTC1.mintLockedFbtcRequest(amount);
        userPoolReserveInformation.totalSupply += amount;
        emit TokensSupplied(msg.sender, amount, userPoolReserveInformation);
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
                poolManagerConfig.FBTCOracle.getAssetPrice(),
                IERC20Metadata(address(poolManagerConfig.USDT)).decimals(),
                IERC20Metadata(address(poolManagerConfig.FBTC0)).decimals(),
                poolManagerConfig.FBTCOracle.decimals()
            ) >= amount,
            "Requested amount exceeds allowable loanToValue"
        );
        userPoolReserveInformation.inBorrowing += amount;
        emit LoanRequested(msg.sender, amount, userPoolReserveInformation);
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
        poolManagerConfig.USDT.safeTransferFrom(
            poolManagerConfig.AvalonUSDTVault,
            msg.sender,
            amount
        );

        emit TokensBorrowed(msg.sender, amount, userPoolReserveInformation);
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

        (uint256 feeForPool, uint256 feeForProtocal) = updateDebt(msg.sender);

        require(amount > feeForProtocal + feeForPool, "too small repay amount");

        poolManagerConfig.USDT.safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        poolManagerConfig.USDT.safeTransfer(
            poolManagerConfig.AntaphaUSDTVault,
            amount - feeForProtocal
        );
        _protocalProfitUnclaimed += feeForProtocal;
        _protocalProfitAccumulate += feeForProtocal;
        userPoolReserveInformation.totalBorrowed -= amount;

        emit TokensRepaid(msg.sender, amount, userPoolReserveInformation);
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
        uint256 amount,
        DataTypes.UserPoolReserveInformation memory userPoolReserveInformation
    ) external onlyOwner {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        poolManagerConfig.FBTC1.burn(amount);
        _userPoolReserveInformation[user] = userPoolReserveInformation;
        emit Liquidation(user, userPoolReserveInformation);
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
                userPoolReserveInformation.totalBorrowed,
                userPoolReserveInformation.inBorrowing,
                poolManagerConfig.FBTCOracle.getAssetPrice(),
                IERC20Metadata(address(poolManagerConfig.USDT)).decimals(),
                IERC20Metadata(address(poolManagerConfig.FBTC0)).decimals(),
                poolManagerConfig.FBTCOracle.decimals()
            ) >= amount,
            "Exceed withdraw limit"
        );

        userPoolReserveInformation.totalSupply -= amount;
        userPoolReserveInformation.inWithdrawing += amount;
        emit WithdrawalRequested(
            msg.sender,
            amount,
            userPoolReserveInformation
        );
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

        emit MintFBTC0Confirmed(amount, depositTxid, outputIndex);
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
        require(
            userPoolReserveInformation.inWithdrawing >= amount,
            "Exceed withdraw limit"
        );

        userPoolReserveInformation.inWithdrawing -= amount;
        poolManagerConfig.FBTC1.confirmRedeemFbtc(amount);
        poolManagerConfig.FBTC0.safeTransfer(msg.sender, amount);

        emit TokensWithdrawn(msg.sender, amount, userPoolReserveInformation);
    }

    /**
     * @dev Claims the accumulated protocol earnings.
     * Requirements:
     * - The caller must have the POOL_ADMIN_ROLE.
     */
    function claimProtocolEarnings() external onlyOwner {
        DataTypes.PoolManagerConfig
            memory poolManagerConfig = _poolManagerConfig;
        poolManagerConfig.USDT.transfer(msg.sender, _protocalProfitUnclaimed);
        _protocalProfitUnclaimed = 0;
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
        override
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
        reserveAfterUpdateDebt.timeStampIndex = userPoolReserveInformation
            .timeStampIndex;
        reserveAfterUpdateDebt.totalSupply = userPoolReserveInformation
            .totalSupply;
        reserveAfterUpdateDebt.inBorrowing = userPoolReserveInformation
            .inBorrowing;
        reserveAfterUpdateDebt.inWithdrawing = userPoolReserveInformation
            .inWithdrawing;

        (
            uint256 feeForPool,
            uint256 feeForProtocal
        ) = calculateIncreasingInterest(
                userPoolReserveInformation.totalBorrowed,
                userPoolConfig.interestRate,
                poolManagerConfig.PROTOCAL_FEE_INTEREST_RATE,
                userPoolReserveInformation.timeStampIndex
            );

        reserveAfterUpdateDebt.totalBorrowed =
            userPoolReserveInformation.totalBorrowed +
            feeForPool +
            feeForProtocal;
    }

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
        (feeForPool, feeForProtocal) = calculateIncreasingInterest(
            userPoolReserveInformation.totalBorrowed,
            userPoolConfig.interestRate,
            poolManagerConfig.PROTOCAL_FEE_INTEREST_RATE,
            userPoolReserveInformation.timeStampIndex
        );

        // Update the total borrowed amount by adding both fees
        userPoolReserveInformation.totalBorrowed += feeForPool + feeForProtocal;

        // Update the borrowed timestamp to the current block timestamp
        userPoolReserveInformation.timeStampIndex = uint40(block.timestamp);
    }

    //------------------------view functions--------------------------
    /**
     * @dev Calculates the increasing interest for both the pool and the protocol.
     * @param totalBorrowed The total amount borrowed.
     * @param poolInterestRate The interest rate for the pool.
     * @param protocolInterestRate The interest rate for the protocol.
     * @param timeStampIndex The timestamp when the borrowing occurred.
     * @return feeForPool The calculated interest fee for the pool.
     * @return feeForProtocal The calculated interest fee for the protocol.
     */
    function calculateIncreasingInterest(
        uint256 totalBorrowed,
        uint256 poolInterestRate,
        uint256 protocolInterestRate,
        uint40 timeStampIndex
    ) public view returns (uint256 feeForPool, uint256 feeForProtocal) {
        // Calculate the fee for the pool based on the user's interest rate and borrowed timestamp
        feeForPool =
            totalBorrowed.rayMul(
                MathUtils.calculateLinearInterest(
                    (poolInterestRate * WadRayMath.RAY) / DENOMINATOR,
                    timeStampIndex
                )
            ) -
            totalBorrowed;

        // Calculate the fee for the protocol based on the protocol fee interest rate and borrowed timestamp
        feeForProtocal =
            totalBorrowed.rayMul(
                MathUtils.calculateLinearInterest(
                    (protocolInterestRate * WadRayMath.RAY) / DENOMINATOR,
                    timeStampIndex
                )
            ) -
            totalBorrowed;
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
        uint256 totalBorrowed,
        uint256 inBorrowing,
        uint256 FBTC0Price,
        uint256 USDTDecimal,
        uint256 FBTC0Decimal,
        uint256 oracleDecimal
    ) public view returns (uint256) {
        if (totalBorrowed == 0) {
            return totalSupply;
        } else {
            console.log(
                ((((FBTC0Price *
                    totalSupply *
                    10 ** USDTDecimal -
                    (inBorrowing + totalBorrowed) *
                    10 ** FBTC0Decimal) * 10 ** oracleDecimal) /
                    (FBTC0Price * 10 ** (USDTDecimal + FBTC0Decimal))) *
                    maxWithdrawRate) / DENOMINATOR
            );
            return
                ((((FBTC0Price *
                    totalSupply *
                    10 ** USDTDecimal -
                    (inBorrowing + totalBorrowed) *
                    10 ** FBTC0Decimal) * 10 ** oracleDecimal) /
                    (FBTC0Price * 10 ** (USDTDecimal + FBTC0Decimal))) *
                    maxWithdrawRate) / DENOMINATOR;
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
        uint256 FBTC0Price,
        uint256 USDTDecimal,
        uint256 FBTC0Decimal,
        uint256 oracleDecimal
    ) public view returns (uint256) {
        return
            (((totalSupply * FBTC0Price * 10 ** USDTDecimal) /
                (10 ** FBTC0Decimal * 10 ** oracleDecimal)) * loanToValue) /
            DENOMINATOR -
            inBorrowing;
    }
}
