# Framework change
The repo is currently in brownie which is EOL, and loved by few.  You're welcome to write tests in this framework but you are also very much inveted to move the contracts to another repo/development framework such as Foundry or Hardhat and write tests there.  Please provide a deploy script and a readme that explains how to run the tests and deploy.  The choosen framework should be capable of deployment including contract verification on all of the chains listed here: https://github.com/BalancerMaxis/bal_addresses/blob/main/extras/chains.json.  The deploy script/readme should demonstrate/describe how to deploy on at least 2 of the supported chains.    

# Tests
## Factory and Init
- Deploy Factory
- Deploy 2 or more injectors
- Verify that the injectors can be configured independantly and do not share storage

## Injector Config
- Add 2 gauges with the same config
- Add 1 gauge with a different config
- Add a config over MaxInjectionAmount and verify it reverts
- Test that read functions deliver expected results
- removeGauge removes a gauge from operation
- Reconfigure already configured gauge using addGauge to replace current config
- Configure when not owner
## Operation
- Verify that check/perform upkeep work with the 3 gauges
- Verify proper failure states (checkUpkeep false, performUpkeep reverts)
  - All rounds finished
  - Not enough tokens in injector
  - Token not added to gauge
  - Less than minWaitPeriod since last injection
  - Injection over MaxInjectionAmount(can lower MaxInjectionAmount to below a current schedule)
  - Assign the distributorship of a gauge to another address(can be an EOA) and then back again. 
- Test Sweeps
- Keep when not Keeper fails
- Admin/configuration is not possible by non owner
- Verify that all state-changing functions are somehow permissioned and that said permissioning works.
##  Integration test
  - Run 1-3 gauges over at least 3 epochs
  
# Setup
The best test suite would deploy tokens, pools and gauges all from scratch, but for someone who hasn't worked with Balancer a lot, this could be more time consuming than the test itselfs.  If you want a shortcut, here are some addresses you can use on **Arbitrum fork**** to cut down much of the setup work.
Note that you can get lp_token address from the gauge, the poolId from the pool token address, and info about the pool by calling get_pool_info on the vault providing the poolId

## Gauges
### RDNT/WETH
UI: https://app.balancer.fi/#/arbitrum/pool/0x32df62dc3aed2cd6224193052ce665dc181658410002000000000000000003bd
Pool Id: `0x32df62dc3aed2cd6224193052ce665dc181658410002000000000000000003bd`
BPT(deposit token) Address: https://arbiscan.io/token/0x32df62dc3aed2cd6224193052ce665dc18165841
Gauge Address: https://arbiscan.io/address/0xcf9f895296f5e1d66a7d4dcf1d92e1b435e9f999

###  4pool 
UI: https://app.balancer.fi/#/arbitrum/pool/0x423a1323c871abc9d89eb06855bf5347048fc4a5000000000000000000000496
Pool Id: `0x423a1323c871abc9d89eb06855bf5347048fc4a5000000000000000000000496`
BPT(deposit token) Address: https://arbiscan.io/token/0x423a1323c871abc9d89eb06855bf5347048fc4a5
Gauge Address: https://arbiscan.io/address/0xa14453084318277b11d38fbe05d857a4f647442b

## Incentive Tokens 
use WETH, can wrap fork ETH to get it:
https://arbiscan.io/token/0x82af49447d8a07e3bd95bd0d56f35241523fbab1

## Relevent Governance Addresses and how to configure
Authorizer Adapter Entrypoint: `0x97207B095e4D5C9a6e4cfbfcd2C3358E03B90c4A`
call: `performAction(address(target), bytes(calldata)` on the entrypoint where target is the gauge you wish to add a reward token for and "calldata" is generated follows:

you need to call_data encode a call to `add_reward_token(token(address), distributor(address)`
Where distributor is the address of a factory deployed injector that can handle said token.,
