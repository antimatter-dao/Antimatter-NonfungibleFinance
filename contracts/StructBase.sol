// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StructBase {
    uint internal constant ClaimTypeInstant  = 0;
    uint internal constant ClaimTypeDelay = 1;
    uint internal constant ClaimTypeLinear = 2;

    struct CreateReq {
        // metadata of NFT
        string metadata;
        // NFT amount
        uint nftAmount;
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint claimAt;
        uint claimType;
    }

    struct Pool {
        // metadata of NFT
        string metadata;
        // creator of Pool
        address creator;
        // NFT amount
        uint nftAmount;
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint claimAt;
        uint claimType;
    }

    mapping(uint => Pool) public pools;
    uint public nextNftId;

    function getPool(uint nftId) public view returns(Pool memory) {
        return pools[nftId];
    }

    event Created(address indexed sender, uint nftId, Pool pool);
    event Claimed(address indexed sender, uint nftId, address[] underlyingTokens, uint[] underlyingAmounts);
}
