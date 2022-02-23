// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

library StorageSlot {
  function getAddressAt(bytes32 slot) internal view returns (address a) {
    assembly { a := sload(slot) }
  }
  function setAddressAt(bytes32 slot, address address_) internal {
    assembly { sstore(slot, address_) }
  }
}

contract Contract_invariant {
  /* Both of these values need to be the same thing at all time */
  uint public immutable immutable_value;
  uint public storage_value;
  /* And then the contract has some storage values, here just one. And then it's constructor */
  uint public counter;
  /* A new constructor takes the old contract to set storage values. It should loop over them */
  constructor(Contract_invariant c) {
    uint immut = 0;
    if (address(c) != address(0)) { counter = c.counter(); storage_value = c.storage_value(); immut = c.storage_value(); }
    immutable_value = immut;
  }
  /* The same function, with either the storage value or the immutable value, to compare gas cost */
  function branch_storage(uint c) external returns(int) { if (storage_value == c) return 1; return 2; }
  function branch_immutable(uint c) external returns(int) { if (immutable_value == c) return 1; return 2; }
  /* The contract has some functions that alter its state, and that alter storage_value */
  function increment() external { counter += 1; }
  function new_value() external { if (counter >= 2) { storage_value += 1; counter = 1; } }
}

contract MyProxy {
  bytes32 public constant _IMPL_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
  uint constant required_value = 1 ether;
  uint constant required_delay = 100;
  mapping(address => bool) public whitelist;
  mapping(address => uint) public timestamps;
  address public last_interact;
  //Redeploy the contract with new state
  function redeploy() external {
    Contract_invariant old_c = Contract_invariant(this.getImplementation());
    Contract_invariant c = new Contract_invariant(old_c);
    this.setImplementation(address(c));
  }
  //Anyone can challenge the value of the immutable constant
  function challenge_pointer() external {
    Contract_invariant old_c = Contract_invariant(this.getImplementation());
    old_c.storage_value();
    //Check the value of the immutable variable
    require(old_c.storage_value() != old_c.immutable_value());
    //Now patch the contract
    this.redeploy();
    //Make the payment
    whitelist[last_interact] = false;
    payable(msg.sender).send(required_value); //Maybe not secure, idk
  }
  /* Be whitelisted */
  function in_whitelist() external payable {
    require(msg.value == required_value);
    whitelist[msg.sender] = true;
    timestamps[msg.sender] = block.timestamp;
  }
  /* Get your money back */
  function out_whitelist() external {
    require(whitelist[msg.sender]);
    require(block.timestamp >= timestamps[msg.sender] + required_delay);
    whitelist[msg.sender] = false;
    payable(msg.sender).send(required_value); //Maybe not secure, idk
  }
  /* Probably should be private functions */
  function setImplementation(address implementation_) public {
    StorageSlot.setAddressAt(_IMPL_SLOT, implementation_);
  }
  function getImplementation() public view returns (address) {
    return StorageSlot.getAddressAt(_IMPL_SLOT);
  }
  /* Fallback */
  /* Can call the proxied contract iif you're whitelisted */
  modifier im_fallback {
    if (msg.sender != address(this)) require(whitelist[msg.sender]);
    last_interact = msg.sender;
    _;
  }
  /* Actual fallback functions */
  function branch_storage(uint c) external im_fallback returns(int) { Contract_invariant(this.getImplementation()).branch_storage(c); }
  function branch_immutable(uint c) external im_fallback returns(int) { Contract_invariant(this.getImplementation()).branch_immutable(c); }
  function increment() external im_fallback { Contract_invariant(this.getImplementation()).increment(); }
  function new_value() external im_fallback { Contract_invariant(this.getImplementation()).new_value(); }
  function counter() external im_fallback returns(uint) { return Contract_invariant(this.getImplementation()).counter(); }
  function storage_value() external im_fallback returns(uint) { return Contract_invariant(this.getImplementation()).storage_value(); }
  function immutable_value() external im_fallback returns(uint) { return Contract_invariant(this.getImplementation()).immutable_value(); }
}
