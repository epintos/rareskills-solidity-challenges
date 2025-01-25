// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { Script } from "forge-std/Script.sol";
import { NFT } from "src/NFT.sol";

contract DeployNFT is Script {
    function run(uint256 nftPrice, address tokenToPayWith) public returns (NFT nftContract) {
        vm.startBroadcast();
        nftContract = new NFT(nftPrice, tokenToPayWith);
        vm.stopBroadcast();
    }
}
