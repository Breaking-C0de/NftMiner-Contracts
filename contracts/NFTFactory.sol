// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CustomNFT} from "./CustomNFT.sol";
contract NFTFactory is CCIPReceiver{
    // ERRORS
    error NFTNotDeployed();

    // EVENTS
    event NFTDeployed(address indexed nftAddress, address indexed owner);
    event NFTMinted(address indexed nftAddress, address indexed owner);

    mapping(address => address[]) private s_ownerToNfts;
    constructor(address router) CCIPReceiver(router){
    }

    function CreateAndDeployNFTContract(string memory _nftName, string memory _nftSymbol, string[] memory _tokenURIs, address _owner) internal {
        CustomNFT nft = new CustomNFT(_nftName, _nftSymbol, _tokenURIs, _owner);
        // check if nft is deployed
        if (address(nft) == address(0)) revert NFTNotDeployed();
        s_ownerToNfts[_owner].push(address(nft));
        emit NFTDeployed(address(nft), _owner);
    }

    function mint(
        address to,
        uint16 indexUri,
        address nftAddress,
        address caller
    ) internal {
        CustomNFT nft = CustomNFT(nftAddress);
        nft.mint(to, indexUri, caller);
        emit NFTMinted(nftAddress, to);
    }

    function getTokenURIs(address nftAddress) public view returns (string[] memory) {
        CustomNFT nft = CustomNFT(nftAddress);
        return nft.getTokenURIs();
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        (uint8 _operation, string memory _nftName, string memory _nftSymbol, string[] memory _tokenURIs, address _caller, address _to, uint16 _indexUri, address _nftAddress) = abi.decode(message.data, (uint8, string, string, string[], address, address, uint16, address));
        if (_operation == 0) {
            CreateAndDeployNFTContract(_nftName, _nftSymbol, _tokenURIs, _caller);
        } else if (_operation == 1) {
            mint(_to, _indexUri, _nftAddress, _caller);
        }
    }

    function getNFTs(address owner) public view returns (address[] memory) {
        return s_ownerToNfts[owner];
    }
}
