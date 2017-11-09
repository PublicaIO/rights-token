pragma solidity ^0.4.18;

import './PebbleToken.sol';
import './RightsToken.sol';

/** @title Contract for shares management - CoinExchange-safe **/

contract SafeRightsToken is RightsToken {

    mapping (address => bool) public withdrawable;
    mapping (address => uint256) public claimable;

    function SafeRightsToken(PebbleToken _pebbles) public RightsToken(_pebbles) {
        return;
    }

    /**
     * @dev Declare oneself as a beneficiary -- should be called by any rational human
     * @param _withdrawable Whether msg.sender wants to get dividends
     */
    function setWithdrawable(bool _withdrawable) public {
        withdrawable[msg.sender] = _withdrawable;
    }

    function withdrawTo(address _owner) internal { // remainders -- let remain
        uint256 dividends = totalDividends - lastTotalDividends[_owner];
        if (dividends * balances[_owner] >= dividends) {
            dividends = dividends * balances[_owner] / TOTAL_SHARES;
        } else { // too much dividends caused overflow, so calculating more roughly
            dividends = dividends / TOTAL_SHARES * balances[_owner];
        }

        lastTotalDividends[_owner] = totalDividends;
        if (withdrawable[_owner]) {
            if (dividends + claimable[_owner] > dividends) {
                dividends += claimable[_owner];
                claimable[_owner] = 0;
            }
            if (pebbles.transfer(_owner, dividends)) {
                Withdrawal(_owner, dividends);
            }
            // else { claimable[_owner] += dividends; } // if transfer fails, then will try to transfer next time -- this should never happen!
        } else { // perhaps _owner is some CoinExchange, do not give dividends to them
            if (claimable[_owner] + dividends > claimable[_owner]) {
                claimable[_owner] += dividends;
                Reclaim(_owner, _owner, dividends);
            }
        }
    }

    /**
     * @dev Transfer proportion of claims from a sender to a recipient after transfering _value shares
     * @param _from Sender
     * @param _to Recipient
     * @param _value Shares that was just transfered
     */
    function transferClaims(address _from, address _to, uint256 _value) internal {
        uint256 claims = claimable[_from] * _value; // claims = claimable[_from]*_value/(balances[_from]+_value)

        if (claims / claimable[_from] == _value) {
            claims /= balances[_from] + _value;
        } else { // too much claims caused overflow, so calculating more roughly
            claims = claimable[_from] / (balances[_from] + _value) * _value;
        }

        if (claimable[_to] + claims > claimable[_to]) {
            claimable[_to] += claims;
            claimable[_from] -= claims;
            Reclaim(_from, _to, claims);
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (super.transfer(_to, _value)) {
            transferClaims(msg.sender, _to, _value);
            return true;
        }

        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (super.transferFrom(_from, _to, _value)) {
            transferClaims(_from, _to, _value);
            return true;
        }

        return false;
    }

    event Reclaim(address indexed _from, address indexed _to, uint256 _cents);

}
