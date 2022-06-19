// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
        for (uint256 i = 0; i < accounts.length; i++) {
            kycAccounts[accounts[i]] = true;
        }
    }

    /**
     * @dev remove many accounts' access from KYC
     * @param accounts Accounts to remove access
     */
    function removeManyKYC(address[] calldata accounts) external onlyKYCAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            kycAccounts[accounts[i]] = false;
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting dgovern storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
