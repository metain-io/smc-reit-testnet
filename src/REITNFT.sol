// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./KYCAccessUpgradeable.sol";
import "./ERC1155Tradable.sol";
import "./IREITTradable.sol";

contract REITNFT is IREITTradable, ERC1155Tradable, KYCAccessUpgradeable {
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    event Create(uint256 id);

    struct TokenMetadata {
        uint256 unitValue;
        uint64 initiateTime;
        uint64 liquidationTime;
        uint64 taxRate;
    }

    struct TokenYieldData {        
        uint256[] dividendPerShares;
        uint32 dividendsLength;
        uint64 liquidationTimeExtension;
    }

    struct YieldVesting {
        // beneficiary of yield
        address beneficiary;
        // amount of tokends locked
        uint256 lockingDividends;
        // amount of tokens in pending
        uint256 pendingDividends;
        // total dividends claimed
        uint256 claimedDividends;

        bool initialized;
        // amount of tokens given
        uint32 lastClaimIndex;
    }

    uint256 public constant PERCENT_DECIMALS_MULTIPLY = 100 * 10**6; // allow upto 6 decimals of percentage

    uint256 private constant MAX_REIT_LIFE_MONTHS = 10 * 12;

    mapping(uint256 => TokenMetadata) public tokenMetadata;
    mapping(uint256 => TokenYieldData) public tokenYieldData;
    mapping(uint256 => mapping(address => YieldVesting))
        private tokenYieldVesting;

    // address of the payable tokens to fund and claim
    mapping(uint256 => IERC20) private fundingToken;
    mapping(uint256 => uint256) public fundingVault;

    mapping(uint256 => address) private ipoContracts;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _lockingBalances;

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
            _balances[_id][_msgSender()] + _lockingBalances[_id][_msgSender()] > 0,
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

        fundingToken[_id] = IERC20(_fundingToken);
        tokenMetadata[_id] = TokenMetadata(0, 0, 0, 0);
        tokenYieldData[_id] = TokenYieldData(            
            new uint256[](MAX_REIT_LIFE_MONTHS),
            0,
            0
        );

        _mint(_initialOwner, _id, _initialSupply, _data);

        tokenSupply[_id] = _initialSupply;

        emit Create(_id);
        return _id;
    }

    function initiate(
        uint256 _id,
        uint64 initiateTime,
        uint256 unitValue,
        uint64 liquidationTime,
        uint64 taxRate
    ) external creatorOnly(_id) {
        tokenMetadata[_id] = TokenMetadata(
            unitValue,
            initiateTime,
            liquidationTime,
            taxRate
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
        address account = _msgSender();

        if (!tokenYieldVesting[_id][account].initialized) {
            return 0;
        }

        uint256 unlockedBalances = _balances[_id][account];
        uint256 claimableYield = 0;
        uint32 dividendsLength = tokenYieldData[_id].dividendsLength;
        uint32 lastClaimIndex = tokenYieldVesting[_id][account].lastClaimIndex;
        for (uint32 i = lastClaimIndex; i < dividendsLength; ++i) {
            claimableYield +=
                tokenYieldData[_id].dividendPerShares[i] *
                unlockedBalances;
        }

        return
            claimableYield + tokenYieldVesting[_id][account].pendingDividends;
    }

    function getLockedYieldDividends(uint256 _id)
        external
        view
        shareHoldersOnly(_id)
        returns (uint256)
    {
        address account = _msgSender();

        if (!tokenYieldVesting[_id][account].initialized) {
            return 0;
        }

        uint256 lockedBalance = _lockingBalances[_id][account];
        uint256 lockedYield = 0;
        uint32 dividendsLength = tokenYieldData[_id].dividendsLength;
        uint32 lastClaimIndex = tokenYieldVesting[_id][account].lastClaimIndex;
        for (uint32 i = lastClaimIndex; i < dividendsLength; ++i) {
            lockedYield +=
                tokenYieldData[_id].dividendPerShares[i] *
                lockedBalance;
        }

        return lockedYield + tokenYieldVesting[_id][account].lockingDividends;
    }

    function claimBenefit(uint256 _id) external onlyKYC nonReentrant {
        address account = _msgSender();

        _liquidateYield(account, _id);

        uint256 claimableYield = tokenYieldVesting[_id][account]
            .pendingDividends;
        require(claimableYield > 0, "REITNFT: no more claimable yield");

        require(
            fundingVault[_id] >= claimableYield,
            "REITNFT: need more fundings from issuer"
        );

        unchecked {
            tokenYieldVesting[_id][account].pendingDividends = 0;
            tokenYieldVesting[_id][account].claimedDividends += claimableYield;
        }

        IERC20 payableToken = fundingToken[_id];
        require(
            payableToken.transfer(account, claimableYield),
            "REITNFT: Could not transfer fund"
        );

        unchecked {
            fundingVault[_id] -= claimableYield;
        }
    }

    function _liquidateYield(address account, uint256 _id) internal {
        if (isIPOContract(_id, account)) {
            return;
        }

        if (!tokenYieldVesting[_id][account].initialized) {
            tokenYieldVesting[_id][account] = YieldVesting(
                account,
                0,
                0,
                0,
                true,
                0
            );
        }

        // Calculate yields
        uint256 claimableYield = 0;
        uint256 unregisteredYield = 0;

        if (tokenYieldVesting[_id][account].initialized) {
            uint256 lockedBalance = _lockingBalances[_id][account];
            uint256 unlockedBalance = _balances[_id][account];
            uint32 dividendsLength = tokenYieldData[_id].dividendsLength;
            uint32 lastClaimIndex = tokenYieldVesting[_id][account]
                .lastClaimIndex;
            for (uint32 i = lastClaimIndex; i < dividendsLength; ++i) {
                uint256 dividend = tokenYieldData[_id].dividendPerShares[i];
                claimableYield += dividend * unlockedBalance;
                unregisteredYield += dividend * lockedBalance;
            }

            tokenYieldVesting[_id][account].lastClaimIndex = dividendsLength;
        }

        if (claimableYield > 0) {
            unchecked {
                tokenYieldVesting[_id][account]
                    .pendingDividends += claimableYield;
            }
        }

        if (unregisteredYield > 0) {
            unchecked {
                tokenYieldVesting[_id][account]
                    .lockingDividends += unregisteredYield;
            }
        }
    }

    function payDividends(uint256 _id, uint256 amount) external {
        IERC20 payableToken = fundingToken[_id];

        require(
            payableToken.transferFrom(_msgSender(), address(this), amount),
            "REITNFT: Could not transfer fund"
        );

        fundingVault[_id] = fundingVault[_id].add(amount);
    }

    function unlockDividendPerShare(
        uint256 _id,
        uint256 dividendPerShare,
        uint32 index
    ) external creatorOnly(_id) {
        tokenYieldData[_id].dividendPerShares[index] = dividendPerShare;
        if (tokenYieldData[_id].dividendsLength < index + 1) {
            tokenYieldData[_id].dividendsLength = index + 1;
        }
    }

    function getYieldDividendPerShareAt(uint256 _id, uint256 index)
        external
        view
        returns (uint256)
    {
        return tokenYieldData[_id].dividendPerShares[index];
    }

    function getTotalYieldDividendPerShare(uint256 _id)
        external
        view
        returns (uint256)
    {
        uint256 sum = 0;
        TokenYieldData memory yieldData = tokenYieldData[_id];
        for (uint32 i = 0; i < yieldData.dividendsLength; ++i) {
            sum += yieldData.dividendPerShares[i];
        }
        return sum;
    }

    function registerBalances(uint256 _id) external onlyKYC nonReentrant {
        address account = _msgSender();

        uint256 amount = _lockingBalances[_id][account];
        require(amount > 0, "Already registered all");

        uint256 taxAmount = (tokenMetadata[_id].unitValue *
            amount *
            tokenMetadata[_id].taxRate) / PERCENT_DECIMALS_MULTIPLY;

        IERC20 payableToken = fundingToken[_id];
        require(
            payableToken.transferFrom(account, address(this), taxAmount),
            "REITNFT: Could not pay tax"
        );

        unchecked {
            _lockingBalances[_id][account] = 0;
            _balances[_id][account] += amount;

            tokenYieldVesting[_id][account]
                .pendingDividends += tokenYieldVesting[_id][account]
                .lockingDividends;
            tokenYieldVesting[_id][account].lockingDividends = 0;
        }
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
            _lockingBalances[id][to] += amount;
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
                _lockingBalances[id][to] += amount;
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

    function lockingBalanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _lockingBalances[id][account];
    }

    function getShareUnitPrice(uint256 _id)
        external
        view
        override
        returns (uint256)
    {
        return tokenMetadata[_id].unitValue;
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
