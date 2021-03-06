// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IndexBase {
    struct CreateReq {
        string name;
        // metadata of NFT
        string metadata;
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
    }

    struct Index {
        string name;
        // metadata of NFT
        string metadata;
        // creator of the index
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

    function getUnderlyingTokensLength(uint nftId) public view returns(uint) {
        return indices[nftId].underlyingTokens.length;
    }

    function getUnderlyingToken(uint nftId, uint index) public view returns(address) {
        return indices[nftId].underlyingTokens[index];
    }

    event IndexCreated(address indexed sender, uint nftId, string name);
    event Mint(address indexed sender, uint nftId, uint nftAmount, uint totalSpend);
    event Burn(address indexed sender, uint nftId, uint nftAmount, uint totalIncome);
    event FeeReceived(uint indexed nftId, address indexed platform, address indexed creator, uint platformFee, uint creatorFee);
}
