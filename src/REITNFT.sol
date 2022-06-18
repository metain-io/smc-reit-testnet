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
        uint256 registerationFee;
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
    mapping(uint256 => mapping(address => YieldVesting))
        private tokenYieldVesting;
    mapping(uint256 => uint256) public dividendFunds;    

    // address of the payable tokens to fund and claim
    mapping(uint256 => IERC20Extented) private fundingToken;

    mapping(uint256 => mapping(address => uint256)) private _registeredBalances;

    /**
     * @dev check if an account is KYC
     * @return bool
     */
    function isKYC(address account) public view returns (bool) {
        require(account != address(0));
        return kycAccounts[account];
    }
    
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

        tokenMetadata[_id] = REITMetadata(0, 0, 0, 0);

        tokenYieldData[_id] = REITYield(0, 0);

        mint(_initialOwner, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;

        emit Create(_id);
        return _id;
    }

    function initiate(
        uint256 _id,
        uint256 ipoTime,
        uint256 ipoUnitPrice,
        uint256 liquidationTime,
        uint256 registerationFee
    ) external creatorOnly(_id) {
        tokenMetadata[_id] = REITMetadata(
            ipoTime,
            ipoUnitPrice,
            liquidationTime,
            registerationFee
        );
    }

    function registeredBalanceOf(address account, uint256 id) public view virtual returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _registeredBalances[id][account];
    }

    function registerBalanceOwnership(uint256 _id) external onlyKYC holdersOnly(_id) {
        REITMetadata memory metadata = tokenMetadata[_id];

        uint256 balance = balanceOf(msg.sender, _id);
        uint256 quantity = balance.sub(_registeredBalances[_id][_msgSender()]);

        require(quantity > 0, "REITNFT: Nothing to register");

        IERC20Extented payableToken = fundingToken[_id];
        uint256 fee = quantity
            .mul(metadata.ipoUnitPrice)
            .mul(metadata.registerationFee)
            .div(10**payableToken.decimals());

        require(
            payableToken.transferFrom(msg.sender, address(this), fee),
            "REITNFT: Could not transfer fund"
        );

        _registeredBalances[_id][_msgSender()] = balance;
    }

    function claimBenefit(uint256 _id)
        external
        onlyKYC
        holdersOnly(_id)
        nonReentrant
    {
        REITYield memory yieldData = tokenYieldData[_id];

        if (!tokenYieldVesting[_id][msg.sender].initialized) {
            tokenYieldVesting[_id][msg.sender].initialized = true;
            tokenYieldVesting[_id][msg.sender].beneficiary = msg.sender;
            tokenYieldVesting[_id][msg.sender].released = 0;
        }

        YieldVesting memory yieldVesting = tokenYieldVesting[_id][msg.sender];

        uint256 claimableYield = _registeredBalances[_id][_msgSender()]
            .mul(yieldData.yieldDividend)
            .sub(yieldVesting.released);
        require(claimableYield > 0, "REITNFT: no more claimable yield");

        uint256 availableFund = dividendFunds[_id];
        require(
            availableFund >= claimableYield,
            "REITNFT: need more fundings from issuer"
        );

        dividendFunds[_id] = dividendFunds[_id].sub(claimableYield);
        tokenYieldVesting[_id][msg.sender].released = yieldVesting.released.add(
            claimableYield
        );

        IERC20Extented payableToken = fundingToken[_id];
        require(
            payableToken.transfer(msg.sender, claimableYield),
            "REITNFT: Could not transfer fund"
        );
    }

    function payDividends(uint256 _id, uint256 amount) external {
        IERC20Extented payableToken = fundingToken[_id];

        require(
            payableToken.transferFrom(msg.sender, address(this), amount),
            "REITNFT: Could not transfer fund"
        );

        dividendFunds[_id] = dividendFunds[_id].add(amount);
    }

    function unlockDividends(
        uint256 _id,
        uint256 dividend
    ) external creatorOnly(_id) {
        uint256 nextDividend = tokenYieldData[_id].yieldDividend.add(dividend);
        uint256 totalSupply = tokenSupply[_id];
        uint256 totalSupplyValue = totalSupply.mul(nextDividend);
        uint256 totalFunding = dividendFunds[_id];
        require(totalSupplyValue <= totalFunding, "Not enough funding to pay all dividends");
        tokenYieldData[_id].yieldDividend = nextDividend;
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(ERC1155Upgradeable, IREITTradable) {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155Upgradeable, IREITTradable) {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function balanceOf(address account, uint256 id)
        public
        view
        override(ERC1155Upgradeable, IREITTradable)
        returns (uint256)
    {
        return ERC1155Upgradeable.balanceOf(account, id);
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
