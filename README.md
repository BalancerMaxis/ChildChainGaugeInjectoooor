# periodicRewardsInjector

## Intro
The ChildChainGaugeInjector is designed to manage weekly injections of non-bal tokens into  Child Chain layer zero gauges based on a predefined keeper using chainlink keepers.
It is meant to be deployed for a single ERC20 reward token, but can manage any number of gauges for that token.

It allows the configured admin to define a list of schedules, and then can be operated by [Chainlink Automation](https://automation.chain.link/).

Methods exist to define new schedules either without validation (overwrite whatever is there), and with validation (ensure current schedules are finished and there is the correct balance to complete the proposed schedule).

The contract also includes functionality for the owner to sweep ERC20 tokens and gas tokens in order to allow the contract to be easily decommissioned should there be any issues or it is no longer needed.


### The Child Chain Gauge runs on weekly epochs:

- Only the defined distributor for a given token may inject rewards.  
- The injector uses changes to period_finish on the gauge contract to understand epochs and runs once per epoch as early as possible.

This contract is intended to operate as the distributor, and has functionality to return distributorship to the owner

### The watchlist

The injector runs using a watch list.  The watch list is defined as the tuple of [gaugeAddress, amount, maxTopups].

For every streamer address, assuming a sufficent token balance, the injector will inject the specified amounts each epoch until it has done so maxTopups time.

List changes are atomic.  A new list replaces an old one.

This list is defined by calling the function `setRecipientList(streamerAddresses, amountsPerPeriod, maxPeriods)` on the deployed injector.

`setValidatedRecipientList(streamerAddresses, amountsPerPeriod, maxPeriods)` can also be called.  It checks that there are running programs that still have periods to pay out, and that the balance in the injector contract is sufficient to pay the full new program.  Note that it will not catch if there are too many tokens to prevent griefing, so if you want to keep exact balances you should confirm that the balance is 0 or sweep it before running `setValidatedRecipientList`.  It will revert if these conditions are not met, and set a new list if they are. 


### Balances
The injector uses ERC20 balances in the injector contract to pay rewards.  The upkeeps will not run if there is not enough tokens in the contract to satisfy all currently due injections.

The following usage pattern can be followed to maintain proper balances at all times:

#### When setting schedule
- Use `setValidatedRecipientList(streamerAddresses, amountsPerPeriod, maxPeriods)`
- Ensure that there is 0 token balance in the contract
- Transfer the exact amount required for the entire program (all streams, all amounts, all periods)
- Do not load the next schedule until the current one is complete.


#### To abort a schedule midway through or reset
- Use `setRecipientList([], [], [])` to clear the list.
- Use `sweep(token)` to transfer any remaining tokens back to the owner.
- Now you can use the normal process to set a new schedule.

## Deployment and operations

### Dependancies/environment setup
This repo requires eth-brownie to work.  Both versions 1.17 and 1.19 have been tested.  The contracts were developed using python3.9 and brownie 1.19.

On a mac with homebrew from the root of this repo run the following commands to install brownie and run the tests:
```bash
export WEB3_INFURA_PROJECT_ID=<your infura key>
export ETHERSCAN_TOKEN=<your etherscan API token> 
brew install python@3.9
python3.9 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
brownie test
```
Note that ETHERSCAN_TOKEN can be changed to whatever network you are operating on, for example:

 - POLYGONSCAN_TOKEN
 - OPTIMISMSCAN_TOKEN
 - ABRISCAN_TOKEN
 - ZKEVMSCAN_TOKEN
 - GNOSISSCAN_TOKEN

Note that this installs a version of brownie 1.19.3 modified/maintained by tritium to include the extra chains Balancer operates on. 

You will need to have an account setup in brownie with gas.  You can read more about brownie accounts [here](https://eth-brownie.readthedocs.io/en/v1.19.0/core-accounts.html).

You can create a new address with
`brownie accounts new <id>` where id is the string you will use to identify the account.
You can view the account using `brownie accounts list`.  You will need to transfer some gas tokens to this address on the account you want to deploy on.

Read more about brownie accounts in the docs to learn how to import/use an account you already have a private key for.

### Deploying an injector
Deployment is done using the deploy script found in [scripts/deploy.py](scripts/deploy.py).  You will need to edit it and change the following

- update account to somehow load the account with gas created.  If you used a new account you can put your id in the quotes.
- update ADMIN_ADDRESS to point to the address that should admin the injector
- update UPKEEP_CALLER_ADDRESS to point to the address of the chainlink registry keeper who will be calling this address.
- update TOKEN_ADDRESS to be the token you want to be handled by this contract (note that the Balancer Maxi's must whitelist a token on a gauge before it can be distributed).
- Ensure that the correct contract address for the chain you are deploying too exists in LINK_BY_CHAIN
- Ensure the correct chainlink registry address for the cain you are deploying to exists in REGISTRY_BY_CHAIN. [Chainlink Docs])(https://docs.chain.link/chainlink-automation/supported-networks/#configurations)

Once everything looks good run `brownie run --network <network name> scripts/deploy.py`. 

The list of all available network names can be found by running `brownie network list`.
In general you will want to use one of `[arbitrum-main, polygon-main, optimism-main]`

This should deploy the contract and return the deployed address.  Write it down/check it on etherscan and make sure it is there and verified.  You can play with it.  At this point the deployer is still owner as the multisig has not accepted ownership.

### Configuring an Injector
[scripts/configre.py](scripts/configure.py) is a set of simple tools that can help you build gnosis transaction builder jsons to do the following 3 things from a multisig safe:
1. Accept Ownership of a safe
2. Set a recipient list on the injector
3. Register the injector with chainlink

Note that to register the injector you need LINK tokens in the registering wallet/safe that will be sent as part of the registration transaction.  For sidechains 10 LINK should be more than enough to get started.

#### Accepting Admin
Ownership of the injector is accepted by running acceptOwnership() on the contract from an address that has been granted ownership by the prior owner.
If the owner is an EOA, that address can use etherscan. If not the following steps can be taken to generate a transaction builder json file to load into a safe to do this.

run `brownie console`
in the console run `from scripts.configure import accept_ownership` then

```python
accept_ownership(injector_address="",
                 safe_address="") 
```
Inputting the address of your injector and safe.  Json output will be spit out that you can copy and paste to a file.

Tip:  To write this to a file do this
```python
import json
with open("output.json", "w") as f:
  json.dumps(accept_ownership(injector_address="",
                              safe_address=""))
```

#### Setting up a recipient list

As stated above,  The watch list is defined as the tuple of [streamerAddress, amount, maxTopups].  This is represented as 3 lists with a common index represeting each tuple.

Similar to the steps above, to generate a watch list use the following in `brownie console` on the proper network:

```python
from scripts.configure import set_recipient_list
set_recipient_list(gauge_addresses=["",""], 
                   amounts_per_period=[1,2], 
                   max_periods=[3,3], 
                   injector_address="", 
                   safe_address="", 
                   token_address="") 
```

The above schedule will send 1 wei and 2 wei each of the specified token to the 2 addresses specified for 3 rounds each via the specified injector, setup by the specific safe.  The total cost of this program would be `1*3 + 2*3 = 9` wei.
Note that the current watchlist as well as the current topup count for max topups is reset each time a new list is configured.

You can use the same logic from above to output the resulting JSON to a file directly.

#### Registering the upkeep with chainlink
Registering a chainlink upkeep involves paying some money into the chainlink registrar.  After that, chainlink will check
the contract each block to see if it is ready to run.  When it signifies it is, it will run the specified call data and execute the transfer and notify.
Note that as part of this process some LINK must be paid into the upkeep contract.  For sidechains, 10 LINK should usually be enough.  These steps assume the specified link is sitting in the multisig where the payload is executed. 

from brownie console (remeber the correct network)
```python
from scripts.configure import register_upkeep
register_upkeep(upkeep_contract="0x0000000000000000000000000000000000000000", 
                name="some name", 
                gas_limit=500000, 
                link_deposit_gwei=10*10**18, 
                sender="0x0000000000000000000000000000000000000000", 
                source=69)
```

Where upkeep_contract is the address of the injector just deployed and sender is the address of the multisig that the payload will be run on.  Note that source is an unsigned 8 byte number that shows up in events.  You could try finding one of your own and hope it stays unique and use it for reporting.  This defaults to 69 so that's not a good one to use for something unique.  It can be left out of the run and the default of 69 will be used.

The resulting payload should register the upkeep. You can then find your registed upkeep by going to [Chainlink automation dashboard](https://automation.chain.link/arbitrum).  Select the chain you deployed on.  Then scroll down to recent upkeeps.  The name you specified should show up at or near the top of that list.  Click on it.
Write down that link and/or the upkeep id.  This is the page where you can monitor your link balance.  To topup, connect to this dapp with wallet connect and use the top-up action to send in more link.  You can also stop the automation and recover deposited and unspent link this way.
