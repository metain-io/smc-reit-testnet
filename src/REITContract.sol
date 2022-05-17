// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC1155Tradable.sol";

/**
 * @title REITContract
 */
contract REITContract is Ownable, ERC1155Tradable {
    using SafeMath for uint256;

    uint256 private _currentTokenID = 0;

    // Mapping from token ID to total supplies
    mapping(uint256 => mapping(address => uint256)) private _totalSupplies;

    /**
     * @dev Creates REIT NFT Contract.
     */
    constructor () ERC1155Tradable("", "", 0)
    {
        
    }
}
