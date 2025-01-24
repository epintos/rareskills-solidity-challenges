// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SkillsCoin
 * @author Esteban Pintos
 * @notice Basic ERC20 token that can be minted and burned by anyone
 */
contract SkillsCoin is ERC20 {
    error SkillsCoin__CannotMintToZeroAddress();

    constructor() ERC20("SkillsCoin", "SKC") { }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
