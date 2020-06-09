// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0; //changed from >=0.4.21 <0.7.0 before deploying for the first time

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}
