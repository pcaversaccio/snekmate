// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {VyperDeployer} from "utils/VyperDeployer.sol";

import {ICircuitBreaker} from "./interfaces/ICircuitBreaker.sol";

contract CircuitBreakerTest is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    ICircuitBreaker private circuitBreaker;

    address private deployer = address(vyperDeployer);

    function setUp() public {
        circuitBreaker = ICircuitBreaker(
            vyperDeployer.deployContract("src/snekmate/utils/mocks/", "circuit_breaker_mock")
        );
    }

    function testInitialSetup() public view {
        assertTrue(!circuitBreaker.breaker_tripped());
    }

    function testTripSuccess() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true);
        emit ICircuitBreaker.BreakerTripped(deployer);
        circuitBreaker.trip();
        assertTrue(circuitBreaker.breaker_tripped());
        vm.stopPrank();
    }

    function testTripWhileTripped() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true);
        emit ICircuitBreaker.BreakerTripped(deployer);
        circuitBreaker.trip();
        assertTrue(circuitBreaker.breaker_tripped());

        vm.expectRevert(bytes("circuit_breaker: breaker is tripped"));
        circuitBreaker.trip();
        assertTrue(circuitBreaker.breaker_tripped());
        vm.stopPrank();
    }

    function testFuzzTripSuccess(address account) public {
        vm.startPrank(account);
        vm.expectEmit(false, false, false, true);
        emit ICircuitBreaker.BreakerTripped(account);
        circuitBreaker.trip();
        assertTrue(circuitBreaker.breaker_tripped());
        vm.stopPrank();
    }

    function testFuzzTripWhileTripped(address first, address second) public {
        vm.startPrank(first);
        vm.expectEmit(false, false, false, true);
        emit ICircuitBreaker.BreakerTripped(first);
        circuitBreaker.trip();
        assertTrue(circuitBreaker.breaker_tripped());
        vm.stopPrank();

        vm.startPrank(second);
        vm.expectRevert(bytes("circuit_breaker: breaker is tripped"));
        circuitBreaker.trip();
        assertTrue(circuitBreaker.breaker_tripped());
        vm.stopPrank();
    }
}

contract CircuitBreakerInvariants is Test {
    VyperDeployer private vyperDeployer = new VyperDeployer();

    ICircuitBreaker private circuitBreaker;
    CircuitBreakerHandler private circuitBreakerHandler;

    function setUp() public {
        circuitBreaker = ICircuitBreaker(
            vyperDeployer.deployContract("src/snekmate/utils/mocks/", "circuit_breaker_mock")
        );
        circuitBreakerHandler = new CircuitBreakerHandler(circuitBreaker);
        targetContract(address(circuitBreakerHandler));
    }

    function statefulFuzzTripped() public view {
        assertEq(circuitBreaker.breaker_tripped(), circuitBreakerHandler.tripped());
    }
}

contract CircuitBreakerHandler {
    bool public tripped;

    ICircuitBreaker private circuitBreaker;

    constructor(ICircuitBreaker circuitBreaker_) {
        circuitBreaker = circuitBreaker_;
    }

    function trip() public {
        circuitBreaker.trip();
        tripped = true;
    }
}
