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
        // address of buy token
        uint tokenId;
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
    }

    mapping(uint => Index) public indices;
    uint public nextTokenId;

    event IndexCreated(address indexed sender, Index index);
    event Mint(address indexed sender, uint tokenId, uint amount);
    event Burn(address indexed sender, uint tokenId, uint amount);
}
