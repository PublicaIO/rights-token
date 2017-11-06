# Publica `PebbleToken` (or `PBL`) Smart Contract
This is a standard ERC20 Token with no extra functionality for now (later we shall hardcode some scheduling / managing of PBLs, s.t. half PBLs would be initially spread among the investors and another half would be being gradually released to the market during some years).
10^9^ PBLs are minted at once in the constructor. Each PBL is divisible into 1000 "cents".
One can obtain PBLs during ICO or at CoinExchanges which trade ERC20 tokens.

# `RightsToken` Smart Contract
Like the `PebbleToken` smartcontract, `RightsToken` also is an ERC20 Token, but with some extra functionality.
In contrast to the `PebbleToken` which will be unique in the Publica ecosystem, the number of `RightsToken` smartcontracts to be deployed is unlimited. Each `RightsToken` corresponds to one *book* (or any other object of copyright) and maintains functionality for being traded for PBLs.
Sale and dividends of `RightsToken` are held with PBLs only, but one can also trade its tokens (or *shares*) as usual ERC20 Tokens according to the rules of a CoinExchange or any other marketplace.
We describe some core functionality for these smartcontracts, but some extras and some details could be reconsidered for the forthcoming versions of `RightsToken` -- in accordance to the needs and wishes of the *authors*. See e.g. `SafeRightsToken` smartcontract.

## Typical lifecycle and usecases
- An *author* (or any other holder of copyright, or any person on their behalf) deploys a `RightsToken`. See the constructor `RightsToken::RightsToken`.
Initially the *author* holds all the `shares` (or tokens; their number is hardcoded and equal to 1.000.000 for now, but this can be reconsidered at any time for the forthcoming `RightsToken` smartcontracts).
- The *author* decides to start trading their *shares* of the copyright and sets a price for one *share*. See function `RightsToken::changePrice(_newPrice)`.
The *author* then can stop the sale at any time by setting the price back to zero. Note however that all the *shares* bought so far will always remain tradeable at the will of their holders just as standard ERC20 Tokens.
- An *investor* who wishes to obtain some *shares* buys them for PBLs from the *author* (the other way is to buy them via any CoinExchange, but perhaps the standard option is to purchase the *shares* directly from the *author* so as to support the development and promotion of the *book*). This purchase consists of the two steps:
  - First the *investor* obtains some PBLs and permits the `RightsToken` smartcontract to take some of them via the ERC20 allowance mechanism. See function `PebbleToken::approve(_spender,_value)`.
  - Then the *investor* contacts the `RightsToken` and confirms their will to purchase *shares* for all the allowed PBLs. The `RightsToken` then calculates the amount of *shares* which could be sold for the available PBLs, and completes the transfers. See function `RightsToken::buy()`.
  -- It might happen that the *investor* wants to pay their PBLs via some CoinExchange, or to buy the *shares* in favor of someone else, s.t. the PBL-payer's account differs from the *share*-recipients' account. In this case the *investor* should use function `RightsToken::buyFor(_recipient)` and specify the *share*-recipients' account as an argument.
  -- The *investor* might also occure to be afraid that the price of a *share* could unexpectedly increase between these two steps (indeed, the *author* could have called `RightsToken::changePrice` just a moment before the *investor*'s second transaction got deployed). If the investment is big enough, the *investor* could receive far less *shares* than he expected to. In order to prevent such an undesirable scenario the *investor* can call `RightsToken::safeBuy(_sharePriceLimit)` and specify the upper limit of the price of a *share*. If the price is greater than the limit, the deal will be cancelled.
  -- Function `RightsToken::safeBuy(_recipient,_sharePriceLimit)` allows to handle the both above-described issues.
- The *author* has got some revenue from the *book* (after the publishing, for some product placement , via `PublicaReads`, etc) and should spread the income among the shareholders in form of PBLs. This payment consist again of the two steps:
  - First the *author* obtains some PBLs and permits the `RightsToken` smartcontract to take some of them via the ERC20 allowance mechanism. See function `PebbleToken::approve(_spender,_value)`.
  - Then the *author* contacts the `RightsToken` and confirms their will to pay all the allowed PBLs as dividends. The `RightsToken` then takes the available PBLs and keeps them until the shareholders come and claim their rights on the dividends. See function `RightsToken::pay()`. The reason why not to distribute the dividends immediately after the *author*'s payment lies in the architecture of the Ethereum blockchain: such distribution would consume far more gas in comparison with the on-demand withdrawals.
- A shareholder wishes to withdraw their part of dividends (proportionally to their *share*, of course). See function `RightsToken::withdraw()`.
The `RightsToken` transfers to the shareholder the appropriate proportional amount of PBLs as dividends. This could be done each time the *author* makes a payment (see `RightsToken::pay()`) or arbitrarily less often -- so as to have few accumulated withdrawals.
- A shareholder wishes to transfer some of their *shares* to some other shareholder. This might happen when shareholders trade their *shares* on a CoinExchange, when the *author* runs the sale, or when a shareholder just wishes to do it at his own free will. See function `RightsToken::transfer(_to,_value)`. It consists of two major procedures:
  - withdraw all dividends accumulated so far (if any) to both sender and recipient of *shares*;
  - make a traditional ERC20 Token transfer.
The prior withdrawals should be completed before the transfer, because the transfer changes the proportions of the *shares* and thus influences the calculus of the proportions of the forthcoming dividends.
Exactly the same issue applies to the function `RightsToken::transferFrom(_from,_to,_value)`.
- The lifecycle of this smartcontract is potentially unlimited: all shareholders may trade their *shares* get their dividends as long as the *author* gets any revenue from the *book*.

# `SafeRightsToken` Smart Contract
`SafeRightsToken` is a descendant of `RightsToken` which can better handle one important issue.
Many CoinExchanges and other marketplaces employ a variety of different approaches for trading ERC20 tokens. Many of them create some temporary or ad-hoc accounts (sometimes even joint accounts for several shareholders) for keeping the tokens, and then these tokens are accessible only via standard ERC20 interface.
The problem occurs when the *author* makes a payment (see function `RightsToken::pay()`) while some *shares* are being kept on those accounts which are not under direct control of the shareholders. When a shareholder wishes to transfer some of their *shares* to their own account, the prior withdrawal of the dividends will leave the PBLs on the uncontrollable account, and these dividend PBLs perhaps may be lost forever.
In order to avoid such loss and make *shares* be tradeable at any marketplace while keeping all the dividend PBLs for the actual shareholders, we added some extra functionality to the core `RightsToken` smartcontract.
Unlike `RightsToken`, this smartcontract does not automatically trigger withdrawals before transfering *shares*. Instead it transfers *shares* together with proportional amount of claimable dividends.

> Example:
> Investor A buys 200.000 *shares*, and investor B buys 100.000 *shares* (of total 1.000.000 *shares*) of some `SafeRightsToken` smartcontract right after its deployment.
> *Author* gets some revenue and pays 1000 PBLs as dividends (by calling method `pay()`).
> Now investors A and B have not received any dividends, but they can do it at any time: A could get 200 PBLs, and B could get 100 PBLs.
> B calls `withdraw()` to withdraw their dividends and gets 100 PBLs.
> *Author* pays another 500 PBLs as dividends.
> Now A could withdraw 300 PBLs and B could withdraw 50 PBLs.
> A transfers 50.000 *shares* to B.
> This transfer does not trigger automatic withdrawals for both A and B (as it would happen with `RightsToken`), but instead transfers 50.000 (=25% of 200.000) *shares* together with 75 (=25% of 300) PBLs.
> Now both A and B have 150.000 *shares* each, but A could withdraw 225 PBLs and B could withdraw 125 PBLs.

This calculus does not look too sound in case of two persons, but if A was an account hosted by some CoinExchange then it would help not to send PBLs to this account. In order to keep the soundness for the deals among private persons, there is method `SafeRightsToken::setWithdrawable(_withdrawable)` which turns on the automatic withdrawals.
It makes sense to turn it on for each (greedy) private person so as not to transfer their dividend PBLs together with *shares*, but CoinExchanges perhaps won't do that. Say if A was a private person (with `withdrawable=true`) in the example above, then they would automatically get their 300 PBLs just before the *shares* transfer.
