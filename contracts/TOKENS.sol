// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract ObsidianToken is ERC20 {

    address immutable public owner;
    constructor (uint _supply) ERC20("OBS", "Obsidian Token"){
        owner = msg.sender;
        _mint(owner, _supply);
    }

    function mint(uint _amount) external {
        require(msg.sender == owner, "Only owner");
        _mint(owner, _amount);
    }
}

contract LavaToken is ERC20 {

    address immutable public owner;
    constructor (uint _supply) ERC20("LAVA", "Lava Token"){
        owner = msg.sender;
        _mint(owner, _supply);
    }

    function mint(uint _amount) external {
        require(msg.sender == owner, "Only owner");
        _mint(owner, _amount);
    }
}