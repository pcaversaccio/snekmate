# @version ^0.3.6
"""
@title Multicall Functions
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice These functions can be used to batch together multiple external
        function calls into one single external function call.
        The implementation is inspired by Matt Solomon's implementation here:
        https://github.com/mds1/multicall/blob/master/src/Multicall3.sol.
"""


# @dev Batch struct for ordinary function calls. 
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


# @dev Result struct for function call results.
struct Result:
    success: bool
    return_data: Bytes[max_value(uint16)]


@external
def multicall(data: DynArray[Batch, max_value(uint16)]) -> DynArray[Result, max_value(uint16)]:
    """
    @dev Aggregates function calls, ensuring that each
         function returns successfully if required.
    @param data The array of `Batch` structs.
    @return DynArray The array of `Result` structs.
    """
    length: uint256 = len(data)
    results: DynArray[Result, max_value(uint16)] = []
    for i in data:
        idx: uint256 = 0
        if (i.allow_failure == False):
            results[idx].return_data = raw_call(i.target, i.call_data, max_outsize=max_value(uint16))
            results[idx].success = True
            idx += 1
        else:
            results[idx].success, results[idx].return_data = \
                raw_call(i.target, i.call_data, max_outsize=max_value(uint16), revert_on_failure=False)
            idx += 1
    return results


@external
@payable
def multicall_value(data: DynArray[BatchValue, max_value(uint16)]) -> DynArray[Result, max_value(uint16)]:
    """
    @dev Aggregates function calls with a `msg.value`,
         ensuring that each function returns successfully
         if required.
    @param data The array of `BatchValue` structs.
    @return DynArray The array of `Result` structs.
    """
    value_accumulator: uint256 = 0
    length: uint256 = len(data)
    results: DynArray[Result, max_value(uint16)] = []
    for i in data:
        idx: uint256 = 0
        msg_value: uint256 = i.value
        value_accumulator = unsafe_add(value_accumulator, msg_value)
        if (i.allow_failure == False):
            results[idx].return_data = raw_call(i.target, i.call_data, max_outsize=max_value(uint16), value=msg_value)
            results[idx].success = True
            idx += 1
        else:
            results[idx].success, results[idx].return_data = \
                raw_call(i.target, i.call_data, max_outsize=max_value(uint16), value=msg_value, revert_on_failure=False)
            idx += 1
    assert msg.value == value_accumulator, "Multicall: value mismatch"
    return results


@external
def multicall_self(data: DynArray[Batch, max_value(uint16)]) -> DynArray[Result, max_value(uint16)]:
    """
    @dev Aggregates function calls using `DELEGATECALL`,
         ensuring that each function returns successfully
         if required.
    @param data The array of `Batch` structs.
    @return DynArray The array of `Result` structs.
    """
    length: uint256 = len(data)
    results: DynArray[Result, max_value(uint16)] = []
    for i in data:
        idx: uint256 = 0
        if (i.allow_failure == False):
            results[idx].return_data = raw_call(i.target, i.call_data, max_outsize=max_value(uint16), is_delegate_call=True)
            results[idx].success = True
            idx += 1
        else:
            results[idx].success, results[idx].return_data = \
                raw_call(i.target, i.call_data, max_outsize=max_value(uint16), is_delegate_call=True, revert_on_failure=False)
            idx += 1
    return results


@external
@payable
def multicall_value_self(data: DynArray[BatchValue, max_value(uint16)]) -> DynArray[Result, max_value(uint16)]:
    """
    @dev Aggregates function calls with a `msg.value`
         using `DELEGATECALL`, ensuring that each
         function returns successfully if required.
    @param data The array of `BatchValue` structs.
    @return DynArray The array of `Result` structs.
    """
    value_accumulator: uint256 = 0
    length: uint256 = len(data)
    results: DynArray[Result, max_value(uint16)] = []
    for i in data:
        idx: uint256 = 0
        msg_value: uint256 = i.value
        value_accumulator = unsafe_add(value_accumulator, msg_value)
        if (i.allow_failure == False):
            results[idx].return_data = raw_call(i.target, i.call_data, max_outsize=max_value(uint16), value=msg_value, is_delegate_call=True)
            results[idx].success = True
            idx += 1
        else:
            results[idx].success, results[idx].return_data = \
                raw_call(i.target, i.call_data, max_outsize=max_value(uint16), value=msg_value, is_delegate_call=True, revert_on_failure=False)
            idx += 1
    assert msg.value == value_accumulator, "Multicall: value mismatch"
    return results


@external
@pure
def multistaticcall(data: DynArray[BatchValue, max_value(uint16)]) -> DynArray[Result, max_value(uint16)]:
    """
    @dev Aggregates static function calls, ensuring that each
         function returns successfully if required.
    @param data The array of `Batch` structs.
    @return DynArray The array of `Result` structs.
    """
    length: uint256 = len(data)
    results: DynArray[Result, max_value(uint16)] = []
    for i in data:
        idx: uint256 = 0
        if (i.allow_failure == False):
            results[idx].return_data = raw_call(i.target, i.call_data, max_outsize=max_value(uint16), is_static_call=True)
            results[idx].success = True
            idx += 1
        else:
            results[idx].success, results[idx].return_data = \
                raw_call(i.target, i.call_data, max_outsize=max_value(uint16), is_static_call=True, revert_on_failure=False)
            idx += 1
    return results
