// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract BlindBox is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    address public nftGift;
    address public matter;
    uint public drawFee;
    mapping(address => bool) public participated;
    EnumerableSetUpgradeable.UintSet nftGiftSet;

    event Drew(address indexed sender, uint indexed tokenId);

    function initialize(address _matter, uint _drawFee) public initializer {
        matter = _matter;
        drawFee = _drawFee;
    }

    function draw() external nonReentrant canDraw {
        IERC20Upgradeable(matter).safeTransferFrom(msg.sender, address(this), drawFee);
        participated[msg.sender] = true;

        uint seed = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, blockhash(block.number-1), gasleft())));
        uint index = seed % getGiftLength();
        uint tokenId = nftGiftSet.at(index);
        IERC721Upgradeable(nftGift).safeTransferFrom(address(this), msg.sender, tokenId);
        nftGiftSet.remove(tokenId);

        emit Drew(msg.sender, tokenId);
    }

    function packBox(uint[] memory tokenIds) external onlyOwner {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(!nftGiftSet.contains(tokenId), "duplicated token id");
            IERC721Upgradeable(nftGift).safeTransferFrom(msg.sender, address(this), tokenId);
            nftGiftSet.add(tokenId);
        }
    }

    function withdrawMatter(address to, uint amount) external onlyOwner {
        IERC20Upgradeable(matter).safeTransfer(to, amount);
    }

    function withdrawNFT(address to, uint tokenId) external onlyOwner {
        IERC721Upgradeable(nftGift).safeTransferFrom(address(this), to, tokenId);
        nftGiftSet.remove(tokenId);
    }

    function withdrawAllNFT(address to) external onlyOwner {
        while (nftGiftSet.length() > 0) {
            uint tokenId = nftGiftSet.at(0);
            IERC721Upgradeable(nftGift).safeTransferFrom(address(this), to, tokenId);
            nftGiftSet.remove(tokenId);
        }
        require(nftGiftSet.length() == 0, "withdraw all failed");
    }

    function getGiftLength() public view returns (uint) {
        return nftGiftSet.length();
    }

    function getAllGiftIds() public view returns (uint[] memory) {
        uint[] memory giftIds = new uint[](getGiftLength());
        for (uint i = 0; i < getGiftLength(); i++) {
            giftIds[i] = nftGiftSet.at(i);
        }
        return giftIds;
    }

    modifier canDraw() {
        require(getGiftLength() > 0, "no gift left");
        require(IERC721Upgradeable(nftGift).balanceOf(msg.sender) == 0, "forbid gift owner");
        require(!participated[msg.sender], "forbid re-draw");
        _;
    }
}
