// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *    @title Capped ERC20 Token
 *    @notice A token whose max supply is fixed by the owner
 *    @dev Uses OpenZeppelin's ERC20, Ownable and Pausable for standard functionalities
 */

contract CappedToken is ERC20, Pausable, Ownable {
    uint256 private immutable _cap;

    // Total supply has been exceeded.
    error ERC20ExceededCap(uint256 increasedSupply, uint256 cap);

    // The supplied cap is not a valid cap.
    error ERC20InvalidCap(uint256 cap);

    // Custom error for unauthorized access
    error NotAuthorized();

    // Event emitted on successful minting
    event Minted(address indexed minter, address indexed to, uint256 amount);
    event Burned(address indexed burner, uint256 value);

    // Mapping to store authorized users
    mapping(address => bool) public authorizedUsers;

    /**
     * @dev Constructor to initialize the token with a name and symbol
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param cap_ The max supply
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 cap_
    ) ERC20(name, symbol) Ownable(msg.sender) {
        authorizedUsers[msg.sender] = true;

        if (cap_ <= 0) {
            revert ERC20InvalidCap(0);
        }
        _cap = cap_;
    }

    /**
     * @dev Authorize a new user to mint tokens
     * @param _address The address to authorize
     */
    function authorize(address _address) external onlyOwner {
        authorizedUsers[_address] = true;
    }

    /**
     * @dev Revoke authorization of a user to mint tokens
     * @param _address The address to revoke authorization
     */
    function revokeAuthorization(address _address) external onlyOwner {
        authorizedUsers[_address] = false;
    }

    /**
     * @dev Mint new tokens
     * @param to The address to receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external {
        if (authorizedUsers[msg.sender]) {
            _mint(to, amount);
            emit Minted(msg.sender, to, amount);
        } else {
            revert NotAuthorized();
        }
    }

    /**
     * @dev Burn holding tokens
     * @param account which wants to burn tokens
     * @param amount The amount of tokens to burn
     */

    function burn(address account, uint256 amount) external {
        if (authorizedUsers[msg.sender]) {
            _burn(account, amount);
            emit Burned(msg.sender, amount);
        } else {
            revert NotAuthorized();
        }
    }

    /**
     * @dev Pause token transfers
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev Unpause token transfers
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Stopping token transfers
     * @notice Override the _update function for pause and cap mechanism
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._update(from, to, amount);

        if (from == address(0)) {
            uint256 maxSupply = cap();
            uint256 supply = totalSupply();
            if (supply > maxSupply) {
                revert ERC20ExceededCap(supply, maxSupply);
            }
        }
    }
}
