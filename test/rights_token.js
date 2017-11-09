
var PebbleToken = artifacts.require("PebbleToken");
var RightsToken = artifacts.require("SafeRightsToken");

contract('RightsToken', function(accounts) {
  let owner = accounts[0];
  let author = accounts[1];
  let buyer = accounts[2];
  let pebbleToken;
  let rightsToken;

  beforeEach(async function() {
    pebbleToken = await PebbleToken.deployed();
    await pebbleToken.transfer(buyer, 1000);

    rightsToken = await RightsToken.deployed();
    await rightsToken.setAuthor(author);
  });

  it('prerequisite: make sure buyer has some pebbles', async function() {
    let buyerBalance = await pebbleToken.balanceOf(buyer);

    assert.equal(buyerBalance, 1000);
  });

  it('author can change share price', async function() {
    let prevPrice = await rightsToken.sharePrice.call();
    await rightsToken.changePrice(prevPrice + 1, {from: author});
    let newPrice = await rightsToken.sharePrice.call();

    assert.notEqual(prevPrice, newPrice);
  });
});
