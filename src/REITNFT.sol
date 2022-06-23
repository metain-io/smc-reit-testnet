// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./KYCAccessUpgradeable.sol";
import "./ERC1155Tradable.sol";
import "./IREITTradable.sol";

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

contract REITNFT is IREITTradable, ERC1155Tradable, KYCAccessUpgradeable {
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    event Create(uint256 id);

    struct REITMetadata {
        uint256 ipoTime;
        uint256 ipoUnitPrice;
        uint256 liquidationTime;
        uint256 registerationTaxRate;
    }

    struct REITYield {
        uint256 liquidationExtension;
        uint256[] yieldDividendPerShares;
        uint yieldDividendIndexCounter;        
    }

    struct YieldVesting {
        bool initialized;
        // beneficiary of yield after they are released
        address beneficiary;
        // amount of tokens given
        uint256 lastClaimTime;
        // amount of tokens in pending
        uint256 futureAmount;
        // total yield claimed so far
        uint256 totalClaimedYield;
    }

    uint constant MAX_REIT_LIFE_MONTHS = 10 * 12;
    uint256 constant PERCENT_DECIMALS_MULTIPLY = 100000000; // allow upto 6 decimals of percentage

    mapping(uint256 => REITMetadata) public tokenMetadata;
    mapping(uint256 => REITYield) public tokenYieldData;
    mapping(uint256 => mapping(address => YieldVesting))
        private tokenYieldVesting;
    mapping(uint256 => uint256) public dividendFunds;

    // address of the payable tokens to fund and claim
    mapping(uint256 => IERC20Extented) private fundingToken;
    mapping(uint256 => address) private ipoContracts;

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
    ) public override initializer {
        super.initialize(_name, _symbol, _uri);

        __KYCAccess_init();
    }

    /**
     * @dev Require msg.sender to own more than 0 of the token id
     */
    modifier shareHoldersOnly(uint256 _id) {
        require(
            balanceOf(_msgSender(), _id) > 0,
            "ERC1155Tradable#shareHoldersOnly: ONLY_OWNERS_ALLOWED"
        );
        _;
    }

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
     * @param _initialOwner address of the first owner of the token
     * @param _initialSupply amount to supply the first owner
     * @param _uri URI for this token type
     * @param _fundingToken Token as stable-coin to pay investors
     * @param _data Data to pass if receiver is contract
     * @return The newly created token ID
     */
    function createREIT(
        address _initialOwner,
        uint256 _initialSupply,
        string calldata _uri,
        address _fundingToken,
        bytes calldata _data
    ) external onlyGovernor returns (uint256) {
        uint256 _id = super._getNextTokenID();
        super._incrementTokenTypeId();
        _setCreator(_initialOwner, _id);

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
            tokenUri[_id] = _uri;
        }

        fundingToken[_id] = IERC20Extented(_fundingToken);
        tokenMetadata[_id] = REITMetadata(0, 0, 0, 0);
        tokenYieldData[_id] = REITYield(0, new uint256[](MAX_REIT_LIFE_MONTHS), 0);

        _mint(_initialOwner, _id, _initialSupply, _data);

        tokenSupply[_id] = _initialSupply;

        emit Create(_id);
        return _id;
    }

    function initiate(
        uint256 _id,
        uint256 ipoTime,
        uint256 ipoUnitPrice,
        uint256 liquidationTime,
        uint256 registerationTaxRate
    ) external creatorOnly(_id) {
        tokenMetadata[_id] = REITMetadata(
            ipoTime,
            ipoUnitPrice,
            liquidationTime,
            registerationTaxRate
        );
    }

    function getClaimedYield(uint256 _id) external view shareHoldersOnly(_id) returns (uint256) {
        return tokenYieldVesting[_id][_msgSender()].totalClaimedYield;
    }

    function getTotalClaimableBenefit(uint256 _id)
        external
        view
        shareHoldersOnly(_id)
        returns (uint256)
    {
        YieldVesting memory yieldVesting = tokenYieldVesting[_id][_msgSender()];
        return _getClaimableBenefit(_msgSender(), _id).add(yieldVesting.futureAmount);
    }

    function _getClaimableBenefit(address account, uint256 _id) internal view returns (uint256) {        
        YieldVesting memory yieldVesting = tokenYieldVesting[_id][account];
        if (!yieldVesting.initialized) {
            return 0;
        }

        REITYield memory yieldData = tokenYieldData[_id];

        uint256 balance = balanceOf(account, _id);
        uint256 claimableYield = 0;
        for (uint i = yieldVesting.lastClaimTime; i < yieldData.yieldDividendIndexCounter; ++i) {
            uint256 amount = yieldData.yieldDividendPerShares[i].mul(balance);
            claimableYield = claimableYield.add(amount);
        }
        
        return claimableYield;
    }

    function claimBenefit(uint256 _id)
        external
        onlyKYC
        shareHoldersOnly(_id)
        nonReentrant
    {
        if (!tokenYieldVesting[_id][_msgSender()].initialized) {
            tokenYieldVesting[_id][_msgSender()].initialized = true;
            tokenYieldVesting[_id][_msgSender()].beneficiary = _msgSender();
            tokenYieldVesting[_id][_msgSender()].futureAmount = 0;
            tokenYieldVesting[_id][_msgSender()].lastClaimTime = 0;
            tokenYieldVesting[_id][_msgSender()].totalClaimedYield = 0;
        }

        YieldVesting memory yieldVesting = tokenYieldVesting[_id][_msgSender()];
        uint256 claimableYield = _getClaimableBenefit(_msgSender(), _id).add(yieldVesting.futureAmount);        
        require(claimableYield > 0, "REITNFT: no more claimable yield");

        uint256 availableFund = dividendFunds[_id];
        require(
            availableFund >= claimableYield,
            "REITNFT: need more fundings from issuer"
        );

        REITYield memory yieldData = tokenYieldData[_id];        
        tokenYieldVesting[_id][_msgSender()].futureAmount = 0;
        tokenYieldVesting[_id][_msgSender()].lastClaimTime = yieldData.yieldDividendIndexCounter;
        tokenYieldVesting[_id][_msgSender()].totalClaimedYield = tokenYieldVesting[_id][_msgSender()].totalClaimedYield.add(claimableYield);

        IERC20Extented payableToken = fundingToken[_id];
        require(
            payableToken.transfer(_msgSender(), claimableYield),
            "REITNFT: Could not transfer fund"
        );

        dividendFunds[_id] = dividendFunds[_id].sub(claimableYield);
    }

    function _liquidateYield(address acount, uint256 _id) internal {
        if (!tokenYieldVesting[_id][acount].initialized) {
            tokenYieldVesting[_id][acount].initialized = true;
            tokenYieldVesting[_id][acount].beneficiary = acount;
            tokenYieldVesting[_id][acount].futureAmount = 0;
            tokenYieldVesting[_id][acount].lastClaimTime = 0;
        }

        uint256 claimableYield = _getClaimableBenefit(acount, _id);
        if (claimableYield > 0) {
            REITYield memory yieldData = tokenYieldData[_id];
            tokenYieldVesting[_id][acount].futureAmount = tokenYieldVesting[_id][acount].futureAmount.add(claimableYield);
            tokenYieldVesting[_id][acount].lastClaimTime = yieldData.yieldDividendIndexCounter;
        }
    }

    function payDividends(uint256 _id, uint256 amount) external {
        IERC20Extented payableToken = fundingToken[_id];

        require(
            payableToken.transferFrom(_msgSender(), address(this), amount),
            "REITNFT: Could not transfer fund"
        );

        dividendFunds[_id] = dividendFunds[_id].add(amount);
    }

    function unlockDividendPerShare(uint256 _id, uint256 dividendPerShare, uint index)
        external
        creatorOnly(_id)
    {
        tokenYieldData[_id].yieldDividendPerShares[index] = dividendPerShare;
        if (tokenYieldData[_id].yieldDividendIndexCounter < index + 1) {
            tokenYieldData[_id].yieldDividendIndexCounter = index + 1;
        }
    }

    function getYieldDividendPerShareAt(uint256 _id, uint index)
        external
        view
        returns (uint256)
    {
        return tokenYieldData[_id].yieldDividendPerShares[index];
    }

    function getTotalYieldDividendPerShare(uint _id) external view returns (uint256) { 
        uint256 sum = 0;
        REITYield memory yieldData = tokenYieldData[_id];
        for (uint i = 0; i < yieldData.yieldDividendIndexCounter; ++i) {
            sum += yieldData.yieldDividendPerShares[i];
        }
        return sum;

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

        if (!isIPOContract(id, from) && !isIPOContract(id, to)) {
            uint256 taxAmount = _calculateTransferTax(id, amount);
            IERC20 payableToken = fundingToken[id];
            require(
                payableToken.transferFrom(from, address(this), taxAmount),
                "REITNFT: Could not pay tax"
            );

            _liquidateYield(from, id);
        }
        
        _liquidateYield(to, id);

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

        for (uint i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (!isIPOContract(id, from) && !isIPOContract(id, to)) {
                uint256 taxAmount = _calculateTransferTax(id, amount);
                IERC20 payableToken = fundingToken[id];
                require(
                    payableToken.transferFrom(from, address(this), taxAmount),
                    "REITNFT: Could not pay tax"
                );

                _liquidateYield(from, id);
            }

            _liquidateYield(to, id);
        }

        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _calculateTransferTax (uint256 _id, uint256 amount) internal view returns (uint256) {
        REITMetadata memory metadata = tokenMetadata[_id];
        return metadata.ipoUnitPrice.mul(amount).mul(metadata.registerationTaxRate).div(PERCENT_DECIMALS_MULTIPLY);
    }

    function setKYCAdmin(address account) external onlyGovernor {
        require(account != address(0), "KYC Admin cannot be zero address");
        _setKYCAdmin(account);
    }

    function revokeKYCAdmin() external onlyGovernor {
        _setKYCAdmin(address(0));
    }

    function balanceOf(address account, uint256 id)
        public
        view
        override(ERC1155Upgradeable, IREITTradable)
        returns (uint256)
    {
        return ERC1155Upgradeable.balanceOf(account, id);
    }

    function getShareUnitPrice(uint256 _id)
        external
        view
        override
        returns (uint256)
    {
        return tokenMetadata[_id].ipoUnitPrice;
    }

    function setIPOContract(uint256 _id, address account)
        external
        creatorOnly(_id)
    {
        ipoContracts[_id] = account;
    }

    function getIPOContract(uint256 _id) external view returns (address) {
        return ipoContracts[_id];
    }

    function isIPOContract(uint256 _id, address account)
        public
        view
        returns (bool)
    {
        return ipoContracts[_id] == account;
    }
}
