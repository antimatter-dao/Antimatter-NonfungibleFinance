// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./IndexBase.sol";
import "./interfaces/IAggregationRouterV3.sol";

contract Index is IndexBase, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC1155Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint;

    uint public fee;
    address payable platform;

    function initialize(string memory uri) public initializer {
        super.__Ownable_init();
        super.__ReentrancyGuard_init();
        super.__ERC1155_init(uri);

        fee = 0.05 ether;
        platform = payable(0x0000000000000000000000000000000000000000);
    }

    function createIndex(CreateReq memory req) external {
        require(req.underlyingTokens.length > 0, "invalid length");
        require(req.underlyingTokens.length == req.underlyingAmounts.length, "invalid length");

        uint tokenId = nextTokenId++;

        Index memory index;
        index.creator = payable(msg.sender);
        index.tokenId = tokenId;
        index.underlyingTokens = req.underlyingTokens;
        index.underlyingAmounts = req.underlyingAmounts;
        indices[tokenId] = index;

        emit IndexCreated(msg.sender, index);
    }

    function mint(uint tokenId, uint amount, IAggregationRouterV3 router, bytes calldata data) external payable nonReentrant {
        Index memory index = indices[tokenId];
        require(index.creator != address(0), "Index not exists");

        {
            for (uint i = 0; i < index.underlyingTokens.length; i++) {
                (bool success, bytes memory result) = address(router).call{value: msg.value}(abi.encodePacked(router.swap.selector, data));
                if (!success) {
                    revert(RevertReasonParser.parse(result, "callBytes failed: "));
                } else {
                    (uint returnAmount,) = abi.decode(result, (uint, uint));
                }
            }
        }

        super._mint(msg.sender, tokenId, amount, "");
        _handleFee(tokenId);

        emit Mint(msg.sender, tokenId, amount);
    }

    function burn(uint tokenId, uint amount, IAggregationRouterV3 router, bytes calldata data) external nonReentrant {
        Index memory index = indices[tokenId];
        require(index.creator != address(0), "Index not exists");

        {
            for (uint i = 0; i < index.underlyingTokens.length; i++) {
                (bool success, bytes memory result) = address(router).call(abi.encodePacked(router.swap.selector, data));
                if (!success) {
                    revert(RevertReasonParser.parse(result, "callBytes failed: "));
                } else {
                    (uint returnAmount,) = abi.decode(result, (uint, uint));
                }
            }
        }

        super._burn(msg.sender, tokenId, amount);
        _handleFee(tokenId);

        emit Burn(msg.sender, tokenId, amount);
    }

    function approveERC20(address token, address spender, uint amount) external onlyOwner {
        IERC20Upgradeable(token).approve(spender, amount);
    }

    function setFee(uint fee_) external onlyOwner {
        fee = fee_;
    }

    function setPlatform(address payable platform_) external onlyOwner {
        platform = platform_;
    }

    function _handleFee(uint tokenId) private {
        require(msg.value == fee, "Invalid FEE");
        uint halfFee = fee.div(2);
        if (halfFee > 0) {
            indices[tokenId].creator.transfer(halfFee);
            platform.transfer(halfFee);
        }
    }
}
