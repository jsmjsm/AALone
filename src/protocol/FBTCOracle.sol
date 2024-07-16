// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IOracle.sol";

/**
 * @title FBTCOracle
 * @dev Oracle contract for fetching the price of an asset.
 */
contract FBTCOracle is IFBTCOracle, Ownable {
    // The interface for the price aggregator
    AggregatorInterface private assetSource;

    /**
     * @dev Constructor that sets the initial price aggregator source and the initial owner.
     * @param source The initial price aggregator source.
     * @param initialOwner The initial owner of the contract.
     */
    constructor(
        AggregatorInterface source,
        address initialOwner
    ) Ownable(initialOwner) {
        assetSource = source;
    }

    /**
     * @dev Sets a new price aggregator source.
     * @param source The new price aggregator source.
     * Requirements:
     * - Can only be called by the contract owner.
     */
    function setAssetSource(AggregatorInterface source) external onlyOwner {
        assetSource = source;
    }

    /**
     * @dev Gets the latest price of the asset.
     * @return The latest price of the asset as a uint256.
     */
    function getAssetPrice() public view returns (uint256) {
        int256 price = assetSource.latestAnswer();
        return uint256(price);
    }

    /**
     * @dev Gets the number of decimals used by the price aggregator.
     * @return The number of decimals as a uint8.
     */
    function decimals() public view returns (uint8) {
        return assetSource.decimals();
    }
}
