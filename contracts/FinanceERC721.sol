// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./FinanceBase.sol";

contract FinanceERC721 is FinanceBase, ERC721Upgradeable {

    function initialize(string memory name, string memory symbol) public initializer {
        super.init();
        super.__ERC721_init(name, symbol);
    }

    function create(CreateReq memory req, ClaimParam[] memory claims) external {
        super._create(req, claims, 1);
    }

    function claim(uint nftId) external {
        super._claim(nftId, 1);
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
}
