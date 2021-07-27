// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./StructBase.sol";

abstract contract FinanceBase is StructBase, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize() public initializer {
        super.__Ownable_init();
        super.__ReentrancyGuard_init();
    }

    function create(CreateReq memory req) external nonReentrant {
        require(req.claimType <= 2, "invalid claimType");
        require(req.underlyingTokens.length > 0, "invalid length of underlyingTokens");
        require(req.underlyingTokens.length == req.underlyingAmounts.length, "invalid length of underlyingTokens");

        for (uint i = 0; i < req.underlyingTokens.length; i++) {
            IERC20Upgradeable(req.underlyingTokens[i]).safeTransfer(address(this), req.underlyingAmounts[i]);
        }

        uint nftId = nextNftId++;
        _mintNFT(msg.sender, nftId, req.nftAmount);

        Pool memory pool;
        pool.metadata = req.metadata;
        pool.creator = msg.sender;
        pool.nftAmount = req.nftAmount;
        pool.underlyingTokens = req.underlyingTokens;
        pool.underlyingAmounts = req.underlyingAmounts;
        pool.claimType = req.claimType;
        pools[nftId] = pool;

        emit Created(msg.sender, nftId, pool);
    }

    function claim(uint nftId) external nonReentrant {
        Pool memory pool = pools[nftId];
        require(pool.creator != address(0), "pool not exists");

        _burnNFT(msg.sender, nftId, pool.nftAmount);

        for (uint i = 0; i < pool.underlyingTokens.length; i++) {
            IERC20Upgradeable(pool.underlyingTokens[i]).safeTransfer(msg.sender, pool.underlyingAmounts[i]);
        }

        emit Claimed(msg.sender, nftId, pool.underlyingTokens, pool.underlyingAmounts);
    }

    function approveERC20(address token, address spender, uint amount) external onlyOwner {
        IERC20Upgradeable(token).approve(spender, amount);
    }

    function _mintNFT(address to, uint nftId, uint amount) internal virtual;

    function _burnNFT(address account, uint nftId, uint amount) internal virtual;
}
