# Hypercerts Periphery Contracts

[![TEST](https://github.com/hypercerts-org/protocol-periphery/actions/workflows/test.yml/badge.svg)](https://github.com/hypercerts-org/protocol-periphery/actions/workflows/test.yml)
[![Slither Analysis](https://github.com/hypercerts-org/protocol-periphery/actions/workflows/slither.yaml/badge.svg)](https://github.com/hypercerts-org/protocol-periphery/actions/workflows/slither.yaml)

## Table of Contents

- [Hypercerts Periphery Contracts](#hypercerts-periphery-contracts)
	- [Table of Contents](#table-of-contents)
	- [BatchTransferFraction](#batchtransferfraction)
		- [Implementation](#implementation)
		- [Usage](#usage)
		- [Deployments](#deployments)

## BatchTransferFraction

### Implementation

```mermaid
sequenceDiagram
actor o as Owner
participant h as Hypercert Minter Contract
participant b as BatchTransfer Contract
actor r as Recipients

o ->> h: call splitFraction()
h ->> h: split fraction
o ->> h: call setApprovalForAll()
o ->> b: call batchTransfer()
critical will be reverted if the owner is not the owner of each fractions
b --> h: check if caller is the owner of fraction
b ->> r: safeTransferFrom()
end

```

```solidity
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
```

### Usage

> [!important]
> make sure you own the hypercerts.
>
> most of hypercerts have **CREATOR ONLY** [transfer restriction](https://github.com/hypercerts-org/hypercerts-protocol/blob/a606868b1f8d0502124428c45a985002170e6fca/contracts/src/protocol/interfaces/IHypercertToken.sol#L9-L19), so make sure you created the hypercerts as well.

1. Encode data with [ethers](https://docs.ethers.org/v5/api/utils/abi/coder) or [viem](https://viem.sh/docs/abi/encodeAbiParameters#encodeabiparameters).

   with ethers

   ```javascript
   import { ethers } from "ethers";
   ...
   const recipients = ["0x123....", "0x456...."];
   const fractionIds = [BigInt("23894....5301"), BigInt("23894....5302")];

   const encodedData = ethers.AbiCoder.defaultAbiCoder().encode(
   	[`tuple(address[], uint256[])`],
   	[[recipients, fractionIds]]
   );
   console.log('Encoded Data:', encodedData);
    // e.g. Encoded Data: 0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000100000000000000000000000006aa005386f53ba7b980c61e0d067cabc7602a620000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000c000000000000000000000000000000002
   ```

   with viem

   ```javascript
   import { encodeAbiParameters } from 'viem';

   ...
   const recipients = ["0x123....", "0x456...."];
   const fractionIds = [BigInt("23894....5301"), BigInt("23894....5302")];
   const abiParams = [
    {
      type: 'tuple',
      components: [{ type: 'address[]' }, { type: 'uint256[]' }],
    },
   ];
   const encodedData = encodeAbiParameters(abiParams, [
    [recipients, fractionIds],
   ]);
   ```

2. In the HypercertsMinter contract on the chain where you want to execute batch transfer, call [setApprovalForAll (0xa22cb465)](https://optimistic.etherscan.io/address/0x822F17A9A5EeCFd66dBAFf7946a8071C265D1d07#writeProxyContract#F17) to approve the batchTransfer contract to send hypercerts.
   `operator == BatchTransfer contract address, approved == true`

3. call batchTransfer function

### Deployments

| chain            | chainId  | address                                                                                                                          |
| ---------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Sepolia          | 11155111 | [0x59e07f1cc8eb8eca2703179a7217673318a0fe47](https://sepolia.etherscan.io/address/0x59e07f1cc8eb8eca2703179a7217673318a0fe47)    |
| Base Sepolia     | 84532    | [0x3C0FaAA04078d715BB05Af82Ca99c41623AeC5Ae](https://sepolia.basescan.org/address/0x3C0FaAA04078d715BB05Af82Ca99c41623AeC5Ae)    |
| Arbitrum Sepolia | 421614   | [0x0fCCa2bAd3103934304874E782450688B7a044B0](https://sepolia.arbiscan.io/address/0x0fCCa2bAd3103934304874E782450688B7a044B0)     |
| Optimism         | 10       | [0xf77e452ec289da0616574aae371800ca4d6315b1](https://optimistic.etherscan.io/address/0xf77e452ec289da0616574aae371800ca4d6315b1) |
| Base             | 8453     | [0xc4aEB039BC432343bf4dB57Be203E0540d385a18](https://basescan.org/address/0xc4aEB039BC432343bf4dB57Be203E0540d385a18)            |
| Arbitrum         | 42161    | [0x8b973c408c2748588b3ECFfDA06D670819FbEb1D](https://arbiscan.io/address/0x8b973c408c2748588b3ECFfDA06D670819FbEb1D)             |
| Celo             | 42220    | [0xB64B7e4793D72958e028B1D5D556888b115c4c3E](https://celoscan.io/address/0xB64B7e4793D72958e028B1D5D556888b115c4c3E)             |
