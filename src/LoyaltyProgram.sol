// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IREITTradable.sol";
import "./GovernableUpgradeable.sol";

contract LoyaltyProgram is
    Initializable,
    ContextUpgradeable,
    ReentrancyGuardUpgradeable
{
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
