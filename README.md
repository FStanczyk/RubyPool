# RubyPool
DeFi project. Decentrealized Exechange protocol.


This project is an Automatic Maker Maker that uses a Constant Product Formula to calculate exchange rates.

By now, rewards for staking (adding tokens to liquidity pools) are calculated in the way:

0.2% fee from all exchchanges are distributed between liquidity providers regarding their shares.
If alice coins are 32% percent of all in the liquidity pool, she will get 32% of the fee.

Nothing from the fee comes to the contract.

Tests are not full, I am still working with them but as long as I tried everything looks fine.
Contract was not audited and it may (surely has) some weaknesses.

In Future: 

 -finish testing with larger group of stakers.
 
 -create web application (React front end).
 
 -Most probably change the system of rewards since it doesn't look gas effective.
