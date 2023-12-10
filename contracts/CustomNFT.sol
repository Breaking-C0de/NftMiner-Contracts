// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CustomNFT is ERC721URIStorage {
    //EVENTS
    event MintSuccessful(address indexed to, uint256 indexed tokenId, string tokenURI);

    // ERRORS
    error InvalidTokenURI(string tokenURI);
    error TokenURIArrayFull();
    error NotOwner();

    // CONSTANTS
    uint8 public constant MAX_TOKEN_URIS = 5;
    
    string[] private s_tokenURIs;
    uint256 internal tokenId;
    address immutable i_owner;

    // MODIFIER
    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
    }
    
    constructor(string memory _nftName, string memory _nftSymbol, string[] memory _tokenURIs, address _owner) ERC721(_nftName, _nftSymbol) {
        s_tokenURIs = _tokenURIs;
        i_owner = _owner;
    }

    /**
     * NOTE: This function is to add new tokenURIs to the tokenURIs array
     * @param _tokenURI string
     */
    function addTokenURI(string memory _tokenURI, address caller) public {
        if (caller != i_owner) revert NotOwner();
        if (bytes(_tokenURI).length == 0) revert InvalidTokenURI(_tokenURI);
        if (s_tokenURIs.length > MAX_TOKEN_URIS) revert TokenURIArrayFull();
        s_tokenURIs.push(_tokenURI);
    }

    function mint(address to, uint16 indexUri, address caller) public {
        if (caller != i_owner) revert NotOwner();

        if(indexUri >= s_tokenURIs.length) revert InvalidTokenURI("Token index out of bounds");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, s_tokenURIs[indexUri]);
        tokenId++;  
        emit MintSuccessful(to, tokenId, s_tokenURIs[indexUri]);
    }

    function getTokenURIs() public view returns (string[] memory) {
        return s_tokenURIs;
    }
}