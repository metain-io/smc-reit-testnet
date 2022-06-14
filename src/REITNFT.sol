// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC1155Tradable.sol";
import "./IREITTradable.sol";

contract REITNFT is ERC1155Tradable, IREITTradable {
    using SafeMath for uint256;

    event Create(uint256 id);

    struct REITMetadata {
        uint256 ipoTime;
        uint256 ipoUnitPrice;
        uint256 liquidationTime;
    }

    struct REITYield {
        uint256 yieldDividend;
        uint256 liquidationExtension;
    }

    struct YieldVesting {
        bool initialized;
        // beneficiary of yield after they are released
        address beneficiary;        
        // amount of tokens vested
        uint256 released;
    }

    mapping(uint256 => REITMetadata) public tokenMetadata;
    mapping(uint256 => REITYield) public tokenYieldData;
    mapping(uint256 => uint256) public reitAllowance;
    mapping(address => YieldVesting) public yieldVesting;

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
     * @param _initialOwner address of the first owner of the token
     * @param _initialSupply amount to supply the first owner
     * @param _uri URI for this token type
     * @param _data Data to pass if receiver is contract
     * @return The newly created token ID
     */
    function create(
        address _initialOwner,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) external onlyOwner returns (uint256) {
        uint256 _id = super._getNextTokenID();
        super._incrementTokenTypeId();
        creators[_id] = msg.sender;

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
            tokenUri[_id] = _uri;
        }

        tokenMetadata[_id] = REITMetadata(
            0,
            0,
            0
        );

        tokenYieldData[_id] = REITYield(0, 0);

        _mint(_initialOwner, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;

        emit Create(_id);
        return _id;
    }

    function initiate(uint256 _id, uint256 ipoTime, uint256 ipoUnitPrice, uint liquidationTime) external creatorOnly(_id) {
        tokenMetadata[_id] = REITMetadata(
            ipoTime,
            ipoUnitPrice,
            liquidationTime
        );
    }

    function setYield(uint256 _id, uint256 yieldDividend, uint256 liquidationExtension) external creatorOnly(_id) {
        uint256 totalSupply = tokenSupply[_id];
        uint256 totalSupplyValue = totalSupply.mul(yieldDividend);
        uint256 allowance = reitAllowance[_id];
        require(totalSupplyValue <= allowance, "");
        tokenYieldData[_id] = REITYield(yieldDividend, liquidationExtension);
    }

    function claimYield(uint256 _id) external ownersOnly(_id) {

    }

    function allowYieldFund(uint256 _id, uint256 amount) external onlyOwner {
        reitAllowance[_id] = amount;
    }

    function safeTransferREITFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external override {
        bytes memory empty;
        return safeTransferFrom(from, to, id, amount, empty);
    }

    function getREITBalanceOf(address account, uint256 id)
        external
        view
        override
        returns (uint256)
    {
        return balanceOf(account, id);
    }

    function getIPOUnitPrice(uint256 _id)
        external
        view
        override
        returns (uint256)
    {
        return tokenMetadata[_id].ipoUnitPrice;
    }
}
