// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../Contract.sol";
import "./utils/vm.sol";

contract ContractTest is DSTest {
  Vm vm;
  MyProxy mp;
  Contract_invariant proxy;
  function setUp() public {
    vm = Vm(HEVM_ADDRESS);
    mp = new MyProxy();
    Contract_invariant _c = new Contract_invariant(Contract_invariant(address(0)));
    mp.setImplementation(address(_c));
    proxy = Contract_invariant(address(mp));
  }
  function testFailIncrement() public {
    proxy.increment();
  }
  function testIncrement() public {
    mp.in_whitelist{value: 1 ether}();
    proxy.increment();
  }
  function testFailWhitelist() public {
    mp.in_whitelist{value: 1 ether}();
    mp.out_whitelist();
  }
  function testWhitelist() public {
    mp.in_whitelist{value: 1 ether}();
    vm.warp(block.timestamp + 100);
    mp.out_whitelist();
  }
  function testFailChallenge() public {
    mp.in_whitelist{value: 1 ether}();
    proxy.increment();
    mp.challenge_pointer();
  }
  function testChallenge() public {
    mp.in_whitelist{value: 1 ether}();
    proxy.increment(); proxy.increment();
    proxy.new_value();
    mp.challenge_pointer();
  }
  function testFailState() public {
    mp.in_whitelist{value: 1 ether}();
    proxy.increment(); //Only one increment
    proxy.new_value();
    mp.challenge_pointer();
  }
  function testFailWhenRedeployed() public {
    mp.in_whitelist{value: 1 ether}();
    proxy.increment(); proxy.increment();
    proxy.new_value();
    mp.redeploy();
    mp.challenge_pointer();
  }
  function testMEV() public {
    mp.in_whitelist{value: 1 ether}();
    proxy.increment(); proxy.increment();
    proxy.new_value();
    /* Time pass, and I forgot to call redeploy */
    vm.warp(block.timestamp + 100000);
    //vm.mev should simulate the mev
    mp.challenge_pointer(); //This should fail with MEV
  }
}
