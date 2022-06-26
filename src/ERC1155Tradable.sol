// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC1155Upgradeable.sol";
import "./GovernableUpgradeable.sol";
import "./IREITTradable.sol";

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155Upgradeable, GovernableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using Strings for string;
    
    uint256 private currentTokenID;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => string) public tokenUri;

    string private _contractURI;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    /**
     * @dev Require msg.sender to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(
            creators[_id] == _msgSender(),
            "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    /**
     * @dev Initialization
     * @param _name string Name of the NFT
     * @param _symbol string Symbol of the NFT
     * @param _uri string URI to JSON data of the smart contract
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public virtual initializer {
        __ERC1155_init(_uri);
        __Governable_init();
        __ReentrancyGuard_init();        

        name = _name;
        symbol = _symbol;
        currentTokenID = 0;
        
        _contractURI = _uri;        
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI)
        public
        onlyGovernor
    {
        _setURI(_newBaseMetadataURI);
    }

    /**
     * @dev Will update the base URL of token's contract
     * @param _uri New URL of token's contract
     */
    function setContractURI(string memory _uri) public onlyGovernor {
        _contractURI = _uri;
    }

    /**
     * @dev Return the URL of token's contract
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     */
    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return tokenUri[_id];
    }
    
    /**
     * @dev Mints some amount of tokens to an address
     * @param _to          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     * @param _data        Data to pass if receiver is contract
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public creatorOnly(_id) {
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    /**
     * @dev Mint tokens for each id in _ids
     * @param _to          The address to mint tokens to
     * @param _ids         Array of ids to mint
     * @param _quantities  Array of amounts of tokens to mint per id
     * @param _data        Data to pass if receiver is contract
     */
    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public {
        require(
            _ids.length == _quantities.length,
            "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH"
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            require(
                creators[_id] == msg.sender,
                "ERC1155Tradable#batchMint: ONLY_CREATOR_ALLOWED"
            );
            uint256 quantity = _quantities[i];
            tokenSupply[_id] = tokenSupply[_id].add(quantity);
        }

        _mintBatch(_to, _ids, _quantities, _data);
    }

    /**
     * @dev Change the creator address for given tokens
     * @param _to   Address of the new creator
     * @param _ids  Array of Token IDs to change creator
     */
    function setCreator(address _to, uint256[] memory _ids) public {
        require(
            _to != address(0),
            "ERC1155Tradable#setCreator: INVALID_ADDRESS"
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            require(creators[id] == _msgSender(), "ERC1155Tradable#setCreator: ONLY_CREATOR_ALLOWED");
            _setCreator(_to, id);
        }
    }

    /**
     * @dev Change the creator address for given token
     * @param _to   Address of the new creator
     * @param _id  Token IDs to change creator of
     */
    function _setCreator(address _to, uint256 _id) internal {
        creators[_id] = _to;
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    /**
     * @dev calculates the next token ID based on value of currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenID() internal view returns (uint256) {
        return currentTokenID.add(1);
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() internal {
        currentTokenID++;
    }
}
