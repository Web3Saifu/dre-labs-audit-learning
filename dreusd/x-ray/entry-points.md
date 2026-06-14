# Entry Point Map

## Protocol Flow Paths

```text
deployment -> initialize core proxies -> assign roles -> configure manager/oracles/adapters
configure custodianVault + allow token + oracle -> user mint() -> custody receives token -> dreUSD minted
[mint setup] -> user mintAndStake() -> dreUSD minted to manager -> dreUSDs.deposit() -> shares to receiver
configure custodian signer + daily cap -> keeper mintFromUsd() -> signed fiat reference consumed -> dreUSD minted
[fiat setup] -> keeper mintRewards() -> distributor.addRewards() -> linear vesting begins
set rewards distributor -> user deposit/mint -> vested rewards claimed -> virtual balance rises -> shares minted
[vault deposit] -> user withdraw/redeem -> vested rewards claimed -> virtual balance falls -> dreUSD returned
configure USDC oracle -> requestWithdrawal() -> dreUSD burn -> standard NFT mint
[standard request] + waiting period -> treasury fillWithdrawal() -> NFT burn -> USDC paid
configure express capacity -> requestExpressWithdrawal() -> dreUSD burn -> express NFT mint
[express request] -> operator fillExpressWithdrawals() -> NFT burn -> USDC fronted -> filler debt rises
[express fill] -> treasury payExpressDebt() -> USDC payback -> debt falls -> capacity rises
configure Aave adapter + vault allowance -> vault fill path -> aUSDC pulled -> Aave withdraws USDC to NFT owner
configure LayerZero peers -> OFT send -> source debit -> destination credit
configure share adapter/composer -> deposit-and-send or redeem-and-send -> vault conversion -> OFT transfer
```

## Permissionless

### `dreUSDManager.mint(...)` (two overloads)

| Aspect | Detail |
|---|---|
| Visibility | `external`, `nonReentrant`, `whenNotPaused` |
| Caller | User |
| Parameters | asset, amount, minimum output, deadline, optional permit: user-controlled/signed |
| Call chain | `mint -> _preMintChecks -> _transferAndMint -> dreUSDOracle.getUsdValue -> dreUSD.mint` |
| State modified | dreUSD supply/balance; external custodian token balance |
| Value flow | Stablecoin: user -> custodian; dreUSD: protocol -> user |
| Reentrancy guard | Yes |

### `dreUSDManager.mintFrom(...)`

| Aspect | Detail |
|---|---|
| Visibility | `external`, `nonReentrant`, `whenNotPaused` |
| Caller | Relayer/anyone with user signatures |
| Parameters | full EIP-712 authorization and permit: user-signed |
| Call chain | `mintFrom -> _authorize -> _executePermit -> _transferAndMint -> dreUSD.mint` |
| State modified | `authNonce[from]`; dreUSD supply/balance |
| Value flow | Stablecoin: signer -> custodian; dreUSD: protocol -> receiver |
| Reentrancy guard | Yes |

### `dreUSDManager.mintAndStake(...)`

| Aspect | Detail |
|---|---|
| Visibility | `external`, `nonReentrant`, `whenNotPaused` |
| Caller | User |
| Parameters | asset/amount/receiver/minimums/deadline user-controlled; permit user-signed |
| Call chain | `mintAndStake -> _transferAndMint -> dreUSD.mint(manager) -> dreUSDs.deposit` |
| State modified | dreUSD supply; vault virtual balance and share supply |
| Value flow | Stablecoin -> custody; dreUSD -> vault; shares -> receiver |
| Reentrancy guard | Yes |

### `dreUSDManager.requestWithdrawal(...)`

| Aspect | Detail |
|---|---|
| Visibility | `external`, `nonReentrant`, `whenNotPaused` |
| Caller | dreUSD holder |
| Parameters | amount, minimum USDC, deadline: user-controlled |
| Call chain | `requestWithdrawal -> dreUSD.burn -> oracle.getTokenAmount -> withdrawalNFT.mint` |
| State modified | dreUSD supply; NFT position and `nextTokenId` |
| Value flow | dreUSD burned; no immediate USDC transfer |
| Reentrancy guard | Yes |

### `dreUSDManager.requestExpressWithdrawal(...)`

| Aspect | Detail |
|---|---|
| Visibility | `external`, `nonReentrant`, `whenNotPaused` |
| Caller | dreUSD holder |
| Parameters | amount, minimum USDC, deadline: user-controlled |
| Call chain | `requestExpressWithdrawal -> oracle.getTokenAmount -> dreUSD.burn -> expressNFT.mint` |
| State modified | `expressWithdrawalAvailable`, fee mapping, dreUSD supply, NFT position |
| Value flow | dreUSD burned; no immediate USDC transfer |
| Reentrancy guard | Yes |

### `dreUSDs.deposit/mint/withdraw/redeem` (inherited ERC-4626)

| Aspect | Detail |
|---|---|
| Visibility | Public inherited entry points; hooks are `whenNotPaused` |
| Caller | User/operator with allowance |
| Parameters | assets/shares/receiver/owner: user-controlled |
| Call chain | `ERC4626 entry -> dreUSDs._deposit/_withdraw -> distributor.claimVested -> token transfer/share mint-burn` |
| State modified | `_virtualBalance`, share supply/balances, distributor rewards/timestamps |
| Value flow | dreUSD into or out of vault |
| Reentrancy guard | No explicit guard |

### Other Permissionless Operational Entry Points

| Contract | Function | State/Value Effect |
|---|---|---|
| `dreUSDs` | `claimVestedRewards()` | Claims distributor rewards and increases virtual balance |
| `dreVault` | `performUpkeep(bytes)` | Forwards full configured-token balance downstream |
| `dreWithdrawalKeeperBot` | `performUpkeep(bytes)` | Calls manager fill path; succeeds only if bot has manager treasury role |
| `dreUSD` | inherited ERC-20/OFT transfer/send functions | Transfers or bridges dreUSD subject to local compliance rules |
| `dreUSDs` | inherited ERC-20 transfer functions | Transfers vault shares subject to pause/compliance hook |
| `dreWithdrawalNFT` | inherited ERC-721 transfer/approval functions | Transfers withdrawal claim ownership |
| OVault contracts | inherited OFT/composer entry points | Bridge assets/shares and perform hub vault conversion |

## Role-Gated

| Role/caller | Contract | Function | State or value effect |
|---|---|---|---|
| `KEEPER_ROLE` | Manager | `mintFromUsd`, `mintRewards` | Consumes fiat authorization and mints dreUSD |
| `TREASURY_ROLE` | Manager | `fillWithdrawal` | Burns standard NFTs and pays USDC |
| `TREASURY_ROLE` | Manager | `payExpressDebt` | Pays filler, decreases debt, restores capacity |
| `TREASURY_ROLE` | Manager | `adminWithdraw` | Transfers manager-held ERC-20 |
| `EXPRESS_OPERATOR_ROLE` | Manager | `fillExpressWithdrawals` | Burns express NFTs, fronts USDC, increases filler debt |
| `MODERATOR_ROLE` | Manager | `updateVault`, `updateCustodianList`, `setDailyFiatMintCap`, `updateAllowedList` | Configures custody, signers, caps, assets |
| `WITHDRAWAL_CONFIG_ROLE` | Manager | `updateExpressPaybackAddress`, `updateExpressWithdrawal`, `updateWithdrawal`, `updateVaultAdapter` | Configures withdrawal economics and dependencies |
| `PAUSER_ROLE` | Manager/vault/distributor | `pause`, `unpause` | Toggles operational availability |
| `MODERATOR_ROLE` | Oracle | oracle/feed/threshold setters and removal | Changes pricing trust configuration |
| `GUARDIAN_ROLE` | dreUSD | `freeze`, `unfreeze` | Changes account transfer eligibility |
| manager address | dreUSD | `mint`, `burn` | Changes stablecoin supply |
| manager address | Withdrawal NFT | `mint`, `burn` | Creates/destroys withdrawal claims |
| vault address | Distributor | `claimVested` | Transfers vested dreUSD and updates schedule accounting |
| manager address | Aave adapter | `withdraw` | Pulls vault aUSDC and redeems USDC |
| `MODERATOR_ROLE` | Sanctions wrapper | whitelist add/remove | Changes compliance eligibility |

## Admin-Only

| Contract | Function | State Modified |
|---|---|---|
| dreUSD | `setSanctionsList`, `setDreUSDManager`, ownership functions | Compliance source, mint/burn authority, OFT owner |
| dreUSDs | `setRewardsDistributor`, `setShareOFTAdapter`, `withdrawExcessDreUSD` | Reward and bridge endpoints; excess assets |
| Withdrawal NFT | `setDreUSD`, `setDreUSDManager` | Compliance and manager endpoints |
| Aave adapter | `setDreUSDManager`, `setVault`, `recoverToken` | Withdrawal authority, custody vault, held tokens |
| Composer/share adapter | `setStuckFundsRecipient` | Fallback custody recipient |
| Upgradeable contracts | UUPS upgrade authorization | Implementation code |
| AccessControl contracts | inherited role grant/revoke | Privileged role membership |
| Timelock | inherited schedule/execute/cancel/update | Delayed governance operations |
| dreVault | `recoverToken`, `recoverEther` | Non-configured ERC-20 and ETH recovery |

## Initialization

`dreUSD`, `dreUSDs`, manager, oracle, rewards distributor, withdrawal NFTs,
Aave adapter, share OFT, and share adapter expose one-time initializers. Their
implementations disable direct initialization in constructors; proxy deployment
must initialize atomically.
