// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC1155Tradable.sol";
import "./IREITTradable.sol";
import "./KYCAccess.sol";

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

contract REITNFT is ERC1155Tradable, KYCAccess, IREITTradable {
    using SafeMath for uint256;

    event Create(uint256 id);

    struct REITMetadata {
        uint256 ipoTime;
        uint256 ipoUnitPrice;
        uint256 liquidationTime;
        uint256 ownershipFee;
    }

    struct REITYield {
        uint256 yieldDividend;
        uint256 liquidationExtension;        
    }

    struct YieldVesting {
        bool initialized;
        // beneficiary of yield after they are released
        address beneficiary;      
        // amount of tokens affirmed
        uint256 affirmed;  
        // amount of tokens vested
        uint256 released;
    }

    mapping(uint256 => REITMetadata) public tokenMetadata;
    mapping(uint256 => REITYield) public tokenYieldData;
    mapping(uint256 => mapping(address => YieldVesting)) private tokenYieldVesting;
    mapping(uint256 => uint256) public reitFunding;    

    // address of the payable tokens to fund and claim
    mapping(uint256 => IERC20Extented) private fundingToken;

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
     * @param _initialOwner address of the first owner of the token
     * @param _initialSupply amount to supply the first owner
     * @param _uri URI for this token type
     * @param _fundingToken Token as stable-coin to pay investors
     * @param _data Data to pass if receiver is contract
     * @return The newly created token ID
     */
    function create(
        address _initialOwner,
        uint256 _initialSupply,
        string calldata _uri,
        address _fundingToken,
        bytes calldata _data
    ) external onlyOwner returns (uint256) {
        uint256 _id = super._getNextTokenID();
        super._incrementTokenTypeId();
        creators[_id] = msg.sender;

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
            tokenUri[_id] = _uri;
        }

        fundingToken[_id] = IERC20Extented(_fundingToken);

        tokenMetadata[_id] = REITMetadata(
            0,
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

    function initiate(uint256 _id, uint256 ipoTime, uint256 ipoUnitPrice, uint liquidationTime, uint256 ownershipFee) external creatorOnly(_id) {
        tokenMetadata[_id] = REITMetadata(
            ipoTime,
            ipoUnitPrice,
            liquidationTime,
            ownershipFee
        );
    }

    function affirmOwnership(uint256 _id) external onlyKYC holdersOnly(_id) {
        REITMetadata memory metadata = tokenMetadata[_id];
        YieldVesting memory yieldVesting = tokenYieldVesting[_id][msg.sender];        

        uint256 balance = balanceOf(msg.sender, _id);
        uint256 quantity = balance.sub(yieldVesting.affirmed);

        require(quantity > 0, "REITNFT: Already affirmed");

        IERC20Extented payableToken = fundingToken[_id];
        uint256 fee = quantity.mul(metadata.ipoUnitPrice).mul(metadata.ownershipFee).div(10 ** payableToken.decimals());
        
        require(
            payableToken.transferFrom(
                msg.sender,
                address(this),
                fee
            ),
            "REITNFT: Could not transfer fund"
        );        

        tokenYieldVesting[_id][msg.sender].affirmed = balance;
    }

    function setYield(uint256 _id, uint256 yieldDividend, uint256 liquidationExtension) external creatorOnly(_id) {
        uint256 totalSupply = tokenSupply[_id];
        uint256 totalSupplyValue = totalSupply.mul(yieldDividend);
        uint256 totalFunding = reitFunding[_id];
        require(totalSupplyValue <= totalFunding, "");
        tokenYieldData[_id] = REITYield(yieldDividend, liquidationExtension);
    }

    function claimYield(uint256 _id) external onlyKYC holdersOnly(_id) nonReentrant {
        uint256 balance = balanceOf(msg.sender, _id);
        REITYield memory yieldData = tokenYieldData[_id];

        if (!tokenYieldVesting[_id][msg.sender].initialized) {
            tokenYieldVesting[_id][msg.sender].initialized = true;
            tokenYieldVesting[_id][msg.sender].beneficiary = msg.sender;
            tokenYieldVesting[_id][msg.sender].affirmed = balance;
        }        
        
        YieldVesting memory yieldVesting = tokenYieldVesting[_id][msg.sender];

        uint256 claimableYield = yieldVesting.affirmed.mul(yieldData.yieldDividend).sub(yieldVesting.released);
        require(claimableYield > 0, "REITNFT: no more claimable yield");

        uint256 availableFund = reitFunding[_id];
        require(availableFund >= claimableYield, "REITNFT: need more fund from issuer");

        reitFunding[_id] = reitFunding[_id].sub(claimableYield);
        tokenYieldVesting[_id][msg.sender].released = yieldVesting.released.add(claimableYield);

        IERC20Extented payableToken = fundingToken[_id];
        require(
            payableToken.transfer(
                msg.sender,
                claimableYield
            ),
            "REITNFT: Could not transfer fund"
        );        
    }

    function fundREIT(uint256 _id, uint256 amount) external {
        IERC20Extented payableToken = fundingToken[_id];

        require(
            payableToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "REITNFT: Could not transfer fund"
        );

        reitFunding[_id] = reitFunding[_id].add(amount);
    }

    function safeTransferREITFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external override {
        // TODO: only affirmed quantity is tradeable

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
