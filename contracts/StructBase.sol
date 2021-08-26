// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract StructBase {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

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
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint claimAt;
        ClaimType claimType;
    }

    struct ClaimParam {
        address token;
        uint amount;
        uint claimAt;
    }

    mapping(uint => Pool) public pools;

    EnumerableSetUpgradeable.UintSet internal claimIndex;

    mapping(uint => ClaimParam[]) public claims;
    mapping(uint => mapping(uint => bool)) public claimed;
    uint public nextNftId;

    function getPool(uint nftId) public view returns(Pool memory) {
        return pools[nftId];
    }

    event Created(address indexed sender, uint nftId, string name);
    event Claimed(address indexed sender, uint nftId, address[] underlyingTokens, uint[] underlyingAmounts);
}
