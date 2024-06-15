// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *    @title Mintable ERC20 Token
 *    @notice A token that can be minted by the owner or authorized users
 *    @dev Uses OpenZeppelin's ERC20 and Ownable for standard functionalities
 */
contract MintableToken is ERC20, Ownable {
    // Custom error for unauthorized access
    error NotAuthorized();

    // Event emitted on successful minting
    event Minted(address indexed minter, address indexed to, uint256 amount);

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
}
