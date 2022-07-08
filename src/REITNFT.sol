// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./KYCAccessUpgradeable.sol";
import "./ERC1155Tradable.sol";
import "./IREITTradable.sol";

/**
 * @title REITNFT
 */
contract REITNFT is IREITTradable, ERC1155Tradable, KYCAccessUpgradeable {
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    /**
     * @dev Emitted when REIT NFT of type `id` is created by `creator` wallet.
     */
    event Create(uint256 id, address creator);

    /**
     * @dev Metadata of a REIT NFT
     */
    struct TokenMetadata {
        // Value of each unit at IPO (in USD)
        uint256 unitValue;        
        // Time this project starts
        uint64 initiateTime;
        // Time this project is liquidated
        uint64 liquidationTime;
        // Tax rate for transfering to others
        uint64 transferTax;
    }

    /**
     * @dev Dividends data of a REIT NFT.
     */
    struct TokenDividendData {
        // latest market value of each unit (in USD)
        uint256 unitMarketValue;
        // liquidation value of each share (at liquidation time)
        uint256 liquidationPerShare;
        // sequence of dividend payments per share (each slot in the sequence represents a point in the real timelife, ie. a month, a quarter, etc. )
        uint256[] dividendPerShares;
        // last index of dividend payments sequence
        uint32 dividendsLength;
        // extension time to the liquidation
        uint64 liquidationTimeExtension;
    }

    /**
     * @dev Yield vesting data for each investor of a REIT
     */
    struct YieldVesting {
        // beneficiary of the yield
        address beneficiary;

        // amount of dividends in locking
        uint256 lockingDividends;
        // amount of dividends in pending
        uint256 pendingDividends;
        // total dividends claimed
        uint256 claimedDividends;

        // total liquidations claimed
        uint256 claimedLiquidations;
        // can user claim liquidation?
        bool isLiquidationUnlocked;

        // intialization flag
        bool initialized;
        // index at dividend payments that was claimed
        uint32 lastClaimIndex;
    }

    // Base multiplication of a percentage value in fixed point format
    uint256 private constant PERCENT_DECIMALS_MULTIPLY = 100 * 10**6; // allow upto 6 decimals of percentage

    // Maximum number of dividends sequence of each REIT life cycle
    uint256 private constant MAX_DIVIDENDS_SEQUENCE_COUNT = 100;

    // Metadata mapping
    mapping(uint256 => TokenMetadata) private tokenMetadata;

    // Dividend data mapping
    mapping(uint256 => TokenDividendData) private tokenDividendData;

    // Mapping of yield vestings of investors
    mapping(uint256 => mapping(address => YieldVesting))
        private tokenYieldVesting;

    // Balance of funding vault for each NFT to pay for dividends
    mapping(uint256 => uint256) private dividendVaultBalance;

    // Balance of funding vault for each NFT to pay for liquidations
    mapping(uint256 => uint256) private liquidationVaultBalance;

    // Address of the payable tokens for paying dividends
    mapping(uint256 => IERC20) private fundingToken;

    // IPO contract addresses of each NFT
    mapping(uint256 => address) private ipoContracts;

    // Mapping from token ID to account balances that are locked (will unlock after paying transaction tax)
    mapping(uint256 => mapping(address => uint256)) private _lockingBalances;

    // Mapping from token ID to account balances that are liquidated
    mapping(uint256 => mapping(address => uint256)) private _liquidatedBalances;    

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
     * @dev Require `msg.sender` to own more than 0 of the token id
     */
    modifier shareHoldersOnly(uint256 _id) {
        uint256 totalBalances = _balances[_id][_msgSender()] + _lockingBalances[_id][_msgSender()] + _liquidatedBalances[_id][_msgSender()];
        require(
            totalBalances > 0,
            "ERC1155Tradable#shareHoldersOnly: ONLY_OWNERS_ALLOWED"
        );
        _;
    }

    /**
     * @dev Check if an `account` is in the KYC list
     * @return bool
     */
    function isKYC(address account) public view returns (bool) {
        require(account != address(0));
        return kycAccounts[account];
    }

    /**
     * === ADMINISTRATION ===
     */

    /**
     * @dev Appoint an account as admin that administer KYC list
     * Requirements:
     *
     * - only governor can execute
     */     
    function setKYCAdmin(address account) external onlyGovernor {
        require(account != address(0), "KYC Admin cannot be zero address");
        _setKYCAdmin(account);
    }

    /**
     * @dev Revoke the KYC admin access
     * Requirements:
     *
     * - only governor can execute
     */
    function revokeKYCAdmin() external onlyGovernor {
        _setKYCAdmin(address(0));
    }

    /**
     * @dev Set the IPO contract address that is bound to an NFT
     * Requirements:
     *
     * - only creator of the NFT can execute
     *
     * @param _id ID of the NFT
     * @param account IPO contract address
     */
    function setIPOContract(uint256 _id, address account)
        external
        creatorOnly(_id)
    {
        require(account.isContract(), "IPO must be a contract");
        ipoContracts[_id] = account;
    }

    /**
     * @dev Get the IPO contract address bound to an NFT
     * @param _id ID of the NFT
     * @return address The IPO contract address
     */
    function getIPOContract(uint256 _id) external view returns (address) {
        return ipoContracts[_id];
    }

    /**
     * @dev Check if an address is the IPO contract address
     * @param _id ID of the NFT
     * @param account Address to check
     * @return bool
     */
    function isIPOContract(uint256 _id, address account)
        public
        view
        returns (bool)
    {
        return ipoContracts[_id] == account;
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * Requirements:
     *
     * - only governor can execute
     *
     * @param _initialOwner address of the first owner of the token, and is also the creator
     * @param _initialSupply amount to supply the first owner
     * @param _uri URI for this token type
     * @param _fundingToken Token as stable-coin to pay investors
     * @param _data Data to pass if receiver is contract
     * @return uint256 The newly created token ID
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
        tokenDividendData[_id] = TokenDividendData(
            0,
            0,
            new uint256[](MAX_DIVIDENDS_SEQUENCE_COUNT),
            0,
            0
        );

        _mint(_initialOwner, _id, _initialSupply, _data);

        tokenSupply[_id] = _initialSupply;

        emit Create(_id, _initialOwner);
        return _id;
    }

    /**
     * @dev Initiate a REIT NFT by setting the metadata
     * Requirements:
     *
     * - only creator of the NFT can execute
     *
     * @param _id ID of the NFT to initiate
     * @param initiateTime Time this project starts
     * @param unitValue Value of each NFT unit (in USD)
     * @param liquidationTime Time this project liquidates
     * @param transferTax Transfer tax rate
     */
    function initiateREIT(
        uint256 _id,
        uint64 initiateTime,
        uint256 unitValue,
        uint64 liquidationTime,
        uint64 transferTax
    ) external creatorOnly(_id) {
        tokenMetadata[_id] = TokenMetadata(
            unitValue,
            initiateTime,
            liquidationTime,
            transferTax
        );

        tokenDividendData[_id].unitMarketValue = unitValue;
    }

    /**
     * @dev Set the market value of a REIT unit
     * Requirements:
     *
     * - only creator of the NFT can execute
     *
     * @param _id ID of the NFT
     * @param value Market value of the REIT unit (in USD)
     */
    function setUnitMarketValue(uint256 _id, uint256 value)
        external
        creatorOnly(_id)
    {
        tokenDividendData[_id].unitMarketValue = value;
    }

    /**
     * === DIVIDENDS ==
     */

    /**
     * @dev Transfer payable tokens to a REIT NFT funding vault to pay for dividends
     * @param _id ID of the NFT
     * @param amount Amount of tokens to pay     
     */
    function fundDividendVault(uint256 _id, uint256 amount) external {
        IERC20 payableToken = fundingToken[_id];

        require(
            payableToken.transferFrom(_msgSender(), address(this), amount),
            "REITNFT: Could not transfer fund"
        );

        dividendVaultBalance[_id] = dividendVaultBalance[_id].add(amount);
    }

    /**
     * @dev Transfer payable tokens to a REIT NFT funding vault to pay for liquidations
     * @param _id ID of the NFT
     * @param amount Amount of tokens to pay     
     */
    function fundLiquidationVault(uint256 _id, uint256 amount) external {
        IERC20 payableToken = fundingToken[_id];

        require(
            payableToken.transferFrom(_msgSender(), address(this), amount),
            "REITNFT: Could not transfer fund"
        );

        liquidationVaultBalance[_id] = liquidationVaultBalance[_id].add(amount);
    }

    /**
     * @dev Unlock to allow investors to claim yield dividend at a timeline index in the sequence
     * Requirements:
     *
     * - only creator of the NFT can execute
     *
     * @param id ID of the NFT
     * @param value Amount to pay for each share
     * @param time Timeline index at which this dividend pay for
     */
    function unlockDividendPerShare(
        uint256 id,
        uint256 value,
        uint32 time
    ) external creatorOnly(id) {
        require(tokenDividendData[id].liquidationPerShare == 0, "Must not yet liquidated");

        tokenDividendData[id].dividendPerShares[time] = value;
        if (tokenDividendData[id].dividendsLength < time + 1) {
            tokenDividendData[id].dividendsLength = time + 1;
        }
    }

    /**
     * @dev Unlock to allow investors to claim liquidation
     * Requirements:
     *
     * - only creator of the NFT can execute
     *
     * @param id ID of the NFT
     * @param value Amount to pay for each share
     */
    function unlockLiquidationPerShare(
        uint256 id,
        uint256 value
    ) external creatorOnly(id) {
        tokenDividendData[id].liquidationPerShare = value;
    }

    /**
     * @dev Lock the liquidation sharing
     * Requirements:
     *
     * - only creator of the NFT can execute
     *
     * @param id ID of the NFT
     */
    function lockLiquidationPerShare(
        uint256 id
    ) external creatorOnly(id) {
        tokenDividendData[id].liquidationPerShare = 0;
    }

    /**
     * @dev Allow investors to claim liquidations of NFT of `id`
     * Requirements:
     *
     * - only creator of the NFT can execute
     *
     * @param id ID of the NFT
     * @param accounts Accounts to unlock liquidations
     */
    function allowLiquidationClaim(
        uint256 id,
        address[] calldata accounts
    ) external creatorOnly(id) {
        for (uint256 i = 0; i < accounts.length; ++i) {
            tokenYieldVesting[id][accounts[i]].isLiquidationUnlocked = true;
        }
    }

    /**
     * @dev Lock investors from claiming liquidations of NFT of `id`
     * Requirements:
     *
     * - only creator of the NFT can execute
     *
     * @param id ID of the NFT
     * @param accounts Accounts to hold liquidations
     */
    function holdLiquidationClaim(
        uint256 id,
        address[] calldata accounts
    ) external creatorOnly(id) {
        for (uint256 i = 0; i < accounts.length; ++i) {
            tokenYieldVesting[id][accounts[i]].isLiquidationUnlocked = false;
        }
    }

    function getYieldDividendPerShareAt(uint256 _id, uint256 index)
        external
        view
        returns (uint256)
    {
        return tokenDividendData[_id].dividendPerShares[index];
    }

    function getTotalYieldDividendPerShare(uint256 _id)
        external
        view
        returns (uint256)
    {
        uint256 sum = 0;
        TokenDividendData memory yieldData = tokenDividendData[_id];
        for (uint32 i = 0; i < yieldData.dividendsLength; ++i) {
            sum += yieldData.dividendPerShares[i];
        }
        return sum;
    }

    function claimDividends(uint256 _id) external onlyKYC nonReentrant {
        address account = _msgSender();

        _settleYields(account, _id);

        uint256 claimableYield = tokenYieldVesting[_id][account]
            .pendingDividends;
        require(claimableYield > 0, "REITNFT: no more claimable yield");

        require(
            dividendVaultBalance[_id] >= claimableYield,
            "REITNFT: need more fundings from issuer"
        );

        IERC20 payableToken = fundingToken[_id];
        require(
            payableToken.transfer(account, claimableYield),
            "REITNFT: Could not transfer fund"
        );

        unchecked {
            tokenYieldVesting[_id][account].pendingDividends = 0;
            tokenYieldVesting[_id][account].claimedDividends += claimableYield;

            dividendVaultBalance[_id] -= claimableYield;
        }
    }

    function getTotalClaimableLiquidations(uint256 _id)
        external
        view
        shareHoldersOnly(_id)
        returns (uint256)
    {
        address account = _msgSender();

        if (!tokenYieldVesting[_id][account].initialized) {
            return 0;
        }

        require(tokenYieldVesting[_id][account].isLiquidationUnlocked, "REITNFT: liquidation still on hold");

        uint256 balance = _balances[_id][account];
        uint256 shareLiquidationValue = balance * tokenDividendData[_id].liquidationPerShare;

        return shareLiquidationValue;
    }
    
    function claimLiquidations(uint256 id) external onlyKYC nonReentrant {
        address account = _msgSender();

        require(tokenYieldVesting[id][account].isLiquidationUnlocked, "REITNFT: liquidation still on hold");

        _settleYields(account, id);

        uint256 balance = _balances[id][account];
        uint256 shareLiquidationValue = balance * tokenDividendData[id].liquidationPerShare;

        require(shareLiquidationValue > 0, "REITNFT: no liquidation to claim");

        require(
            liquidationVaultBalance[id] >= shareLiquidationValue,
            "REITNFT: need more fundings from issuer"
        );

        IERC20 payableToken = fundingToken[id];
        require(
            payableToken.transfer(account, shareLiquidationValue),
            "REITNFT: Could not transfer fund"
        );
        
        unchecked {
            tokenYieldVesting[id][account].claimedLiquidations += shareLiquidationValue;

            _liquidatedBalances[id][account] = balance;
            _balances[id][account] = 0;

            liquidationVaultBalance[id] -= shareLiquidationValue;
        }
    }

    function getClaimedDividends(uint256 _id)
        external
        view
        shareHoldersOnly(_id)
        returns (uint256)
    {
        return tokenYieldVesting[_id][_msgSender()].claimedDividends;
    }

    function getClaimedLiquidations(uint256 id)
        external
        view
        shareHoldersOnly(id)
        returns (uint256)
    {
        return tokenYieldVesting[id][_msgSender()].claimedLiquidations;
    }

    function getTotalClaimableDividends(uint256 _id)
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
        uint32 dividendsLength = tokenDividendData[_id].dividendsLength;
        uint32 lastClaimIndex = tokenYieldVesting[_id][account].lastClaimIndex;
        for (uint32 i = lastClaimIndex; i < dividendsLength; ++i) {
            claimableYield +=
                tokenDividendData[_id].dividendPerShares[i] *
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
        uint32 dividendsLength = tokenDividendData[_id].dividendsLength;
        uint32 lastClaimIndex = tokenYieldVesting[_id][account].lastClaimIndex;
        for (uint32 i = lastClaimIndex; i < dividendsLength; ++i) {
            lockedYield +=
                tokenDividendData[_id].dividendPerShares[i] *
                lockedBalance;
        }

        return lockedYield + tokenYieldVesting[_id][account].lockingDividends;
    }

    function _settleYields(address account, uint256 _id) internal {
        if (isIPOContract(_id, account)) {
            return;
        }

        if (!tokenYieldVesting[_id][account].initialized) {
            tokenYieldVesting[_id][account] = YieldVesting(
                account,
                0,
                0,
                0,
                0,
                false,
                true,
                0
            );
        }

        // Calculate yields
        uint256 claimableYield = 0;
        uint256 lockedYield = 0;

        uint256 lockedBalance = _lockingBalances[_id][account];
        uint256 unlockedBalance = _balances[_id][account];
        uint32 dividendsLength = tokenDividendData[_id].dividendsLength;
        uint32 lastClaimIndex = tokenYieldVesting[_id][account].lastClaimIndex;

        unchecked {
            for (uint32 i = lastClaimIndex; i < dividendsLength; ++i) {
                uint256 dividend = tokenDividendData[_id].dividendPerShares[i];
                claimableYield += dividend * unlockedBalance;
                lockedYield += dividend * lockedBalance;
            }
        }

        tokenYieldVesting[_id][account].lastClaimIndex = dividendsLength;

        if (claimableYield > 0) {
            unchecked {
                tokenYieldVesting[_id][account]
                    .pendingDividends += claimableYield;
            }
        }

        if (lockedYield > 0) {
            unchecked {
                tokenYieldVesting[_id][account].lockingDividends += lockedYield;
            }
        }
    }

    /**
     * === TRANSFER ==
     */

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

        require(
            from != to,
            "ERC1155: From_Address must be different from To_Address"
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

        _settleYields(from, id);
        _settleYields(to, id);

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
            _settleYields(from, id);
            _settleYields(to, id);
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

    /**
     * @dev Redeem the locked balance of NFT of `id` from a transfer outside REIT platform
     * Requirements:
     *
     * - Only owners in KYC list can execute
     *
     * @param id ID of the REIT NFT
     */
    function redeemLockedBalances(uint256 id) external onlyKYC nonReentrant {
        address account = _msgSender();

        uint256 amount = _lockingBalances[id][account];
        require(amount > 0, "Already unlocked all");

        uint256 taxAmount = (tokenDividendData[id].unitMarketValue *
            amount *
            tokenMetadata[id].transferTax) / PERCENT_DECIMALS_MULTIPLY;

        IERC20 payableToken = fundingToken[id];
        require(
            payableToken.transferFrom(account, address(this), taxAmount),
            "REITNFT: Could not pay tax"
        );

        unchecked {
            _lockingBalances[id][account] = 0;
            _balances[id][account] += amount;

            tokenYieldVesting[id][account]
                .pendingDividends += tokenYieldVesting[id][account]
                .lockingDividends;
            tokenYieldVesting[id][account].lockingDividends = 0;
        }
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        override(ERC1155Upgradeable, IREITTradable)
        returns (uint256)
    {
        return ERC1155Upgradeable.balanceOf(account, id);
    }

    /**
     * @dev Returns the amount of locked tokens of token type `id` owned by `account`. Tokens are locked when transfering outside REIT trading platform.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function lockedBalanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _lockingBalances[id][account];
    }

    /**
     * === UTILITIES ===
     */

    /**
     * @dev Returns the IPO unit price of REIT NFT of `id`
     */
    function getIPOUnitPrice(uint256 id)
        external
        view
        returns (uint256)
    {
        return tokenMetadata[id].unitValue;
    }
}
