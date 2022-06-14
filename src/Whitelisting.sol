// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Whitelisting is OwnableUpgradeable {
    // white-list mapping
    mapping(address => bool) private whitelisteds;
    bool private _whitelistPaused;    

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelisteds[msg.sender] || _whitelistPaused, "Not whitelisted");
        _;
    }

    function pauseWhiteList () external onlyOwner {
        require(!_whitelistPaused, "Whitelisting already resumed");
        _whitelistPaused = true;
    }

    function resumeWhiteList () external onlyOwner {
        require(_whitelistPaused, "Whitelisting already paused");
        _whitelistPaused = false;
    }

    /**
     * @dev give an account access to whitelisted
     * @param account Account to grant access
     */
    function addToWhitelisted(address account) external onlyOwner {
        whitelisteds[account] = true;
    }

    /**
     * @dev remove an account's access from whitelisted
     * @param account Account to remove
     */
    function removeWhitelisted(address account) external onlyOwner {
        whitelisteds[account] = false;
    }

    /**
     * @dev give many accounts access to whitelisted
     * @param accounts Accounts to grant access
     */
    function addManyToWhitelisted(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelisteds[accounts[i]] = true;
        }
    }

    /**
     * @dev remove many accounts' access from whitelisted
     * @param accounts Accounts to remove access
     */
    function removeManyWhitelisted(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelisteds[accounts[i]] = false;
        }
    }

    /**
     * @dev check if an account is whitelisted
     * @return bool
     */
    function isWhitelisted(address account) public view returns (bool) {
        require(account != address(0));
        return whitelisteds[account];
    }
}
