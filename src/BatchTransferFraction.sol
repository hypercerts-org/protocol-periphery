// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IHypercertToken.sol";

contract BatchTransferFraction {
    IHypercertToken public hypercertToken;
    uint256 internal constant FRACTION_LIMIT = 253;

    error INVALID_LENGTHS();
    error EXCEEDED_FRACTION_LIMIT();
    error INVALID_DATA();
    error INVALID_RECIPIENT(address account);
    error INVALID_CALLER(address account);
    error INVALID_HYPERCERT_ADDRESS(address hypercertAddress);
    error INVALID_BALANCE(address account, uint256 tokenId);
    error INVALID_INDEX(uint256 tokenId);

    event BatchTransferFractions(
        address[] indexed to,
        uint256[] indexed tokenIds
    );

    struct SplitsData {
        address[] recipients;
        uint256[] units;
    }

    struct TransferData {
        address[] recipients;
        uint256[] fractionIds;
    }

    constructor(address _hypercertToken) {
        require(
            _hypercertToken != address(0),
            INVALID_HYPERCERT_ADDRESS(_hypercertToken)
        );
        hypercertToken = IHypercertToken(_hypercertToken);
    }

    /// @notice Splits the tokenId into fractions and transfers them to the recipients
    /// @notice This function only works if
    /// @notice the fraction is not a base type && fraction is index1, and
    /// @notice other fractions are not splitted yet.
    /// @param owner The owner of the tokenId
    /// @param tokenId The tokenId to be split
    /// @param data Encoded SplitsData struct
    /// @dev Splits the tokenId into fractions and transfers them to the recipients
    /// @dev The data should be encoded as SplitsData struct
    /// @dev The recipients and units arrays should be of the same length
    /// @dev If the tokenId is a base type(index0), will be reverted
    function bigBang(
        address owner,
        uint256 tokenId,
        bytes memory data
    ) external {
        // Check if the data is not empty
        require(data.length > 0, INVALID_DATA());

        // Check if the tokenId is a base type
        require(isFirstIndex(tokenId), INVALID_INDEX(tokenId));

        // Check if the caller is the owner or the tokenId is owned by the owner
        require(
            msg.sender == owner || hypercertToken.ownerOf(tokenId) == owner,
            INVALID_CALLER(msg.sender)
        );

        // Decode the data into SplitsData struct
        SplitsData memory splitsData = abi.decode(data, (SplitsData));

        // Check if the length is not exceeded FRACTION_LIMIT
        require(
            splitsData.recipients.length < FRACTION_LIMIT &&
                splitsData.units.length < FRACTION_LIMIT,
            EXCEEDED_FRACTION_LIMIT()
        );
        // Check if the recipients and units arrays are of the same length
        require(
            splitsData.recipients.length == splitsData.units.length ||
                splitsData.recipients.length > 0 ||
                splitsData.units.length > 0,
            INVALID_LENGTHS()
        );

        // Check if owner has a balance of the tokenId
        require(
            hypercertToken.unitsOf(owner, tokenId) > 0,
            INVALID_BALANCE(owner, tokenId)
        );

        hypercertToken.splitFraction(owner, tokenId, splitsData.units);

        uint256 baseType = tokenId & (type(uint256).max << 128);
        uint256[] memory fractionIds = new uint256[](
            splitsData.recipients.length
        );
        for (uint256 i = 0; i < splitsData.recipients.length; i++) {
            fractionIds[i] = baseType + (i + 1);
        }

        _batchTransfer(owner, splitsData.recipients, fractionIds);
    }

    function batchTransfer(address owner, bytes memory data) external {
        require(data.length > 0, INVALID_DATA());
        TransferData memory transferData = abi.decode(data, (TransferData));
        require(
            transferData.recipients.length == transferData.fractionIds.length,
            INVALID_LENGTHS()
        );

        _batchTransfer(
            owner,
            transferData.recipients,
            transferData.fractionIds
        );
    }

    function _batchTransfer(
        address owner,
        address[] memory recipients,
        uint256[] memory fractionIds
    ) internal {
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 fractionId = fractionIds[i];
            require(
                hypercertToken.ownerOf(fractionId) == owner,
                INVALID_CALLER(msg.sender)
            );

            hypercertToken.safeTransferFrom(
                msg.sender,
                recipient,
                fractionId,
                1,
                ""
            );
        }
        emit BatchTransferFractions(recipients, fractionIds);
    }

    function isFirstIndex(uint256 tokenId) internal pure returns (bool) {
        return (tokenId & ((1 << 128) - 1)) == 0;
    }
}
