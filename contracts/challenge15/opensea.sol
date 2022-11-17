pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;
library ArrayUtils {

    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
        internal
        pure
    {
        require(array.length == desired.length);
        require(array.length == mask.length);

        uint words = array.length / 0x20;
        uint index = words * 0x20;
        assert(index / 0x20 == words);
        uint i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                // commonIndex = (1+i)*32
                let commonIndex := mul(0x20, add(1, i))
                // mask + commonIndex
                let maskValue := mload(add(mask, commonIndex))
                // add(array,commonIndex) = array+commonIndex
                //
                // and(not(maskValue), mload(add(array, commonIndex)) = and(!maskValue,array+commonIndex)) = !maskValue && (array+commonIndex)
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] = ((mask[i] ^ 0xff) & array[i]) | (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(a) == keccak256(b);
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint index, bytes memory source)
        internal
        pure
        returns (uint)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for { } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint index, address source)
        internal
        pure
        returns (uint)
    {
        uint conv = uint(source) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteAddressWord(uint index, address source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint index, uint source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint8Word(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write bytes32 into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteBytes32(uint index, bytes32 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }
}

contract opensea{
    struct Order{
      //  address maker;
        bytes calldata0;
        bytes replacementPattern;    
        bytes extradata;  
    }
    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */  
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }
    Sig sig = Sig(0x1c,0xe5e431c228b21ed60defaf057179db0993f01d933bbb50177b542bd4d7b1a7ef,0x7bafe89e95ee186507b7b2223975bdc40e052f1c362764293d1a27bd2a2c84ba);
    bytes32 private flag;
    uint private secret = 10;

    event display(bytes);
    event display_bytes32(bytes32);
    event display_bool(bool);
    event display_call(bool,bytes);
    event display_address(address);
    event sendflag(bytes32);

    constructor() public {

    }

    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 hash)
    {
        uint size = 800;
        bytes memory array = new bytes(size);
        uint index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, order.calldata0);
        index = ArrayUtils.unsafeWriteBytes(index, order.replacementPattern);
        index = ArrayUtils.unsafeWriteBytes(index, order.extradata);
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }
    function validateOrder(bytes32 hash, Order memory order, Sig memory sig)
        internal
        view
        returns (bool)
    {
        /* Prevent signature malleability and non-standard v values. */
        if (uint256(sig.s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return false;
        }
        if (sig.v != 27 && sig.v != 28) {
            return false;
        }

        /* recover via ECDSA, signed by maker (already verified as non-zero). */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == 0xAfcd13ef950E8Edd869956d56aE4E1382F0a9663) {
            return true;
        }
        return false;
    }
    function buy(address buyer,uint256 price) public returns (bool){
        return true;
    }
 
	function sell() public returns (bytes32){   
        require(msg.sender == address(this),"Wrong msg.sender");
        require(secret == 2,"you need to call check() first~");
		flag = 0x20bb353f6ca259a92ff74a4f127403e699620d4b68d890c130518feef9b3799b;
        emit display_address(msg.sender);
        emit sendflag(flag);
        return flag;
    }
    
    function approved_sign() public returns(bytes32 ){
        address buyer = 0x3245772623316E2562d90E642bb538E48996eC67;
        bytes memory calldata_buy = abi.encodeWithSignature("buy(address,uint256)",buyer,15);
        bytes memory replacementPattern_buy = hex"00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000";
        bytes memory extradata_buy = "";
        Order memory order = Order(calldata_buy,replacementPattern_buy,extradata_buy);  

        emit display(replacementPattern_buy);  
        emit display_bytes32(hashOrder(order));
        emit display_bytes32(hashToSign(order));
        emit display_bool(requireValidOrder(order,sig));

        return hashOrder(order);
    }

    function requireValidOrder(Order memory order, Sig memory sig)
        internal
        returns (bool)
    {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, sig));
        return true;
    }   
    function hashToSign(Order memory order) internal returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashOrder(order)));
    } 

    function check(bytes memory calldata0,bytes memory replacementPattern,bytes memory extradata,bytes memory desired) public returns(bool){
        Order memory order = Order(calldata0,replacementPattern,extradata);
        require(requireValidOrder(order,sig),"fail");
        ArrayUtils.guardedArrayReplace(calldata0,desired,replacementPattern);
        emit display(order.calldata0);
        secret = secret-8;
        
        (bool success, bytes memory returnData) = address(this).call(order.calldata0);     
        emit display_call(success,returnData);
    }
}

