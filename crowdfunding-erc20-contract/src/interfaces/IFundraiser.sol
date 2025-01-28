// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

interface IFundraiser {
    /**
     * @notice Creates a new fundraiser
     * @param goal Funraiser goal
     * @param deadline Fundraiser deadline
     * @return fundraiserId Fundraiser id
     */
    function createFundraiser(uint256 goal, uint256 deadline) external returns (uint256 fundraiserId);

    // /**
    //  * @notice Creator of the fundraiser can withdraw funds if goal is met and deadline is passed.
    //  * @notice If the goal is not met, everyone can withdraw their funds.
    //  * @notice If the goal is met, only the creator can withdraw the funds.
    //  * @notice Donator will withdraw all tokens funds
    //  * @param fundraiserId Fundraiser id
    //  */
    // function withdraw(uint256 fundraiserId) external;

    // /**
    //  * @notice Deposit ETH to a fundraiser
    //  * @param fundraiserId Fundraiser id
    //  */
    // function deposit(uint256 fundraiserId) external payable;

    // /**
    //  * @notice Deposit ERC20 tokens to a fundraiser
    //  * @param erc20TokenAddress ERC20 token address
    //  * @param fundraiserId Fundraiser id
    //  * @param amount Amount to deposit
    //  */
    // function deposit(address erc20TokenAddress, uint256 fundraiserId, uint256 amount) external;
}
