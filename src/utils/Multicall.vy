# @version ^0.3.6
"""
@title Multicall Functions
@license GNU Affero General Public License v3.0
@author pcaversaccio
@notice TBD
"""


struct Batch:
    target: address
    allow_failure: bool
    value: uint256
    call_data: Bytes[max_value(uint16)]


struct Result:
    success: bool
    return_data: Bytes[max_value(uint16)]


@external
@payable
def multicall(data: DynArray[Batch, max_value(uint16)]) -> DynArray[Result, max_value(uint16)]:
    value_accumulator: uint256 = 0
    length: uint256 = len(data)
    results: DynArray[Result, max_value(uint16)] = []
    for i in data:
        counter: uint256 = 0
        msg_value: uint256 = i.value
        value_accumulator = unsafe_add(value_accumulator, msg_value)
        if (i.allow_failure == False):
            results[counter].return_data = raw_call(i.target, i.call_data, max_outsize=max_value(uint16), value=msg_value)
            results[counter].success = True
            counter += 1
        else:
            results[counter].success, results[counter].return_data = \
                raw_call(i.target, i.call_data, max_outsize=max_value(uint16), value=msg_value, revert_on_failure=False)
            counter += 1
    assert msg.value == value_accumulator, "Multicall: value mismatch"
    return results
