// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { BatchTransferFraction } from "../src/BatchTransferFraction.sol";
import { IHypercertToken } from "../src/interfaces/IHypercertToken.sol";

contract BatchTransferFractionTest is Test {
    BatchTransferFraction public batchTransferFraction;
    IHypercertToken public hypercertToken;
    address public currentPrankee;

    function setUp() public {
        configureChain();
        batchTransferFraction = new BatchTransferFraction(address(hypercertToken));
    }

    function testDeployment() public view {
        assertNotEq(address(batchTransferFraction), address(0));
    }

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

    modifier prankception(address prankee) {
        address prankBefore = currentPrankee;
        vm.stopPrank();
        vm.startPrank(prankee);
        _;
        vm.stopPrank();
        if (prankBefore != address(0)) {
            vm.startPrank(prankBefore);
        }
    }
}
