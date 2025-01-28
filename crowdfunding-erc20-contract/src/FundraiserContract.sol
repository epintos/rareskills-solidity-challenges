// SDPX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { IFundraiser } from "./interfaces/IFundraiser.sol";

contract FundraiserContract is IFundraiser {
    /// ERRORS

    // TYPE DECLARATIONS
    struct Fundraiser {
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        address creator;
        bool goalMet;
        bool creatorPaid;
    }

    /// STATE VARIABLES
    mapping(uint256 fundraiserId => Fundraiser fundraiser) private s_fundraisers;
    mapping(uint256 fundraiserId => mapping(address donator => uint256 amountDonated)) private s_donators;
    mapping(address donator => uint256[] fundraiserIds) private s_donatorFundraiserIds;
    uint256 private s_fundraiserQuantity;

    /// FUNCTIONS
    // EXTERNAL FUNCTIONS

    // EXTERNAL VIEW FUNCTIONS
}
