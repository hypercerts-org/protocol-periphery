// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/BatchTransferFraction.sol";
import "../src/interfaces/IHypercertToken.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract DeployBatchTransferScript is Script {
    IHypercertToken internal hypercertToken;

    function configureChain() public {
        string memory root = vm.projectRoot();
        string memory path =
            string.concat(root, "/lib/hypercerts-protocol/contracts/src/deployments/deployments-protocol.json");
        string memory json = vm.readFile(path);
        string memory chainIdStr = vm.toString(block.chainid);

        bytes memory uupsAddressRaw = vm.parseJson(json, string.concat(".", chainIdStr, ".HypercertMinterUUPS"));

        address uupsAddress = abi.decode(uupsAddressRaw, (address));

        hypercertToken = IHypercertToken(uupsAddress);
        console.log("HypercertMinterUUPS: %s", uupsAddress);
        console.log("Deploying BatchTransferFraction on: %s", block.chainid);
    }

    function run() external {
        configureChain();

        vm.startBroadcast();

        // bytes32 salt = keccak256(abi.encodePacked("BatchTransferFraction"));

        // bytes memory arg = abi.encode(address(hypercertToken));

        // bytes memory bytecode = abi.encodePacked(type(BatchTransferFraction).creationCode, arg);

        // address deployedAddress = Create2.deploy(0, salt, bytecode);

        BatchTransferFraction deployedAddress = new BatchTransferFraction(address(hypercertToken));

        console.log("BatchTransferFraction deployed to: %s", address(deployedAddress));
        vm.stopBroadcast();
    }
}
