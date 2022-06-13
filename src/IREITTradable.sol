// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title IREITTradable
 */
interface IREITTradable {
    function getREITBalanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferREITFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function getIPOUnitPrice(uint256 _id) external view returns (uint256);
}
