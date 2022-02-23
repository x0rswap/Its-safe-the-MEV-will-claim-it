# Its-safe-the-MEV-will-claim-it

On Contract.sol, you have a proxy thing. So when you want to call the contract, you go through the proxy.

This contract has its contract "storage value" in immutable variables. So it's cheap to read them. But, when you, dear contract user, change these values, you need to redeploy the contract to update these immutable variables.

So, because you may not want to pay the deploy cost, the proxy asks you to deposit money to interact with the contract, and the MEV will claim your deposit if you forgot to re-deploy the contract.

Therefore, if MEV is really a thing, it's safe to assume these immutables values are actually the storage ones :)

![](mem.jpg)
