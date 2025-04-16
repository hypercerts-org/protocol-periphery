// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IHypercertToken.sol";

contract BatchTransferFraction {
    IHypercertToken public hypercertToken;

    error INVALID_LENGTHS();
    error INVALID_RECIPIENT(address recipient);
    error INVALID_TOKEN_ID(uint256 tokenID);
    error INVALID_CALLER(address caller);
    error INVALID_HYPERCERT_ADDRESS(address hypercertAddress);

    constructor(address _hypercertToken) {
        require(_hypercertToken != address(0), INVALID_HYPERCERT_ADDRESS(_hypercertToken));
        hypercertToken = IHypercertToken(_hypercertToken);
    }
}
