// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155Tradable.sol";
import "./IREITTradable.sol";

contract REITNFT is ERC1155Tradable, IREITTradable {
    event Create(uint256 id);

    struct REITMetadata {
        uint256 ipoTime;
        uint256 ipoUnitPrice;
        uint256 yieldPeriod;
        uint256 yieldDividend;
        uint256 liquidationTime;
        uint256 liquidationExtension;
        uint256[] annualAUM;
        uint256[] purchaseQuota;
    }

    mapping(uint256 => REITMetadata) public tokenMetadata;

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
            0,
            0,
            0,
            0,
            new uint256[](0),
            new uint256[](0)
        );

        _mint(_initialOwner, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;

        emit Create(_id);
        return _id;
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
