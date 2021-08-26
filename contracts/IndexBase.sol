// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IndexBase {
    struct CreateReq {
        string name;
        // metadata of NFT
        string metadata;
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
    }

    struct Index {
        string name;
        // metadata of NFT
        string metadata;
        // creator of the index
        address creator;
        // address list of underlying token
        address[] underlyingTokens;
        // amount list of underlying token
        uint[] underlyingAmounts;
    }

    mapping(uint => Index) public indices;
    uint public nextNftId;

    function getIndex(uint nftId) public view returns(Index memory) {
        return indices[nftId];
    }

    function addressToString(address account) internal pure returns(string memory) {
        return bytesToString(abi.encodePacked(account));
    }

    function bytesToString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    event IndexCreated(address indexed sender, uint nftId, string name);
    event Mint(address indexed sender, uint nftId, uint nftAmount, uint totalSpend);
    event Burn(address indexed sender, uint nftId, uint nftAmount, uint totalIncome);
    event FeeReceived(uint indexed nftId, address indexed platform, address indexed creator, uint platformFee, uint creatorFee);
}
