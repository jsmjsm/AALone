// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./mock/MockERC20.sol";
import "./mock/MockAggregator.sol";
import "./mock/MockFBTC1.sol";
import "../src/protocol/FBTCOracle.sol";
import "../src/protocol/PoolManager.sol";
import "../src/protocol/library/type/DataTypes.sol";

contract PoolManagerTest is Test {
    MockERC20 mockUSDT = new MockERC20("USDT", "USDT", 18);
    MockERC20 mockFBTC0 = new MockERC20("FBTC0", "FBTC0", 18);
    MockFBTC1 mockFBTC1 = new MockFBTC1();

    FBTCOracle public fbtcOracle;
    AggregatorMock public aggregatorMock;
    PoolManager public poolManager;

    address public poolAdmin = address(0x001);
    address public oracleOwner = address(0x002);
    address public avalonUSDTVault = address(0x003);
    address public antaphaUSDTVault = address(0x004);
    address public user = address(0x010);

    function setUp() public {
        vm.startPrank(poolAdmin);
        aggregatorMock = new AggregatorMock();
        fbtcOracle = new FBTCOracle(aggregatorMock, oracleOwner);
        DataTypes.PoolManagerConfig memory config = DataTypes
            .PoolManagerConfig({
                DEFAULT_MAX_WITHDRAW_RATE: 5000,
                DEFAULT_POOL_INTEREST_RATE: 500,
                DEFAULT_LTV: 5000,
                PROTOCAL_FEE_INTEREST_RATE: 100,
                USDT: mockUSDT,
                FBTC0: mockFBTC0,
                FBTC1: mockFBTC1,
                FBTCOracle: fbtcOracle,
                AvalonUSDTVault: avalonUSDTVault,
                AntaphaUSDTVault: antaphaUSDTVault
            });
        poolManager = new PoolManager(config, poolAdmin);
        vm.stopPrank();
    }

    function testCreatePool() public {
        // Ensure the pool is not initialized initially
        DataTypes.UserPoolConfig memory initialConfig = poolManager
            .getUserPoolConfig(poolAdmin);
        assertFalse(initialConfig.init);

        // Set the role for the pool admin (mocking the role assignment)
        vm.prank(address(poolAdmin));
        // Create the pool
        poolManager.createPool(user);

        // Verify the pool is initialized with correct parameters
        DataTypes.UserPoolConfig memory userPoolConfig = poolManager
            .getUserPoolConfig(user);

        DataTypes.PoolManagerConfig memory storedConfig = poolManager
            .getPoolManagerConfig();

        assertTrue(userPoolConfig.init);
        assertEq(
            userPoolConfig.interestRate,
            storedConfig.DEFAULT_POOL_INTEREST_RATE
        );
        assertEq(
            userPoolConfig.maxWithdrawRate,
            storedConfig.DEFAULT_MAX_WITHDRAW_RATE
        );
        assertEq(userPoolConfig.loanToValue, storedConfig.DEFAULT_LTV);
    }

    function testCreatePool_NotAdmin() public {
        // Ensure non-admin cannot create a pool
        address nonAdmin = address(0x123);
        vm.prank(nonAdmin);
        vm.expectRevert();
        poolManager.createPool(user);
    }

    function testSupply() public {
        uint256 amount = 1000 * 10 ** 18;

        // Ensure the pool is initialized
        vm.prank(poolAdmin);
        poolManager.createPool(user);
        vm.stopPrank();

        // Mint tokens to the user
        mockFBTC0.mint(user, amount);
        assertEq(mockFBTC0.balanceOf(user), amount);

        vm.startPrank(user);
        // Approve the PoolManager to spend the tokens
        mockFBTC0.approve(address(poolManager), amount);

        // Supply tokens to the pool
        poolManager.supply(amount);

        // Verify the tokens were transferred to the PoolManager
        assertEq(mockFBTC0.balanceOf(address(poolManager)), amount);

        // Verify the user's pool reserve information
        DataTypes.UserPoolReserveInformation memory reserveInfo = poolManager
            .getUserPoolReserveInformation(user);

        assertEq(reserveInfo.totalSupply, amount);
    }

    function testSupply_PoolNotInitialized() public {
        uint256 amount = 1000 * 10 ** 18;

        // Mint tokens to the user
        mockFBTC0.mint(poolAdmin, amount);
        assertEq(mockFBTC0.balanceOf(poolAdmin), amount);

        // Approve the PoolManager to spend the tokens
        mockFBTC0.approve(address(poolManager), amount);

        // Attempt to supply tokens to the pool without initialization
        vm.expectRevert("Pool not initialized");
        poolManager.supply(amount);
    }

    function testRequestBorrow_PoolNotInitialized() public {
        uint256 amount = 500 * 10 ** 18;
        // Attempt to borrow without initializing the pool
        vm.expectRevert("Pool not initialized");
        poolManager.requestBorrow(amount);
    }

    function testRequestBorrow_ExceedsAllowableLTV() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 60000001 * 10 ** 18; // This should exceed the allowable LTV

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);
        aggregatorMock.setLatestAnswer(60000); // 1 USDT per FBTC

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);
        poolManager.supply(supplyAmount);

        // Attempt to borrow an amount that exceeds the allowable LTV
        vm.expectRevert("Requested amount exceeds allowable loanToValue");
        poolManager.requestBorrow(borrowAmount);
    }

    function testRequestBorrow_Success() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 3000000 * 10 ** 18; // This should be within the allowable LTV

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);
        aggregatorMock.setLatestAnswer(60000);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);
        poolManager.supply(supplyAmount);

        // Borrow an amount within the allowable LTV
        poolManager.requestBorrow(borrowAmount);
        // Verify the borrowing amount is updated correctly
        DataTypes.UserPoolReserveInformation memory reserveInfo = poolManager
            .getUserPoolReserveInformation(user);
        assertEq(reserveInfo.inBorrowing, borrowAmount);
    }

    function testBorrow_PoolNotInitialized() public {
        uint256 borrowAmount = 500 * 10 ** 18;

        // Attempt to borrow without initializing the pool
        vm.expectRevert("Pool not initialized");
        poolManager.borrow(borrowAmount);
    }

    function testBorrow_InsufficientInBorrowingAmount() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 500 * 10 ** 18;

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);
        poolManager.supply(supplyAmount);

        // Mock the FBTC oracle price
        aggregatorMock.setLatestAnswer(1 * 10 ** 18); // 1 USDT per FBTC

        // Borrow an amount
        poolManager.requestBorrow(borrowAmount);

        // Attempt to borrow more than the inBorrowing amount
        uint256 excessBorrowAmount = borrowAmount + 1;
        vm.expectRevert("Insufficient inBorrowing amount");
        poolManager.borrow(excessBorrowAmount);
    }

    function testBorrow_Success() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 500 * 10 ** 18;

        vm.startPrank(avalonUSDTVault);
        mockUSDT.mint(avalonUSDTVault, borrowAmount);
        mockUSDT.approve(address(poolManager), borrowAmount);
        vm.stopPrank();

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);

        poolManager.supply(supplyAmount);
        // Mock the FBTC oracle price
        aggregatorMock.setLatestAnswer(1 * 10 ** 18); // 1 USDT per FBTC

        // Borrow an amount
        poolManager.requestBorrow(borrowAmount);

        poolManager.borrow(borrowAmount);

        // Verify the borrowing amount and total borrowed amount are updated correctly
        DataTypes.UserPoolReserveInformation memory reserveInfo = poolManager
            .getUserPoolReserveInformation(user);

        assertEq(reserveInfo.totalBorrowed, borrowAmount);
        assertEq(reserveInfo.inBorrowing, 0);
    }

    function testRepay_Failed() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 500 * 10 ** 18;

        vm.startPrank(avalonUSDTVault);
        mockUSDT.mint(avalonUSDTVault, borrowAmount);
        mockUSDT.approve(address(poolManager), borrowAmount);
        vm.stopPrank();

        vm.prank(user);
        vm.expectRevert("Pool not initialized");
        poolManager.repay(1);

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);

        poolManager.supply(supplyAmount);
        // Mock the FBTC oracle price
        aggregatorMock.setLatestAnswer(1 * 10 ** 18); // 1 USDT per FBTC

        // Borrow an amount
        poolManager.requestBorrow(borrowAmount);

        poolManager.borrow(borrowAmount);

        // Verify the borrowing amount and total borrowed amount are updated correctly
        DataTypes.UserPoolReserveInformation memory reserveInfo = poolManager
            .getUserPoolReserveInformation(user);

        assertEq(reserveInfo.totalBorrowed, borrowAmount);
        assertEq(reserveInfo.inBorrowing, 0);
        uint256 bocktime = block.timestamp;
        skip(365 days);

        (uint256 fee1, uint256 fee2) = poolManager.calculateIncreasingInterest(
            500000000000000000000,
            500,
            100,
            uint40(bocktime)
        );

        mockUSDT.approve(address(poolManager), borrowAmount - 1);
        vm.expectRevert();
        poolManager.repay(borrowAmount);

        mockUSDT.approve(address(poolManager), borrowAmount);
        vm.expectRevert("too small repay amount");
        poolManager.repay(1);
    }

    function testRepay_Success() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 500 * 10 ** 18;

        vm.startPrank(avalonUSDTVault);
        mockUSDT.mint(avalonUSDTVault, borrowAmount);
        mockUSDT.approve(address(poolManager), borrowAmount);
        vm.stopPrank();

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);

        poolManager.supply(supplyAmount);
        // Mock the FBTC oracle price
        aggregatorMock.setLatestAnswer(1 * 10 ** 18); // 1 USDT per FBTC

        // Borrow an amount
        poolManager.requestBorrow(borrowAmount);

        poolManager.borrow(borrowAmount);

        // Verify the borrowing amount and total borrowed amount are updated correctly
        DataTypes.UserPoolReserveInformation memory reserveInfo = poolManager
            .getUserPoolReserveInformation(user);

        assertEq(reserveInfo.totalBorrowed, borrowAmount);
        assertEq(reserveInfo.inBorrowing, 0);
        uint256 bocktime = block.timestamp;
        skip(365 days);

        (uint256 fee1, uint256 fee2) = poolManager.calculateIncreasingInterest(
            500000000000000000000,
            500,
            100,
            uint40(bocktime)
        );

        mockUSDT.approve(address(poolManager), borrowAmount);
        poolManager.repay(borrowAmount);
    }

    function testLiquidate_Failed() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 500 * 10 ** 18;

        vm.startPrank(avalonUSDTVault);
        mockUSDT.mint(avalonUSDTVault, borrowAmount);
        mockUSDT.approve(address(poolManager), borrowAmount);
        vm.stopPrank();

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);

        poolManager.supply(supplyAmount);
        // Mock the FBTC oracle price
        aggregatorMock.setLatestAnswer(1 * 10 ** 18); // 1 USDT per FBTC

        // Borrow an amount
        poolManager.requestBorrow(borrowAmount);

        poolManager.borrow(borrowAmount);

        DataTypes.UserPoolReserveInformation
            memory userPoolReserveInformation = DataTypes
                .UserPoolReserveInformation({
                    timeStampIndex: uint40(block.timestamp),
                    totalSupply: 0,
                    totalBorrowed: 0,
                    inBorrowing: 0,
                    inWithdrawing: 0
                });

        vm.stopPrank();
        vm.prank(user);
        vm.expectRevert();
        poolManager.liquidate(user, userPoolReserveInformation);
    }

    function testLiquidate_Success() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 500 * 10 ** 18;

        vm.startPrank(avalonUSDTVault);
        mockUSDT.mint(avalonUSDTVault, borrowAmount);
        mockUSDT.approve(address(poolManager), borrowAmount);
        vm.stopPrank();

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);

        poolManager.supply(supplyAmount);
        // Mock the FBTC oracle price
        aggregatorMock.setLatestAnswer(1 * 10 ** 18); // 1 USDT per FBTC

        // Borrow an amount
        poolManager.requestBorrow(borrowAmount);

        poolManager.borrow(borrowAmount);

        DataTypes.UserPoolReserveInformation
            memory userPoolReserveInformation = DataTypes
                .UserPoolReserveInformation({
                    timeStampIndex: uint40(block.timestamp),
                    totalSupply: 0,
                    totalBorrowed: 0,
                    inBorrowing: 0,
                    inWithdrawing: 0
                });

        vm.stopPrank();
        vm.prank(poolAdmin);
        poolManager.liquidate(user, userPoolReserveInformation);
    }

    function testRequestWithdraw_Failed() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 5000000 * 10 ** 18;

        vm.startPrank(avalonUSDTVault);
        mockUSDT.mint(avalonUSDTVault, borrowAmount);
        mockUSDT.approve(address(poolManager), borrowAmount);
        vm.stopPrank();

        vm.expectRevert();
        poolManager.requestWithdraw(supplyAmount / 4);

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);

        poolManager.supply(supplyAmount);
        // Mock the FBTC oracle price
        aggregatorMock.setLatestAnswer(60000); // 1 USDT per FBTC

        // Borrow an amount
        poolManager.requestBorrow(borrowAmount);

        poolManager.borrow(borrowAmount);

        // Verify the borrowing amount and total borrowed amount are updated correctly
        DataTypes.UserPoolReserveInformation memory reserveInfo = poolManager
            .getUserPoolReserveInformation(user);

        assertEq(reserveInfo.totalBorrowed, borrowAmount);
        assertEq(reserveInfo.inBorrowing, 0);
        skip(365 days);
        mockUSDT.approve(address(poolManager), borrowAmount);
        poolManager.repay(borrowAmount);
        vm.expectRevert();
        poolManager.requestWithdraw(supplyAmount / 2);
    }

    function testRequestWithdraw_Success() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 5000000 * 10 ** 18;

        vm.startPrank(avalonUSDTVault);
        mockUSDT.mint(avalonUSDTVault, borrowAmount);
        mockUSDT.approve(address(poolManager), borrowAmount);
        vm.stopPrank();

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);

        poolManager.supply(supplyAmount);
        // Mock the FBTC oracle price
        aggregatorMock.setLatestAnswer(60000); // 1 USDT per FBTC

        // Borrow an amount
        poolManager.requestBorrow(borrowAmount);

        poolManager.borrow(borrowAmount);

        // Verify the borrowing amount and total borrowed amount are updated correctly
        DataTypes.UserPoolReserveInformation memory reserveInfo = poolManager
            .getUserPoolReserveInformation(user);

        assertEq(reserveInfo.totalBorrowed, borrowAmount);
        assertEq(reserveInfo.inBorrowing, 0);
        skip(365 days);
        mockUSDT.approve(address(poolManager), borrowAmount);
        poolManager.repay(borrowAmount);
        poolManager.requestWithdraw(supplyAmount / 4);
    }

    function testWithdraw_Faled() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 5000000 * 10 ** 18;

        vm.startPrank(avalonUSDTVault);
        mockUSDT.mint(avalonUSDTVault, borrowAmount);
        mockUSDT.approve(address(poolManager), borrowAmount);
        vm.stopPrank();

        vm.expectRevert();
        poolManager.withdraw(supplyAmount / 4);
        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);

        poolManager.supply(supplyAmount);
        // Mock the FBTC oracle price
        aggregatorMock.setLatestAnswer(60000); // 1 USDT per FBTC

        // Borrow an amount
        poolManager.requestBorrow(borrowAmount);

        poolManager.borrow(borrowAmount);

        // Verify the borrowing amount and total borrowed amount are updated correctly
        DataTypes.UserPoolReserveInformation memory reserveInfo = poolManager
            .getUserPoolReserveInformation(user);

        assertEq(reserveInfo.totalBorrowed, borrowAmount);
        assertEq(reserveInfo.inBorrowing, 0);
        skip(365 days);

        mockUSDT.approve(address(poolManager), borrowAmount);
        poolManager.repay(borrowAmount);
        poolManager.requestWithdraw(supplyAmount / 4);

        vm.expectRevert();
        poolManager.withdraw(supplyAmount / 4 + 1);
    }

    function testWithdraw_Success() public {
        uint256 supplyAmount = 1000 * 10 ** 18;
        uint256 borrowAmount = 5000000 * 10 ** 18;

        vm.startPrank(avalonUSDTVault);
        mockUSDT.mint(avalonUSDTVault, borrowAmount);
        mockUSDT.approve(address(poolManager), borrowAmount);
        vm.stopPrank();

        // Initialize the pool
        vm.prank(poolAdmin);
        poolManager.createPool(user);

        vm.startPrank(user);
        // Mint and supply tokens to the pool
        mockFBTC0.mint(user, supplyAmount);
        mockFBTC0.approve(address(poolManager), supplyAmount);

        poolManager.supply(supplyAmount);
        // Mock the FBTC oracle price
        aggregatorMock.setLatestAnswer(60000); // 1 USDT per FBTC

        // Borrow an amount
        poolManager.requestBorrow(borrowAmount);

        poolManager.borrow(borrowAmount);

        // Verify the borrowing amount and total borrowed amount are updated correctly
        DataTypes.UserPoolReserveInformation memory reserveInfo = poolManager
            .getUserPoolReserveInformation(user);

        assertEq(reserveInfo.totalBorrowed, borrowAmount);
        assertEq(reserveInfo.inBorrowing, 0);
        skip(365 days);

        mockUSDT.approve(address(poolManager), borrowAmount);
        poolManager.repay(borrowAmount);
        poolManager.requestWithdraw(supplyAmount / 4);
        poolManager.withdraw(supplyAmount / 4);
    }

    function testClaimProtocolEarnings() public {
        vm.startPrank(poolAdmin);

        DataTypes.PoolManagerConfig memory config = DataTypes
            .PoolManagerConfig({
                DEFAULT_MAX_WITHDRAW_RATE: 5000,
                DEFAULT_POOL_INTEREST_RATE: 500,
                DEFAULT_LTV: 500,
                PROTOCAL_FEE_INTEREST_RATE: 100,
                USDT: mockUSDT,
                FBTC0: mockFBTC0,
                FBTC1: mockFBTC1,
                FBTCOracle: fbtcOracle,
                AvalonUSDTVault: address(0x789),
                AntaphaUSDTVault: address(0xABC)
            });
        poolManager.setPoolManagerConfig(config);

        uint256 initialAdminBalance = mockUSDT.balanceOf(poolAdmin);
        uint256 protocolProfit = 1000 ether;
        vm.store(
            address(poolManager),
            bytes32(uint256(0)),
            bytes32(protocolProfit)
        );

        mockUSDT.mint(address(poolManager), protocolProfit);
        poolManager.claimProtocolEarnings();

        uint256 newAdminBalance = mockUSDT.balanceOf(poolAdmin);
        assertEq(newAdminBalance, initialAdminBalance + protocolProfit);
        assertEq(poolManager.getProtocolProfitUnclaimed(), 0);

        vm.stopPrank();
    }
}
