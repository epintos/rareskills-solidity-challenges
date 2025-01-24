// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title RareCoin
 * @author Esteban Pintos
 * @notice Basic ERC20 token that can be minted only if SkillsCoin is transferred to it
 */
contract RareCoin is ERC20 {
    error RareCoin__TransferFailed();

    address private immutable s_skillsCoinAddress;

    constructor(address skillsCoinAddress) ERC20("RareCoin", "RC") {
        s_skillsCoinAddress = skillsCoinAddress;
    }

    /**
     * @notice Transfers SkillsCoin to this contract and mints RareCoin to the sender
     * @param amount The amount of RareCoin to mint
     */
    function trade(uint256 amount) public {
        (bool success,) = s_skillsCoinAddress.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount)
        );
        if (!success) {
            revert RareCoin__TransferFailed();
        }
        _mint(msg.sender, amount);
    }
}
