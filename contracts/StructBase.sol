// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StructBase {
    uint internal constant ClaimTypeInstant  = 0;
    uint internal constant ClaimTypeDelay = 1;
    uint internal constant ClaimTypeLinear = 2;

    struct CreateReq {
        // total amount of token0
        uint amountTotal0;
        // address of buy token
        address[] token1;
        // total amount of token1
        uint[] amountTotal1;
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint claimAt;
        uint claimType;
    }

    struct Pool {
        address creator;
        uint tokenId;
        uint amountTotal0;
        // address of buy token
        address[] token1;
        // total amount of token1
        uint[] amountTotal1;
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint claimAt;
        uint claimType;
    }

    mapping(uint => Pool) public pools;
    uint public nextTokenId;

    event Created(address indexed sender, Pool pool);
    event Claimed(address indexed sender, uint tokenId, address[] tokens, uint[] amounts);
}
