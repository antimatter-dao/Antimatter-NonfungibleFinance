// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StructBase {

    enum ClaimType {
        LOCKER
//        SPOT,
//        FUTURE,
    }

    struct CreateReq {
        string name;
        // metadata of NFT
        string metadata;
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
        ClaimType claimType;
    }

    struct Pool {
        string name;
        // metadata of NFT
        string metadata;
        // creator of Pool
        address creator;
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
        // NFT amount
        uint nftAmount;
        ClaimType claimType;
    }

    struct ClaimParam {
        address token;
        uint amount;
        uint claimAt;
    }

    mapping(uint => Pool) public pools;

    mapping(uint => ClaimParam[]) public claims;
    mapping(uint => mapping(uint => bool)) public claimed;
    uint public nextNftId;

    function getPool(uint nftId) public view returns(Pool memory) {
        return pools[nftId];
    }

    function getUnderlyingTokensLength(uint nftId) public view returns(uint) {
        return pools[nftId].underlyingTokens.length;
    }

    function getUnderlyingToken(uint nftId, uint index) public view returns(address) {
        return pools[nftId].underlyingTokens[index];
    }

    function getClaim(uint nftId, uint index) public view returns(ClaimParam memory) {
        return claims[nftId][index];
    }

    function getClaimLength(uint nftId) public view returns(uint) {
        return claims[nftId].length;
    }

    event Created(address indexed sender, uint indexed nftId, string name);
    event Claimed(address indexed sender, uint indexed nftId, address token, uint amount);
}
