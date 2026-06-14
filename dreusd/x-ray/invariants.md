# Invariant Map

> DRE USD | 61 guards | 18 inferred properties | 4 not fully enforced on-chain

## 1. Enforced Guards (Reference)

#### G-1
`roles.defaultAdmin != address(0)` · `dreUSDManager.sol:200` · Prevents deployment without a role administrator.

#### G-2
`_cap <= MAX_DAILY_FIAT_MINT_CAP_USD` · `dreUSDManager.sol:262` · Bounds fiat-backed issuance configured per day.

#### G-3
`maxLimit >= outstanding` · `dreUSDManager.sol:300` · Prevents express configuration from invalidating already consumed capacity.

#### G-4
`waitingTime >= 1 days && waitingTime <= 14 days` · `dreUSDManager.sol:317` · Bounds withdrawal settlement delay.

#### G-5
`IAaveV3Adapter(adapter).getUsdc() == usdc` · `dreUSDManager.sol:331` · Prevents withdrawal unit/token mismatch.

#### G-6
`allowed[asset]` · `dreUSDManager.sol:810` · Restricts token-backed minting to configured collateral.

#### G-7
`block.timestamp <= deadline` · `dreUSDManager.sol:811` · Prevents stale token-mint orders.

#### G-8
`signer == from` · `dreUSDManager.sol:871` · Binds delegated mint parameters to the funding account.

#### G-9
`dreUSDAmount >= minAmountOut` · `dreUSDManager.sol:937` · Enforces user mint slippage.

#### G-10
`sharesOut >= minSharesOut` · `dreUSDManager.sol:449` · Enforces final vault-share slippage.

#### G-11
`m.chainId == block.chainid` · `dreUSDManager.sol:980` · Prevents cross-chain fiat authorization replay.

#### G-12
`!usedMintRefs[m.mintRef]` · `dreUSDManager.sol:981` · Makes each fiat authorization reference one-use.

#### G-13
`custodians[signer]` · `dreUSDManager.sol:990` · Requires an approved reserve attestor.

#### G-14
`newTotal <= dailyFiatMintCapUsd` · `dreUSDManager.sol:703` · Enforces the configured daily fiat issuance ceiling.

#### G-15
`usdcAmount >= minUsdcAmount` · `dreUSDManager.sol:499` · Enforces standard-withdrawal quote protection.

#### G-16
`totalUsdcAmount <= expressWithdrawalAvailable` · `dreUSDManager.sol:524` · Prevents express requests from exceeding available capacity.

#### G-17
`block.timestamp >= position.createdAt + withdrawalWaitingTime` · `dreUSDManager.sol:553` · Enforces maturity of standard withdrawal claims.

#### G-18
`positionExists(tokenId)` · `dreUSDManager.sol:547` · Prevents settlement of nonexistent or already-burned claims.

#### G-19
`amount <= min(expressFillerDebt, limitHeadroom)` · `dreUSDManager.sol:782` · Prevents payback from over-restoring capacity or overpaying tracked debt.

#### G-20
`feeBps <= MAX_EXPRESS_WITHDRAWAL_FEE_BPS` · `dreUSDManager.sol:290` · Caps express fees at 5%.

#### G-21
`msg.sender == dreUSDManager` · `dreUSD.sol:89` · Restricts stablecoin minting to the manager.

#### G-22
`msg.sender == dreUSDManager` · `dreUSD.sol:95` · Restricts stablecoin burning to the manager.

#### G-23
`!frozen[account]` / `frozen[account]` · `dreUSD.sol:113,121` · Maintains explicit freeze state transitions.

#### G-24
`!frozen[addr] && !sanctionsList.isSanctioned(addr)` · `dreUSD.sol:133-138` · Blocks normal local movement by ineligible addresses.

#### G-25
`oracles[token] != address(0)` · `dreUSDOracle.sol:215` · Requires a configured pricing source.

#### G-26
`block.timestamp - updatedAt <= threshold` · `dreUSDOracle.sol:224` · Rejects stale mint prices.

#### G-27
`answer > 0` · `dreUSDOracle.sol:229` · Rejects invalid Chainlink prices.

#### G-28
`price within deviationThresholds[token] of $1` · `dreUSDOracle.sol:413` · Restricts supported stablecoin depeg exposure.

#### G-29
`MIN_STALENESS_THRESHOLD <= threshold <= MAX_STALENESS_THRESHOLD` · `dreUSDOracle.sol:338` · Prevents disabling or trivially breaking freshness checks.

#### G-30
`MIN_GRACE_PERIOD <= gracePeriod <= MAX_GRACE_PERIOD` · `dreUSDOracle.sol:200` · Bounds post-sequencer recovery delay.

#### G-31
`priceDecimals <= 18` · `dreUSDOracle.sol:116` · Bounds decimal scaling assumptions.

#### G-32
`$0.50 <= setOracle price <= $2.00` · `dreUSDOracle.sol:141` · Detects obvious feed-pair misconfiguration.

#### G-33
`msg.sender == vault` · `dreRewardsDistributor.sol:148` · Ensures reward transfers and vault virtual accounting occur in one flow.

#### G-34
`whenNotPaused` · `dreRewardsDistributor.sol:108,147` · Stops reward scheduling and claiming during emergencies.

#### G-35
`msg.sender == dreUSDManager` · `dreAaveAdapter.sol:113` · Restricts Aave-backed withdrawals to manager settlement.

#### G-36
`available >= amount` · `dreAaveAdapter.sol:120` · Requires vault balance, allowance, and Aave liquidity.

#### G-37
`delta >= amount && withdrawn >= amount` · `dreAaveAdapter.sol:125,130` · Enforces minimum aToken pull and USDC redemption.

#### G-38
`allowance(_vault, adapter) > 0` · `dreAaveAdapter.sol:195` · Prevents configuring an immediately unusable custody vault.

#### G-39
`msg.sender == dreUSDManager` · `dreWithdrawalNFT.sol:106,125` · Restricts withdrawal-claim creation and destruction.

#### G-40
`usdcAmount > 0` · `dreWithdrawalNFT.sol:108` · Prevents empty withdrawal claims.

#### G-41
`paused() == false` · `dreUSDs.sol:213,228,262` · Stops vault deposits, withdrawals, and share transfers together.

#### G-42
`receiver/owner is not blocked` · `dreUSDs.sol:126-156` · Reflects compliance restrictions in ERC-4626 limits.

#### G-43
`amount == excessDreUSD()` · `dreUSDs.sol:174-179` · Limits admin extraction to real balance above virtual accounting.

#### G-44
`_stuckFundsRecipient != address(0)` · `dreOVaultComposer.sol:47,56` · Ensures failed bridge operations have a custody destination.

#### G-45
`shareAmountReceived >= minAmountLD` · `dreOVaultComposer.sol:91` · Enforces vault-conversion slippage before bridging.

#### G-46
`assetAmountReceived >= minAmountLD` · `dreOVaultComposer.sol:131` · Enforces redemption slippage before bridging.

#### G-47
`recipient != address(0)` · `dreVault.sol:62,74` · Prevents recovery transfers to the zero address.

#### G-48
`token_ != token` · `dreVault.sol:63` · Prevents owner recovery from bypassing configured custody forwarding.

#### G-49
`amount > 0` · `dreVault.sol:55` · Prevents meaningless forwarding operations.

#### G-50
`_whitelisted[addr] || sanctioned` · `SanctionsListWhitelistWrapper.sol:43` · Defaults non-whitelisted accounts to blocked.

Additional constructor, initializer, zero-address, same-value, role, position,
balance, and pause guards account for the remaining 11 mechanically detected
guards.

## 2. Inferred Invariants (Single-Contract)

#### I-1
`Conservation` · On-chain: **Yes**

> Vault `totalAssets` equals `_virtualBalance + currently vested distributor rewards`; direct transfers are excluded.

**Derivation** — NatSpec and formula: `dreUSDs.sol:38-40,105-114`; deposit adds claimed rewards plus assets at `214-216`, withdrawal adds claimed rewards then subtracts assets at `229-231`.

**If violated** — Share conversion can create dilution or insolvency between real assets and shares.

#### I-2
`Bound` · On-chain: **Yes**

> Daily fiat issuance is at most `dailyFiatMintCapUsd`, itself at most 100 million USD.

**Derivation** — guard-lift: setter bound at `261-266`; only daily writer is `_checkAndUpdateDailyFiatMint` at `698-709`.

**If violated** — Custodian-authorized supply can exceed operational issuance policy.

#### I-3
`Conservation` · On-chain: **Yes**

> `expressWithdrawalMaxLimit - expressWithdrawalAvailable` tracks consumed express capacity across request and payback.

**Derivation** — delta pair: request decreases available at `731-734`; payback increases available by the same paid amount at `790-795`; reconfiguration preserves outstanding amount at `297-303`.

**If violated** — Express claims can exceed configured capacity or capacity can remain unnecessarily locked.

#### I-4
`Conservation` · On-chain: **Yes**

> A filled express claim increases `expressFillerDebt` by user amount plus fee; payback decreases debt and restores equal capacity.

**Derivation** — delta pair: `dreUSDManager.sol:610-636` and `768-795`.

**If violated** — Filler reimbursement or express availability diverges from completed claims.

#### I-5
`StateMachine` · On-chain: **Yes**

> A withdrawal NFT progresses from nonexistent -> minted position -> burned position; manager-only mint/burn gates each edge.

**Derivation** — edge: `_positions[tokenId]` creation and `_safeMint` at `dreWithdrawalNFT.sol:110-120`; deletion and burn at `128-138`.

**If violated** — The same withdrawal claim can be paid twice or become unclaimable.

#### I-6
`StateMachine` · On-chain: **Yes**

> A fiat `mintRef` transitions from unused to used exactly once.

**Derivation** — edge: `usedMintRefs[m.mintRef] == false@981 -> true@993`; no clearing writer exists.

**If violated** — One reserve attestation can mint dreUSD repeatedly.

#### I-7
`Temporal` · On-chain: **Yes**

> Standard withdrawal claims cannot be filled before `createdAt + withdrawalWaitingTime`.

**Derivation** — temporal predicate: mint timestamp at `dreWithdrawalNFT.sol:115`; fill guard at `dreUSDManager.sol:553`; setter bounds waiting time at `314-323`.

**If violated** — Long-queue liquidity can be accessed before its configured delay.

#### I-8
`Bound` · On-chain: **Yes**

> Accepted oracle prices are positive, fresh, within configured deviation, and used only after sequencer recovery grace.

**Derivation** — guard-lift across `getUsdValue`, `getTokenAmount`, and `validatePrice`: `dreUSDOracle.sol:214-323,358-417`.

**If violated** — Mint or withdrawal conversion uses an invalid stablecoin valuation.

#### I-9
`Temporal` · On-chain: **Yes**

> Reward vesting is linear between `cTs` and `eTs`, and claims reduce `rewards` by the transferred vested amount.

**Derivation** — ratio: `vested = (newClaimTimestamp-cTs)*rewards/(eTs-cTs)` at `175-180`; delta pair `rewards -= vested`, token transfer, `cTs = newClaimTimestamp` at `163-170`.

**If violated** — Vault assets and future rewards are double-counted or lost.

## 3. Inferred Invariants (Cross-Contract)

#### X-1
On-chain: **Yes**

> Manager token mint and withdrawal amounts use the same configured oracle's validated decimal/freshness model.

**Caller side** — `dreUSDManager.sol:957-964,493-499,518-524`.

**Callee side** — `dreUSDOracle.sol:214-293`; moderator write sites at `91-205`.

**If violated** — Backing deposited, dreUSD issued, and USDC claims use inconsistent units or prices.

#### X-2
On-chain: **Yes**

> Distributor claims transfer exactly the amount added to the vault's `_virtualBalance`.

**Caller side** — `dreUSDs.sol:160-163,204-231`.

**Callee side** — `dreRewardsDistributor.sol:147-170`.

**If violated** — ERC-4626 share pricing diverges from actual reward assets.

#### X-3
On-chain: **Yes**

> Standard fill through the Aave adapter pays at least the NFT's USDC amount to its current owner.

**Caller side** — `dreUSDManager.sol:549-590`.

**Callee side** — adapter identity check `dreUSDManager.sol:328-334`; liquidity and redemption checks `dreAaveAdapter.sol:109-132`.

**If violated** — A burned withdrawal NFT is not matched by sufficient payout.

#### X-4
On-chain: **No**

> Every custodian-signed fiat mint corresponds to equal off-chain USD reserves.

**Caller side** — signature, chain, replay, and cap enforcement at `dreUSDManager.sol:975-1000`.

**Callee side** — no on-chain reserve contract exists in scope; custodian membership is admin-written at `246-256`.

**If violated** — dreUSD supply exceeds real fiat backing despite valid on-chain authorization.

#### X-5
On-chain: **No**

> Cross-chain debit, message delivery, destination credit, and lockbox release conserve aggregate dreUSD/share value.

**Caller side** — bridge-specific local credits/fallbacks at `dreUSD.sol:184-192`, `dreShareOFT.sol:109-117`, `dreShareOFTAdapter.sol:72-82`.

**Callee side** — LayerZero endpoint, peer, DVN, and messaging implementation is vendored/outside first-party scope.

**If violated** — Aggregate cross-chain supply or canonical locked shares diverge.

## 4. Economic Invariants

#### E-1
On-chain: **No**

> Total dreUSD supply is fully backed by accepted on-chain stablecoins plus verified off-chain fiat reserves.

**Follows from** — `I-2` + `I-6` + `I-8` + `X-1` + `X-4`.

**If violated** — The stablecoin becomes undercollateralized.

#### E-2
On-chain: **Yes**

> Vault shares redeem proportionally against virtual principal plus unclaimed vested rewards without counting direct donations.

**Follows from** — `I-1` + `I-9` + `X-2`.

**If violated** — Depositors are diluted or promised more assets than the vault accounts for.

#### E-3
On-chain: **Yes**

> Express withdrawal capacity and filler debt remain coherent through request, fill, configuration, and payback.

**Follows from** — `I-3` + `I-4`.

**If violated** — The system overcommits express liquidity or misstates reimbursement.

#### E-4
On-chain: **No**

> A complete cross-chain round trip cannot create or destroy dreUSD or vault-share economic claims, excluding explicit dust rules.

**Follows from** — `X-5`.

**If violated** — Cross-chain users or canonical vault holders experience supply imbalance.
