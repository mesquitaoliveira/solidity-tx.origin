// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
contract LojaAlice {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function Comprar() public payable {}

    function transfer(address _to, uint256 amount) public {
        require(tx.origin == owner, "Not owner");
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function getBalance()public view returns (uint256) {
        return address(this).balance;
    }
}
