// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.20;

import {ERC1155} from "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a collateral of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 *
 * NOTE: This contract implies a global limit of 2**256 - 1 to the number of tokens
 * that can be minted.
 *
 * CAUTION: This extension should not be added in an upgrade to an already deployed contract.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 id => uint256) private _collateral;
    uint256 private _collateralAll;

    /**
     * @dev Total value of tokens in with a given id.
     */
    function collateral(uint256 id) public view virtual returns (uint256) {
        return _collateral[id];
    }

    /**
     * @dev Total value of tokens.
     */
    function collateral() public view virtual returns (uint256) {
        return _collateralAll;
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return collateral(id) > 0;
    }

    /**
     * @dev See {ERC1155-_update}.
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override {
        super._update(from, to, ids, values);

        if (from == address(0)) {
            uint256 totalMintValue = 0;
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 value = values[i];
                // Overflow check required: The rest of the code assumes that collateral never overflows
                _collateral[ids[i]] += value;
                totalMintValue += value;
            }
            // Overflow check required: The rest of the code assumes that collateralAll never overflows
            _collateralAll += totalMintValue;
        }

        if (to == address(0)) {
            uint256 totalBurnValue = 0;
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 value = values[i];

                unchecked {
                    // Overflow not possible: values[i] <= balanceOf(from, ids[i]) <= collateral(ids[i])
                    _collateral[ids[i]] -= value;
                    // Overflow not possible: sum_i(values[i]) <= sum_i(collateral(ids[i])) <= collateralAll
                    totalBurnValue += value;
                }
            }
            unchecked {
                // Overflow not possible: totalBurnValue = sum_i(values[i]) <= sum_i(collateral(ids[i])) <= collateralAll
                _collateralAll -= totalBurnValue;
            }
        }
    }
}
