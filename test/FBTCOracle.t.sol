// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/protocol/FBTCOracle.sol";
import "./mock/MockAggregator.sol";

contract FBTCOracleTest is Test {
    FBTCOracle public fbtcOracle;
    AggregatorMock public aggregatorMock;
    address public owner;
    address public otherAccount;

    function setUp() public {
        owner = address(this);
        otherAccount = address(0x123);

        aggregatorMock = new AggregatorMock();
        fbtcOracle = new FBTCOracle(aggregatorMock, owner);
    }

    function testInitialDeployment() public {
        assertEq(fbtcOracle.owner(), owner);
        assertEq(fbtcOracle.getAssetPrice(), 0);
    }

    function testSetAssetSource() public {
        AggregatorMock newAggregatorMock = new AggregatorMock();
        fbtcOracle.setAssetSource(newAggregatorMock);
        assertEq(fbtcOracle.getAssetPrice(), 0);
    }

    function testGetAssetPrice() public {
        int256 newPrice = 20000 * 10 ** 8;
        aggregatorMock.setLatestAnswer(newPrice);
        assertEq(fbtcOracle.getAssetPrice(), uint256(newPrice));
    }
}
