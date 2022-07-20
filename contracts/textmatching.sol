// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { strings } from "./strings.sol";


/// @title Blockchain string matching in Solidity
/// @author Robert Susik
/// @notice This contract implements classic text matching algorithms. It is written for research purpose to measure gas usage performance. The functions are working algorithms but they return only the number of matches instead of their positions, but it can be easily fixed if necessary.
contract TextMatching {

    using strings for string;
    using strings for strings.slice;

    /// @notice Text maching algorithm from solidity-stringutils library (https://github.com/Arachnid/solidity-stringutils) adapted to search all pattern occurences.
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function strutil(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        uint256 index = 0;
        strings.slice memory text = t.toSlice();
        strings.slice memory pattern = p.toSlice();
        
        for (;text.find(pattern)._len > 0; ) {
            text._len--;
            text._ptr++;
            index++;
        }
        
        emit Log('count', index);
        return (index);
    }



    /// @notice Knuth-Morris-Pratt algorithm
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function kmp(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        uint256[] memory N = new uint256[](m+2);
        uint256 index = 0;
        uint256 i = 0;
        uint256 j = 0;
        uint256 pch = 0;
        uint256 tch = 0;

        // Create failure table
        i = 1;
        j = 0;
        while (i < m) {
            assembly { pch := and(mload(add(add(p, i), 1)), 0x00000000000000000000000000000000000000000000000000000000000000FF) }
            assembly { tch := and(mload(add(add(p, j), 1)), 0x00000000000000000000000000000000000000000000000000000000000000FF) }
            if (pch == tch) {
                N[i++] = ++j;
            } else if (j > 0) {
                j = N[j - 1];
            } else {
                N[i++] = 0;
            }
        }

        // Search
        i = 0;
        j = 0;

        while(i < n) {
            assembly { pch := and(mload(add(add(p, j), 1)), 0x00000000000000000000000000000000000000000000000000000000000000FF) }
            assembly { tch := and(mload(add(add(t, i), 1)), 0x00000000000000000000000000000000000000000000000000000000000000FF) }
            if (pch == tch) {
                if (j == m - 1) {
                    index++;
                    j = N[j-1];
                    continue;
                } else {
                    i++; j++;
                }
            } else {
                if (j > 0) {
                    j = N[j-1];
                } else {
                    i++;
                }
            }
        }

        emit Log('count', index);
        return (index);
    }



    /// @notice Shift-Or algorithm
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function so(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        if (m < 256) {
            return so_lt256(t, n, p, m);
        } else {
            return so_ge256(t, n, p, m);
        }
    }

    /// @notice Shift-Or algorithm (ver. for m<256)
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function so_lt256(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        // uint256[] memory arr = new uint256[](n);
        uint256 index = 0;
        uint256 i = 0;
        uint256 D = 0;
        assembly {
            D := not(0)
        }
        uint256 mm = 1 << (m - 1);
        uint256[] memory B = new uint256[](256);
        for (i = 32; i <= 256*32; i += 32) {
            assembly {
                mstore(add(B, i), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            }
        }
        uint256 v = 0;
        uint256 ptr = 0;
        assembly {
            ptr := add(p, 1)
        }
        for (i = 0; i < m; i++) {
            assembly {
                v := and(mload(ptr), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                ptr := add(ptr, 1)
            }
            B[v] &= ~(1 << i);
        }

        uint256 tptr = 0;
        assembly {
            tptr := add(t, 1)
        }

        for (i = 0; i < n; i++) {
            assembly {
                v := and(mload(tptr), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                tptr := add(tptr, 1)
            }
            D = (D<<1) | B[v];
            if ((D & mm) != mm) {
                // arr[index] = i - m + 1;
                index++;
            }
        }

        emit Log('count', index);

        return (index);
    }


    /// @notice Shift-Or algorithm (ver. for m>=256)
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function so_ge256(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        // uint256[] memory arr = new uint256[](n);
        uint256 index = 0;
        uint256 i = 0;
        uint256 D = 0;
        assembly {
            D := not(0)
        }
        uint256 mm = 1 << (256 - 1);
        uint256[] memory B = new uint256[](256);
        for (i = 32; i <= 256*32; i += 32) {
            assembly {
                mstore(add(B, i), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            }
        }
        uint256 v = 0;
        uint256 ptr = 0;
        bytes32 hh = 0;
        assembly {
            ptr := add(p, 1)
            hh := keccak256(add(p, 32), m)
        }
        for (i = 0; i < 256; i++) {
            assembly {
                v := and(mload(ptr), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                ptr := add(ptr, 1)
            }
            B[v] &= ~(1 << i);
        }

        uint256 tptr = 0;
        assembly {
            tptr := add(t, 1)
        }

        for (i = 0; i < n; i++) {
            assembly {
                v := and(mload(tptr), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                tptr := add(tptr, 1)
            }
            D = (D<<1) | B[v];
            if ((D & mm) != mm) {
                assembly {
                    if eq(hh, keccak256(sub(tptr, 0xe1), m)) { // 256 - 32 + 1
                        index := add(index, 1)
                    }
                }
            }
        }

        emit Log('count', index);

        return (index);
    }

    /// @notice Improved Shift-Or algorithm
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function so2(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        if (m < 256) {
            return so2_lt256(t, n, p, m);
        } else {
            return so2_ge256(t, n, p, m);
        }
    }

    /// @notice Improved Shift-Or algorithm (ver. for m<256)
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function so2_lt256(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        // uint256[] memory arr = new uint256[](n);
        uint256[] memory B = new uint256[](256);
        uint256 index = 0;
        uint256 i = 0;
        uint256 D = 0;
        uint256 mm = 1 << (m - 1);
        uint256 be = 0;
        uint256 v = 0;
        assembly {
            be := add(B, 0x20)
            D := not(0)
            for { i := 0} lt(i, 0x2000) { i := add(i, 0x20)} {
                mstore(add(be, i), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            }
            let ptr := add(p, 1)
            for { i := 0} lt(i, m) { i := add(i, 1)} {
                v := and(mload(ptr), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                let bv := add(be, mul(v, 0x20))
                mstore(
                    bv, 
                    and(mload(bv), not(exp(2, i)))
                )

                ptr := add(ptr, 1)
            }

            let tptr := add(t, 1)
            // let arra := add(arr, 0x20)
            for { i := 0} lt(i, n) { i := add(i, 1)} {
                v := and(mload(tptr), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                let bv := add(be, mul(v, 0x20))
                
                D := or(mul(D, 0x2), mload(bv))

                tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(i, m), 1))
                    // arra := add(arra, 0x20)
                    index := add(index, 1)
                }

            }
        }

        emit Log('count', index);
        return (index);
    }


    /// @notice Improved Shift-Or algorithm (ver. for m>=256)
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function so2_ge256(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        // uint256[] memory arr = new uint256[](n);
        uint256[] memory B = new uint256[](256);
        uint256 index = 0;
        uint256 i = 0;
        uint256 D = 0;
        uint256 mm = 1 << (256 - 1);
        uint256 be = 0;
        uint256 v = 0;
        assembly {
            let hh := keccak256(add(p, 32), m)
            be := add(B, 0x20)
            D := not(0)
            for { i := 0} lt(i, 0x2000) { i := add(i, 0x20)} {
                mstore(add(be, i), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            }
            let ptr := add(p, 1)
            for { i := 0} lt(i, 256) { i := add(i, 1)} {
                v := and(mload(ptr), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                let bv := add(be, mul(v, 0x20))
                mstore(
                    bv, 
                    and(mload(bv), not(exp(2, i)))
                )

                ptr := add(ptr, 1)
            }

            let tptr := add(t, 1)
            // let arra := add(arr, 0x20)
            for { i := 0} lt(i, n) { i := add(i, 1)} {
                v := and(mload(tptr), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                let bv := add(be, mul(v, 0x20))
                
                D := or(mul(D, 0x2), mload(bv))

                tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    if eq(hh, keccak256(sub(tptr, 0xe1), m)) { // 256 - 32 + 1
                        index := add(index, 1)
                    }
                    // mstore(arra, add(sub(i, m), 1))
                    // arra := add(arra, 0x20)
                    // index := add(index, 1)
                }

            }
        }

        emit Log('count', index);
        return (index);
    }


    /// @notice Further Improved Shift-Or algorithm with
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function so3(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        if (m < 256) {
            return so3_lt256(t, n, p, m);
        } else {
            return so3_ge256(t, n, p, m);
        }
    }


    /// @notice Further Improved Shift-Or algorithm (ver. for m<256)
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function so3_lt256(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        // uint256[] memory arr = new uint256[](n);
        uint256[] memory B = new uint256[](256);
        uint256 index = 0;
        uint256 i = 0;
        uint256 D = 0;
        uint256 mm = 1 << (m - 1);
        uint256 be = 0;
        uint256 v = 0;
        assembly {
            be := add(B, 32)
            D := not(0)
            for { i := 0} lt(i, 8192) { i := add(i, 32)} {
                mstore(add(be, i), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            }
            let ptr := add(p, 1)
            for { i := 0} lt(i, m) { i := add(i, 1)} {
                v := and(mload(ptr), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                let bv := add(be, mul(v, 32))
                mstore(
                    bv, 
                    and(mload(bv), not(exp(2, i)))
                )

                ptr := add(ptr, 1)
            }

            let tptr := add(t, 32)
            // let arra := add(arr, 32)
            for { i := 0} lt(i, n) { i := add(i, 32)} {
                let chunk := mload(tptr)
                v := and(div(chunk, 0x100000000000000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                let bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1) // TODO: te inkrementacje mozna usunac
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(i, m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x1000000000000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 1), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x10000000000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 2), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x100000000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 3), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x1000000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 4), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x10000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 5), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x100000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 6), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x1000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 7), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x10000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 8), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x100000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 9), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x1000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 10), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x10000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 11), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x100000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 12), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x1000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 13), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x10000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 14), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x100000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 15), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x1000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 16), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x10000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 17), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x100000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 18), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x1000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 19), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x10000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 20), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x100000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 21), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x1000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 22), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x10000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 23), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x100000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 24), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x1000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 25), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x10000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 26), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x100000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 27), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x1000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 28), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x10000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 29), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(div(chunk, 0x100), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 30), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                v := and(chunk, 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 31), m), 1))
                    // arra := add(arra, 32)
                    index := add(index, 1)
                }

                tptr := add(tptr, 32)

            }
        }

        emit Log('count', index);
        return (index);
    }

    /// @notice Further Improved Shift-Or algorithm (ver. for m>=256)
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function so3_ge256(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        // uint256[] memory arr = new uint256[](n);
        uint256[] memory B = new uint256[](256);
        uint256 index = 0;
        uint256 i = 0;
        uint256 D = 0;
        uint256 mm = 1 << (256 - 1);
        uint256 be = 0;
        uint256 v = 0;
        assembly {
            let hh := keccak256(add(p, 32), m)
            be := add(B, 32)
            D := not(0)
            for { i := 0} lt(i, 8192) { i := add(i, 32)} {
                mstore(add(be, i), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            }
            let ptr := add(p, 1)
            for { i := 0} lt(i, 256) { i := add(i, 1)} {
                v := and(mload(ptr), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                let bv := add(be, mul(v, 32))
                mstore(
                    bv, 
                    and(mload(bv), not(exp(2, i)))
                )

                ptr := add(ptr, 1)
            }

            let tptr := add(t, 32)
            // let arra := add(arr, 32)
            for { i := 0} lt(i, n) { i := add(i, 32)} {
                let chunk := mload(tptr)
                v := and(div(chunk, 0x100000000000000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                let bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(i, m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    // if eq(hh, keccak256(sub(tptr, 256), m)) {
                    if eq(hh, keccak256(sub(tptr, 255), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x1000000000000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 1), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 254), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x10000000000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 2), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 253), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x100000000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 3), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 252), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x1000000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 4), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 251), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x10000000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 5), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 250), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x100000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 6), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 249), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x1000000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 7), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 248), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x10000000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 8), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 247), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x100000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 9), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 246), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x1000000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 10), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 245), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x10000000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 11), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 244), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x100000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 12), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 243), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x1000000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 13), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 242), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x10000000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 14), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 241), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x100000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 15), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 240), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x1000000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 16), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 239), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x10000000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 17), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 238), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x100000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 18), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 237), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x1000000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 19), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 236), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x10000000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 20), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 235), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x100000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 21), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 234), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x1000000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 22), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 233), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x10000000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 23), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 232), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x100000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 24), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 231), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x1000000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 25), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 230), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x10000000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 26), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 229), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x100000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 27), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 228), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x1000000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 28), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 227), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x10000), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 29), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 226), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(div(chunk, 0x100), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 30), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 225), m)) {
                        index := add(index, 1)
                    }
                }

                v := and(chunk, 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 32))
                
                D := or(mul(D, 0x2), mload(bv))

                // tptr := add(tptr, 1)
                if gt( xor(and(D, mm), mm), 0 ) {
                    // mstore(arra, add(sub(add(i, 31), m), 1))
                    // arra := add(arra, 32)
                    // index := mload(sub(tptr, 256))
                    if eq(hh, keccak256(sub(tptr, 224), m)) {
                        index := add(index, 1)
                    }
                }

                tptr := add(tptr, 32)

            }
        }

        emit Log('count', index);
        return (index);
    }

    /// @notice Backward Nondeterministic Dawg Matching algorithm
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function bndm(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        if (m < 256) {
            return bndm_lt256(t, n, p, m);
        } else {
            return bndm_ge256(t, n, p, m);
        }
    }

    /// @notice Backward Nondeterministic Dawg Matching algorithm (ver. for m<256)
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function bndm_lt256(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        // uint256[] memory arr = new uint256[](n);
        uint256[] memory B = new uint256[](256);
        uint256 index = 0;
        uint256 i = 0;
        uint256 D = 0;
        uint256 be = 0;
        uint256 v = 0;
        assembly {
            let j := 0
            let bv := 0
            be := add(B, 0x20)
            for { i := 0} lt(i, 0x2000) { i := add(i, 0x20)} {
                mstore(add(be, i), 0x0000000000000000000000000000000000000000000000000000000000000000)
            }
            let ptr := add(p, 1)
            let s := 1
            for { i := sub(m, 1)} lt(i, m) { i := sub(i, 1)} { // for (i=m-1; i>=0; i--){
                v := and(mload(add(ptr, i)), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 0x20))
                mstore( // B[x[i]] |= s; s <<= 1;
                    bv, 
                    or(mload(bv), s)  //exp(2, sub(sub(m, 1), i)))
                )
                s := mul(s, 2)
            }

            let tptr := add(t, 1)
            // let arra := add(arr, 0x20)
            for { j := 0} lt(j, add(sub(n, m), 1)) { } { // j=0; while (j <= n-m){
                i := sub(m, 1)
                
                let last := m
                D := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                for { } and(lt(i, m), gt(D, 0)) {  } { // while (i>=0 && d!=0) {    not(or(eq(i, 0), eq(D, 0)))
                    v := and(mload(add(tptr, add(j, i))), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                    bv := add(be, mul(v, 0x20))
                    D := and(D, mload(bv)) // d &= B[y[j+i]];
                    i := sub(i, 1)         // i--;

                    if gt(D, 0) { // if (d != 0){
                        if lt(i, sub(m, 0)) {    // if (i >= 0)
                            last := add(i, 1)
                        }
                        if gt(i, sub(m, 1)) { // } else {
                            index := add(index, 1)//add(index, 1)
                            // mstore(arra, j)
                            // arra := add(arra, 32)
                        }
                    }

                    D := mul(D, 2) // d <<= 1;
                    
                }

                j := add(j, last) // add(j, add(i, 2)) // j += last;

            }
        }

        emit Log('count', index);
        return (index);
    }


    /// @notice Backward Nondeterministic Dawg Matching algorithm (ver. for m>=256)
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function bndm_ge256(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        // uint256[] memory arr = new uint256[](n);
        uint256[] memory B = new uint256[](256);
        uint256 index = 0;
        uint256 i = 0;
        uint256 D = 0;
        uint256 be = 0;
        uint256 v = 0;
        assembly {
            let j := 0
            let bv := 0
            be := add(B, 0x20)
            for { i := 0} lt(i, 0x2000) { i := add(i, 0x20)} {
                mstore(add(be, i), 0x0000000000000000000000000000000000000000000000000000000000000000)
            }
            let ptr := add(p, 1)
            let s := 1
            for { i := sub(256, 1)} lt(i, 256) { i := sub(i, 1)} { // for (i=m-1; i>=0; i--){
                v := and(mload(add(ptr, i)), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                bv := add(be, mul(v, 0x20))
                mstore( // B[x[i]] |= s; s <<= 1;
                    bv, 
                    or(mload(bv), s)  //exp(2, sub(sub(m, 1), i)))
                )
                s := mul(s, 2)
            }
            let hh := keccak256(add(p, 32), m)
            let tptr := add(t, 1)
            // let arra := add(arr, 0x20)
            for { j := 0} lt(j, add(sub(n, 256), 1)) { } { // j=0; while (j <= n-m){
                i := sub(256, 1)
                
                let last := 255
                D := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                for { } and(lt(i, 256), gt(D, 0)) {  } { // while (i>=0 && d!=0) {    not(or(eq(i, 0), eq(D, 0)))
                    v := and(mload(add(tptr, add(j, i))), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                    bv := add(be, mul(v, 0x20))
                    D := and(D, mload(bv)) // d &= B[y[j+i]];
                    i := sub(i, 1)         // i--;

                    if gt(D, 0) { // if (d != 0){
                        if lt(i, sub(256, 0)) {    // if (i >= 0)
                            last := add(i, 1)
                        }
                        if gt(i, sub(256, 1)) {
                            v := keccak256(add(tptr, add(j, 31)), m)
                            if eq(v, hh) {
                                index := add(index, 1)
                            }
                        }
                    }

                    D := mul(D, 2) // d <<= 1;
                    
                }

                j := add(j, last) // add(j, add(i, 2)) // j += last;

            }
        }

        emit Log('count', index);
        return (index);
    }
    
    /// @notice Boyer-Moore-Horspool algorithm
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function hor(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {

        // uint256[] memory arr = new uint256[](n);
        uint256[] memory B = new uint256[](256);
        
        uint256 pptr = 0;
        uint256 tptr = 0;
        uint256 i = 0;
        uint256 index = 0;
        uint256 c1 = 0;
        uint256 c2 = 0;
        uint256 be = 0;
        uint256 hh = 0;

        assembly {
            pptr := add(p, 1)
            tptr := add(t, 1)
            be := add(B, 0x20)
        }
        
        for (i = 0; i < 256; i++) {
            B[i] = m;
        }

        for (i = 0; i < m - 1; i++) {
            assembly { // B[pb[i]] = m;
                mstore(
                    add(
                        be, 
                        mul(
                            and(mload(pptr), 0x00000000000000000000000000000000000000000000000000000000000000FF), 
                            32
                        )
                    ),
                    sub(sub(m, i), 1)
                )
                pptr := add(pptr, 1)
            }
        }

        assembly {
            pptr := add(p, 1)
            hh := keccak256(add(p, 32), m)
        }

        i = 0;
        while (i < n - m + 1 ) { // m + 1 to align bits
            assembly {
                c1 := and(mload(sub(add(add(tptr, i), m), 1)), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                c2 := and(mload(add(pptr, sub(m, 1))), 0x00000000000000000000000000000000000000000000000000000000000000FF)
            }
            if (c1 == c2 ) {
                assembly {
                    // let mask := sub(exp(2, mul(sub(m, 1), 8)), 1)
                    // if eq( 
                    //     xor( // memcmp
                    //     and(mload(add(pptr,  sub(m, 2)  )), mask),
                    //     and(mload(add(add(tptr, i), sub(m, 2))), mask)
                    // ) , 0) {
                    //     // let arra := add(arr, 0x20)
                    //     mstore(add(add(arr, 32), mul(index, 32)), i)
                    //     // arra := add(arra, 32)
                    //     index := add(index, 1)
                    // }
                    // index := mload(add(add(tptr, i), 29))
                    if eq(
                        keccak256(add(add(tptr, i), 31), m),
                        hh
                    ) {
                        index := add(index, 1)
                    }
                }
            }
            assembly {
                i := add(i, mload(add(be, mul(c1, 32))))
            }
        }

        emit Log('count', index);
        return (index);
    }


    /// @notice Improved Boyer-Moore-Horspool algorithm
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function hor2(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {

        // uint256[] memory arr = new uint256[](n);
        uint256[] memory B = new uint256[](256);
        
        uint256 pptr = 0;
        uint256 tptr = 0;
        uint256 i = 0;
        uint256 index = 0;
        uint256 c1 = 0;
        uint256 c2 = 0;
        uint256 be = 0;
        uint256 hh = 0;
        // uint256 arra = 0;

        assembly {
            pptr := add(p, 1)
            tptr := add(t, 1)
            be := add(B, 0x20)
            hh := keccak256(add(p, 32), m)
            // arra := add(arr, 0x20)
            let mask := sub(exp(2, mul(sub(m, 1), 8)), 1)

            for { i := 0} lt(i, 256) { i := add(i, 1)} {
                mstore(add(be, mul(i, 32)), m)
            }

            for { i := 0} lt(i, sub(m, 1)) { i := add(i, 1)} {
                mstore( // B[pb[i]] = m;
                    add(
                        be, 
                        mul(
                            and(mload(pptr), 0x00000000000000000000000000000000000000000000000000000000000000FF), 
                            32
                        )
                    ),
                    sub(sub(m, i), 1)
                )
                pptr := add(pptr, 1)
            }
            
            pptr := add(p, 1)

            // mstore(msize(), 2)
            // mstore(add(msize(), 0x20), sub(m, 1))
            // ...
            // mstore(0x40, add(memOffset, 0x60))
            // let m_minus_one := sub(m, 1)
            let n_minus_n_plus_one := add(sub(n, m), 1)

            for {i := 0} lt( i, n_minus_n_plus_one) {} {
                c1 := and(mload(sub(add(add(tptr, i), m), 1)), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                c2 := and(mload(add(pptr, sub(m, 1))), 0x00000000000000000000000000000000000000000000000000000000000000FF)
                if eq(c1, c2) {
                    // if eq( // only for m < 32 (marginaly cheaper in some cases)
                    //     xor( // memcmp
                    //     and(mload(add(pptr,  sub(m, 2)  )), mask),
                    //     and(mload(add(add(tptr, i), sub(m, 2))), mask)
                    // ) , 0) {
                    //     // let arra := add(arr, 0x20)
                    //     // mstore(arra, i)
                    //     // arra := add(arra, 32)
                    //     index := add(index, 1)
                    // }
                    if eq(
                        keccak256(add(add(tptr, i), 31), m),
                        hh
                    ) {
                        index := add(index, 1)
                    }
                }
                i := add(i, mload(add(be, mul(c1, 32))))
            }
        }

        emit Log('count', index);
        // emit Log('pos', arr[0]);
        // for (i = 0; i < 2; i ++) {
        //     emit Log('pos', arr[i]);
        // }

        return (index);
    }

    /// @notice Naive pattern matching algorithm (in pure Solidity)
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function naive(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        bytes memory tb = bytes(t);
        bytes memory pb = bytes(p);
        // uint256[] memory arr = new uint256[](n);
        uint256 index = 0;
        uint256 i = 0;
        uint256 j = 0;
        
        for (i = 0; i < n - m + 1; i++) {
            for (j = 0; j < m; j++) {
                if(tb[i + j] != pb[j]) {
                    break;
                }
            }
            if(j == m) {
                // arr[index] = i;
                index++;
            }
        }

        emit Log('count', index);
        return (index);
    }

    /// @notice Improved Naive pattern matching algorithm
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function naive2(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        // uint256[] memory arr = new uint256[](n);
        uint256 index = 0;
        uint256 i = 0;
        uint256 j = 0;
        uint8 c1 = 0;
        uint8 c2 = 0;
        
        for (i = 0; i < n - m + 1; i++) {
            assembly {
                for {j := 0 } lt(j, m) {j := add(j, 1) } {
                    c1 := mload(add(t, add(add(i, 1), j)))
                    c2 := mload(add(p, add(j, 1)))
                    if and(xor(c1, c2), 0x00000000000000000000000000000000000000000000000000000000000000FF) {
                        break
                    }
                }
            }
            if(j == m) {
                // arr[index] = i;
                index++;
            }
        }

        emit Log('count', index);
        // emit Log('pos', arr[0]);

        return (index);
    }

    event Log(string s, uint256 _v);
    event LogByte(string s, bytes1 _v);
    event LogData(uint8 c1, uint8 c2, uint256 i, uint256 j);
    event Log8(string s, uint8 _v);
    event LogStr(string v);
    event LogArr(uint256[] v);

    uint256 constant base = 256;



    /// @notice Rabin-Karp algorithm with rolling hash
    /// @param t text
    /// @param n text length
    /// @param p pattern
    /// @param m pattern length
    /// @return number of pattern occurences in text
    function rk(string memory t, uint256 n, string memory p, uint256 m) public payable returns (uint256) {
        uint256 ph = 0;
        uint256 th = 0;
        uint256 i = 0;
        uint256 index = 0;
        uint8 b = 0;
        uint8 c = 0;
        uint256 hh = 0;
        uint256 g = base;

        for (i = 0; i < m-2; i++) {
            assembly { g := mul( g, base) }
        }
        
        for (i = 0; i < m; i++) {
            assembly { b := and(mload(add(p, add(i, 1))), 0x00000000000000000000000000000000000000000000000000000000000000FF) }
            assembly { ph := add(mul( ph, base), b) }
        }

        assembly { hh := keccak256(add(p, 32), m) }

        for (i = 0; i < m; i++) {
            assembly { b := and(mload(add(t, add(i, 1))), 0x00000000000000000000000000000000000000000000000000000000000000FF) }
            assembly { th := add(mul( th, base), b) }
        }

        for (i = (m); i < n + 1; i++) {
            if (ph == th) {
                assembly {
                    if eq(
                        keccak256(add(t, sub(add(i, 32), m)), m),
                        hh
                    ) {
                        index := add(index, 1)
                    }
                }
            }
            
            assembly { b := and(mload(add(t, add(i, 1))), 0x00000000000000000000000000000000000000000000000000000000000000FF) }
            assembly { c := and(mload(add(t, sub(add(i, 1), m))), 0x00000000000000000000000000000000000000000000000000000000000000FF) }
            assembly { th := add(mul(sub( th, mul(g, c)), base), b) }
        }

        if (ph == th) {
            assembly {
                if eq(
                    keccak256(add(t, sub(add(i, 32), m)), m),
                    hh
                ) {
                    index := add(index, 1)
                }
            }
        }

        emit Log('count', index);

        return (index);
    }


}
