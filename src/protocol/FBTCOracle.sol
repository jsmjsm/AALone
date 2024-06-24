// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IOracle.sol";

/**
 * @title FBTCOracle
 * @dev Oracle contract for fetching the price of an asset.
 */
contract FBTCOracle is IFBTCOracle {
    // The interface for the price aggregator
    AggregatorInterface private assetSource;

    /**
     * @dev Constructor that sets the initial price aggregator source.
     * @param source The initial price aggregator source.
     */
    constructor(AggregatorInterface source) {
        assetSource = source;
    }

    /**
     * @dev Sets a new price aggregator source.
     * @param source The new price aggregator source.
     * Requirements:
     * - This function could have access control to restrict who can call it.
     */
    function setAssetSource(AggregatorInterface source) external {
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
}
