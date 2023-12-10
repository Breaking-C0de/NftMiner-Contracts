// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {Withdraw} from "./utils/Withdraw.sol";
import "./CustomNFT.sol";
contract NFTFactoryRouter is Withdraw {
    // ERRORS
    error TokenURIArrayAllowedLengthExceeded(string message);
    error TokenURIArrayEmpty(string message);

    enum PayFeesIn {
        Native,
        LINK
    }

    address immutable i_router;
    address immutable i_link;
    event MessageSent(bytes32 messageId);

    constructor(address router, address link) {
        i_router = router;
        i_link = link;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);
    }

    receive() external payable {}

    function mint(
        uint64 destinationChainSelector,
        address receiver,
        PayFeesIn payFeesIn,
        address nftAddress,
        address to,
        uint16 indexUri
    ) external {
        // [operation, _nftName, _nftSymbol, _tokenURIs, _caller, _to, _indexUri, _nftAddress]
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(uint8(1), "", "", [0], msg.sender, to, indexUri, nftAddress),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );

        bytes32 messageId;

        if (payFeesIn == PayFeesIn.LINK) {
            // LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(
                destinationChainSelector,
                message
            );
        } else {
            messageId = IRouterClient(i_router).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );
        }
        emit MessageSent(messageId);
    }

    function nftDeploy(
        uint64 destinationChainSelector,
        address receiver,
        PayFeesIn payFeesIn,
        string memory _nftName,
        string memory _nftSymbol,
        string[] memory _tokenURIs
    ) external {
        if(_tokenURIs.length > 5) revert TokenURIArrayAllowedLengthExceeded("Upto 5 tokenURIs are allowed");
        if(_tokenURIs.length == 0) revert TokenURIArrayEmpty("tokenURIs array cannot be empty");

        // [operation, _nftName, _nftSymbol, _tokenURIs, _caller, _to, _indexUri, _nftAddress]
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(uint8(0), _nftName, _nftSymbol, _tokenURIs, msg.sender, address(0), uint16(0), address(0)),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );

        bytes32 messageId;

        if (payFeesIn == PayFeesIn.LINK) {
            // LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(
                destinationChainSelector,
                message
            );
        } else {
            messageId = IRouterClient(i_router).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );
        }
        emit MessageSent(messageId);
    }
    
}
