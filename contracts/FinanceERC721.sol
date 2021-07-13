// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./FinanceBase.sol";

contract FinanceERC721 is FinanceBase, ERC721Upgradeable {

    function initialize(string memory name, string memory symbol) public initializer {
        super.initialize();
        super.__ERC721_init(name, symbol);
    }

    function _mintNFT(address to, uint tokenId, uint amount) internal override {
        require(amount == 1, "");
        super._mint(to, tokenId);
    }

    function _burnNFT(address account, uint tokenId, uint amount) internal override {
        require(super.ownerOf(tokenId) == account, "");
        require(amount == 1, "");
        super._burn(tokenId);
    }
}
