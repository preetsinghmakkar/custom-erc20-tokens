// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *    @title Pausable ERC20 Token
 *    @notice A token that can be paused by the owner in an emergency period
 *    @dev Uses OpenZeppelin's ERC20, Ownable and Pausable for standard functionalities
 */

contract PausableToken is ERC20, Pausable, Ownable {
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
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {
        // The owner is automatically authorized
        authorizedUsers[msg.sender] = true;
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
     * @dev Unpause token transfers
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Stopping token transfers
     * @notice Override the _update function for pause mechanism
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._update(from, to, amount);
    }
}
