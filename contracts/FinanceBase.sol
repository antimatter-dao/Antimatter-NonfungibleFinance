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
        require(req.token1.length > 0, "invalid length");
        require(req.token1.length == req.amountTotal1.length, "invalid length");

        for (uint i = 0; i < req.token1.length; i++) {
            IERC20Upgradeable(req.token1[i]).safeTransfer(address(this), req.amountTotal1[i]);
        }

        uint tokenId = nextTokenId++;
        _mintNFT(msg.sender, tokenId, req.amountTotal0);

        Pool memory pool;
        pool.creator = msg.sender;
        pool.tokenId = tokenId;
        pool.amountTotal0 = req.amountTotal0;
        pool.token1 = req.token1;
        pool.amountTotal1 = req.amountTotal1;
        pool.claimType = req.claimType;
        pools[tokenId] = pool;

        emit Created(msg.sender, pool);
    }

    function claim(uint tokenId) external nonReentrant {
        Pool memory pool = pools[tokenId];
        require(pool.creator != address(0), "pool not exists");

        _burnNFT(msg.sender, tokenId, pool.amountTotal0);

        for (uint i = 0; i < pool.token1.length; i++) {
            IERC20Upgradeable(pool.token1[i]).safeTransfer(msg.sender, pool.amountTotal1[i]);
        }

        emit Claimed(msg.sender, tokenId, pool.token1, pool.amountTotal1);
    }

    function approveERC20(address token, address spender, uint amount) external onlyOwner {
        IERC20Upgradeable(token).approve(spender, amount);
    }

    function _mintNFT(address to, uint tokenId, uint amount) internal virtual;

    function _burnNFT(address account, uint tokenId, uint amount) internal virtual;
}
