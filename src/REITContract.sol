// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title REITContract
 */
contract REITContract is
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;
   
    /**
     * @dev Creates REIT NFT Contract.
     */
    constructor(
    )  {
        
    }

}
