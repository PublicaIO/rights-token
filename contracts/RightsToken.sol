pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './PebbleToken.sol';

contract RightsToken is StandardToken, Ownable {
    uint256 public TOTAL_SHARES = 1000000; // total shares: perhaps should be user-defined, but not for now
    string public name = "";
    address public author = 0x0;
    PebbleToken public pebbles = PebbleToken(0x0);
    uint256 public sharePrice = 0; // the price the author is selling their shares (0 means shares are not being sold)

    uint256 public totalDividends = 0; // total dividends payed by the author to the shareholders so far
    mapping (address => uint256) public balances;
    mapping (address => uint256) public lastTotalDividends;
    mapping (address => mapping (address => uint256)) public allowed;

    function RightsToken(PebbleToken _pebbles) public {
        pebbles = _pebbles;

        totalSupply = TOTAL_SHARES;
        balances[author] = TOTAL_SHARES;
    }

    function setAuthor(address _author) public onlyOwner {
        author = _author;
    }

    function setName(string _name) public onlyOwner {
        name = _name;
    }

    function withdrawTo(address _owner) internal { // remainders -- let remain
        uint256 dividends = totalDividends - lastTotalDividends[_owner];
        uint256 t = dividends * balances[_owner];

        if (t >= dividends) {
            dividends = t / TOTAL_SHARES;
        } else { // too much dividends caused overflow, so calculating more roughly
            dividends = dividends / TOTAL_SHARES * balances[_owner];
        }

        pebbles.transfer(_owner, dividends); // if transfer fails (it should never happen), _owner just loses their dividends
        lastTotalDividends[_owner] = totalDividends;
        Withdrawal(_owner, dividends);
    }

    /**
     * @dev Invest PBLs and gain some shares for the sender themself or for someone else
     * @param _recipient Address of the beneficiary
     * @return Purchased shares
     */
    function buyFor(address _recipient) public returns (uint256 purchasedShares) {
        uint256 cents = pebbles.allowance(msg.sender, this);
        if (cents > pebbles.balanceOf(msg.sender)) {
            cents = pebbles.balanceOf(msg.sender);
        }

        uint256 shares = cents / sharePrice;
        if (shares > balances[author]) {
            shares = balances[author];
        }

        if (balances[_recipient] + shares <= balances[_recipient]) { // shares==0 means shares are not being sold, < means overflow
            return 0;
        }

        uint256 price = shares * sharePrice;
        if (price <= shares) { // sharePrice==0 means shares are not being sold, shares==0 means no deal, < means overflow
            return 0;
        }

        if (!pebbles.transferFrom(msg.sender, author, price)) {
            return 0;
        }

        withdrawTo(author);
        withdrawTo(_recipient);
        balances[author] -= shares;
        balances[_recipient] += shares;
        Purchase(msg.sender, price, _recipient, shares);
        return shares;
    }

    /**
     * @dev Invest PBLs and gain some shares for the sender
     * @return Purchased shares
     */
    function buy() public returns (uint256 purchasedShares) {
        return buyFor(msg.sender);
    }

    /**
     * @dev Invest PBLs and gain some shares for the sender themself or for someone else; additionally check that sharePrice hasn't grown
     * @return Purchased shares
     */
    function safeBuyFor(address _recipient, uint256 _sharePriceLimit) public returns (uint256 purchasedShares) {
        if (sharePrice > _sharePriceLimit) return 0;
        return buyFor(_recipient);
    }

    /**
     * @dev Invest PBLs and gain some shares for the sender; additionally check that sharePrice hasn't grown beyond the given limit
     * @return Purchased shares
     */
    function safeBuy(uint256 _sharePriceLimit) public returns (uint256 purchasedShares) {
        if (sharePrice > _sharePriceLimit) return 0;
        return buyFor(msg.sender);
    }

    /**
     * @dev Pay author's PBL dividents to all investors
     */
    function pay() public {
        require(msg.sender == author);
        uint256 cents = pebbles.allowance(msg.sender, this);
        if (cents > pebbles.balanceOf(msg.sender)) {
            cents = pebbles.balanceOf(msg.sender);
        }

        require(pebbles.transferFrom(msg.sender, this, cents));
        totalDividends += cents;
        require(totalDividends >= cents);
        Payment(cents);
    }

    /**
     * @dev Withdraw investor's PBL dividends accumulated up to now
     * @return Withdrawn PBL cents
     */
    function withdraw() public returns (uint256 withdrawnCents) {
        uint256 cents = pebbles.balanceOf(msg.sender);
        withdrawTo(msg.sender);
        return pebbles.balanceOf(msg.sender) - cents;
    }

    function changePrice(uint256 _newPrice) public {
        require(msg.sender == author);
        sharePrice = _newPrice;
    }

    function() public { // no direct deposits!
        revert();
    }

    event Purchase(address indexed sender, uint256 cents, address indexed recipient, uint256 shares);
    event Payment(uint256 _cents);
    event Withdrawal(address indexed _owner, uint256 _value);
}
