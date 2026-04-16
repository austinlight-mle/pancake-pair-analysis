// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint256 private constant DECIMALS_18 = 1e18;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(42);
        buffer[0] = "0";
        buffer[1] = "x";

        uint256 value = uint256(uint160(addr));
        for (uint256 i = 0; i < 20; i++) {
            uint256 shift = (19 - i) * 8;
            uint8 b = uint8(value >> shift);
            buffer[2 + i * 2] = HEX_DIGITS[b >> 4];
            buffer[3 + i * 2] = HEX_DIGITS[b & 0x0f];
        }

        return string(buffer);
    }

    function toFixed18(uint256 scaledValue) internal pure returns (string memory) {
        uint256 integerPart = scaledValue / DECIMALS_18;
        uint256 fractionalPart = scaledValue % DECIMALS_18;

        bytes memory fraction = new bytes(18);
        for (uint256 i = 18; i > 0; i--) {
            fraction[i - 1] = bytes1(uint8(48 + (fractionalPart % 10)));
            fractionalPart /= 10;
        }

        return
            string(
                abi.encodePacked(
                    toString(integerPart),
                    ".",
                    string(fraction)
                )
            );
    }
}
