// SPDX-License-Identifier: MIT
// Chainlink Contracts v0.8
pragma solidity ^0.8.0;

interface AggregatorInterface {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

interface IFBTCOracle {
    /**
     * @notice Sets the asset's price source
     * @param source The address of the source of the asset
     */
    function setAssetSource(AggregatorInterface source) external;

    /**
     * @notice Gets the price of the asset
     * @return The price of the asset
     */
    function getAssetPrice() external view returns (uint256);

    function decimals() external view returns (uint8);
}
