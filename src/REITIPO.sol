// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IREITTradable.sol";
import "./Whitelisting.sol";

contract REITIPO is
    IERC1155ReceiverUpgradeable,
    Initializable,
    Whitelisting,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // address of the REIT NFT
    IREITTradable private _nft;
    uint256 private _nftId;

    // address of the stable token
    mapping(string => IERC20) private _payableToken;

    function initialize(address _nftAddress, uint256 id) external initializer {
        require(_nftAddress != address(0x0));
        __Ownable_init();
        __Whitelisting_init();

        _nft = IREITTradable(_nftAddress);
        _nftId = id;
        _whitelistFree = false;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Returns the address of the IERC1155 contract
     */
    function getNFT() external view returns (address) {
        return address(_nft);
    }

    /**
     * @dev add a new token contract address as payable
     * @param name Name of token
     * @param token Token contract adddress
     */
    function allowPayableToken(string calldata name, address token)
        public
        onlyOwner
    {
        _payableToken[name] = IERC20(token);
    }

    /**
     * @dev Withdraw total ether to owner's wallet
     *
     * Requirements:
     * - Only the owner can withdraw
     * - The contract must have ether left.
     */
    function withdrawFunds() external nonReentrant onlyOwner {
        require(
            address(this).balance > 0,
            "REIT IPO: Contract's balance is empty"
        );

        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Withdraw total payable tokens to owner's wallet
     *
     * Requirements:
     * - Only the owner can withdraw
     */
    function withdrawPayableToken(string calldata name)
        external
        nonReentrant
        onlyOwner
    {
        IERC20 token = _payableToken[name];
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    /**
     * @dev Withdraw the remaining NFTs to owner's wallet
     *
     * Requirements:
     * - Only the owner can withdraw.
     */
    function withdrawNFT() external nonReentrant onlyOwner {
        uint256 balance = _nft.balanceOf(address(this), _nftId);

        bytes memory empty;
        _nft.safeTransferFrom(address(this), owner(), _nftId, balance, empty);
    }

    /**
     * @notice Buy Token with stable coin under vesting conditions.
     * @param token Name of token to use
     * @param quantity Amount of REIT NFT to buy
     */
    function purchaseWithToken(string calldata token, uint256 quantity)
        external
        onlyWhitelisted
    {
        uint256 stock = _nft.balanceOf(address(this), _nftId);
        require(stock >= quantity, "REITIPO: not enough units to sell");

        uint256 price = _nft.getIPOUnitPrice(_nftId);
        require(price > 0, "REITIPO: price not set");

        uint256 amount = price * quantity;
        require(
            _payableToken[token].transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "REITIPO: not enough funds to buy"
        );

        if (_nft.isKYC(msg.sender)) {        
            bytes memory empty;
            _nft.safeTransferFrom(address(this), msg.sender, _nftId, quantity, empty);
            // TODO: allow IPO to register the balance without fee
        } else {
            // Pending this purchase
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId;
    }
}
