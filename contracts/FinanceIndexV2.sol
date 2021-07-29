// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IndexBase.sol";

contract FinanceIndexV2 is IndexBase, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC1155Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint;

    address public router;
    address public matter;
    address public platform;
    uint public fee;

    function initialize(string memory _uri, address _matter, address _platform, uint _fee) public initializer {
        super.__Ownable_init();
        super.__ReentrancyGuard_init();

        super.__ERC1155_init(_uri);
        matter = _matter;
        platform = _platform;
        fee = _fee;
        router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    }

    function createIndex(CreateReq memory req) external {
        require(req.underlyingTokens.length > 0, "invalid length");
        require(req.underlyingTokens.length == req.underlyingAmounts.length, "invalid length");

        uint nftId = nextNftId++;

        Index memory index;
        index.name = req.name;
        index.metadata = req.metadata;
        index.creator = msg.sender;
        index.underlyingTokens = req.underlyingTokens;
        index.underlyingAmounts = req.underlyingAmounts;
        indices[nftId] = index;

        emit IndexCreated(msg.sender, nftId, index);
    }

    function mint(uint nftId, uint nftAmount) external payable nonReentrant {
        Index memory index = indices[nftId];
        require(index.creator != address(0), "index not exists");
        require(msg.value > fee, "invalid value");
        uint totalInAmount = msg.value.sub(fee);

        uint remaining = totalInAmount;
        for (uint i = 0; i < index.underlyingTokens.length; i++) {
            uint amountOut = index.underlyingAmounts[i];
            address[] memory path = new address[](2);
            path[0] = IUniswapV2Router02(router).WETH();
            path[1] = index.underlyingTokens[i];
            uint deadline = block.timestamp.add(20 minutes);
            uint[] memory amounts = IUniswapV2Router02(router)
                .swapETHForExactTokens{value: remaining}(amountOut, path, address(this), deadline);
            remaining = remaining.sub(amounts[0]);
        }

        super._mint(msg.sender, nftId, nftAmount, "");
        _handleFee(nftId);
        payable(msg.sender).transfer(remaining);

        emit Mint(msg.sender, nftId, nftAmount, totalInAmount.sub(remaining));
    }

        function burn(uint nftId, uint nftAmount, uint[] memory amountOutMins) external nonReentrant {
            Index memory index = indices[nftId];
            require(index.creator != address(0), "index not exists");
            require(index.underlyingTokens.length == amountOutMins.length, "invalid length of amountOutMins");

            uint totalOutAmount = 0;
            for (uint i = 0; i < index.underlyingTokens.length; i++) {
                uint amountIn = index.underlyingAmounts[i];
                address[] memory path = new address[](2);
                path[0] = index.underlyingTokens[i];
                path[1] = IUniswapV2Router02(router).WETH();
                uint deadline = block.timestamp.add(20 minutes);
                IERC20Upgradeable(index.underlyingTokens[i]).approve(router, amountIn);
                uint[] memory amounts = IUniswapV2Router02(router)
                    .swapExactTokensForETH(amountIn, amountOutMins[i], path, address(this), deadline);
                totalOutAmount = totalOutAmount.add(amounts[amounts.length-1]);
            }

            super._burn(msg.sender, nftId, nftAmount);
            payable(msg.sender).transfer(totalOutAmount.sub(fee));
            _handleFee(nftId);

            emit Burn(msg.sender, nftId, nftAmount, totalOutAmount);
        }

    function approveERC20(address token, address spender, uint amount) external onlyOwner {
        IERC20Upgradeable(token).approve(spender, amount);
    }

    function setFee(uint fee_) external onlyOwner {
        fee = fee_;
    }

    function setPlatform(address platform_) external onlyOwner {
        platform = platform_;
    }

    function setUniswapV2Router(address router_) external onlyOwner {
        router = router_;
    }

    function _handleFee(uint nftId) private {
        uint halfFee = fee.div(2);
        if (halfFee > 0) {
            payable(platform).transfer(halfFee);

            uint amountOutMin = 0;
            address[] memory path = new address[](2);
            path[0] = IUniswapV2Router02(router).WETH();
            path[1] = matter;
            uint deadline = block.timestamp.add(20 minutes);
            uint[] memory amounts = IUniswapV2Router02(router)
                .swapExactETHForTokens{value: halfFee}(amountOutMin, path, indices[nftId].creator, deadline);

            emit FeeReceived(nftId, platform, indices[nftId].creator, halfFee, amounts[amounts.length-1]);
        }
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
