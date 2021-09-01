// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "./StructBase.sol";

abstract contract FinanceBase is StructBase, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.Map;

    EnumerableSetUpgradeable.AddressSet addrSet1;
    EnumerableSetUpgradeable.AddressSet addrSet2;
    mapping(address => uint) addrValue1;
    mapping(address => uint) addrValue2;

    function init() public initializer {
        super.__Ownable_init();
        super.__ReentrancyGuard_init();
    }

    function _create(
        CreateReq memory req,
        ClaimParam[] memory _claims,
        uint nftAmount
    ) internal nonReentrant {
        require(req.claimType == ClaimType.LOCKER, "un-support claimType");
        require(req.underlyingTokens.length > 0, "invalid length of underlyingTokens");
        require(req.underlyingTokens.length == req.underlyingAmounts.length, "invalid length of underlyingTokens");

        if (_claims.length > 0) {
            for (uint i = 0; i < req.underlyingTokens.length; i++) {
                require(!addrSet1.contains(req.underlyingTokens[i]), "duplicated token");
                addrSet1.add(req.underlyingTokens[i]);
                addrValue1[req.underlyingTokens[i]] = req.underlyingAmounts[i];
                addrValue2[req.underlyingTokens[i]] = 0;
            }
            for (uint i = 0; i < _claims.length; i++) {
                addrSet2.add(_claims[i].token);
                addrValue2[_claims[i].token] = addrValue2[_claims[i].token].add(_claims[i].amount);
            }
            require(addrSet1.length() == addrSet2.length(), "different length of tokens");

            for (uint i = 0; i < addrSet1.length(); i++) {
                require(addrValue1[addrSet1.at(i)] == addrValue2[addrSet1.at(i)], "different amount of tokens");
                addrSet2.remove(addrSet1.at(i));
            }
            require(addrSet2.length() == 0, "different tokens addresses");

            // clear data
            while (addrSet1.length() > 0) {
                addrSet1.remove(addrSet1.at(0));
            }
            require(addrSet1.length() == 0, "addrSet1 must be clear");
        }

        for (uint i = 0; i < req.underlyingTokens.length; i++) {
            IERC20Upgradeable(req.underlyingTokens[i])
                .safeTransferFrom(msg.sender, address(this), req.underlyingAmounts[i].mul(nftAmount));
        }

        uint nftId = nextNftId++;
        _mintNFT(msg.sender, nftId, nftAmount);

        Pool memory pool;
        pool.name = req.name;
        pool.metadata = req.metadata;
        pool.creator = msg.sender;
        pool.nftAmount = nftAmount;
        pool.underlyingTokens = req.underlyingTokens;
        pool.underlyingAmounts = req.underlyingAmounts;
        pool.claimType = req.claimType;
        pools[nftId] = pool;

        for(uint i = 0; i < _claims.length; i++) {
            claims[nftId].push(_claims[i]);
        }

        emit Created(msg.sender, nftId, req.name);
    }

    function _claim(uint nftId, uint nftAmount) internal nonReentrant {
        Pool memory pool = pools[nftId];
        require(pool.creator != address(0), "pool not exists");
        require(pool.claimType == ClaimType.LOCKER, "un-support claimType");

        if (claims[nftId].length == 0) {
            for (uint i = 0; i < pool.underlyingTokens.length; i++) {
                IERC20Upgradeable(pool.underlyingTokens[i]).safeTransfer(msg.sender, pool.underlyingAmounts[i]);
                emit Claimed(msg.sender, nftId, pool.underlyingTokens[i], pool.underlyingAmounts[i]);
            }
            _burnNFT(msg.sender, nftId, pool.nftAmount);
        } else {
            for (uint i = 0; i < claims[nftId].length; i++) {
                ClaimParam memory claim = claims[nftId][i];
                if (claims[nftId][i].claimAt <= block.timestamp && !claimed[nftId][i]) {
                    claimed[nftId][i]= true;
                    IERC20Upgradeable(claims[nftId][i].token).safeTransfer(msg.sender, claims[nftId][i].amount);
                    emit Claimed(msg.sender, nftId, claims[nftId][i].token, claims[nftId][i].amount);
                if (i == claims[nftId].length-1) {
                        _burnNFT(msg.sender, nftId, pool.nftAmount);
                    }
                }
            }
        }
    }

    function approveERC20(address token, address spender, uint amount) external onlyOwner {
        IERC20Upgradeable(token).approve(spender, amount);
    }

    function _mintNFT(address to, uint nftId, uint amount) internal virtual;

    function _burnNFT(address account, uint nftId, uint amount) internal virtual;
}
