// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IHypercertToken.sol";

contract BatchTransferFraction {
    IHypercertToken public immutable hypercertToken;

    error INVALID_LENGTHS();
    error INVALID_DATA();
    error INVALID_CALLER(address caller);
    error INVALID_HYPERCERT_ADDRESS(address hypercertAddress);

    event BatchFractionTransfer(address indexed from, address[] indexed to, uint256[] indexed fractionId);

    struct TransferData {
        address[] recipients;
        uint256[] fractionIds;
    }

    constructor(address _hypercertToken) {
        require(_hypercertToken != address(0), INVALID_HYPERCERT_ADDRESS(_hypercertToken));
        hypercertToken = IHypercertToken(_hypercertToken);
    }

    /// @dev msg.sender must be the owner of all the fraction IDs being transferred
    /// @dev msg.sender must have approved the contract to transfer the fractions
    /// @dev The length of recipients and fractionIds must be the same
    /// @param data The encoded data containing the recipients and fraction IDs
    function batchTransfer(bytes memory data) external {
        require(data.length > 0, INVALID_DATA());
        TransferData memory transferData = abi.decode(data, (TransferData));
        require(transferData.recipients.length == transferData.fractionIds.length, INVALID_LENGTHS());
        _batchTransfer(transferData.recipients, transferData.fractionIds);
    }

    /// @notice Transfers fractions to multiple recipients
    /// @dev The length of recipients and fractionIds must be the same
    /// @dev The caller must be the owner of all the fraction IDs being transferred
    /// @param recipients The addresses of the recipients
    /// @param fractionIds The IDs of the fractions to be transferred
    function _batchTransfer(address[] memory recipients, uint256[] memory fractionIds) internal {
        uint256 length = recipients.length;
        for (uint256 i = 0; i < length; i++) {
            address recipient = recipients[i];
            uint256 fractionId = fractionIds[i];
            require(hypercertToken.ownerOf(fractionId) == msg.sender, INVALID_CALLER(msg.sender));

            hypercertToken.safeTransferFrom(msg.sender, recipient, fractionId, 1, "");
        }
        emit BatchFractionTransfer(msg.sender, recipients, fractionIds);
    }
}
