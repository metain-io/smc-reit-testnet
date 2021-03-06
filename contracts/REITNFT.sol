// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// 
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// 
contract KYCAccessUpgradeable is Initializable, ContextUpgradeable {
    // kyc list mapping
    mapping(address => bool) internal kycAccounts;

    address private _kycAdmin;

    function __KYCAccess_init() internal onlyInitializing {
        __KYCAccess_init_unchained();
    }

    function __KYCAccess_init_unchained() internal onlyInitializing {
        _setKYCAdmin(_msgSender());
    }

    modifier onlyKYCAdmin() {
        require(_kycAdmin == msg.sender, "KYCAccess: caller is not the admin");
        _;
    }

    /**
     * @dev Throws if called by any account that's not KYC.
     */
    modifier onlyKYC() {
        require(kycAccounts[msg.sender], "Not yet KYC");
        _;
    }

    function _setKYCAdmin(address account) internal {
        _kycAdmin = account;
    }

    /**
     * @dev give an account access to KYC
     * @param account Account to grant access
     */
    function addToKYC(address account) external onlyKYCAdmin {
        kycAccounts[account] = true;
    }

    /**
     * @dev remove an account's access from KYC
     * @param account Account to remove
     */
    function removeKYC(address account) external onlyKYCAdmin {
        kycAccounts[account] = false;
    }

    /**
     * @dev give many accounts access to KYC
     * @param accounts Accounts to grant access
     */
    function addManyToKYC(address[] calldata accounts) external onlyKYCAdmin {
        for (uint i = 0; i < accounts.length; i++) {
            kycAccounts[accounts[i]] = true;
        }
    }

    /**
     * @dev remove many accounts' access from KYC
     * @param accounts Accounts to remove access
     */
    function removeManyKYC(address[] calldata accounts) external onlyKYCAdmin {
        for (uint i = 0; i < accounts.length; i++) {
            kycAccounts[accounts[i]] = false;
        }
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)
/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)
/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)
/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)
/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
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
    ) public virtual override {
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// 
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernor`, which can be applied to your functions to restrict their use to
 * the governor.
 */
abstract contract GovernableUpgradeable is Initializable, ContextUpgradeable {
    address private _governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    function __Governable_init() internal onlyInitializing {
        __Governable_init_unchained();
    }

    function __Governable_init_unchained() internal onlyInitializing {
        _transferGovernorship(_msgSender());
    }

    /**
     * @dev Returns the address of the current governor.
     */
    function governor() public view virtual returns (address) {
        return _governor;
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(governor() == _msgSender(), "Governable: caller is not the governor");
        _;
    }

    /**
     * @dev Leaves the contract without governor. It will not be possible to call
     * `onlyGovernor` functions anymore. Can only be called by the current governor.
     *
     * NOTE: Renouncing governorship will leave the contract without an governor,
     * thereby removing any functionality that is only available to the governor.
     */
    function renounceGovernorship() public virtual onlyGovernor {
        _transferGovernorship(address(0));
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`newGovernor`).
     * Can only be called by the current governor.
     */
    function transferGovernorship(address newGovernor) public virtual onlyGovernor {
        require(newGovernor != address(0), "Governable: new governor is the zero address");
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`newGovernor`).
     * Internal function without access restriction.
     */
    function _transferGovernorship(address newGovernor) internal virtual {
        address oldGovernor = _governor;
        _governor = newGovernor;
        emit GovernorshipTransferred(oldGovernor, newGovernor);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)
/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// 
/**
 * @title IREITTradable
 */
interface IREITTradable {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function isKYC(address account) external view returns (bool);

    function getLoyaltyLevel(address account) external view returns(uint);

    function getIPOUnitPrice(uint256 _id) external view returns (uint256);

    function isIPOContract(uint256 _id, address account)
        external
        view
        returns (bool);
}

// 
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
            "ONLY_CREATOR_ALLOWED"
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
            "INVALID_ARRAYS_LENGTH"
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            require(
                creators[_id] == msg.sender,
                "ONLY_CREATOR_ALLOWED"
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
            "INVALID_ADDRESS"
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            require(creators[id] == _msgSender(), "ONLY_CREATOR_ALLOWED");
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

// 
contract LoyaltyProgram is
    Initializable,
    ContextUpgradeable,
    ReentrancyGuardUpgradeable{
    using SafeMath for uint256;
    
    /**
     * @dev Staking information of each investor
     */
    struct Staking {
        uint256 amount;
        uint256 startTime;
        uint level;
        bool initialized;
    }

    uint256[] public loyaltyConditions;

    // address of the stakeable token
    IERC20 internal _stakeableToken;
    uint256 internal _minimumStakingPeriod;

    mapping(address => Staking) internal _stakings;
    
    address private _loyaltyAdmin;

    function __LoyaltyProgram_init() internal onlyInitializing {
        __LoyaltyProgram_init_unchained();
    }

    function __LoyaltyProgram_init_unchained() internal onlyInitializing {
        _setLoyaltyProgramAdmin(_msgSender());
    }

    modifier onlyLoyaltyAdmin() {
        require(_loyaltyAdmin == msg.sender, "LoyaltyProgram: caller is not the admin");
        _;
    }

    function _setLoyaltyProgramAdmin(address account) internal {
        _loyaltyAdmin = account;
    }

    function setupLoyaltyProgram(address _token, uint256 period) external onlyLoyaltyAdmin {
        _stakeableToken = IERC20(_token);
        _minimumStakingPeriod = period;        
    }

    function setLoyaltyConditions(uint256[] calldata conditions) external onlyLoyaltyAdmin {
        loyaltyConditions = conditions;
    }

    /**
     * @dev Returns the address of the IREC20 contract
     */
    function getStakeableTokenContract() external view returns (address) {
        return address(_stakeableToken);
    }

    /**
     * @notice Stake token
     * @param amount Amount of token to stake
     */
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake nothing");

        address account = _msgSender();

        require(_stakeableToken.transferFrom(account, address(this), amount), "Could not transfer token");

        if (!_stakings[account].initialized) {
            _stakings[account] = Staking(amount, block.timestamp, 0, true);
        } else {
            unchecked {
                _stakings[account].amount += amount;   
                _stakings[account].startTime = block.timestamp;
            }
        }

        _settleLoyaltyLevel(account);
    }

    function unstake() external nonReentrant {
        address account = _msgSender();
        uint256 elapsed = block.timestamp.sub(_stakings[account].startTime);
        require(elapsed > _minimumStakingPeriod, "Cannot withdraw early");

        require(_stakeableToken.transferFrom(address(this), account, _stakings[account].amount), "Could not transfer token");
        _stakings[account].amount = 0;
        _stakings[account].level = 0;
    }    

    function _settleLoyaltyLevel(address account) internal {
        uint256 amount = _stakings[account].amount;

        for (uint i = loyaltyConditions.length - 1; i >= 0; --i) {
            if (amount >= loyaltyConditions[i]) {
                _stakings[account].level = i;
                break;
            }
        }
    }
}

// 
/**
 * @title REITNFT
 */
contract REITNFT is
    IREITTradable,
    ERC1155Tradable,
    KYCAccessUpgradeable,
    LoyaltyProgram{
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    /**
     * @dev Emitted when REIT NFT of type `id` is created by `creator` wallet.
     */
    event Create(uint256 id, address creator, uint256 supply, string uri);

    /**
     * @dev Metadata of a REIT NFT
     */
    struct TokenMetadata {
        // Value of each unit at IPO (in USD)
        uint256 unitValue;
        // Tax rate for transfering to others
        uint256[] transferTaxes;
        // Time this project starts
        uint64 initiateTime;
        // Time this project is liquidated
        uint64 liquidationTime;
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

    // Staking token contract, which is MEI token
    IERC20 private stakingToken;

    // Tokens required for each loyalty level
    uint256[] private loyaltyRequirements;

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
        __LoyaltyProgram_init();
    }

    /**
     * @dev Require `msg.sender` to own more than 0 of the token id
     */
    modifier shareHoldersOnly(uint256 _id) {
        uint256 totalBalances = _balances[_id][_msgSender()] +
            _lockingBalances[_id][_msgSender()] +
            _liquidatedBalances[_id][_msgSender()];
        require(totalBalances > 0, "ONLY_OWNERS_ALLOWED");
        _;
    }

    /**
     * @dev Check if an `account` is in the KYC list
     * @return bool
     */
    function isKYC(address account) public view returns (bool) {
        require(account != address(0), "ZERO_ADDRESS");
        return kycAccounts[account];
    }

    /**
     * === GETTERS ===
     */

    function getFundingToken(uint256 id) public view returns (address) {
        return address(fundingToken[id]);
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
        require(account != address(0), "ZERO_ADDRESS");
        _setKYCAdmin(account);
    }

    /**
     * @dev Appoint an account as admin that administer loyalty program
     * Requirements:
     *
     * - only governor can execute
     */
    function setLoyaltyProgramAdmin(address account) external onlyGovernor {
        require(
            account != address(0),
            "ZERO_ADDRESS"
        );
        _setLoyaltyProgramAdmin(account);
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
        require(account.isContract(), "NOT_A_CONTRACT");
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
        tokenMetadata[_id] = TokenMetadata(0, new uint256[](5), 0, 0);
        tokenDividendData[_id] = TokenDividendData(
            0,
            0,
            new uint256[](MAX_DIVIDENDS_SEQUENCE_COUNT),
            0,
            0
        );

        _mint(_initialOwner, _id, _initialSupply, _data);

        tokenSupply[_id] = _initialSupply;

        emit Create(_id, _initialOwner, _initialSupply, _uri);
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
     * @param transferTaxes Transfer tax rates
     */
    function initiateREIT(
        uint256 _id,
        uint64 initiateTime,
        uint256 unitValue,
        uint64 liquidationTime,
        uint256[] calldata transferTaxes
    ) external creatorOnly(_id) {
        tokenMetadata[_id] = TokenMetadata(
            unitValue,
            transferTaxes,
            initiateTime,
            liquidationTime
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
     * @param id ID of the NFT
     * @param amount Amount of tokens to pay
     */
    function fundDividendVault(uint256 id, uint256 amount) external {
        require(
            tokenDividendData[id].liquidationPerShare == 0,
            "NOT_LIQUIDATED"
        );

        IERC20 payableToken = fundingToken[id];

        require(
            payableToken.transferFrom(_msgSender(), address(this), amount),
            "TRANSFER_ERROR"
        );

        dividendVaultBalance[id] = dividendVaultBalance[id].add(amount);
    }

    /**
     * @dev Withdraw payable tokens from dividend vault
     * Requirements:
     *
     * - Only governor can execute
     *
     * @param id ID of the NFT
     * @param amount Amount of tokens to pay
     * @param to Address to transfer to
     */
    function withdrawDividendVault(
        uint256 id,
        uint256 amount,
        address to
    ) external onlyGovernor {
        require(
            dividendVaultBalance[id] >= amount,
            "NOT_ENOUGH"
        );

        IERC20 payableToken = fundingToken[id];

        require(
            payableToken.transfer(to, amount),
            "TRANSFER_ERROR"
        );

        dividendVaultBalance[id] = dividendVaultBalance[id].sub(amount);
    }

    /**
     * @dev Transfer payable tokens to a REIT NFT funding vault to pay for liquidations
     * @param id ID of the NFT
     * @param amount Amount of tokens to pay
     */
    function fundLiquidationVault(uint256 id, uint256 amount) external {
        IERC20 payableToken = fundingToken[id];

        require(
            payableToken.transferFrom(_msgSender(), address(this), amount),
            "TRANSFER_ERROR"
        );

        liquidationVaultBalance[id] = liquidationVaultBalance[id].add(amount);
    }

    /**
     * @dev Withdraw payable tokens from liquidation vault
     * Requirements:
     *
     * - Only governor can execute
     *
     * @param id ID of the NFT
     * @param amount Amount of tokens to pay
     * @param to Address to transfer to
     */
    function withdrawLiquidationVault(
        uint256 id,
        uint256 amount,
        address to
    ) external onlyGovernor {
        require(
            liquidationVaultBalance[id] >= amount,
            "NOT_ENOUGH"
        );

        IERC20 payableToken = fundingToken[id];

        require(
            payableToken.transfer(to, amount),
            "TRANSFER_ERROR"
        );

        liquidationVaultBalance[id] = liquidationVaultBalance[id].sub(amount);
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
        require(
            tokenDividendData[id].liquidationPerShare == 0,
            "NOT_LIQUIDATED"
        );

        if (tokenDividendData[id].dividendsLength < time + 1) {
            tokenDividendData[id].dividendsLength = time + 1;
        }
        tokenDividendData[id].dividendPerShares[time] = value;
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
    function unlockLiquidationPerShare(uint256 id, uint256 value)
        external
        creatorOnly(id)
    {
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
    function lockLiquidationPerShare(uint256 id) external creatorOnly(id) {
        tokenDividendData[id].liquidationPerShare = 0;
    }

    /**
     * @dev Allow several investors to claim liquidations of NFT of `id`
     * Requirements:
     *
     * - only creator of the NFT can execute
     *
     * @param id ID of the NFT
     * @param accounts Accounts to unlock liquidations
     */
    function allowLiquidationClaims(uint256 id, address[] calldata accounts)
        external
        creatorOnly(id)
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            tokenYieldVesting[id][accounts[i]].isLiquidationUnlocked = true;
        }
    }

    /**
     * @dev Lock several investors from claiming liquidations of NFT of `id`
     * Requirements:
     *
     * - only creator of the NFT can execute
     *
     * @param id ID of the NFT
     * @param accounts Accounts to hold liquidations
     */
    function holdLiquidationClaims(uint256 id, address[] calldata accounts)
        external
        creatorOnly(id)
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            tokenYieldVesting[id][accounts[i]].isLiquidationUnlocked = false;
        }
    }

    /**
     * @dev Withdraw `amount` of staked tokens
     * note In emergency situation, governor can withdraw staked tokens to fix things.
     * Requirements:
     *
     * - only governor can execute
     */
    function withdrawLoyaltyStakings(uint256 amount) external onlyGovernor {
        require(amount > 0, "ZERO_AMOUNT");

        uint256 balance = _stakeableToken.balanceOf(address(this));
        require(balance > amount, "NOT_ENOUGH");

        _stakeableToken.transfer(governor(), amount);
    }

    /**
     * === CLAIMING DIVIDENDS AND LIQUIDATIONS ===
     */

    /**
     * @dev Get dividend per share of NFT of `id` at time index `index`
     *
     * @param id ID of the NFT
     * @param index Time index
     * @return uint256 Amount of shared dividend
     */
    function getDividendPerShare(uint256 id, uint256 index)
        external
        view
        returns (uint256)
    {
        return tokenDividendData[id].dividendPerShares[index];
    }

    /**
     * @dev Get total amount of dividend per share of NFT of `id`
     *
     * @param id ID of the NFT
     * @return uint256 Total amount of all shared dividends
     */
    function getTotalDividendPerShare(uint256 id)
        external
        view
        returns (uint256)
    {
        uint256 sum = 0;
        TokenDividendData memory yieldData = tokenDividendData[id];
        for (uint32 i = 0; i < yieldData.dividendsLength; ++i) {
            sum += yieldData.dividendPerShares[i];
        }
        return sum;
    }

    /**
     * @dev Get total liquidation value of sender
     * Requirements:
     *
     * - Only owners of NFT can execute
     *
     * @param id ID of the NFT
     * @return uint256 total liquidation value
     */
    function getClaimableLiquidations(uint256 id)
        external
        view
        shareHoldersOnly(id)
        returns (uint256)
    {
        address account = _msgSender();

        if (tokenYieldVesting[id][account].isLiquidationUnlocked == false) {
            return 0;
        }

        uint256 balance = _balances[id][account];
        uint256 shareLiquidationValue = balance *
            tokenDividendData[id].liquidationPerShare;

        return shareLiquidationValue;
    }

    /**
     * @dev Pay dividends to sender based on total NFT they are owning.
     * Requirements:
     *
     * - Only owners in KYC list can execute
     *
     * @param id ID of the NFT
     */
    function claimDividends(uint256 id) external onlyKYC nonReentrant {
        address account = _msgSender();

        // Settle all sharings before continue
        _settleYields(account, id);

        // Amount to claim
        uint256 claimableYield = tokenYieldVesting[id][account]
            .pendingDividends;
        require(claimableYield > 0, "REITNFT: no more claimable yield");

        // Transfer payable tokens (stable-coin) to sender as shared yield dividends
        require(
            dividendVaultBalance[id] >= claimableYield,
            "REITNFT: need more fundings from issuer"
        );

        IERC20 payableToken = fundingToken[id];
        require(
            payableToken.transfer(account, claimableYield),
            "REITNFT: Could not transfer fund"
        );

        // Payment done
        unchecked {
            tokenYieldVesting[id][account].pendingDividends = 0;
            tokenYieldVesting[id][account].claimedDividends += claimableYield;

            dividendVaultBalance[id] -= claimableYield;
        }
    }

    /**
     * @dev Pay liquidations to sender based on total NFT they are owning.
     * Requirements:
     *
     * - Only owners in KYC list can execute
     * - Owners must be allowed to claim liquidation
     *
     * @param id ID of the NFT
     */
    function claimLiquidations(uint256 id) external onlyKYC nonReentrant {
        address account = _msgSender();

        // Owners must be allowed to claim liquidation
        require(
            tokenYieldVesting[id][account].isLiquidationUnlocked,
            "REITNFT: liquidation still on hold"
        );

        uint256 balance = _balances[id][account];
        uint256 shareLiquidationValue = balance *
            tokenDividendData[id].liquidationPerShare;

        require(shareLiquidationValue > 0, "REITNFT: no liquidation to claim");

        require(
            liquidationVaultBalance[id] >= shareLiquidationValue,
            "REITNFT: need more fundings from issuer"
        );

        // Settle all yield dividends because all shares will be burned
        _settleYields(account, id);

        IERC20 payableToken = fundingToken[id];
        require(
            payableToken.transfer(account, shareLiquidationValue),
            "REITNFT: Could not transfer fund"
        );

        // Done
        unchecked {
            // Burn all shares belong to the sender
            _liquidatedBalances[id][account] = balance;
            _balances[id][account] = 0;

            liquidationVaultBalance[id] -= shareLiquidationValue;
            tokenYieldVesting[id][account]
                .claimedLiquidations += shareLiquidationValue;
        }
    }

    /**
     * @dev Get total amount of dividend that was claimed by sender
     */
    function getClaimedDividends(uint256 id)
        external
        view
        shareHoldersOnly(id)
        returns (uint256)
    {
        return tokenYieldVesting[id][_msgSender()].claimedDividends;
    }

    /**
     * @dev Get total amount of liquidation that was claimed by sender
     */
    function getClaimedLiquidations(uint256 id)
        external
        view
        shareHoldersOnly(id)
        returns (uint256)
    {
        return tokenYieldVesting[id][_msgSender()].claimedLiquidations;
    }

    /**
     * @dev Get total amount of dividends that can be claimed
     */
    function getTotalClaimableDividends(uint256 _id)
        external
        view
        shareHoldersOnly(_id)
        returns (uint256)
    {
        address account = _msgSender();

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

    /**
     * @dev Get total amount of dividends currently locked (until unlocked by redeeming)
     */
    function getLockedDividends(uint256 id)
        external
        view
        shareHoldersOnly(id)
        returns (uint256)
    {
        address account = _msgSender();

        uint256 lockedBalance = _lockingBalances[id][account];
        uint256 lockedYield = 0;
        uint32 dividendsLength = tokenDividendData[id].dividendsLength;
        uint32 lastClaimIndex = tokenYieldVesting[id][account].lastClaimIndex;
        for (uint32 i = lastClaimIndex; i < dividendsLength; ++i) {
            lockedYield +=
                tokenDividendData[id].dividendPerShares[i] *
                lockedBalance;
        }

        return lockedYield + tokenYieldVesting[id][account].lockingDividends;
    }

    /**
     * @dev Settle yield dividends of `account` that owns token of type `id`. Settled amount is set to pending so account can claim as payable tokens later.
     */
    function _settleYields(address account, uint256 id) internal {
        // IPO contract does not need settling
        if (isIPOContract(id, account)) {
            return;
        }

        // initialize vesting data
        if (!tokenYieldVesting[id][account].initialized) {
            tokenYieldVesting[id][account] = YieldVesting(
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
        uint32 lastClaimIndex = tokenYieldVesting[id][account].lastClaimIndex;
        uint32 dividendsLength = tokenDividendData[id].dividendsLength;
        if (lastClaimIndex < dividendsLength) {
            uint256 claimableYield = 0;
            uint256 lockedYield = 0;

            uint256 unlockedBalance = _balances[id][account];
            uint256 lockedBalance = _lockingBalances[id][account];

            unchecked {
                // combine all dividends from time indices that were not yet claimed by this account
                for (uint32 i = lastClaimIndex; i < dividendsLength; ++i) {
                    uint256 dividend = tokenDividendData[id].dividendPerShares[
                        i
                    ];
                    claimableYield += dividend * unlockedBalance;
                    lockedYield += dividend * lockedBalance;
                }
            }

            // as yields are settled, mark this account has claimed all currently
            tokenYieldVesting[id][account].lastClaimIndex = dividendsLength;

            if (claimableYield > 0) {
                unchecked {
                    tokenYieldVesting[id][account]
                        .pendingDividends += claimableYield;
                }
            }

            if (lockedYield > 0) {
                unchecked {
                    tokenYieldVesting[id][account]
                        .lockingDividends += lockedYield;
                }
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

            // this is the IPO purchase, pay all the yields until settlement
            if (isIPOContract(id, from)) {
                uint32 lastClaimIndex = tokenYieldVesting[id][to]
                    .lastClaimIndex;
                if (lastClaimIndex > 0) {
                    uint256 unclaimedYield = 0;
                    for (uint256 i = 0; i < lastClaimIndex; ++i) {
                        unclaimedYield +=
                            tokenDividendData[id].dividendPerShares[i] *
                            amount;
                    }

                    tokenYieldVesting[id][to]
                        .pendingDividends += unclaimedYield;
                }
            }
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
        require(amount > 0, "ALREADY_UNLOCKED_ALL");

        uint256 tax = _getTransferTaxRate(account, id);
        uint256 taxAmount;
        unchecked {
            taxAmount = (tokenDividendData[id].unitMarketValue * amount * tax) / PERCENT_DECIMALS_MULTIPLY;
        }

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
     * @dev Returns the amount of liquidated tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function liquidatedBalanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _liquidatedBalances[id][account];
    }

    /**
     * === UTILITIES ===
     */

    /**
     * @dev Returns the IPO unit price of REIT NFT of `id`
     */
    function getIPOUnitPrice(uint256 id) external view returns (uint256) {
        return tokenMetadata[id].unitValue;
    }

    function getIPOTime(uint256 id) external view returns (uint256) {
        return tokenMetadata[id].initiateTime;
    }

    function getLiquidationTime(uint256 id) external view returns (uint256) {
        return
            tokenMetadata[id].liquidationTime +
            tokenDividendData[id].liquidationTimeExtension;
    }

    function getTransferTaxRate(uint256 id) external view returns (uint256) {
        return _getTransferTaxRate(_msgSender(), id);
    }

    function _getTransferTaxRate(address account, uint256 id)
        internal
        view
        returns (uint256)
    {
        uint256 loyalty = _stakings[account].level;
        uint256 tax = tokenMetadata[id].transferTaxes[loyalty];
        if (tax == 0) {
            tax = tokenMetadata[id].transferTaxes[0];
        }
        return tax;
    }

    function getUnitMarketPrice(uint256 id) external view returns (uint256) {
        return tokenDividendData[id].unitMarketValue;
    }

    function getLoyaltyLevel(address account) override public view returns(uint) {
        return _stakings[account].level;
    }
}