// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./FinanceBase.sol";

contract FinanceERC1155 is FinanceBase, ERC1155Upgradeable {

    function initialize(string memory uri) public initializer {
        super.initialize();
        super.__ERC1155_init(uri);
    }

    function _mintNFT(address to, uint tokenId, uint amount) internal override {
        super._mint(to, tokenId, amount, "");
    }

    function _burnNFT(address account, uint tokenId, uint amount) internal override {
        super._burn(account, tokenId, amount);
    }
}
