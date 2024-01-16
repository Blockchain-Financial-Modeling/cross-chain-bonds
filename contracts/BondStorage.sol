// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IRouterClient } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { CCIPReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "./BondData.sol";

contract BondStorage {
    mapping(address => uint256) internal _principals;
    mapping(address => mapping(address => uint256)) internal _approvals;

    BondData.Bond bonds;
    BondData.Issuer public issuer;
    IRouterClient public router;
    LinkTokenInterface public linkToken;

    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address feeToken,
        uint256 fees
    );

    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender
    );
}