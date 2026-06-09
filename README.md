# DRE App - dreUSD contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the **Issues** page in your private contest repo (label issues as **Medium** or **High**)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
Base (hub chain), - using LayerZero OFT standard to deploy on the following chains:
Ethereum, 
Polygon, 
Monad, 
Arbitrum
MegaETH
Ink

___

### Q: If you are integrating tokens, are you allowing only whitelisted tokens to work with the codebase or any complying with the standard? Are they assumed to have certain properties, e.g. be non-reentrant? Are there any types of [weird tokens](https://github.com/d-xo/weird-erc20) you want to integrate?
Only whitelisted tokens. The protocol accepts stablecoins via an explicit allowlist managed by MODERATOR_ROLE through updateAllowedList(). For withdrawal flow USDC is set as an immutable reference in the dreUSDManager constructor, as withdrawals happen only in USDC. For minting dreUSD, only tokens that have been allowlisted AND have a configured Chainlink oracle price feed can be used for minting.

The token we will accept at launch:
USDC - 6 decimals, ERC-20 with EIP-2612 Permit. Has an admin blocklist. Non-reentrant. Standard ERC-20 behavior.

Assumptions and handling:
All accepted tokens are assumed to be non-reentrant.
Fee-on-transfer: The codebase handles fee-on-transfer tokens via before/after balance differential checks in _transferAndMint(). If USDT enables fee-on-transfer, the protocol mints dreUSD based on the actual amount received, not the amount sent.
All accepted tokens use 6 decimals. dreUSD uses 18 decimals. The oracle handles decimal conversion.
The protocol also uses SafeERC20 for all token interactions to handle non-standard return values (e.g., USDT).
The protocol's own tokens - dreUSD (ERC-20, 18 decimals), dreUSDs (ERC-4626, 18 decimals), and dreWithdrawalNFT (ERC-721) — are standard implementations and do not exhibit weird traits.
No weird tokens are intentionally integrated. We do not plan to integrate rebasing tokens, tokens with multiple entry points, or tokens with callbacks (e.g., ERC-777).

___

### Q: Are there any limitations on values set by admins (or other roles) in the codebase, including restrictions on array lengths?
Role trust levels and limitations:
DEFAULT_ADMIN_ROLE (Governance multisig via timelock): Fully trusted. Can grant/revoke all roles, configure core contract settings, and authorize upgrades. All admin actions go through a 48-hour timelock. Users must trust this role completely.
UPGRADER_ROLE (Upgrader multisig via timelock): Fully trusted. Can authorize UUPS contract upgrades via upgradeToAndCall(). Trusted to upgrade only to properly audited implementations that do not introduce storage collisions or malicious logic.
MODERATOR_ROLE (Moderator multisig): Trusted to configure operational settings correctly. Controls:
updateVault() — custodian vault address
updateCustodianList() — add/remove authorized fiat mint custodian signers
setDailyFiatMintCap() — capped at 100,000,000 USD (100M, 2 decimal precision)
updateAllowedList() — allowlist stablecoins for minting
Oracle configuration: setOracle(), setStalenessThreshold() (1 min – 24 hours), setDeviationThreshold() (up to 10,000 bps / 100%), setSequencerUptimeFeed(), setGracePeriod() (1 min – 24 hours), removeOracle()
KEEPER_ROLE (individual wallet or automated): Trusted to mint dreUSD for fiat deposits. Can only call mintFromUsd() and mintRewards(), both of which require a valid custodian signature over a FiatMint struct. The keeper cannot mint without a custodian's ECDSA signature. Fiat mints are subject to the daily fiat mint cap, replay protection via mintRef, expiration via validUntil, and chain ID binding.
EXPRESS_OPERATOR_ROLE (individual wallet or automated): Trusted to fill express withdrawal NFTs promptly. Calls fillExpressWithdrawals(tokenIds[]). The operator must supply USDC from their own wallet to fill positions. No unbounded array length restriction is enforced on tokenIds[], but practically limited by block gas.
TREASURY_ROLE (Treasury multisig): Trusted to fill standard withdrawals and manage express debt. Controls:
fillWithdrawal(tokenIds[], useVault) — fill standard withdrawals (after waiting period). No enforced array length limit on tokenIds[], practically gas-limited.
payExpressDebt(amount) — repay express filler debt
adminWithdraw(token, to, amount) — withdraw any ERC-20 held by the contract
WITHDRAWAL_CONFIG_ROLE (Moderator multisig): Trusted to configure withdrawal parameters within guardrails:
updateExpressWithdrawal(maxLimit, feeBps, feeRecipient) — express fee capped at 500 bps (5%) via MAX_EXPRESS_WITHDRAWAL_FEE_BPS
updateWithdrawal(waitingTime) — standard withdrawal waiting time, 1–14 days
updateExpressPaybackAddress(address) — express debt repayment recipient
updateVaultAdapter(address) — Aave adapter for vault-sourced fills
PAUSER_ROLE (Pauser multisig): Trusted to pause and unpause minting, withdrawals, staking, and reward distribution. Cannot modify parameters, access funds, or grant roles.
GUARDIAN_ROLE (Guardian multisig): Trusted to freeze and unfreeze specific addresses on dreUSD/dreShareOFT for compliance. Cannot modify any other parameters. Freezing prevents an address from minting, transferring, staking, or redeeming.
Owner (on dreUSD, dreShareOFT, dreShareOFTAdapter): Manages LayerZero OApp settings (peers, delegates, message inspectors). Trusted to configure cross-chain messaging correctly.
Hardcoded guardrails:
Express withdrawal fee: max 500 bps (5%): MAX_EXPRESS_WITHDRAWAL_FEE_BPS = 500
Standard withdrawal waiting time: 1–14 days: MIN_WITHDRAWAL_WAITING_TIME = 1 days, MAX_WITHDRAWAL_WAITING_TIME = 14 days
Daily fiat mint cap: max 100,000,000 USD: MAX_DAILY_FIAT_MINT_CAP_USD = 10_000_000_000 (100M in 2-decimal format)
Reward vest period: fixed 7 days: VEST_PERIOD = 7 days (constant, not configurable)
Oracle staleness threshold: 1 min – 24 hours: MIN_STALENESS_THRESHOLD = 1 minutes, MAX_STALENESS_THRESHOLD = 24 hours
Oracle grace period: 1 min – 24 hours - MIN_GRACE_PERIOD = 1 minutes, MAX_GRACE_PERIOD = 24 hours
Oracle deviation threshold: up to 10,000 bps (100%) - enforced via `ScalingConstants.BPS_DENOMINATOR` (10,000)
No hardcoded variables that we plan to change post-deployment. All configurable parameters will be set during initialization and adjusted operationally through the roles described above.

The roles are trusted to complete their responsible functionality without mistakes, malicious intentions, or other issues.
But, if these roles can exceed their permissions and access another role's restricted functions, and cause Medium or High impact, then it can be considered a valid issue.
___

### Q: Are there any limitations on values set by admins (or other roles) in protocols you integrate with, including restrictions on array lengths?
No. We trust the governance of the protocols we integrate with:
Chainlink: Trusted to provide accurate, timely price feed data. Our oracle enforces staleness and deviation checks as a defensive layer, but we trust Chainlink's node operator governance and aggregation mechanism.
Aave V3: Trusted to maintain pool liquidity and honor aToken redemptions. The dreAaveAdapter withdraws USDC from Aave to fill withdrawal requests. We trust Aave governance will not rug aToken holders or introduce malicious pool parameters.
LayerZero: Trusted to relay cross-chain messages correctly and in a timely manner. We trust the LayerZero relayer and DVN (Decentralized Verifier Network) configuration to deliver messages faithfully.
OpenZeppelin: We use OpenZeppelin's upgradeable contracts (AccessControl, ERC20, ERC4626, ERC721, UUPS, Pausable, ReentrancyGuard). These are battle-tested and we trust their implementations.

___

### Q: Is the codebase expected to comply with any specific EIPs?
Yes. The codebase is expected to comply with the following EIPs:
ERC-20 (dreUSD): dreUSD is a standard ERC-20 stablecoin. Full ERC-20 compliance is required for composability across DeFi — DEXs, lending protocols, and wallets all expect standard ERC-20 behavior. dreUSD must be freely transferable, approvable, and integrable with any ERC-20-compatible protocol.
EIP-2612 / ERC-20 Permit (dreUSD): dreUSD supports gasless approvals via permit(). This allows users to approve and mint in a single transaction without a separate approval tx. The protocol also uses permit signatures in the mint() and mintAndStake() flows to improve UX by reducing the number of transactions required.
ERC-4626 Tokenized Vault (dreUSDs): dreUSDs is the yield-bearing savings token implemented as an ERC-4626 vault. Compliance with ERC-4626 enables standard integration with DeFi aggregators, yield optimizers, and portfolio trackers that understand the vault interface. Users deposit dreUSD and receive shares whose value appreciates as rewards vest into the vault. Note: the max* view functions (maxDeposit, maxMint, maxWithdraw, maxRedeem) may not fully account for paused or sanctioned states — this is a known deviation documented in prior audits.
ERC-721 + ERC-721Enumerable (dreWithdrawalNFT): Withdrawal positions are represented as transferable ERC-721 NFTs. This allows users to trade or transfer pending withdrawal claims on secondary markets. Enumerable extension enables on-chain and off-chain discovery of pending positions. Two instances exist: one for standard withdrawals and one for express withdrawals.
EIP-1822 / UUPS (all contracts): All core contracts use the Universal Upgradeable Proxy Standard. UUPS was chosen over Transparent Proxy for smaller proxy bytecode and because the upgrade authorization logic lives in the implementation contract, enabling cleaner separation of concerns. Upgradeability is gated by UPGRADER_ROLE and executed through a 48-hour timelock.
EIP-712 (dreUSDManager - mintFrom): The mintFrom() function uses EIP-712 typed structured data signing to authorize third-party mints. A user signs a typed data message binding the asset, amount, receiver, slippage, deadline, nonce, and chain ID. This enables meta-transaction patterns where a relayer or dApp can mint on behalf of a user without the user interacting with the contract directly.
LayerZero OFT Standard (dreUSD, dreShareOFT, dreShareOFTAdapter): dreUSD implements OFTUpgradeable for native cross-chain transfers. dreShareOFT (spoke chains) and dreShareOFTAdapter (hub chain lockbox) enable cross-chain vault share bridging.

Issues related to EIP violations can be considered valid only if they qualify for Medium or High severity definitions.
___

### Q: Are there any off-chain mechanisms involved in the protocol (e.g., keeper bots, arbitrage bots, etc.)? We assume these mechanisms will not misbehave, delay, or go offline unless otherwise specified.
Off-chain mechanisms:
Fiat Mint Keeper (KEEPER_ROLE): Processes fiat-backed dreUSD minting. When a user deposits fiat off-chain through a banking partner, the custodian signs a FiatMint struct (containing mintRef, receiver, usdAmount, validUntil, chainId) with their private key. The keeper bot monitors off-chain deposit confirmations, receives the custodian-signed message, and submits it on-chain via mintFromUsd() or mintRewards(). The on-chain contract verifies the custodian's ECDSA signature, checks the daily fiat mint cap, validates the mintRef hasn't been replayed, confirms validUntil hasn't passed, and verifies chainId matches. The keeper cannot mint without a valid custodian signature.

Rewards Minting Keeper (KEEPER_ROLE): Same mechanism as above but calls mintRewards() instead. Mints dreUSD to the dreRewardsDistributor and triggers addRewards() to start/extend the 7-day linear vesting schedule. This is triggered periodically based on revenue generated by the underlying reserve assets.

Express Withdrawal Filler (EXPRESS_OPERATOR_ROLE): Monitors pending express withdrawal NFTs on-chain (via getPendingRange() on the express withdrawal NFT contract). When positions are pending, the operator calls fillExpressWithdrawals(tokenIds[]), supplying USDC from their own wallet to pay both the user amount and the express fee. Target fill time is ~6 hours. The operator is later reimbursed via payExpressDebt().

Standard Withdrawal Filler (TREASURY_ROLE): Monitors pending standard withdrawal NFTs. After the waiting period (7 days) has elapsed for a position, the treasury calls fillWithdrawal(tokenIds[], useVault) to transfer USDC to NFT holders. USDC is sourced either from the caller's wallet or from the Aave adapter (which redeems aTokens from Aave V3).

LayerZero Relayer: Third-party infrastructure that relays cross-chain messages between hub and spoke chains for dreUSD transfers and dreUSDs share bridging. Assumed to operate correctly per LayerZero's DVN security model.

All off-chain mechanisms (keepers, fillers) are assumed to operate correctly and in a timely manner. If they go offline, minting and withdrawal fills are delayed but no funds are at risk — user deposits are safe in the custodian vault, and withdrawal NFTs remain valid claims.

___

### Q: What properties/invariants do you want to hold even if breaking them has a low/unknown impact?
dreUSDs share price must only increase or stay flat, never decrease. totalAssets() in the dreUSDs vault equals _virtualBalance + dreRewardsDistributor.vestedAmount(). Rewards are always additive. The share price (totalAssets / totalSupply) should only go up over time as rewards vest. Any mechanism that causes the share price to decrease (other than rounding dust) would be a valid finding.
expressWithdrawalAvailable <= expressWithdrawalMaxLimit must always hold. The express withdrawal pool tracks available capacity. This invariant ensures the express system never offers more than the configured maximum.
Every dreUSD burned for a withdrawal must produce a corresponding withdrawal NFT with the correct USDC amount. When a user calls requestWithdrawal() or requestExpressWithdrawal(), their dreUSD is burned and an NFT is minted with the exact USDC amount they are owed (after fees for express). The NFT's stored amount must accurately reflect what the user will receive when filled.
Fiat mint replay protection must hold. Each mintRef in a FiatMint struct can only be used once. The usedMintRefs mapping must prevent any custodian-signed message from being executed twice.
Frozen and sanctioned addresses cannot mint, transfer, stake, or redeem dreUSD or dreUSDs. The compliance enforcement via _validateAddress() must be consistent across all user-facing flows. Compliance checks are enforced on dreUSD transfers (including mint/burn), dreUSDs transfers (including deposit/withdraw), and withdrawal NFT transfers.
_virtualBalance in dreUSDs must accurately reflect actual deposited + claimed dreUSD. It increases on deposit and vested reward claims, decreases on withdrawal. Direct dreUSD transfers to the vault should not inflate the share price (they become unclaimable excess that can be recovered by admin via withdrawExcessDreUSD()).

Issues related to invariant violations can be considered valid only if they qualify for Medium or High severity definitions.
___

### Q: Please discuss any design choices you made.
Virtual balance pattern in dreUSDs instead of raw balanceOf. The dreUSDs vault tracks a _virtualBalance variable rather than using dreUSD.balanceOf(address(this)) for totalAssets(). This prevents share price inflation from direct dreUSD transfers (donation attacks). Any dreUSD sent directly to the vault is unclaimable and does not affect share pricing. An admin function withdrawExcessDreUSD() allows recovery of such donations. If a mechanism were found that causes _virtualBalance to desynchronize from actual holdings in a way that leads to loss of funds, that may be a valid finding.
Fixed 7-day reward vest period (VEST_PERIOD = 7 days). The vest period was changed from a configurable parameter to a constant after the Spearbit audit identified that a configurable vestPeriod under 1 day could cause an underflow that bricks addRewards(). Making it a constant eliminates this misconfiguration risk entirely.
Slippage protection is user-set, deviation checks are protocol-set — they serve different purposes. User-set minAmountOut in mints and withdrawals protects the user from receiving too little. Protocol-set deviation thresholds in the oracle protect the protocol from disbursing too much during a depeg event. These are complementary, not substitutes. The oracle reverts if the Chainlink price deviates beyond the configured threshold, acting as a protocol-level circuit breaker independent of what slippage the user sets.
Express withdrawal slippage check is applied on the gross oracle quote, before fee deduction. In `requestExpressWithdrawal()`, the oracle converts dreUSD to a gross USDC amount (`totalUsdcAmount`), and the slippage check (`minUsdcAmount`) is applied against this gross amount. The express fee is then deducted inside `_queueExpressWithdrawal()`. This means the user's actual USDC received (`totalUsdcAmount - fee`) can be lower than `minUsdcAmount`. The express fee is capped at 5% (`MAX_EXPRESS_WITHDRAWAL_FEE_BPS = 500`), which bounds the maximum gap between the slippage-checked amount and the net amount received. Frontends should quote the net amount (after fee) and set `minUsdcAmount` accounting for the fee. If the pre-fee slippage design causes a serious loss of funds, it may be a valid finding.
Withdrawal NFTs are transferable ERC-721s. This is a deliberate design choice. Withdrawal positions can be sold or transferred on secondary markets. Compliance checks are enforced on NFT transfers via _update() overrides — frozen/sanctioned addresses cannot receive withdrawal NFTs. The current NFT owner at fill time receives the USDC, not necessarily the original requester.
Cross-chain quarantine pattern for compliance. When a dreUSD cross-chain transfer arrives via LayerZero and the recipient is frozen or sanctioned, the _credit() override in dreUSD and dreShareOFT bypasses _validateAddress() during minting so tokens are not stuck in LayerZero's message queue. The frozen address receives the tokens but cannot subsequently transfer them — they are effectively quarantined. This is intentional: it prevents funds from being permanently stranded in the LayerZero messaging layer while still enforcing compliance on all future movements.
Express withdrawal partial fills based on available capacity. If a user requests an express withdrawal for more USDC than expressWithdrawalAvailable, the request reverts entirely rather than partially filling. This is all-or-nothing by design. The user must either request within available capacity or use the standard withdrawal path.
Fiat mint signatures are not purpose-bound. The FiatMint struct signed by custodians does not include a field distinguishing between mintFromUsd and mintRewards actions. Both functions accept the same signed payload. The contract enforces separation at the function level: mintFromUsd reverts if m.receiver == dreRewardsDistributor, and mintRewards requires m.receiver == dreRewardsDistributor. This is a known simplification documented in the Spearbit audit (finding 5.2.2). A keeper with KEEPER_ROLE could route a rewards-intended signature through mintFromUsd by changing the receiver, but the current guard prevents this specific case.
ReentrancyGuardTransient for gas efficiency. The codebase uses OpenZeppelin's transient-storage-based reentrancy guard (EIP-1153) instead of the standard storage-based one. This saves gas on every guarded function call. Transient storage is supported on all target deployment chains.
Aave adapter withdrawal is not strictly amount-bound. When fillWithdrawal() sources USDC from the Aave adapter via dreAaveAdapter.withdraw(), the adapter redeems aTokens from Aave. Due to Aave's rounding and interest accrual, the exact amount withdrawn may differ slightly from the requested amount. The adapter validates that the withdrawn amount meets a minimum threshold. This was flagged in the Quantstamp audit (DRE-10) and fixed to use the requested amount strictly.
___

### Q: Please provide links to previous audits (if any) and all the known issues or acceptable risks.
https://github.com/dre-labs/transparency/blob/main/audits/dreusd/2026-02-spearbit-dreusd.pdf
https://github.com/dre-labs/transparency/blob/main/audits/dreusd/2026-03-quantstamp-dreusd.pdf
___

### Q: Please list any relevant protocol resources.
https://www.dre.app/
https://www.docs.dre.app/

___

### Q: Additional audit information.
The reward tiers breakdown (each tier includes the LSW fixed pay, community judging pot and LJ fixed pay):

- **Guaranteed** - will be paid out even if there are no issues - 20,000 USDC.
- **Medium** - the pot if at least one Medium is found - 40,000 USDC.
- **High** - the pot if at least one High is found - 60,000 USDC.

Forked / inherited contracts:
No contracts are forked from other protocols. All core logic is custom-written. The codebase inherits from standard, unmodified OpenZeppelin Upgradeable contracts and LayerZero OFT contracts:
OpenZeppelin Contracts Upgradeable: ERC20PermitUpgradeable, ERC4626Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, PausableUpgradeable, ReentrancyGuardTransient
LayerZero: OFTUpgradeable, OFTAdapterUpgradeable
Chainlink: AggregatorV3Interface (interface only)
Aave V3: IAaveV3Pool (custom interface for withdraw() and getReserveData())

Previous audits and changes since:

Two prior audits were completed:

Spearbit (Cantina) - Feb 8–14, 2026 on commit 49e08974. Found 35 issues (10 Medium, 22 Low, 3 Gas). All findings were addressed and verified by Spearbit on commit 3c0e338a.
Quantstamp - Feb 23 – Mar 2, 2026 on commit e167c45. Found 13 issues (1 Medium, 10 Low, 2 Informational). 11 fixed, 2 acknowledged. Fix review completed on commit 7428378.

Changes since the last audit fix review should be the primary focus area.

Known issues / acceptable risks (from prior audits):

Bridge sends can credit blocked recipients on destination (Quantstamp DRE-7, Acknowledged). Cross-chain bridge routing uses a quarantine pattern. Blocked recipients can be credited on the destination chain via _credit() (which bypasses compliance checks), but they are unable to subsequently transfer, stake, or redeem. This is by design — funds are quarantined rather than stuck in LayerZero's message queue.

Express filler debt can be reimbursed to incorrect filler (Quantstamp DRE-12, Acknowledged). expressFillerDebt is tracked globally, not per filler. payExpressDebt() repays to the configured expressPaybackAddress, not to the individual filler who advanced USDC. This is acceptable because we intend to have only one express filler provider. If multiple fillers are added in the future, the expressPaybackAddress will be updated to a shared address and funds split manually through governance.

Ownership can be renounced (Quantstamp S1, Acknowledged). OpenZeppelin's Ownable and AccessControl allow renounceOwnership() and renounceRole(). We acknowledge this risk but prefer not to override battle-tested inheritance trees solely to disable renounce flows. This is managed operationally — privileged roles are not intended to be renounced.

Compose flow can get stuck on freeze/sanctions/pause (Spearbit 5.2.3, Acknowledged). Cross-chain compose operations (spoke-to-hub deposit+stake) can revert if the vault is paused or the recipient is frozen/sanctioned between send and execution. The refund path depends on the same compliance checks. This requires operator intervention to unblock. Documented as an operational risk with monitoring.

Centralization risks (Spearbit 5.2.15). All administrative control rests with multisig wallets. No on-chain governance or token voting. This is intentional at this stage. Mitigated by 48-hour timelock on all admin actions, multi-sig requirements, and geographically distributed key holders.

ERC-4626 max* view functions do not fully account for paused or sanctioned states (Spearbit QA 6.1.8). maxDeposit(), maxMint(), maxWithdraw(), maxRedeem() may return non-zero values even when the contract is paused or the caller is blocked. The actual deposit/withdraw/redeem transactions will revert correctly, but off-chain integrations reading these view functions may get inaccurate previews. This is a known deviation from strict ERC-4626 compliance.

Areas Watsons should focus on:
Cross-chain flows (dreOVaultComposer, dreShareOFT, dreShareOFTAdapter). The compose pattern (spoke-to-hub deposit + vault stake), refund mechanism, and cross-chain compliance enforcement are the most complex flows. Edge cases around message ordering, partial failures, stuck funds, and compliance state desynchronization across chains are high-value areas.
Reward distribution and vesting (dreRewardsDistributor + dreUSDs interaction). The linear vesting mechanism, _virtualBalance accounting, share price calculation via totalAssets(), and the interaction between addRewards(), claimVested(), and vault deposit/withdraw flows. Any mechanism that could deflate or inflate the share price is high priority.
Withdrawal queue mechanics (dreUSDManager + dreWithdrawalNFT). Express and standard withdrawal paths, NFT minting/burning, fee calculations, the express capacity tracking (expressWithdrawalAvailable, expressFillerDebt, expressWithdrawalMaxLimit), and the payback mechanism.
Oracle interactions (dreUSDOracle). Price validation during minting and withdrawals, staleness checks, deviation thresholds, sequencer uptime checks, and decimal conversion between 6-decimal stablecoins and 18-decimal dreUSD.

Compliance enforcement consistency. _validateAddress() checks across dreUSD, dreUSDs, dreWithdrawalNFT, dreShareOFT, and dreUSDManager. Ensure sanctions and freeze enforcement is consistent across all mint, transfer, stake, withdraw, and bridge flows with no bypass paths.

It's assumed that Aave pools will not suffer a loss.


# Audit scope

[dreusd @ cbc24961331f5d97b46e3e7143b2f8f8aa057be8](https://github.com/dre-labs/dreusd/tree/cbc24961331f5d97b46e3e7143b2f8f8aa057be8)
- [dreusd/contracts/dreAaveAdapter.sol](dreusd/contracts/dreAaveAdapter.sol)
- [dreusd/contracts/dreRewardsDistributor.sol](dreusd/contracts/dreRewardsDistributor.sol)
- [dreusd/contracts/dreUSDManager.sol](dreusd/contracts/dreUSDManager.sol)
- [dreusd/contracts/dreUSDOracle.sol](dreusd/contracts/dreUSDOracle.sol)
- [dreusd/contracts/dreUSD.sol](dreusd/contracts/dreUSD.sol)
- [dreusd/contracts/dreUSDs.sol](dreusd/contracts/dreUSDs.sol)
- [dreusd/contracts/dreVault.sol](dreusd/contracts/dreVault.sol)
- [dreusd/contracts/dreWithdrawalKeeperBot.sol](dreusd/contracts/dreWithdrawalKeeperBot.sol)
- [dreusd/contracts/dreWithdrawalNFT.sol](dreusd/contracts/dreWithdrawalNFT.sol)
- [dreusd/contracts/governance/dreTimelockController.sol](dreusd/contracts/governance/dreTimelockController.sol)
- [dreusd/contracts/interfaces/IAaveV3Adapter.sol](dreusd/contracts/interfaces/IAaveV3Adapter.sol)
- [dreusd/contracts/interfaces/IAaveV3Pool.sol](dreusd/contracts/interfaces/IAaveV3Pool.sol)
- [dreusd/contracts/interfaces/IAutomationCompatible.sol](dreusd/contracts/interfaces/IAutomationCompatible.sol)
- [dreusd/contracts/interfaces/IdreRewardsDistributor.sol](dreusd/contracts/interfaces/IdreRewardsDistributor.sol)
- [dreusd/contracts/interfaces/IdreUSDManager.sol](dreusd/contracts/interfaces/IdreUSDManager.sol)
- [dreusd/contracts/interfaces/IDreUSDOracle.sol](dreusd/contracts/interfaces/IDreUSDOracle.sol)
- [dreusd/contracts/interfaces/IdreUSD.sol](dreusd/contracts/interfaces/IdreUSD.sol)
- [dreusd/contracts/interfaces/IdreUSDs.sol](dreusd/contracts/interfaces/IdreUSDs.sol)
- [dreusd/contracts/interfaces/IdreVault.sol](dreusd/contracts/interfaces/IdreVault.sol)
- [dreusd/contracts/interfaces/IdreWithdrawalKeeperBot.sol](dreusd/contracts/interfaces/IdreWithdrawalKeeperBot.sol)
- [dreusd/contracts/interfaces/ISanctionsList.sol](dreusd/contracts/interfaces/ISanctionsList.sol)
- [dreusd/contracts/interfaces/IWithdrawalKeeperManager.sol](dreusd/contracts/interfaces/IWithdrawalKeeperManager.sol)
- [dreusd/contracts/interfaces/IWithdrawalNFTQueue.sol](dreusd/contracts/interfaces/IWithdrawalNFTQueue.sol)
- [dreusd/contracts/interfaces/IWithdrawalNFT.sol](dreusd/contracts/interfaces/IWithdrawalNFT.sol)
- [dreusd/contracts/libraries/ScalingConstants.sol](dreusd/contracts/libraries/ScalingConstants.sol)
- [dreusd/contracts/ovault/dreOVaultComposer.sol](dreusd/contracts/ovault/dreOVaultComposer.sol)
- [dreusd/contracts/ovault/dreShareOFTAdapter.sol](dreusd/contracts/ovault/dreShareOFTAdapter.sol)
- [dreusd/contracts/ovault/dreShareOFT.sol](dreusd/contracts/ovault/dreShareOFT.sol)
- [dreusd/contracts/whitelist/SanctionsListWhitelistWrapper.sol](dreusd/contracts/whitelist/SanctionsListWhitelistWrapper.sol)


