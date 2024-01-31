// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title CallReceiverMock
 * @author pcaversaccio
 * @custom:coauthor cairoeth
 * @notice Forked and adjusted accordingly from here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/mocks/CallReceiverMock.sol.
 * @dev Allows to test receiving state-changing and/or static external calls.
 */
contract CallReceiverMock {
    event MockFunctionCalled();
    event MockFunctionCalledWithArgs(uint256 a, uint256 b);

    string private _retValue = "0xba5ed";

    /**
     * @dev Emits `MockFunctionCalled` and returns the string `0xba5ed`
     * after function invocation.
     * @return string The return string `0xba5ed`.
     */
    function mockFunction() public payable returns (string memory) {
        emit MockFunctionCalled();
        return _retValue;
    }

    /**
     * @dev Emits `MockFunctionCalled` after function invocation.
     */
    function mockFunctionEmptyReturn() public payable {
        emit MockFunctionCalled();
    }

    /**
     * @dev Emits `MockFunctionCalledWithArgs` and returns the string `0xba5ed`
     * after function invocation.
     * @param a The first 32-byte function argument.
     * @param b The second 32-byte function argument.
     * @return string The return string `0xba5ed`.
     */
    function mockFunctionWithArgs(
        uint256 a,
        uint256 b
    ) public payable returns (string memory) {
        emit MockFunctionCalledWithArgs(a, b);
        return _retValue;
    }

    /**
     * @dev Emits `MockFunctionCalled` and returns the string `0xba5ed`
     * after function invocation.
     * @notice `payable` function calls will revert.
     * @return string The return string `0xba5ed`.
     */
    function mockFunctionNonPayable() public returns (string memory) {
        emit MockFunctionCalled();
        return _retValue;
    }

    /**
     * @dev Returns the string `0xba5ed` after function invocation.
     * @notice Special function to mock `STATICCALL` calls.
     * @return string The return string `0xba5ed`.
     */
    function mockStaticFunction() public view returns (string memory) {
        return _retValue;
    }

    /**
     * @dev Reverts with an empty reason.
     */
    function mockFunctionRevertsWithEmptyReason() public payable {
        // solhint-disable-next-line reason-string, custom-errors
        revert();
    }

    /**
     * @dev Reverts with a non-empty reason.
     */
    function mockFunctionRevertsWithReason() public payable {
        // solhint-disable-next-line custom-errors
        revert("CallReceiverMock: reverting");
    }

    /**
     * @dev Returns the string `0xba5ed` after function invocation.
     * @param slot The 32-byte key in storage.
     * @param value The 32-byte value to store at `slot`.
     * @notice Writes to storage slot `slot` with value `value`.
     * @return string The return string `0xba5ed`.
     */
    function mockFunctionWritesStorage(
        bytes32 slot,
        bytes32 value
    ) public payable returns (string memory) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, value)
        }
        return _retValue;
    }
}
