// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFireBridge {
    struct Request {
        uint256 amount;
        uint256 fee;
    }

    function addBurnRequest(
        uint256 _amount
    ) external returns (bytes32 _hash, Request memory _r);

    function addMintRequest(
        uint256 _amount,
        bytes32 _depositTxid,
        uint256 _outputIndex
    ) external returns (bytes32 _hash, Request memory _r);
}

interface IFBTC1 {
    function mintLockedFbtcRequest(
        uint256 _amount
    ) external returns (uint256 realAmount);

    function redeemFbtcRequest(
        uint256 _amount,
        bytes32 _depositTxid,
        uint256 _outputIndex
    ) external returns (bytes32 _hash, IFireBridge.Request memory _r);

    function confirmRedeemFbtc(uint256 _amount) external;

    function burn(uint256 _amount) external;
}
