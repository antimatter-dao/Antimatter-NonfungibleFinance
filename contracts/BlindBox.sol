// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract BlindBox is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint;
    using StringsUpgradeable for uint;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    string baseURI;
    address public matter;
    uint public drawDeposit;
    uint public claimAt;
    mapping(address => bool) public participated;
    EnumerableSetUpgradeable.UintSet nftGiftSet;

    event Drew(address indexed sender, uint indexed tokenId);
    event Claimed(address indexed sender, uint indexed nftId, address token, uint amount);

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address matter_,
        uint drawFee_
    ) public initializer {
        super.__Ownable_init();
        super.__ReentrancyGuard_init();
        super.__ERC721_init(name_, symbol_);

        baseURI = baseURI_;
        matter = matter_;
        drawDeposit = drawFee_;
        claimAt = block.timestamp.add(180 days);

        packBox(66);
    }

    function draw() external nonReentrant canDraw {
        IERC20Upgradeable(matter).safeTransferFrom(msg.sender, address(this), drawDeposit);
        participated[msg.sender] = true;

        uint seed = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, blockhash(block.number-1), gasleft())));
        uint index = seed % getGiftLength();
        uint tokenId = nftGiftSet.at(index);
        IERC721Upgradeable(this).safeTransferFrom(address(this), msg.sender, tokenId);
        nftGiftSet.remove(tokenId);

        emit Drew(msg.sender, tokenId);
    }

    function packBox(uint length) internal {
        for (uint i = 0; i < length; i++) {
            uint tokenId = i+1;
            require(!nftGiftSet.contains(tokenId), "duplicated token id");
            IERC721Upgradeable(this).safeTransferFrom(msg.sender, address(this), tokenId);
            nftGiftSet.add(tokenId);
        }
    }

    function claim(uint nftId) external {
        require(claimAt < block.timestamp, "claim not ready");
        IERC20Upgradeable(matter).safeTransfer(msg.sender, drawDeposit);
        super._burn(nftId);

        emit Claimed(msg.sender, nftId, matter, drawDeposit);
    }

    function withdrawMatter(address to, uint amount) external onlyOwner {
        IERC20Upgradeable(matter).safeTransfer(to, amount);
    }

    function withdrawNFT(address to, uint tokenId) external onlyOwner {
        IERC721Upgradeable(this).safeTransferFrom(address(this), to, tokenId);
        nftGiftSet.remove(tokenId);
    }

    function withdrawAllNFT(address to) external onlyOwner {
        while (nftGiftSet.length() > 0) {
            uint tokenId = nftGiftSet.at(0);
            IERC721Upgradeable(this).safeTransferFrom(address(this), to, tokenId);
            nftGiftSet.remove(tokenId);
        }
        require(nftGiftSet.length() == 0, "withdraw all failed");
    }

    function setDrawDeposit(uint drawDeposit_) external onlyOwner {
        drawDeposit = drawDeposit_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0
            ? string(abi.encodePacked(baseURI_, "?nftId=", tokenId.toString(), "&chainId=", block.chainid.toString()))
            : '';
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier canDraw() {
        require(getGiftLength() > 0, "no gift left");
        require(IERC721Upgradeable(this).balanceOf(msg.sender) == 0, "forbid gift owner");
        require(!participated[msg.sender], "forbid re-draw");
        _;
    }
}
