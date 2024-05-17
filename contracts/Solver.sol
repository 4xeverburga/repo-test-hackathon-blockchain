// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";

contract EthDomainResolver {
    using BytesUtils for bytes;

    PublicResolver public resolver;

    constructor(address _resolverAddress) {
        resolver = PublicResolver(_resolverAddress);
    }

    function resolveAddressFromDomain(
        string memory domain
    ) public view returns (address) {
        bytes32 node = getNode(domain);
        address payable addrPayable = resolver.addr(node);
        bytes memory addr = abi.encodePacked(addrPayable);
        if (addr.length == 0) {
            return address(0);
        } else {
            return address(bytesToAddress(addr));
        }
    }

    function bytesToAddress(bytes memory b) private pure returns (address) {
        return address(bytesToBytes20(b));
    }

    function bytesToBytes20(bytes memory b) private pure returns (bytes20) {
        require(b.length >= 20, "Input too short");
        bytes20 result;
        assembly {
            result := mload(add(b, 20))
        }
        return result;
    }

    function getNode(string memory name) public pure returns (bytes32) {
        return namehash(name);
    }

    function namehash(string memory name) public pure returns (bytes32) {
        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        if (bytes(name).length == 0) {
            return
                0x0000000000000000000000000000000000000000000000000000000000000000;
        } else {
            bytes memory nameBytes = bytes(name);
            uint8 len = uint8(nameBytes.length);
            for (uint8 i = 0; i < len; i++) {
                node = bytes32(
                    uint256(
                        keccak256(abi.encodePacked(node, bytes1(nameBytes[i])))
                    )
                );
            }
            bytes32 parent = 0x00000000000000000000000000000000000000000000000000000000deadbeef;
            return bytes32(uint256(keccak256(abi.encodePacked(node, parent))));
        }
    }
}
