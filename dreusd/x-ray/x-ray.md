# DRE USD X-Ray

> Pre-audit protocol briefing. This is not a vulnerability report.

Analyzed branch: `main` at `26ad8712cb7e5608e8308a937ef432dc0dffe906`

## 1. Protocol Overview

DRE is a hybrid **fiat-backed stablecoin**, **ERC-4626 yield vault**, and
**cross-chain OFT/OVault system**.

| Subsystem | Contracts | Responsibility |
|---|---|---|
| Stablecoin core | `dreUSD`, `dreUSDManager`, `dreUSDOracle` | Compliance-aware dreUSD mint/burn, fiat and tokenized minting, oracle conversion, withdrawal accounting |
| Yield | `dreUSDs`, `dreRewardsDistributor` | ERC-4626 staking shares and linearly vested dreUSD rewards |
| Withdrawals | `dreWithdrawalNFT`, `dreWithdrawalKeeperBot`, `dreAaveAdapter` | Transferable withdrawal claims, automated queue selection, Aave-funded settlement |
| Custody | `dreVault` | Permissionless forwarding of configured stablecoin to downstream custody |
| Cross-chain | `dreOVaultComposer`, `dreShareOFT`, `dreShareOFTAdapter`, `dreUSD` | LayerZero asset/share bridging, compose operations, quarantine fallback |
| Governance/compliance | `dreTimelockController`, `SanctionsListWhitelistWrapper` | Delayed privileged execution and allowlist-wrapped sanctions |

The hub deployment holds the complete system. Spoke deployments contain dreUSD
and share OFTs, while the hub share adapter locks canonical vault shares.

### Principal Value Flows

1. Stablecoin mint: user stablecoin moves to `custodianVault`; oracle-valued
   dreUSD is minted to the user or directly deposited into dreUSDs.
2. Fiat mint: a keeper submits a custodian-signed authorization; dreUSD is
   minted against off-chain reserves subject to replay and daily-cap controls.
3. Standard withdrawal: dreUSD is burned and replaced with a transferable NFT;
   after the waiting period, treasury liquidity or Aave-backed liquidity pays
   the current NFT owner in USDC.
4. Express withdrawal: dreUSD is burned and an express NFT is minted; an
   operator fronts USDC plus fees and the protocol tracks filler debt/capacity.
5. Yield: dreUSD is funded into the distributor, vested linearly, and claimed
   into the vault's virtual accounting balance.
6. Bridge: dreUSD uses mint/burn OFT accounting; vault shares use a hub lockbox
   adapter and spoke share OFTs.

### Backwards-Compatibility Code

No source construct met all X-Ray requirements for classification as inactive
backwards-compatibility code. Upgrade storage gaps are active layout safeguards.

## 2. Threat and Trust Model

Protocol classified as **Stablecoin / Yield Aggregator** with **Bridge** and
centralized custody characteristics.

### Actors

| Actor | Trust | Capabilities |
|---|---|---|
| User | Untrusted | Mint, stake, transfer, bridge, request withdrawals |
| Keeper | Trusted operator | Submit signed fiat/reward mints |
| Treasury | Trusted operator | Fill standard withdrawals, repay express debt, withdraw manager-held tokens |
| Express operator | Trusted operator | Front USDC for express NFTs |
| Moderator/config roles | Privileged | Configure allowlists, oracle parameters, custody, queue limits |
| Guardian/pauser | Privileged emergency actor | Freeze addresses and pause operational paths |
| Upgrader/admin/owner | Fully trusted | Upgrade implementations, assign roles, replace critical endpoints |
| Custodian signer | External trusted party | Attest fiat backing and mint authorization |
| Chainlink | External trusted system | Stablecoin prices, sequencer status, automation triggers |
| LayerZero | External trusted system | Cross-chain message authenticity and delivery |
| Aave V3 | External trusted system | aUSDC accounting and USDC withdrawal liquidity |

### Permissionless Entry Points

The grep-verified and inherited value-moving surface includes:

- `dreUSDManager.mint(...)`, `mintFrom(...)`, and `mintAndStake(...)`
- `dreUSDManager.requestWithdrawal(...)` and `requestExpressWithdrawal(...)`
- inherited `dreUSDs.deposit/mint/withdraw/redeem`
- `dreUSDs.claimVestedRewards()`
- `dreVault.performUpkeep()`
- `dreWithdrawalKeeperBot.performUpkeep()`; manager role checks still apply downstream
- inherited ERC-20/ERC-721 transfer and approval functions
- inherited LayerZero OFT send/receive and composer entry points

Full access classification: [entry-points.md](entry-points.md).

### Trust Boundaries

- **Fiat backing boundary:** on-chain supply correctness depends on honest,
  unique custodian signatures corresponding to real reserves.
- **Oracle boundary:** mint and redemption amounts depend on configured
  Chainlink feeds, token decimals, freshness, deviation, and L2 sequencer data.
- **Custody boundary:** accepted mint assets leave the manager and are forwarded
  to external custody; backing cannot be proven solely from these contracts.
- **Upgrade boundary:** most critical contracts are UUPS-upgradeable.
- **Bridge boundary:** LayerZero messages create or release canonical value on
  destination chains; compliance failures intentionally quarantine rather than
  reject destination credits.
- **Liquidity boundary:** standard withdrawals may depend on vault aUSDC balance,
  allowance, Aave liquidity, and treasury execution.

### Key Attack Surfaces

- **Fiat mint authorization and daily cap** &nbsp;&#91;[I-6](invariants.md#i-6), [X-4](invariants.md#x-4)&#93; — worth confirming reserve attestations, replay domains, signer rotation, and cap behavior across operational days.

- **Oracle decimal, freshness, deviation, and sequencer conversion** &nbsp;&#91;[I-8](invariants.md#i-8), [X-1](invariants.md#x-1)&#93; — every mint and withdrawal conversion crosses this boundary.

- **ERC-4626 virtual balance and streamed reward accounting** &nbsp;&#91;[I-1](invariants.md#i-1), [X-2](invariants.md#x-2), [E-2](invariants.md#e-2)&#93; — worth tracing every path that changes real dreUSD, virtual assets, vested rewards, or share supply.

- **Express capacity, debt, and fee lifecycle** &nbsp;&#91;[I-3](invariants.md#i-3), [I-4](invariants.md#i-4), [E-3](invariants.md#e-3)&#93; — request, fill, configuration, and payback jointly maintain this accounting.

- **Transferable withdrawal claims and queue progression** &nbsp;&#91;[I-5](invariants.md#i-5), [X-3](invariants.md#x-3)&#93; — settlement pays the current compliant owner rather than the original requester.

- **LayerZero credit and fallback quarantine** &nbsp;&#91;[X-5](invariants.md#x-5), [E-4](invariants.md#e-4)&#93; — destination credits deliberately bypass normal address validation and rely on later transfer restrictions or fallback custody.

- **Aave adapter liquidity and exact redemption** &nbsp;&#91;[X-3](invariants.md#x-3)&#93; — manager settlement assumes adapter token identity, vault allowance, aToken behavior, and pool liquidity remain coherent.

- **Privileged replacement and upgrade surface** — admin, owner, moderator,
  withdrawal-config, and upgrader roles can replace core trust endpoints.

### Centralization and Pause Coverage

The code defines a timelock and documents multisig ownership, but role assignment
is deployment-specific. `dreUSDManager`, `dreUSDs`, and
`dreRewardsDistributor` expose emergency pause paths. dreUSD uses address-level
freeze rather than global pause. Oracle, Aave adapter, NFT, vault forwarder, and
bridge contracts do not share one protocol-wide emergency switch.

## 3. Invariants

> **61 enforced guards, 9 single-contract invariants, 5 cross-contract assumptions, and 4 economic properties catalogued.** See the complete [Invariant Map](invariants.md).

## 4. Integrations

| Integration | Usage | Failure effect |
|---|---|---|
| Chainlink price feeds | USD/token conversion and peg validation | Mint and withdrawal quoting reverts |
| Chainlink sequencer feed | L2 health and grace period | Oracle-dependent flows revert |
| Chainlink Automation | Vault forwarding and withdrawal keeper triggering | Operations remain callable manually but automation stalls |
| Aave V3 | Redeem custodied aUSDC for withdrawal USDC | Vault-funded standard fills revert or lack liquidity |
| LayerZero OFT/OVault | Cross-chain dreUSD and share movement | Bridge delivery, refunds, or compose operations may stall/fallback |
| Sanctions oracle | Transfers, vault operations, NFT ownership | Blocked users cannot use normal movement paths |
| ERC-20 Permit/ECDSA | Delegated mint authorization | Signature/domain/nonce correctness is security-critical |

## 5. Test Analysis

- 21 Solidity test files and 649 `test*` functions were detected.
- 17 stateless fuzz tests were detected.
- Fork tests are present for deployment flows.
- No Foundry stateful `invariant_*`, Echidna, Medusa, Halmos, or Certora suite
  was detected.
- `forge coverage` exceeded the three-minute collection window, so line and
  branch coverage metrics are unavailable. This does not change test-existence
  counts.
- A subsequent full `forge test --summary` run also exceeded five minutes, so
  this X-Ray does not claim a passing or failing runtime test verdict.

### Highest-Value Test Gaps

1. Stateful conservation tests spanning mint, stake, reward vest, withdraw NFT,
   express fill, debt payback, and bridge cycles.
2. Cross-chain supply/lockbox invariants under failed delivery, quarantined
   recipients, compose refunds, retries, and upgrades.
3. Stateful oracle tests combining feed replacement, staleness, sequencer
   recovery, token decimals, and parameter changes.
4. Role-transition tests proving timelock/multisig deployment assignments and
   emergency pause coverage.
5. Long-running queue models with transferred NFTs, blocked holders,
   out-of-order fills, limited Aave liquidity, and keeper batches.

## 6. Documentation and Code Quality

Documentation is extensive and security-relevant: architecture, custody,
bridging, compliance, role, deployment, money-flow, fiat-mint, and timelock
documents are present. Contracts contain detailed NatSpec and explicit design
notes for quarantine behavior, virtual accounting, fee handling, and adapter
requirements.

Observed documentation drift:

- Some README/architecture descriptions describe older behavior, while source
  includes deviation thresholds and stricter vault/reward handling.
- `IMPLEMENTATION_STATUS.md` itself records requirement/design differences.
- Security guarantees therefore need to be sourced from current code plus the
  latest operational configuration, not a single overview document.

The largest concentration of review effort is `dreUSDManager.sol` at 1,064
lines, followed by the 445-line oracle.

## 7. Git History

The current branch contains one commit (`26ad871`, "Initial commit") by one
recorded contributor. This is a squashed import, so fix-candidate analysis,
review cadence, ownership distribution, late changes, and dangerous-area
evolution cannot be inferred from branch history.

The working tree contains pre-existing LayerZero submodule changes outside this
X-Ray output. They were not modified by this run.

### Security Observations

- No historical co-change or review signal is available from the current branch.
- The internal audit report records previously identified and fixed issues, but
  git history cannot independently establish the associated patches.
- The manager and oracle dominate current source size and deserve review
  priority based on code volume, not commit frequency.

## 8. Recommended Audit Order

1. `dreUSDManager` mint, fiat authorization, withdrawal queues, and role paths.
2. `dreUSDs` plus `dreRewardsDistributor` asset/share/reward accounting.
3. `dreUSDOracle` conversions and all feed/sequencer configuration.
4. LayerZero token/share supply accounting and fallback custody.
5. Aave settlement, queue NFTs, keeper ordering, and custody forwarding.
6. Deployment scripts and actual role/timelock/multisig wiring.

## X-Ray Verdict

**ADEQUATE** — The repository has extensive unit and stateless fuzz coverage, strong protocol documentation, explicit role boundaries, timelock and emergency controls, but no stateful invariant suite or formal verification and no usable coverage metrics from this run.

**Structural facts:**
1. 3,415 production Solidity lines across 15 non-interface, non-mock contracts.
2. 21 test files contain 649 test functions, including 17 stateless fuzz tests and no stateful invariant functions.
3. Nine principal contracts are upgradeable or inherit upgradeable cross-chain components.
4. `dreUSDManager.sol` contains 1,064 lines and coordinates the majority of value-moving flows.
5. Current-branch git history is a single squashed commit, so temporal review signals are unavailable.
