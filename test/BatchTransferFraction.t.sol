// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { BatchTransferFraction } from "../src/BatchTransferFraction.sol";
import { IHypercertToken } from "../src/interfaces/IHypercertToken.sol";

interface IERC1155 {
    function setApprovalForAll(address operator, bool approved) external;
}

contract BatchTransferFractionTest is Test {
    BatchTransferFraction public batchTransferFraction;
    IHypercertToken public hypercertToken;
    address public currentPrankee;
    address public owner;
    address public alice = makeAddr("Alice");
    address public bob = makeAddr("Bob");
    uint256 public CLAIM_ID;
    uint256 public FRACTION_ID;

    event BatchFractionTransfer(address indexed from, address[] indexed to, uint256[] indexed fractionId);

    function setUp() public {
        configureChain();
        batchTransferFraction = new BatchTransferFraction(address(hypercertToken));
    }

    function testDeployment() public view {
        assertNotEq(address(batchTransferFraction), address(0));
    }

    function testRevertINVALID_HYPERCERT_ADDRESS() public {
        vm.expectRevert(abi.encodeWithSelector(BatchTransferFraction.INVALID_HYPERCERT_ADDRESS.selector, address(0)));
        new BatchTransferFraction(address(0));
    }

    function testRevertINVALID_DATA() public {
        vm.expectRevert(BatchTransferFraction.INVALID_DATA.selector);
        batchTransferFraction.batchTransfer("");
    }

    function testRevertINVALID_LENGTHS() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 314_761_189_401_868_078_703_621_511_874_385_595_596_802;
        tokenIds[1] = 314_761_189_401_868_078_703_621_511_874_385_595_596_803;

        address[] memory recipients = new address[](3);
        recipients[0] = alice;
        recipients[1] = bob;
        recipients[2] = address(0);

        bytes memory data = abi.encode(BatchTransferFraction.TransferData(recipients, tokenIds));

        vm.expectRevert(BatchTransferFraction.INVALID_LENGTHS.selector);
        batchTransferFraction.batchTransfer(data);
    }

    function testRevertINVALID_CALLER() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 314_761_189_401_868_078_703_621_511_874_385_595_596_802;
        tokenIds[1] = 314_761_189_401_868_078_703_621_511_874_385_595_596_803;

        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;

        bytes memory data = abi.encode(BatchTransferFraction.TransferData(recipients, tokenIds));

        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(BatchTransferFraction.INVALID_CALLER.selector, alice));
        batchTransferFraction.batchTransfer(data);
        vm.stopPrank();
    }

    function testBatchTransfer() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 314_761_189_401_868_078_703_621_511_874_385_595_596_802;
        tokenIds[1] = 314_761_189_401_868_078_703_621_511_874_385_595_596_803;

        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;

        bytes memory data = abi.encode(BatchTransferFraction.TransferData(recipients, tokenIds));

        vm.startPrank(owner);
        hypercertToken.setApprovalForAll(address(batchTransferFraction), true);

        vm.expectEmit(true, true, true, true);
        emit BatchFractionTransfer(owner, recipients, tokenIds);

        batchTransferFraction.batchTransfer(data);

        assertEq(hypercertToken.ownerOf(tokenIds[0]), alice, "Alice should own the first token");
        assertEq(hypercertToken.ownerOf(tokenIds[1]), bob, "Bob should own the second token");

        vm.stopPrank();
    }

    function _setApprovalForAll(address caller, address operator) internal prankception(caller) {
        IERC1155(address(hypercertToken)).setApprovalForAll(operator, true);
    }

    function configureChain() public {
        string memory root = vm.projectRoot();
        string memory path =
            string.concat(root, "/lib/hypercerts-protocol/contracts/src/deployments/deployments-protocol.json");
        string memory json = vm.readFile(path);
        string memory chainIdStr = vm.toString(block.chainid);

        bytes memory uupsAddressRaw = vm.parseJson(json, string.concat(".", chainIdStr, ".HypercertMinterUUPS"));

        address uupsAddress = abi.decode(uupsAddressRaw, (address));

        hypercertToken = IHypercertToken(uupsAddress);

        if (block.chainid == 11_155_111) {
            // Sepolia
            CLAIM_ID = 296_385_941_588_137_401_676_599_283_073_070_112_178_176;
            FRACTION_ID = CLAIM_ID + 1;
            owner = 0xc3593524E2744E547f013E17E6b0776Bc27Fc614;
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
