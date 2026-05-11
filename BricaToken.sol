// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title BRICA Token (BRX)
 * @notice Fixed-supply ERC20 with controlled launch, burn, and permit support
 * @dev Audit-optimized, no mint, no blacklist, no upgradeability
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BRICA is ERC20, ERC20Permit, Ownable {

    /*//////////////////////////////////////////////////////////////
                                SUPPLY
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    /*//////////////////////////////////////////////////////////////
                        TRADING CONTROL
    //////////////////////////////////////////////////////////////*/

    bool public tradingEnabled;

    mapping(address => bool) public isExcludedFromTrading;

    event TradingEnabled();
    event ExclusionUpdated(address indexed account, bool status);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address initialHolder)
        ERC20("BRICA", "BRX")
        ERC20Permit("BRICA")
        Ownable(msg.sender)
    {
        require(initialHolder != address(0), "BRX: zero holder");

        _mint(initialHolder, MAX_SUPPLY);

        // Allow setup before launch
        isExcludedFromTrading[initialHolder] = true;
        isExcludedFromTrading[address(this)] = true;
    }

    /*//////////////////////////////////////////////////////////////
                        TRANSFER OVERRIDE
    //////////////////////////////////////////////////////////////*/

    function _update(address from, address to, uint256 amount) internal override {

        // Allow minting and burning
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        // Trading gate (before launch)
        if (!tradingEnabled) {
            require(
                isExcludedFromTrading[from] || isExcludedFromTrading[to],
                "BRX: trading not enabled"
            );
        }

        super._update(from, to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "BRX: already enabled");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function setExcluded(address account, bool status) external onlyOwner {
        isExcludedFromTrading[account] = status;
        emit ExclusionUpdated(account, status);
    }

    /*//////////////////////////////////////////////////////////////
                                BURN
    //////////////////////////////////////////////////////////////*/

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}