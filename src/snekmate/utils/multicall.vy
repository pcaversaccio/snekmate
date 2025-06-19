# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Multicall Functions
@custom:contract-name multicall
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to batch together multiple `external`
        function calls into one single `external` function call. Please note
        that this contract is written in the most agnostic way possible and
        users should adjust statically allocatable memory to their specific
        needs before deploying it:
        https://github.com/pcaversaccio/snekmate/discussions/82.
        The implementation is inspired by Matt Solomon's implementation here:
        https://github.com/mds1/multicall/blob/main/src/Multicall3.sol.
@custom:security You must ensure that any contract that integrates the `CALL`-based
                 `multicall` and `multicall_value` functions never holds funds after
                 the end of a transaction. Otherwise, any ETH, tokens, or other funds
                 held by this contract can be stolen. Also, never approve a contract
                 that integrates the `CALL`-based functions `multicall` and `multicall_value`
                 to spend your tokens. If you do, anyone can steal your tokens! Eventually,
                 please make sure you understand how `msg.sender` works in `CALL` vs
                 `DELEGATECALL` to the multicall contract, as well as the risks of
                 using `msg.value` in a multicall. To learn more about the latter, see:
                 - https://github.com/runtimeverification/verified-smart-contracts/wiki/List-of-Security-Vulnerabilities#payable-multicall,
                 - https://samczsun.com/two-rights-might-make-a-wrong.
"""


# @dev Stores the 1-byte upper bound for the dynamic arrays.
_DYNARRAY_BOUND: constant(uint8) = max_value(uint8)


# @dev Batch struct for ordinary (i.e. `nonpayable`) function calls.
struct Batch:
    target: address
    allow_failure: bool
    calldata: Bytes[1_024]


# @dev Batch struct for `payable` function calls.
struct BatchValue:
    target: address
    allow_failure: bool
    value: uint256
    calldata: Bytes[1_024]


# @dev Batch struct for ordinary (i.e. `nonpayable`) function calls
# using this contract as destination address.
struct BatchSelf:
    allow_failure: bool
    calldata: Bytes[1_024]


# @dev Result struct for function call results.
struct Result:
    success: bool
    return_data: Bytes[max_value(uint8)]


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@internal
def _multicall(data: DynArray[Batch, _DYNARRAY_BOUND]) -> DynArray[Result, _DYNARRAY_BOUND]:
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
    results: DynArray[Result, _DYNARRAY_BOUND] = []
    success: bool = empty(bool)
    return_data: Bytes[max_value(uint8)] = b""
    for batch: Batch in data:
        if batch.allow_failure:
            success, return_data = raw_call(batch.target, batch.calldata, max_outsize=255, revert_on_failure=False)
        else:
            success = True
            return_data = raw_call(batch.target, batch.calldata, max_outsize=255)
        results.append(Result(success=success, return_data=return_data))
    return results


@internal
@payable
def _multicall_value(data: DynArray[BatchValue, _DYNARRAY_BOUND]) -> DynArray[Result, _DYNARRAY_BOUND]:
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
    results: DynArray[Result, _DYNARRAY_BOUND] = []
    success: bool = empty(bool)
    return_data: Bytes[max_value(uint8)] = b""
    for batch: BatchValue in data:
        msg_value: uint256 = batch.value
        # WARNING: If you expect to hold any funds in a contract that integrates
        # this function, you must ensure that the next line uses checked arithmetic!
        # Please read the contract-level security notice carefully. For further
        # insights also, see the following X thread:
        # https://x.com/Guhu95/status/1736983530343981307.
        value_accumulator = unsafe_add(value_accumulator, msg_value)
        if batch.allow_failure:
            success, return_data = raw_call(
                batch.target, batch.calldata, max_outsize=255, value=msg_value, revert_on_failure=False
            )
        else:
            success = True
            return_data = raw_call(batch.target, batch.calldata, max_outsize=255, value=msg_value)
        results.append(Result(success=success, return_data=return_data))
    assert msg.value == value_accumulator, "multicall: value mismatch"
    return results


@internal
def _multicall_self(data: DynArray[BatchSelf, _DYNARRAY_BOUND]) -> DynArray[Result, _DYNARRAY_BOUND]:
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
    results: DynArray[Result, _DYNARRAY_BOUND] = []
    success: bool = empty(bool)
    return_data: Bytes[max_value(uint8)] = b""
    for batch: BatchSelf in data:
        if batch.allow_failure:
            success, return_data = raw_call(
                self, batch.calldata, max_outsize=255, is_delegate_call=True, revert_on_failure=False
            )
        else:
            success = True
            return_data = raw_call(self, batch.calldata, max_outsize=255, is_delegate_call=True)
        results.append(Result(success=success, return_data=return_data))
    return results


@internal
@view
def _multistaticcall(data: DynArray[Batch, _DYNARRAY_BOUND]) -> DynArray[Result, _DYNARRAY_BOUND]:
    """
    @dev Aggregates static function calls, ensuring that each
         function returns successfully if required.
    @notice It is important to note that an external call
            via `raw_call` does not perform an external code
            size check on the target address.
    @param data The array of `Batch` structs.
    @return DynArray The array of `Result` structs.
    """
    results: DynArray[Result, _DYNARRAY_BOUND] = []
    success: bool = empty(bool)
    return_data: Bytes[max_value(uint8)] = b""
    for batch: Batch in data:
        if batch.allow_failure:
            success, return_data = raw_call(
                batch.target, batch.calldata, max_outsize=255, is_static_call=True, revert_on_failure=False
            )
        else:
            success = True
            return_data = raw_call(batch.target, batch.calldata, max_outsize=255, is_static_call=True)
        results.append(Result(success=success, return_data=return_data))
    return results
