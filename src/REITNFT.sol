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
    mapping(uint256 => address) private ipoContracts;

    mapping(uint256 => mapping(address => uint256)) private _registeredBalances;

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
        _setCreator(_msgSender(), _id);

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
            tokenUri[_id] = _uri;
        }

        fundingToken[_id] = IERC20Extented(_fundingToken);
        tokenMetadata[_id] = REITMetadata(0, 0, 0, 0);
        tokenYieldData[_id] = REITYield(0, 0);

        mint(_initialOwner, _id, _initialSupply, _data);
        _registeredBalances[_id][_initialOwner] = _initialSupply;

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

    function registeredBalanceOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _registeredBalances[id][account];
    }

    function registerBalanceOwnership(uint256 _id)
        external
        onlyKYC
        shareHoldersOnly(_id)
    {
        REITMetadata memory metadata = tokenMetadata[_id];

        uint256 balance = balanceOf(_msgSender(), _id);
        uint256 quantity = balance.sub(_registeredBalances[_id][_msgSender()]);

        require(quantity > 0, "REITNFT: Nothing to register");

        IERC20Extented payableToken = fundingToken[_id];
        uint256 fee = quantity
            .mul(metadata.ipoUnitPrice)
            .mul(metadata.registerationFee)
            .div(10**payableToken.decimals());

        require(
            payableToken.transferFrom(_msgSender(), address(this), fee),
            "REITNFT: Could not transfer fund"
        );

        _registeredBalances[_id][_msgSender()] = balance;
    }

    function claimBenefit(uint256 _id)
        external
        onlyKYC
        shareHoldersOnly(_id)
        nonReentrant
    {
        REITYield memory yieldData = tokenYieldData[_id];

        if (!tokenYieldVesting[_id][_msgSender()].initialized) {
            tokenYieldVesting[_id][_msgSender()].initialized = true;
            tokenYieldVesting[_id][_msgSender()].beneficiary = _msgSender();
            tokenYieldVesting[_id][_msgSender()].released = 0;
        }

        YieldVesting memory yieldVesting = tokenYieldVesting[_id][_msgSender()];

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
        tokenYieldVesting[_id][_msgSender()].released = yieldVesting.released.add(
            claimableYield
        );

        IERC20Extented payableToken = fundingToken[_id];
        require(
            payableToken.transfer(_msgSender(), claimableYield),
            "REITNFT: Could not transfer fund"
        );
    }

    function payDividends(uint256 _id, uint256 amount) external {
        IERC20Extented payableToken = fundingToken[_id];

        require(
            payableToken.transferFrom(_msgSender(), address(this), amount),
            "REITNFT: Could not transfer fund"
        );

        dividendFunds[_id] = dividendFunds[_id].add(amount);
    }

    function unlockDividends(uint256 _id, uint256 dividend)
        external
        creatorOnly(_id)
    {
        uint256 nextDividend = tokenYieldData[_id].yieldDividend.add(dividend);
        uint256 totalSupply = tokenSupply[_id];
        uint256 totalSupplyValue = totalSupply.mul(nextDividend);
        uint256 totalFunding = dividendFunds[_id];
        require(
            totalSupplyValue <= totalFunding,
            "Not enough funding to pay all dividends"
        );
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

        uint256 fromRegisteredBalance = _registeredBalances[id][from];
        require(fromRegisteredBalance >= amount, "Insufficient registered balance for transfer");

        _safeTransferFrom(from, to, id, amount, data);

        unchecked {
            _registeredBalances[id][from] = fromRegisteredBalance - amount;
        }

        if (isIPOContract(id, to) || (isKYC(to) && isIPOContract(id, from))) {
            _registeredBalances[id][to] = _registeredBalances[id][to].add(
                amount
            );
        }
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

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _registeredBalances[id][from];
            require(fromBalance >= amount, "Insufficient registered balance for transfer");            
        }

        _safeBatchTransferFrom(from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            
            uint256 fromBalance = _registeredBalances[id][from];
            unchecked {
                _registeredBalances[id][from] = fromBalance - amount;
            }
        }

        if (isKYC(to)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];

                if (isIPOContract(id, from)) {
                    uint256 amount = amounts[i];
                    _registeredBalances[id][to] = _registeredBalances[id][to]
                        .add(amount);
                }
            }
        } else {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];

                if (isIPOContract(id, to)) {
                    uint256 amount = amounts[i];
                    _registeredBalances[id][to] = _registeredBalances[id][to]
                        .add(amount);
                }
            }
        }
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

    function getIPOUnitPrice(uint256 _id)
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
