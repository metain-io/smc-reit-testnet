// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IREITTradable.sol";
import "./WhitelistingUpgradeable.sol";
import "./GovernableUpgradeable.sol";

contract REITIPO is
    IERC1155ReceiverUpgradeable,
    Initializable,
    WhitelistingUpgradeable,
    GovernableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;

    // address of the REIT NFT
    IREITTradable private _nft;

    mapping(uint256 => mapping(address => uint256)) _pendingBalances;

    // address of the stable token
    mapping(string => IERC20) private _payableToken;

    function initialize(address _nftAddress) external initializer {
        require(_nftAddress != address(0x0), "NFT contract cannot be zero address");
        __Governable_init();
        __Whitelisting_init();

        _nft = IREITTradable(_nftAddress);
        _whitelistFree = false;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Returns the address of the IERC1155 contract
     */
    function getNFTContract() external view returns (address) {
        return address(_nft);
    }

    function getPendingBalances(uint256 id, address account) external view returns(uint256) {
        return _pendingBalances[id][account];
    }

    /**
     * @dev add a new token contract address as payable
     * @param name Name of token
     * @param token Token contract adddress
     */
    function allowPayableToken(string calldata name, address token)
        public
        onlyGovernor
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
    function withdrawFunds() external nonReentrant onlyGovernor {
        require(
            address(this).balance > 0,
            "REIT IPO: Contract's balance is empty"
        );

        payable(governor()).transfer(address(this).balance);
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
        onlyGovernor
    {
        IERC20 token = _payableToken[name];
        uint256 balance = token.balanceOf(address(this));
        token.transfer(governor(), balance);
    }

    /**
     * @dev Withdraw the remaining NFTs to owner's wallet
     *
     * Requirements:
     * - Only the owner can withdraw.
     */
    function withdrawNFT(uint256 id) external nonReentrant onlyGovernor {
        uint256 balance = _nft.balanceOf(address(this), id);

        bytes memory empty;
        _nft.safeTransferFrom(address(this), governor(), id, balance, empty);
    }

    /**
     * @notice Buy Token with stable coin under vesting conditions.
     * @param token Name of token to use
     * @param id ID of NFT
     * @param quantity Amount of REIT NFT to buy
     */
    function purchaseWithToken(string calldata token, uint256 id, uint256 quantity)
        external
        onlyWhitelisted
    {
        require(_nft.isIPOContract(id, address(this)), "REITIPO: Must set this as REIT IPO contract");

        uint256 stock = _nft.registeredBalanceOf(address(this), id);
        require(stock >= quantity, "REITIPO: not enough units to sell");

        uint256 price = _nft.getShareUnitPrice(id);
        require(price > 0, "REITIPO: price not set");

        uint256 amount = price * quantity;
        require(
            _payableToken[token].transferFrom(
                _msgSender(),
                address(this),
                amount
            ),
            "REITIPO: not enough funds to buy"
        );

        if (_nft.isKYC(_msgSender())) {        
            bytes memory empty;

            // IPO contract will register the balance without fee
            _nft.safeTransferFrom(address(this), _msgSender(), id, quantity, empty);            
        } else {
            // Pending this purchase until buyer is KYC
            _pendingBalances[id][_msgSender()] = _pendingBalances[id][_msgSender()].add(quantity);
        }
    }

    function claimPendingBalances(uint256 id)
        external
        onlyWhitelisted
    {
        require(_nft.isKYC(_msgSender()), "KYC required");
        require(_pendingBalances[id][_msgSender()] > 0, "No more pending balances");

        uint256 quantity = _pendingBalances[id][_msgSender()];
        uint256 stock = _nft.balanceOf(address(this), id);
        require(stock >= quantity, "REITIPO: not enough units to claim");

        bytes memory empty;        
        _nft.safeTransferFrom(address(this), _msgSender(), id, quantity, empty);
        _pendingBalances[id][_msgSender()] = 0;
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
