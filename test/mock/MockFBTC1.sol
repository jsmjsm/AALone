// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../src/interfaces/IFBTC1.sol";

contract MockFBTC1 is ERC20, IFBTC1 {
    mapping(bytes32 => IFireBridge.Request) public requests;
    uint256 public totalMinted;
    uint256 public totalRedeemed;

    event MintLockedFbtcRequest(
        address indexed user,
        uint256 amount,
        uint256 realAmount
    );
    event RedeemFbtcRequest(
        address indexed user,
        uint256 amount,
        bytes32 depositTxid,
        uint256 outputIndex
    );
    event ConfirmRedeemFbtc(address indexed user, uint256 amount);

    constructor() ERC20("Mock FBTC1", "MFBTC1") {}

    function mintLockedFbtcRequest(
        uint256 _amount
    ) external override returns (uint256 realAmount) {
        // Mock implementation: Simply mint the requested amount
        _mint(msg.sender, _amount);
        totalMinted += _amount;
        realAmount = _amount;

        emit MintLockedFbtcRequest(msg.sender, _amount, realAmount);
    }

    function redeemFbtcRequest(
        uint256 _amount,
        bytes32 _depositTxid,
        uint256 _outputIndex
    ) external override returns (bytes32 _hash, IFireBridge.Request memory _r) {
        // Mock implementation: Create a request and update balances
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");

        _burn(msg.sender, _amount);
        totalRedeemed += _amount;

        _hash = keccak256(
            abi.encodePacked(_amount, _depositTxid, _outputIndex)
        );
        _r = IFireBridge.Request({amount: _amount, fee: 0});

        requests[_hash] = _r;

        emit RedeemFbtcRequest(msg.sender, _amount, _depositTxid, _outputIndex);
    }

    function confirmRedeemFbtc(uint256 _amount) external override {
        // Mock implementation: Confirm redeeming the requested amount
        _mint(msg.sender, _amount);

        emit ConfirmRedeemFbtc(msg.sender, _amount);
    }

    // Additional helper methods for testing
    function getRequest(
        bytes32 _hash
    ) external view returns (IFireBridge.Request memory) {
        return requests[_hash];
    }
}
