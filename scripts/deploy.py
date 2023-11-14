from brownie import (
    interface,
    accounts,
    chain,
    ChildChainGaugeInjector,
)


account = accounts.load("tmdelegate") #load your account here
ADMIN_ADDRESS = "0xc38c5f97B34E175FFd35407fc91a937300E33860" # Balancer Maxi LM Multisig on mainnet, polygon and arbi
UPKEEP_CALLER_ADDRESS = ""
TOKEN_ADDRESS = ""


REGISTRY_BY_CHAIN = {
    42161: "0x75c0530885F385721fddA23C539AF3701d6183D4",
    137: "0x02777053d6764996e594c3E88AF1D58D5363a2e6",
}


LINK_BY_CHAIN = {
    42161: "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4",
    137: "0xb0897686c545045aFc77CF20eC7A532E3120E0F1"
}


injector = ChildChainGaugeInjector.deploy(
    REGISTRY_BY_CHAIN[chain.id],
    60 * 60 * 6,  # minWaitPeriodSeconds is 6 days
    TOKEN_ADDRESS,
    {"from": account},
    publish_source=True
)

injector.transferOwnership(ADMIN_ADDRESS, {"from": account})
