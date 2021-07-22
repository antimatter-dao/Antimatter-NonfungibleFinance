// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IndexBase {
    struct CreateReq {
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
    }

    struct Index {
        address creator;
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
    }

    mapping(uint => Index) public indices;
    uint public nextNftId;

    function getIndex(uint nftId) public view returns(Index memory) {
        return indices[nftId];
    }

    event IndexCreated(address indexed sender, uint nftId, Index index);
    event Mint(address indexed sender, uint nftId, uint nftAmount, uint totalSpend);
    event Burn(address indexed sender, uint nftId, uint nftAmount, uint totalIncome);
}
