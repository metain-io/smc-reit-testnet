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
        uint256 yieldDividendIndexCounter;
        uint256[] yieldDividendPerShares;
    }

    struct YieldVesting {
        bool initialized;
        // beneficiary of yield
        address beneficiary;
        // amount of tokens given
        uint256 lastClaimTime;
        // amount of tokends locked
        uint256 lockingDividends;
        // amount of tokens in pending
        uint256 pendingDividends;
        // total dividends claimed
        uint256 claimedDividends;
    }

    uint256 constant MAX_REIT_LIFE_MONTHS = 10 * 12;
    uint256 constant PERCENT_DECIMALS_MULTIPLY = 100000000; // allow upto 6 decimals of percentage

    mapping(uint256 => REITMetadata) public tokenMetadata;
    mapping(uint256 => REITYield) public tokenYieldData;
    mapping(uint256 => mapping(address => YieldVesting))
        private tokenYieldVesting;
    mapping(uint256 => uint256) public dividendFunds;

    // address of the payable tokens to fund and claim
    mapping(uint256 => IERC20Extented) private fundingToken;
    mapping(uint256 => address) private ipoContracts;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256))
        internal _unregisteredBalances;

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
        tokenYieldData[_id] = REITYield(
            0,            
            0,
            new uint256[](MAX_REIT_LIFE_MONTHS)
        );

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

    function getClaimedYield(uint256 _id)
        external
        view
        shareHoldersOnly(_id)
        returns (uint256)
    {
        return tokenYieldVesting[_id][_msgSender()].claimedDividends;
    }

    function getTotalClaimableBenefit(uint256 _id)
        external
        view
        shareHoldersOnly(_id)
        returns (uint256)
    {
        YieldVesting memory yieldVesting = tokenYieldVesting[_id][_msgSender()];
        return
            _getClaimableBenefit(_msgSender(), _id).add(
                yieldVesting.pendingDividends
            );
    }

    function _getClaimableBenefit(address account, uint256 _id)
        internal
        view
        returns (uint256)
    {
        YieldVesting memory yieldVesting = tokenYieldVesting[_id][account];
        if (!yieldVesting.initialized) {
            return 0;
        }

        REITYield memory yieldData = tokenYieldData[_id];

        uint256 balance = balanceOf(account, _id);
        uint256 claimableYield = 0;
        for (
            uint256 i = yieldVesting.lastClaimTime;
            i < yieldData.yieldDividendIndexCounter;
            ++i
        ) {
            uint256 amount = yieldData.yieldDividendPerShares[i].mul(balance);
            claimableYield = claimableYield.add(amount);
        }

        return claimableYield;
    }

    function _getUnregisteredBenefit(address account, uint256 _id)
        internal
        view
        returns (uint256)
    {
        YieldVesting memory yieldVesting = tokenYieldVesting[_id][account];
        if (!yieldVesting.initialized) {
            return 0;
        }

        REITYield memory yieldData = tokenYieldData[_id];

        uint256 balance = _unregisteredBalances[_id][account];
        uint256 claimableYield = 0;
        for (
            uint256 i = yieldVesting.lastClaimTime;
            i < yieldData.yieldDividendIndexCounter;
            ++i
        ) {
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
        address account = _msgSender();

        if (!tokenYieldVesting[_id][account].initialized) {
            tokenYieldVesting[_id][account].initialized = true;
            tokenYieldVesting[_id][account].beneficiary = account;
            tokenYieldVesting[_id][account].lockingDividends = 0;
            tokenYieldVesting[_id][account].pendingDividends = 0;
            tokenYieldVesting[_id][account].lastClaimTime = 0;
            tokenYieldVesting[_id][account].claimedDividends = 0;
        }

        _liquidateYield(account, _id);

        uint256 claimableYield = tokenYieldVesting[_id][account].pendingDividends;
        require(claimableYield > 0, "REITNFT: no more claimable yield");

        uint256 availableFund = dividendFunds[_id];
        require(
            availableFund >= claimableYield,
            "REITNFT: need more fundings from issuer"
        );

        tokenYieldVesting[_id][account].pendingDividends = 0;        
        tokenYieldVesting[_id][account]
            .claimedDividends = tokenYieldVesting[_id][account]
            .claimedDividends
            .add(claimableYield);

        IERC20Extented payableToken = fundingToken[_id];
        require(
            payableToken.transfer(account, claimableYield),
            "REITNFT: Could not transfer fund"
        );

        dividendFunds[_id] = dividendFunds[_id].sub(claimableYield);
    }

    function _liquidateYield(address account, uint256 _id) internal {
        if (isIPOContract(_id, account)) {
            return;
        }

        if (!tokenYieldVesting[_id][account].initialized) {
            tokenYieldVesting[_id][account].initialized = true;
            tokenYieldVesting[_id][account].beneficiary = account;
            tokenYieldVesting[_id][account].lockingDividends = 0;
            tokenYieldVesting[_id][account].pendingDividends = 0;
            tokenYieldVesting[_id][account].lastClaimTime = 0;
        }
        
        uint256 claimableYield = _getClaimableBenefit(account, _id);
        uint256 unregisteredYield = _getUnregisteredBenefit(account, _id);

        REITYield memory yieldData = tokenYieldData[_id];
        tokenYieldVesting[_id][account].lastClaimTime = yieldData
            .yieldDividendIndexCounter;

        if (claimableYield > 0) {
            tokenYieldVesting[_id][account].pendingDividends = tokenYieldVesting[
                _id
            ][account].pendingDividends.add(claimableYield);
        }
        
        if (unregisteredYield > 0) {
            tokenYieldVesting[_id][account].lockingDividends = tokenYieldVesting[_id][account].lockingDividends.add(unregisteredYield);
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

    function unlockDividendPerShare(
        uint256 _id,
        uint256 dividendPerShare,
        uint256 index
    ) external creatorOnly(_id) {
        tokenYieldData[_id].yieldDividendPerShares[index] = dividendPerShare;
        if (tokenYieldData[_id].yieldDividendIndexCounter < index + 1) {
            tokenYieldData[_id].yieldDividendIndexCounter = index + 1;
        }
    }

    function getYieldDividendPerShareAt(uint256 _id, uint256 index)
        external
        view
        returns (uint256)
    {
        return tokenYieldData[_id].yieldDividendPerShares[index];
    }

    function getTotalYieldDividendPerShare(uint256 _id)
        external
        view
        returns (uint256)
    {
        uint256 sum = 0;
        REITYield memory yieldData = tokenYieldData[_id];
        for (uint256 i = 0; i < yieldData.yieldDividendIndexCounter; ++i) {
            sum += yieldData.yieldDividendPerShares[i];
        }
        return sum;
    }

    function registerBalances(uint256 _id)
        external
        onlyKYC
        nonReentrant
    {
        uint256 amount = _unregisteredBalances[_id][_msgSender()];
        require(amount > 0, "Already registered all");

        uint256 taxAmount = _calculateTransferTax(_id, amount);
        IERC20 payableToken = fundingToken[_id];
        require(
            payableToken.transferFrom(_msgSender(), address(this), taxAmount),
            "REITNFT: Could not pay tax"
        );

        _unregisteredBalances[_id][_msgSender()] = 0;
        _balances[_id][_msgSender()] += amount;

        tokenYieldVesting[_id][_msgSender()].pendingDividends = tokenYieldVesting[_id][_msgSender()].pendingDividends.add(tokenYieldVesting[_id][_msgSender()].lockingDividends);
        tokenYieldVesting[_id][_msgSender()].lockingDividends = 0;
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
        require(to != address(0), "ERC1155: transfer to the zero address");

        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );

        _liquidateYield(from, id);
        _liquidateYield(to, id);

        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        bool isIPOTransfer = isIPOContract(id, from) || isIPOContract(id, to);
        if (!isIPOTransfer) {
            _unregisteredBalances[id][to] += amount;
        } else {
            _balances[id][to] += amount;
        }

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
        }

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            _liquidateYield(from, id);
            _liquidateYield(to, id);
        }

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }

            bool isIPOTransfer = isIPOContract(id, from) ||
                isIPOContract(id, to);
            if (!isIPOTransfer) {
                _unregisteredBalances[id][to] += amount;
            } else {
                _balances[id][to] += amount;
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _calculateTransferTax(uint256 _id, uint256 amount)
        internal
        view
        returns (uint256)
    {
        REITMetadata memory metadata = tokenMetadata[_id];
        return
            metadata
                .ipoUnitPrice
                .mul(amount)
                .mul(metadata.registerationTaxRate)
                .div(PERCENT_DECIMALS_MULTIPLY);
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
