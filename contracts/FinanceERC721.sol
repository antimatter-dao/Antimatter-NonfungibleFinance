// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./FinanceBase.sol";

contract FinanceERC721 is FinanceBase, ERC721Upgradeable {
    using StringsUpgradeable for uint;

    string baseURI;

    function initialize(string memory name, string memory symbol, string memory _baseURI) public initializer {
        super.init();
        super.__ERC721_init(name, symbol);
        baseURI = _baseURI;
    }

    function create(CreateReq memory req, ClaimParam[] memory claims) external {
        super._create(req, claims, 1);
    }

    function claim(uint nftId) external {
        super._claim(nftId, 1);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function _mintNFT(address to, uint tokenId, uint amount) internal override {
        require(amount == 1, "invalid amount");
        super._mint(to, tokenId);
    }

    function _burnNFT(address account, uint tokenId, uint amount) internal override {
        require(super.ownerOf(tokenId) == account, "invalid owner");
        require(amount == 1, "invalid amount");
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, "?nftId=", tokenId.toString(), "&chainId=", block.chainid.toString()))
            : '';
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
