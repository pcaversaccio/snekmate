# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title `multicall` Module Reference Implementation
@custom:contract-name multicall_mock
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
"""


# @dev We import the `multicall` module.
# @notice Please note that the `multicall` module
# is stateless and therefore does not require
# the `initializes` keyword for initialisation.
from .. import multicall as mc


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@external
def multicall(data: DynArray[mc.Batch, mc._DYNARRAY_BOUND]) -> DynArray[mc.Result, mc._DYNARRAY_BOUND]:
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
    return mc._multicall(data)


@external
@payable
def multicall_value(data: DynArray[mc.BatchValue, mc._DYNARRAY_BOUND]) -> DynArray[mc.Result, mc._DYNARRAY_BOUND]:
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
    return mc._multicall_value(data)


@external
def multicall_self(data: DynArray[mc.BatchSelf, mc._DYNARRAY_BOUND]) -> DynArray[mc.Result, mc._DYNARRAY_BOUND]:
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
    return mc._multicall_self(data)


@external
@view
def multistaticcall(data: DynArray[mc.Batch, mc._DYNARRAY_BOUND]) -> DynArray[mc.Result, mc._DYNARRAY_BOUND]:
    """
    @dev Aggregates static function calls, ensuring that each
         function returns successfully if required.
    @notice It is important to note that an external call
            via `raw_call` does not perform an external code
            size check on the target address.
    @param data The array of `Batch` structs.
    @return DynArray The array of `Result` structs.
    """
    return mc._multistaticcall(data)
