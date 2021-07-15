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
        address payable creator;
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
    }

    mapping(uint => Index) public indices;
    uint public nextNftId;

    event IndexCreated(address indexed sender, uint nftId, Index index);
    event Mint(address indexed sender, uint nftId, uint nftAmount);
    event Burn(address indexed sender, uint nftId, uint nftAmount);
}