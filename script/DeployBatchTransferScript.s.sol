// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/BatchTransferFraction.sol";
import "../src/interfaces/IHypercertToken.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract DeployBatchTransferScript is Script {
    IHypercertToken internal hypercertToken;

    function configureChain() public {
        if (block.chainid == 10) {
            // Optimism mainnet
            hypercertToken = IHypercertToken(0x822F17A9A5EeCFd66dBAFf7946a8071C265D1d07);
        } else if (block.chainid == 11_155_111) {
            // Sepolia
            hypercertToken = IHypercertToken(0xa16DFb32Eb140a6f3F2AC68f41dAd8c7e83C4941);
        } else {
            revert("Unsupported chain");
        }
    }

    function run() external {
        configureChain();

        vm.startBroadcast();

        bytes32 salt = keccak256(abi.encodePacked("BatchTransferFraction"));

        bytes memory arg = abi.encode(address(hypercertToken));

        bytes memory bytecode = abi.encodePacked(type(BatchTransferFraction).creationCode, arg);

        address deployedAddress = Create2.deploy(0, salt, bytecode);

        console.log("BatchTransferFraction deployed to: %s", address(deployedAddress));
        vm.stopBroadcast();
    }
}
