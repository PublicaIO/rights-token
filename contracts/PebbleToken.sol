pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';

contract PebbleToken is StandardToken {
    string public name = "Pebbles";
    string public symbol = "PBL";
    uint256 constant TOTAL_SUPPLY = 10 ** 9;
    uint256 constant CENTS_PER_PEBBLE = 1 ** 3;

    function PebbleToken() {
        totalSupply = TOTAL_SUPPLY;
        balances[msg.sender] = TOTAL_SUPPLY;
    }

    function() public { // no direct purchases for now
        revert();
    }
}
