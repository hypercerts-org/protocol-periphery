// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IHypercertToken.sol";

contract BatchTransferFraction {
    IHypercertToken public immutable hypercertToken;
    uint256 internal constant FRACTION_LIMIT = 253;

    error INVALID_LENGTHS();
    error INVALID_DATA();
    error INVALID_CALLER(address caller);
    error INVALID_HYPERCERT_ADDRESS(address hypercertAddress);

    struct TransferData {
        address[] recipients;
        uint256[] fractionIds;
    }

    constructor(address _hypercertToken) {
        require(_hypercertToken != address(0), INVALID_HYPERCERT_ADDRESS(_hypercertToken));
        hypercertToken = IHypercertToken(_hypercertToken);
    }

    function batchTransfer(bytes memory data) external {
        require(data.length > 0, INVALID_DATA());
        TransferData memory transferData = abi.decode(data, (TransferData));
        require(transferData.recipients.length == transferData.fractionIds.length, INVALID_LENGTHS());

        for (uint256 i = 0; i < transferData.recipients.length; i++) {
            address recipient = transferData.recipients[i];
            uint256 fractionId = transferData.fractionIds[i];
            require(hypercertToken.ownerOf(fractionId) == msg.sender, INVALID_CALLER(msg.sender));

            hypercertToken.safeTransferFrom(msg.sender, recipient, fractionId, 1, "");
        }
    }

    function isFirstIndex(uint256 tokenId) public pure returns (bool) {
        return (tokenId & ((1 << 128) - 1)) == 0;
    }

    function getBaseType(uint256 tokenId) public pure returns (uint256) {
        return tokenId & (type(uint256).max << 128);
    }
}
