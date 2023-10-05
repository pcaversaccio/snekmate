# pragma version ^0.3.10
"""
@title Multicall Functions
@custom:contract-name Multicall
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to batch together multiple external
        function calls into one single external function call. Please note
        that this contract is written in the most agnostic way possible and
        users should adjust statically allocatable memory to their specific
        needs before deploying it:
        https://github.com/pcaversaccio/snekmate/discussions/82.
        The implementation is inspired by Matt Solomon's implementation here:
        https://github.com/mds1/multicall/blob/main/src/Multicall3.sol.
@custom:security Make sure you understand how `msg.sender` works in `CALL` vs
                 `DELEGATECALL` to the multicall contract, as well as the risks
                 of using `msg.value` in a multicall. To learn more about the latter, see:
                 - https://github.com/runtimeverification/verified-smart-contracts/wiki/List-of-Security-Vulnerabilities#payable-multicall,
                 - https://samczsun.com/two-rights-might-make-a-wrong.
"""


# @dev Batch struct for ordinary (i.e. `nonpayable`) function calls.
struct Batch:
    target: address
    allow_failure: bool
    call_data: Bytes[max_value(uint16)]


# @dev Batch struct for `payable` function calls.
struct BatchValue:
    target: address
    allow_failure: bool
    value: uint256
    call_data: Bytes[max_value(uint16)]


# @dev Batch struct for ordinary (i.e. `nonpayable`) function calls
# using this contract as destination address.
struct BatchSelf:
    allow_failure: bool
    call_data: Bytes[max_value(uint16)]


# @dev Batch struct for `payable` function calls using this contract
# as destination address. 
struct BatchValueSelf:
    allow_failure: bool
    value: uint256
    call_data: Bytes[max_value(uint16)]


# @dev Result struct for function call results.
struct Result:
    success: bool
    return_data: Bytes[max_value(uint8)]


@external
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@external
def multicall(data: DynArray[Batch, max_value(uint8)]) -> DynArray[Result, max_value(uint8)]:
    """
    @dev Aggregates function calls, ensuring that each
         function returns successfully if required.
         Since this function uses `CALL`, the `msg.sender`
         will be the multicall contract itself.
    @notice It is important to note that an external call
            via `raw_call` does not perform an external code
            size check on the target address.
    @param data The array of `Batch` structs.
    @return DynArray The array of `Result` structs.
    """
    results: DynArray[Result, max_value(uint8)] = []
    return_data: Bytes[max_value(uint8)] = b""
    success: bool = empty(bool)
    for batch in data:
        if (batch.allow_failure == False):
            return_data = raw_call(batch.target, batch.call_data, max_outsize=255)
            success = True
            results.append(Result({success: success, return_data: return_data}))
        else:
            success, return_data = \
                raw_call(batch.target, batch.call_data, max_outsize=255, revert_on_failure=False)
            results.append(Result({success: success, return_data: return_data}))
    return results


@external
@payable
def multicall_value(data: DynArray[BatchValue, max_value(uint8)]) -> DynArray[Result, max_value(uint8)]:
    """
    @dev Aggregates function calls with a `msg.value`,
         ensuring that each function returns successfully
         if required. Since this function uses `CALL`,
         the `msg.sender` will be the multicall contract
         itself.
    @notice It is important to note that an external call
            via `raw_call` does not perform an external code
            size check on the target address.
    @param data The array of `BatchValue` structs.
    @return DynArray The array of `Result` structs.
    """
    value_accumulator: uint256 = empty(uint256)
    results: DynArray[Result, max_value(uint8)] = []
    return_data: Bytes[max_value(uint8)] = b""
    success: bool = empty(bool)
    for batch in data:
        msg_value: uint256 = batch.value
        value_accumulator = unsafe_add(value_accumulator, msg_value)
        if (batch.allow_failure == False):
            return_data = raw_call(batch.target, batch.call_data, max_outsize=255, value=msg_value)
            success = True
            results.append(Result({success: success, return_data: return_data}))
        else:
            success, return_data = \
                raw_call(batch.target, batch.call_data, max_outsize=255, value=msg_value, revert_on_failure=False)
            results.append(Result({success: success, return_data: return_data}))
    assert msg.value == value_accumulator, "Multicall: value mismatch"
    return results


@external
def multicall_self(data: DynArray[BatchSelf, max_value(uint8)]) -> DynArray[Result, max_value(uint8)]:
    """
    @dev Aggregates function calls using `DELEGATECALL`,
         ensuring that each function returns successfully
         if required. Since this function uses `DELEGATECALL`,
         the `msg.sender` remains the same account that
         invoked the function `multicall_self` in the first place.
    @notice Developers can include this function in their own
            contract so that users can submit multiple function
            calls in one transaction. Since the `msg.sender` is
            preserved, it's equivalent to sending multiple transactions
            from an EOA (externally-owned account, i.e. non-contract account).

            Furthermore, it is important to note that an external
            call via `raw_call` does not perform an external code
            size check on the target address.
    @param data The array of `BatchSelf` structs.
    @return DynArray The array of `Result` structs.
    """
    results: DynArray[Result, max_value(uint8)] = []
    return_data: Bytes[max_value(uint8)] = b""
    success: bool = empty(bool)
    for batch in data:
        if (batch.allow_failure == False):
            return_data = raw_call(self, batch.call_data, max_outsize=255, is_delegate_call=True)
            success = True
            results.append(Result({success: success, return_data: return_data}))
        else:
            success, return_data = \
                raw_call(self, batch.call_data, max_outsize=255, is_delegate_call=True, revert_on_failure=False)
            results.append(Result({success: success, return_data: return_data}))
    return results


@external
@payable
def multicall_value_self(data: DynArray[BatchValueSelf, max_value(uint8)]) -> DynArray[Result, max_value(uint8)]:
    """
    @dev Aggregates function calls with a `msg.value` using
         `DELEGATECALL`, ensuring that each function returns
         successfully if required. Since this function uses
         `DELEGATECALL`, the `msg.sender` remains the same
         account that invoked the function `multicall_value_self`
         in the first place.
    @notice Developers can include this function in their own
            contract so that users can submit multiple function
            calls in one transaction. Since the `msg.sender` is
            preserved, it's equivalent to sending multiple transactions
            from an EOA (externally-owned account, i.e. non-contract account).

            Furthermore, it is important to note that an external
            call via `raw_call` does not perform an external code
            size check on the target address.
    @param data The array of `BatchValueSelf` structs.
    @return DynArray The array of `Result` structs.
    """
    value_accumulator: uint256 = empty(uint256)
    results: DynArray[Result, max_value(uint8)] = []
    return_data: Bytes[max_value(uint8)] = b""
    success: bool = empty(bool)
    for batch in data:
        msg_value: uint256 = batch.value
        value_accumulator = unsafe_add(value_accumulator, msg_value)
        if (batch.allow_failure == False):
            return_data = raw_call(self, batch.call_data, max_outsize=255, value=msg_value, is_delegate_call=True)
            success = True
            results.append(Result({success: success, return_data: return_data}))
        else:
            success, return_data = \
                raw_call(self, batch.call_data, max_outsize=255, value=msg_value, is_delegate_call=True, revert_on_failure=False)
            results.append(Result({success: success, return_data: return_data}))
    assert msg.value == value_accumulator, "Multicall: value mismatch"
    return results


@external
@view
def multistaticcall(data: DynArray[Batch, max_value(uint8)]) -> DynArray[Result, max_value(uint8)]:
    """
    @dev Aggregates static function calls, ensuring that each
         function returns successfully if required.
    @notice It is important to note that an external call
            via `raw_call` does not perform an external code
            size check on the target address.
    @param data The array of `Batch` structs.
    @return DynArray The array of `Result` structs.
    """
    results: DynArray[Result, max_value(uint8)] = []
    return_data: Bytes[max_value(uint8)] = b""
    success: bool = empty(bool)
    for batch in data:
        if (batch.allow_failure == False):
            return_data = raw_call(batch.target, batch.call_data, max_outsize=255, is_static_call=True)
            success = True
            results.append(Result({success: success, return_data: return_data}))
        else:
            success, return_data = \
                raw_call(batch.target, batch.call_data, max_outsize=255, is_static_call=True, revert_on_failure=False)
            results.append(Result({success: success, return_data: return_data}))
    return results
