// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/interfaces/IOracle.sol";

contract AggregatorMock is AggregatorInterface {
    int256 private _latestAnswer;
    uint256 private _latestTimestamp;
    uint256 private _latestRound;

    function setLatestAnswer(int256 answer) external {
        _latestAnswer = answer;
        _latestTimestamp = block.timestamp;
        _latestRound++;
        emit AnswerUpdated(answer, _latestRound, block.timestamp);
    }

    function decimals() external view override returns (uint8) {
        return 8;
    }

    function latestAnswer() external view override returns (int256) {
        return _latestAnswer;
    }

    function latestTimestamp() external view override returns (uint256) {
        return _latestTimestamp;
    }

    function latestRound() external view override returns (uint256) {
        return _latestRound;
    }

    function getAnswer(
        uint256 roundId
    ) external view override returns (int256) {
        return _latestAnswer; // Simplification for mock
    }

    function getTimestamp(
        uint256 roundId
    ) external view override returns (uint256) {
        return _latestTimestamp; // Simplification for mock
    }
}
