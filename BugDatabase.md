# Vulnerability Intelligence Database

Source: `AOS/BugdetabaseRaw.md`

This database converts each source report into a reusable audit pattern. Stable IDs follow source-file order. Repeated source numbers and repeated findings remain separate to prevent information loss.

==================================================
## VULN-001
Source reference: Bug Deep Dive #1
======

### BUG ID
VULN-001

### TITLE
Equivalent Economic Outcomes Use Different Fee Paths

### CATEGORY
Incentive Design / Fee Accounting

### SEVERITY
Medium

### ROOT CAUSE
Fees are charged by action type or trade direction, while another protocol path can transform positions into the same final economic state at a lower total fee.

### BROKEN INVARIANT
Economically equivalent state transitions should have equivalent total protocol cost unless the difference is an intentional subsidy.

### WHY THE BUG EXISTS
The fee model was reviewed per function, but not across complete user journeys that combine trading, complementary positions, and redemption.

### ATTACK SURFACE
Swap, order matching, complementary-token minting, redemption, claim-fee, and settlement functions.

### PRECONDITIONS
A user can reach the same final asset exposure through at least two paths, and the cheaper path costs less after all fees.

### ATTACK PATH
Hold one outcome token; buy its complement through the cheaper trade direction; combine both claims; redeem the complete set; receive more net collateral than through the direct exit path.

### WHAT ASSUMPTION FAILED
Different trade directions were assumed to represent different economic actions.

### GENERIC PATTERN
Path-dependent fee asymmetry for economically equivalent outcomes.

### DETECTION HEURISTICS
Build a state-equivalence graph; calculate every path to the same terminal portfolio; compare net fees and protocol revenue.

### SEARCH KEYWORDS
fee, redeem, complete set, outcome token, buy, sell, claim, collateral, matching

### AUDITOR MENTAL TRIGGERS
â€œCan I get the same final assets by doing the opposite trade and then redeeming?â€

### CODE SMELLS
Direction-specific fee formulas; separate trade and redemption fees; no cross-path economic tests.

### COMMON VARIATIONS OF THIS BUG
Mint-versus-buy fee bypass; withdraw-versus-swap bypass; wrap/unwrap path charging less than direct transfer; liquidation-versus-repayment fee asymmetry.

### POTENTIAL IMPACTS
Lost protocol revenue, unfair execution, predictable fee avoidance, and distorted market behavior.

### REPOSITORY SCAN STRATEGY
Map all functions that change user exposure or convert claims into collateral. Compare final balances from alternate call sequences.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Fee libraries, exchange engines, redemption modules, settlement contracts, market makers, and token conversion modules.

### FUNCTION TYPES TO INVESTIGATE
`swap`, `buy`, `sell`, `mint`, `merge`, `redeem`, `claim`, `settle`.

### AI AUDITOR PLAYBOOK
Normalize each path into: initial portfolio, calls, fees paid, final portfolio. Flag a cheaper path with the same final state.

### STEP-BY-STEP DETECTION PROCESS
1. Define a target final portfolio.
2. Enumerate direct and composed paths.
3. Include every fee.
4. Compare net proceeds.
5. Confirm the difference is repeatable and not an intended discount.

### CANONICAL LESSON
Audit fees across complete economic journeys, not one function at a time.

==================================================
## VULN-002
Source reference: Bug Deep Dive #2
======

### BUG ID
VULN-002

### TITLE
Mandatory Token Metadata Rule Is Not Implemented

### CATEGORY
Standards Compliance

### SEVERITY
Medium when the scope explicitly treats mandatory standard violations as Medium; otherwise context-dependent.

### ROOT CAUSE
The token metadata function returns an empty or invalid value instead of data required by a normative `MUST` rule.

### BROKEN INVARIANT
Every advertised standard interface must satisfy all mandatory behavioral requirements.

### WHY THE BUG EXISTS
Interface compatibility was treated as successful compilation rather than semantic compliance.

### ATTACK SURFACE
Metadata getters, interface detection, wallets, indexers, marketplaces, and integrations.

### PRECONDITIONS
The protocol claims standard compliance and the contest or product requirements treat the violated rule as mandatory.

### ATTACK PATH
An integration queries metadata; receives an invalid URI; cannot load schema-compliant metadata or process the token as promised.

### WHAT ASSUMPTION FAILED
Implementing the interface signature was assumed to be enough for compliance.

### GENERIC PATTERN
Nominal interface support without required standard behavior.

### DETECTION HEURISTICS
Compare each implemented standard against every normative `MUST` and `MUST NOT` statement.

### SEARCH KEYWORDS
ERC1155, URI, metadata, supportsInterface, MUST, standard, empty string

### AUDITOR MENTAL TRIGGERS
â€œDoes this return value satisfy the standard, or only the Solidity type?â€

### CODE SMELLS
Stub getters; empty strings; constant zero values; incomplete interface implementations.

### COMMON VARIATIONS OF THIS BUG
Broken ERC-165 claims, missing ERC-721 receiver behavior, invalid ERC-4626 previews, and incorrect ERC-1271 return values.

### POTENTIAL IMPACTS
Integration failure, unusable metadata, broken marketplace support, or contest-defined security impact.

### REPOSITORY SCAN STRATEGY
List claimed standards from inheritance, README, and `supportsInterface`; verify mandatory behavior line by line.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Token contracts, interfaces, metadata modules, adapters, and documentation.

### FUNCTION TYPES TO INVESTIGATE
`uri`, `tokenURI`, `supportsInterface`, receiver callbacks, preview functions.

### AI AUDITOR PLAYBOOK
Retrieve the standardâ€™s normative requirements and match each one to code and tests.

### STEP-BY-STEP DETECTION PROCESS
1. Identify claimed standards.
2. Extract `MUST` rules.
3. Locate implementations.
4. Test edge return values.
5. Check scope-specific severity rules.

### CANONICAL LESSON
Standards compliance is behavioral, not syntactic.

==================================================
## VULN-003
Source reference: Bug Deep Dive #3
======

### BUG ID
VULN-003

### TITLE
Missing Emergency Resolution Permanently Locks User Funds

### CATEGORY
State Management / DoS / Business Logic

### SEVERITY
Medium

### ROOT CAUSE
The state machine has only a successful external-resolution path and no invalidation, timeout, refund, or emergency terminal state.

### BROKEN INVARIANT
Every fund-locking workflow must have a reachable terminal path that returns or distributes assets, even if an external dependency fails permanently.

### WHY THE BUG EXISTS
The design models the oracle or off-chain event as eventually successful and omits failure-state transitions.

### ATTACK SURFACE
Prediction markets, bridges, disputes, escrow, oracle settlement, auctions, and delayed claims.

### PRECONDITIONS
Funds are locked; resolution depends on external data; the event is canceled, ambiguous, unavailable, or never finalized.

### ATTACK PATH
External resolution never arrives; claim requires a resolved flag; every claim reverts; no privileged or permissionless fallback can close the market and return collateral.

### WHAT ASSUMPTION FAILED
The external process was assumed to always produce a valid result.

### GENERIC PATTERN
Fund-locking state machine lacks an escape hatch for failed external resolution.

### DETECTION HEURISTICS
Draw all terminal states and ask what happens if every external callback or oracle update never occurs.

### SEARCH KEYWORDS
resolved, finalized, oracle, claim, invalidate, cancel, timeout, emergency, refund

### AUDITOR MENTAL TRIGGERS
â€œWhat if this real-world event can never be resolved?â€

### CODE SMELLS
Claims guarded by one resolution flag; no deadline fallback; no refund state; no cancellation function.

### COMMON VARIATIONS OF THIS BUG
Bridge message never delivered; auction never finalized; keeper never calls settle; dispute remains pending forever.

### POTENTIAL IMPACTS
Permanent asset lock, protocol-wide liveness failure, and unrecoverable user positions.

### REPOSITORY SCAN STRATEGY
Search for locked balances and all functions that release them. Verify at least one release path remains available under dependency failure.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Market controllers, resolvers, oracle adapters, escrow, settlement, and emergency modules.

### FUNCTION TYPES TO INVESTIGATE
`resolve`, `finalize`, `claim`, `refund`, `cancel`, `invalidate`, `emergencyWithdraw`.

### AI AUDITOR PLAYBOOK
For every external dependency, simulate permanent silence, permanent revert, and invalid data.

### STEP-BY-STEP DETECTION PROCESS
1. Find fund-locking transitions.
2. Identify release conditions.
3. Remove each external dependency.
4. Test whether a terminal state remains reachable.
5. Measure affected balances and duration.

### CANONICAL LESSON
If external resolution can fail, asset recovery must still succeed.

==================================================
## VULN-004
Source reference: Bug Deep Dive #4
======

### BUG ID
VULN-004

### TITLE
Alternate Governance Execution Path Breaks `onlyGovernance`

### CATEGORY
Access Control / State Management / DoS

### SEVERITY
Medium

### ROOT CAUSE
Cross-chain proposals execute directly through a timelock instead of the governor execution function that prepares the internal authorization queue required by `onlyGovernance`.

### BROKEN INVARIANT
Every governance execution path must establish the same authorization state expected by governance-only functions.

### WHY THE BUG EXISTS
The alternate path preserves the final caller but skips hidden state changes performed by the canonical execution flow.

### ATTACK SURFACE
Cross-chain governance, timelocks, proposal queues, governor extensions, and privileged execution adapters.

### PRECONDITIONS
A satellite or alternate executor calls the timelock directly and the target function uses stateful `onlyGovernance` validation.

### ATTACK PATH
Proposal is scheduled cross-chain; timelock calls the target; the governor-specific queue was never populated; `onlyGovernance` rejects the otherwise valid action.

### WHAT ASSUMPTION FAILED
The same apparent caller was assumed to make direct and canonical execution equivalent.

### GENERIC PATTERN
Alternate privileged route skips authorization side effects of the canonical route.

### DETECTION HEURISTICS
Compare complete traces of local, cross-chain, emergency, and timelock execution paths.

### SEARCH KEYWORDS
onlyGovernance, Governor, Timelock, execute, queue, cross-chain, satellite

### AUDITOR MENTAL TRIGGERS
â€œWhat state does the standard execution function set before the timelock call?â€

### CODE SMELLS
Direct timelock calls; duplicated proposal execution; inherited stateful modifiers; bypassed framework methods.

### COMMON VARIATIONS OF THIS BUG
Safe module bypasses guard setup; bridge executor skips nonce registration; emergency route skips role handoff.

### POTENTIAL IMPACTS
Governance functions become permanently unusable on some chains or execution routes.

### REPOSITORY SCAN STRATEGY
Trace each proposal path from origin to target and compare modifiers, queues, hashes, and caller context.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Governors, timelocks, bridge executors, satellite contracts, proposal routers, and access-control modules.

### FUNCTION TYPES TO INVESTIGATE
`propose`, `queue`, `schedule`, `execute`, cross-chain receive handlers.

### AI AUDITOR PLAYBOOK
Diff the canonical framework call graph against every custom execution path.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the canonical governance flow.
2. Record its state writes.
3. Trace alternate flows.
4. Find missing writes or changed callers.
5. execute a governance-only target through each path.

### CANONICAL LESSON
Matching the final caller does not reproduce the full authorization context.

==================================================
## VULN-005
Source reference: Bug Deep Dive #5
======

### BUG ID
VULN-005

### TITLE
Backing Can Be Withdrawn Without Burning Governance Power

### CATEGORY
Accounting / Governance

### SEVERITY
Medium

### ROOT CAUSE
Governance tokens are minted when assets are locked, but an independent withdrawal or recall path releases the backing without burning or reducing the governance tokens.

### BROKEN INVARIANT
Outstanding governance power must not exceed the eligible backing or locked stake that created it.

### WHY THE BUG EXISTS
Mint accounting exists on the deposit path, but the reverse transition was omitted from another asset-exit path.

### ATTACK SURFACE
Staking, vesting, escrow recall, withdrawal, governance wrappers, and vote delegation.

### PRECONDITIONS
The user can receive governance power and later remove the backing through a path that does not update it.

### ATTACK PATH
Lock assets; receive governance tokens; withdraw or recall the locked assets; retain unbacked voting power.

### WHAT ASSUMPTION FAILED
Backing assets were assumed to remain locked for as long as governance tokens exist.

### GENERIC PATTERN
Mint-on-entry without burn-on-every-exit.

### DETECTION HEURISTICS
For every mint trigger, enumerate all paths that reduce or release backing and verify a matching burn.

### SEARCH KEYWORDS
governance token, voting power, escrow, vesting, withdraw, recall, mint, burn

### AUDITOR MENTAL TRIGGERS
â€œCan the backing leave through another contract?â€

### CODE SMELLS
Cross-contract backing custody; multiple withdrawal functions; mint and burn logic in different modules.

### COMMON VARIATIONS OF THIS BUG
Unbacked receipt shares, retained rewards after unstake, debt shares not burned on repayment, delegated votes after unlock.

### POTENTIAL IMPACTS
Governance inflation, unfair voting, proposal capture, and unbacked derivative supply.

### REPOSITORY SCAN STRATEGY
Build a backing-to-representation conservation table and inspect every balance-decreasing path.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Escrow, vesting wallets, staking, governance tokens, delegation modules, and recall controllers.

### FUNCTION TYPES TO INVESTIGATE
`stake`, `lock`, `mint`, `withdraw`, `recall`, `revoke`, `burn`.

### AI AUDITOR PLAYBOOK
Track supply and backing as paired variables across all contracts and all exits.

### STEP-BY-STEP DETECTION PROCESS
1. Find representation minting.
2. Identify backing location.
3. Enumerate backing exits.
4. Verify representation reduction.
5. test a full deposit-withdraw cycle.

### CANONICAL LESSON
Every backing exit must reverse the representation created on entry.

==================================================
## VULN-006
Source reference: Bug Deep Dive #6
======

### BUG ID
VULN-006

### TITLE
Preview Omits Uncollected Fees From Compounded Position Value

### CATEGORY
Accounting / View Consistency

### SEVERITY
Medium

### ROOT CAUSE
The balance preview values a compounded liquidity position using stored balances but excludes fees accrued in the external AMM position and not yet collected.

### BROKEN INVARIANT
A documented withdrawal preview must match the assets a user would receive from an immediate withdrawal within the allowed tolerance.

### WHY THE BUG EXISTS
The view path reads internal accounting only, while the state-changing withdrawal path realizes external fee growth.

### ATTACK SURFACE
Position previews, NAV calculations, withdrawal quotes, frontends, and integrator accounting.

### PRECONDITIONS
The position has uncollected external fees and the preview promises withdrawal-equivalent balances.

### ATTACK PATH
Fees accrue; preview ignores them; user or integration receives an understated balance; downstream limits, accounting, or actions use incorrect values.

### WHAT ASSUMPTION FAILED
Stored balances were assumed to contain all withdrawable value.

### GENERIC PATTERN
View-state simulation omits lazy external accrual realized by the write path.

### DETECTION HEURISTICS
Diff every preview function against the corresponding state-changing function line by line.

### SEARCH KEYWORDS
queryAssetBalances, preview, collect, feesOwed, feeGrowth, compounded, withdraw

### AUDITOR MENTAL TRIGGERS
â€œWhat does withdrawal realize that the view does not simulate?â€

### CODE SMELLS
View reads storage only; withdrawal calls external pool accounting; duplicated valuation formulas.

### COMMON VARIATIONS OF THIS BUG
Missing rewards, interest, penalties, debt accrual, rebases, or pending exchange-rate updates.

### POTENTIAL IMPACTS
Incorrect UI values, broken integrations, failed minimum-output checks, and incorrect risk accounting.

### REPOSITORY SCAN STRATEGY
Pair each query/preview with its execution function and compare all accrual, fee, penalty, and external-state steps.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
View facets, position managers, AMM adapters, fee libraries, and withdrawal modules.

### FUNCTION TYPES TO INVESTIGATE
`previewWithdraw`, `queryAssetBalances`, `positionValue`, `removeLiquidity`, `collect`.

### AI AUDITOR PLAYBOOK
Create identical state snapshots; call preview; simulate immediate withdrawal; compare outputs.

### STEP-BY-STEP DETECTION PROCESS
1. Identify promised preview semantics.
2. Trace withdrawal calculations.
3. List lazy accrual sources.
4. Check preview coverage.
5. quantify deviation.

### CANONICAL LESSON
Preview logic must simulate every value-changing step of execution.

==================================================
## VULN-007
Source reference: Bug Deep Dive #7
======

### BUG ID
VULN-007

### TITLE
Duplicate Pools Redirect Token-Level Rewards

### CATEGORY
Incentive Design / Identity

### SEVERITY
High

### ROOT CAUSE
Rewards are accounted by token pair or token address, while the AMM permits multiple distinct pools for the same pair.

### BROKEN INVARIANT
Rewards assigned to one market identity must only be claimable by liquidity belonging to that exact market.

### WHY THE BUG EXISTS
The protocol uses a weaker identity key than the underlying AMM.

### ATTACK SURFACE
Pool creation, reward registration, hooks, liquidity modification, and donation/distribution functions.

### PRECONDITIONS
Anyone can create another pool with the same tokens but different pool parameters and trigger reward distribution.

### ATTACK PATH
Create duplicate pool; add minimal liquidity; trigger token-level reward accrual or donation; capture rewards in attacker-controlled pool; withdraw.

### WHAT ASSUMPTION FAILED
A token pair was assumed to identify exactly one pool.

### GENERIC PATTERN
Accounting key is less specific than the resource identity it represents.

### DETECTION HEURISTICS
Compare mapping keys against the complete canonical identifier used by the external protocol.

### SEARCH KEYWORDS
poolId, PoolKey, token pair, reward, hook, donate, createPool, mapping token

### AUDITOR MENTAL TRIGGERS
â€œCan two resources share this accounting key?â€

### CODE SMELLS
Mappings keyed only by token; ignored fee/tickSpacing/hook fields; permissionless pool creation.

### COMMON VARIATIONS OF THIS BUG
Duplicate vaults, chains, gauges, markets, collateral types, or NFTs sharing one reward bucket.

### POTENTIAL IMPACTS
Reward theft, dilution, redirected emissions, and loss to legitimate liquidity providers.

### REPOSITORY SCAN STRATEGY
List all identity fields in the external system and compare them with internal reward keys.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Reward distributors, pool registries, hooks, factories, gauge controllers, and adapters.

### FUNCTION TYPES TO INVESTIGATE
`createPool`, `register`, `accrue`, `donate`, `beforeAddLiquidity`, `claim`.

### AI AUDITOR PLAYBOOK
Construct two valid resources that collide under the protocolâ€™s key and test whether one can consume the otherâ€™s accounting.

### STEP-BY-STEP DETECTION PROCESS
1. Derive canonical resource identity.
2. Inspect internal keys.
3. Find omitted dimensions.
4. Create a collision.
5. trigger and measure value transfer.

### CANONICAL LESSON
Internal accounting must use an identity key at least as strong as the external resource ID.

==================================================
## VULN-008
Source reference: repeated source label Bug Deep Dive #6
======

### BUG ID
VULN-008

### TITLE
Exact-Output Input Is Rounded Down and Then Truncated

### CATEGORY
Precision / Accounting

### SEVERITY
High

### ROOT CAUSE
The required input for an exact-output trade is divided with floor rounding and later converted to an integer by discarding the full fractional component.

### BROKEN INVARIANT
For exact output, the charged input must be greater than or equal to the mathematically required input.

### WHY THE BUG EXISTS
Two individually small precision losses align in the traderâ€™s favor at a token-unit boundary.

### ATTACK SURFACE
Exact-output swaps, decimal conversion, fixed-point math, and integer token transfer.

### PRECONDITIONS
The true input has a fractional smallest-unit component and the final conversion floors it.

### ATTACK PATH
Choose output so required input is `N + fraction`; calculation floors or truncates to `N`; receive full output while underpaying; repeat to accumulate pool loss.

### WHAT ASSUMPTION FAILED
Fractional fixed-point precision was assumed harmless before conversion to indivisible token units.

### GENERIC PATTERN
Double floor in exact-output pricing undercharges input.

### DETECTION HEURISTICS
Trace rounding direction through every intermediate type conversion and calculate errors in smallest token units.

### SEARCH KEYWORDS
exactAmountOut, divFloor, into_int, truncate, mulDivDown, requiredInput, decimals

### AUDITOR MENTAL TRIGGERS
â€œWho benefits when the required payment has a fraction?â€

### CODE SMELLS
Floor division in exact-output path; decimal-to-integer cast; no final round-up.

### COMMON VARIATIONS OF THIS BUG
Loan repayment shares rounded down, collateral requirements floored, fee debt truncated, and cross-decimal quote errors.

### POTENTIAL IMPACTS
Repeatable value extraction and gradual or complete pool drain.

### REPOSITORY SCAN STRATEGY
Search exact-output and debt-settlement math. Recompute with rational arithmetic and compare charged integer amounts.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Swap math, decimal libraries, quote engines, routers, and token conversion helpers.

### FUNCTION TYPES TO INVESTIGATE
`exactOutput`, `quoteIn`, `ask_exact_amount_out`, `mulDiv`, conversion functions.

### AI AUDITOR PLAYBOOK
Generate values just above each integer boundary and test whether output remains constant while input rounds down.

### STEP-BY-STEP DETECTION PROCESS
1. Determine correct rounding direction.
2. Follow all operations.
3. locate each floor.
4. choose boundary inputs.
5. repeat the trade and quantify cumulative loss.

### CANONICAL LESSON
Exact-output payment must round up at the final token-unit boundary.


==================================================
## VULN-009
Source reference: Bug Deep Dive #9
======

### BUG ID
VULN-009

### TITLE
Splitting Swaps Repeatedly Accesses the Best Price

### CATEGORY
Accounting / Market Design

### SEVERITY
Medium

### ROOT CAUSE
Each swap rebuilds passive liquidity at the same favorable starting level instead of preserving consumed depth across transactions.

### BROKEN INVARIANT
A trade of total size Q should not produce materially different output when split into smaller trades.

### WHY THE BUG EXISTS
Price impact exists only inside one call and resets before the next call.

### ATTACK SURFACE
Swap, quote, passive-order generation, reserve update.

### PRECONDITIONS
The best price level is regenerated and transaction cost is below the pricing advantage.

### ATTACK PATH
Split one large swap into many small swaps; repeatedly consume the first level; receive more total output.

### WHAT ASSUMPTION FAILED
Per-call curve generation was assumed to preserve persistent liquidity consumption.

### GENERIC PATTERN
Non-additive trade execution where partitioning bypasses price impact.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / Market Design.

### SEARCH KEYWORDS
Splitting, Swaps, Repeatedly, Accesses, Best, Price, Accounting, Market, Design

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Fee-minimum bypass; rate-limit reset; reward-tier reset.

### POTENTIAL IMPACTS
LP loss, unfair execution, MEV extraction.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Swap, quote, passive-order generation, reserve update.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Non-additive trade execution where partitioning bypasses price impact.

==================================================
## VULN-010
Source reference: Bug Deep Dive #10
======

### BUG ID
VULN-010

### TITLE
Asymmetric Liquidity Creates a Flat-Oracle-Price Swap

### CATEGORY
Economic Design / AMM

### SEVERITY
High

### ROOT CAUSE
Single-sided mint and immediate burn convert assets at oracle value while bypassing geometric price bands and trade-size impact.

### BROKEN INVARIANT
All economically equivalent conversions must use the same pricing and slippage model.

### WHY THE BUG EXISTS
Liquidity operations were treated as non-trading even though imbalance performs an implicit swap.

### ATTACK SURFACE
Asymmetric deposit, LP mint, withdrawal, oracle valuation.

### PRECONDITIONS
Single-sided liquidity and immediate withdrawal are allowed.

### ATTACK PATH
Deposit one asset; mint shares at oracle value; burn shares; receive the other asset at a better rate than direct swap.

### WHAT ASSUMPTION FAILED
Adding and removing liquidity was assumed not to be a swap route.

### GENERIC PATTERN
Liquidity lifecycle bypasses swap pricing.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Economic Design / AMM.

### SEARCH KEYWORDS
Asymmetric, Liquidity, Creates, Flat, Oracle, Price, Swap, Economic, Design

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Vault deposit-withdraw arbitrage; imbalanced stable-pool minting.

### POTENTIAL IMPACTS
LP losses and bypassed slippage.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Asymmetric deposit, LP mint, withdrawal, oracle valuation.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Liquidity lifecycle bypasses swap pricing.

==================================================
## VULN-011
Source reference: Bug Deep Dive #11
======

### BUG ID
VULN-011

### TITLE
Curve Order Sizing Omits Swap Fees

### CATEGORY
Accounting / Fee Logic

### SEVERITY
High

### ROOT CAUSE
Reflected XYK orders are sized with gross amounts while settlement applies fees using net amounts.

### BROKEN INVARIANT
Quote generation and settlement must preserve the same fee-adjusted invariant.

### WHY THE BUG EXISTS
Fee logic and curve logic use different amount domains.

### ATTACK SURFACE
Curve reflection, swap quote, fee deduction, reserve update.

### PRECONDITIONS
Mis-sized orders can be filled.

### ATTACK PATH
Trade against no-fee-sized orders; execution settles with different fee math; LP fee value leaks.

### WHAT ASSUMPTION FAILED
Fees were assumed not to affect order sizing.

### GENERIC PATTERN
Quote-settlement mismatch caused by omitted fees.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / Fee Logic.

### SEARCH KEYWORDS
Curve, Order, Sizing, Omits, Swap, Fees, Accounting, Logic

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Fee omitted from liquidation, loan quote, or slippage checks.

### POTENTIAL IMPACTS
Fee leakage, LP loss, invariant drift.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Curve reflection, swap quote, fee deduction, reserve update.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Quote-settlement mismatch caused by omitted fees.

==================================================
## VULN-012
Source reference: Bug Deep Dive #12 first
======

### BUG ID
VULN-012

### TITLE
Mid-Price Average Can Overflow and Halt Auctions

### CATEGORY
Precision / DoS

### SEVERITY
High

### ROOT CAUSE
The midpoint adds two large attacker-influenced prices before division.

### BROKEN INVARIANT
Every accepted price pair must produce a representable average without reverting.

### WHY THE BUG EXISTS
The final result fits, but the intermediate sum does not.

### ATTACK SURFACE
Auction price update, bid/ask aggregation, batch settlement.

### PRECONDITIONS
Users can submit extreme valid prices.

### ATTACK PATH
Submit extreme endpoints; overflow a+b; revert shared auction processing.

### WHAT ASSUMPTION FAILED
Each operand fitting the type was assumed to make the sum safe.

### GENERIC PATTERN
Overflow-before-division in average calculation.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Precision / DoS.

### SEARCH KEYWORDS
Price, Average, Overflow, Halt, Auctions, Precision

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Weighted-average overflow; timestamp midpoint overflow.

### POTENTIAL IMPACTS
Auction-wide denial of service.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Auction price update, bid/ask aggregation, batch settlement.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Overflow-before-division in average calculation.

==================================================
## VULN-013
Source reference: Bug Deep Dive #12 repeated
======

### BUG ID
VULN-013

### TITLE
One Overflowing Market Reverts Shared Auction Processing

### CATEGORY
Precision / DoS

### SEVERITY
High

### ROOT CAUSE
Unsafe midpoint arithmetic is executed inside shared processing without per-market fault isolation.

### BROKEN INVARIANT
One malformed or extreme market must not block unrelated markets.

### WHY THE BUG EXISTS
A local arithmetic failure propagates through the whole batch.

### ATTACK SURFACE
Batch auction and keeper processing.

### PRECONDITIONS
One attacker-controlled item enters a shared loop.

### ATTACK PATH
Trigger one overflowing midpoint; revert the batch; repeatedly pause all auctions.

### WHAT ASSUMPTION FAILED
Failure was assumed to stay local to one market.

### GENERIC PATTERN
Attacker-controlled per-item revert causes global batch DoS.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Precision / DoS.

### SEARCH KEYWORDS
Overflowing, Market, Reverts, Shared, Auction, Processing, Precision

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Bad oracle freezes all assets; malformed order blocks settlement.

### POTENTIAL IMPACTS
System-wide liveness failure.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Batch auction and keeper processing.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Attacker-controlled per-item revert causes global batch DoS.

==================================================
## VULN-014
Source reference: Bug Deep Dive #13
======

### BUG ID
VULN-014

### TITLE
Valid Asset Price Cannot Fit the Fixed-Point Type

### CATEGORY
Precision / Oracle

### SEVERITY
Medium

### ROOT CAUSE
Price scale and integer width cannot represent valid ratios for high-value base assets quoted in high-decimal tokens.

### BROKEN INVARIANT
Every supported asset pair and valid market price must fit encode and decode operations.

### WHY THE BUG EXISTS
Human prices were considered without decimal-normalized encoded bounds.

### ATTACK SURFACE
Oracle adapter, price packing, decimal normalization.

### PRECONDITIONS
A supported pair has an extreme decimal and value combination.

### ATTACK PATH
Normalize the price; overflow, truncate, or revert; block market operation.

### WHAT ASSUMPTION FAILED
The selected type was assumed large enough for all supported pairs.

### GENERIC PATTERN
Representation range excludes valid domain values.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Precision / Oracle.

### SEARCH KEYWORDS
Valid, Asset, Price, Cannot, Fixed, Point, Type, Precision, Oracle

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Tiny prices round to zero; packed oracle truncation.

### POTENTIAL IMPACTS
Unsupported markets, oracle DoS, wrong valuation.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Oracle adapter, price packing, decimal normalization.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Representation range excludes valid domain values.

==================================================
## VULN-015
Source reference: Bug Deep Dive #15
======

### BUG ID
VULN-015

### TITLE
Reflected XYK Curve Decreases K

### CATEGORY
Accounting / AMM Invariant

### SEVERITY
High

### ROOT CAUSE
Discrete reflected orders do not exactly implement the XYK reserve equation.

### BROKEN INVARIANT
Without withdrawals, fee-free trades preserve k and fee trades increase it.

### WHY THE BUG EXISTS
An approximation was assumed equivalent to the source invariant.

### ATTACK SURFACE
Curve generation, order settlement, reserve accounting.

### PRECONDITIONS
Users can repeatedly trade against the reflected curve.

### ATTACK PATH
Execute trades; each trade decreases k; arbitrage extracts the missing reserve value.

### WHAT ASSUMPTION FAILED
The transformed order ladder was assumed invariant-preserving.

### GENERIC PATTERN
Approximation layer violates the invariant it represents.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / AMM Invariant.

### SEARCH KEYWORDS
Reflected, Curve, Decreases, Accounting, Invariant

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Virtual reserves; piecewise curves; discretized liquidity.

### POTENTIAL IMPACTS
Systematic LP loss and pool drain.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Curve generation, order settlement, reserve accounting.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Approximation layer violates the invariant it represents.

==================================================
## VULN-016
Source reference: Bug Deep Dive #16
======

### BUG ID
VULN-016

### TITLE
Settlement Reentrancy Manipulates Spot Price During Liquidity Accounting

### CATEGORY
Reentrancy / Accounting

### SEVERITY
Critical

### ROOT CAUSE
An external settlement call occurs before maker accounting finishes, and later calculations use mutable AMM spot state.

### BROKEN INVARIANT
One transition must use one consistent pool snapshot and callbacks must not alter partial accounting.

### WHY THE BUG EXISTS
Control is yielded between state-dependent calculations.

### ATTACK SURFACE
Settlement callback, liquidity mint, slot0 read, fee and collateral accounting.

### PRECONDITIONS
Attacker controls callback and can move pool price.

### ATTACK PATH
Start liquidity operation; reenter during settle; manipulate price; outer call resumes and over-credits attacker; withdraw collateral and fees.

### WHAT ASSUMPTION FAILED
AMM state was assumed unchanged across external interaction.

### GENERIC PATTERN
Read-after-callback uses attacker-mutable market state.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Reentrancy / Accounting.

### SEARCH KEYWORDS
Settlement, Reentrancy, Manipulates, Spot, Price, During, Liquidity, Accounting

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
ERC777 hook; flash callback; malicious token reentrancy.

### POTENTIAL IMPACTS
Theft of collateral, fees, and protocol insolvency.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Settlement callback, liquidity mint, slot0 read, fee and collateral accounting.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Read-after-callback uses attacker-mutable market state.

==================================================
## VULN-017
Source reference: Bug Deep Dive #17
======

### BUG ID
VULN-017

### TITLE
Uninitialized Tick Fee Math Locks Positions and Inflates Fees

### CATEGORY
Accounting / State Management

### SEVERITY
Critical

### ROOT CAUSE
Fee-growth-inside logic treats uninitialized ticks inconsistently before and after tick initialization, causing underflow or inflated fee deltas.

### BROKEN INVARIANT
Fee growth recorded at position creation must be comparable to fee growth at removal under every tick lifecycle.

### WHY THE BUG EXISTS
The implementation assumes tick initialization state stays compatible with the stored fee checkpoint.

### ATTACK SURFACE
Tick initialization, feeGrowthOutside, position mint/burn, fee collection.

### PRECONDITIONS
Position is created across uninitialized ticks and those ticks later initialize or liquidity reaches zero.

### ATTACK PATH
Create position; change tick initialization state; recompute inside fees; underflow locks removal or huge delta credits attacker; drain balances.

### WHAT ASSUMPTION FAILED
Uninitialized tick semantics were assumed stable over time.

### GENERIC PATTERN
Snapshot formula changes meaning after referenced state initialization.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / State Management.

### SEARCH KEYWORDS
Uninitialized, Tick, Math, Locks, Positions, Inflates, Fees, Accounting, State, Management

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Checkpoint taken before initialization; epoch reset mismatch.

### POTENTIAL IMPACTS
Permanent fund lock or theft of collateral and fees.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Tick initialization, feeGrowthOutside, position mint/burn, fee collection.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Snapshot formula changes meaning after referenced state initialization.

==================================================
## VULN-018
Source reference: Bug Deep Dive #18
======

### BUG ID
VULN-018

### TITLE
Segment Splitting Inflates Borrow Fees

### CATEGORY
Accounting / Precision

### SEVERITY
High

### ROOT CAUSE
One logical range is split into tree nodes and borrow amounts are recomputed from each node's geometric mean instead of the original range.

### BROKEN INVARIANT
Partitioning a range must not change aggregate borrow principal or fees.

### WHY THE BUG EXISTS
The tree loses the original range identity and treats segments as independent positions.

### ATTACK SURFACE
Segment tree, range decomposition, borrow quote, fee calculation.

### PRECONDITIONS
A wide range spans multiple nodes.

### ATTACK PATH
Open one range; tree splits it; compute borrow per node; sum exceeds whole-range calculation; charge excessive fees.

### WHAT ASSUMPTION FAILED
Mathematical aggregation was assumed partition-invariant.

### GENERIC PATTERN
Tree decomposition changes economic value.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / Precision.

### SEARCH KEYWORDS
Segment, Splitting, Inflates, Borrow, Fees, Accounting, Precision

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Reward splitting; per-bin rounding; segmented interest.

### POTENTIAL IMPACTS
Large borrower overcharge and non-deterministic pricing.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Segment tree, range decomposition, borrow quote, fee calculation.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Tree decomposition changes economic value.

==================================================
## VULN-019
Source reference: Bug Deep Dive #19
======

### BUG ID
VULN-019

### TITLE
Annual Rate Is Applied as a Per-Second Rate

### CATEGORY
Accounting / Time / Precision

### SEVERITY
Critical

### ROOT CAUSE
An annualized rate is multiplied directly by elapsed seconds without dividing by seconds per year.

### BROKEN INVARIANT
Interest for t seconds equals principal times annual rate times t/year.

### WHY THE BUG EXISTS
Units were not tracked across the rate API boundary.

### ATTACK SURFACE
Borrow fee accrual, rate curve, timestamp delta.

### PRECONDITIONS
Rate function returns APY and elapsed time is seconds.

### ATTACK PATH
Open debt; wait; fee equals APY times raw seconds; debt grows about 31,536,000 times too fast.

### WHAT ASSUMPTION FAILED
The returned rate was assumed per-second.

### GENERIC PATTERN
Time-unit mismatch in interest accrual.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / Time / Precision.

### SEARCH KEYWORDS
Annual, Rate, Applied, Second, Accounting, Time, Precision

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Per-block versus per-second; basis points versus WAD.

### POTENTIAL IMPACTS
Extreme overcharging and functional DoS.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Borrow fee accrual, rate curve, timestamp delta.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Time-unit mismatch in interest accrual.

==================================================
## VULN-020
Source reference: Bug Deep Dive #20
======

### BUG ID
VULN-020

### TITLE
First-Deposit Share Inflation Can Zero Out Victim Shares

### CATEGORY
Accounting / Share Inflation

### SEVERITY
High

### ROOT CAUSE
Share minting uses a manipulable liquidity-per-share ratio and rounds down without minimum-share protection.

### BROKEN INVARIANT
A positive deposit must mint a fair positive claim on contributed assets.

### WHY THE BUG EXISTS
Empty or low-supply state lets an attacker set an extreme share price.

### ATTACK SURFACE
Vault deposit, LP share mint, donations, compounded positions.

### PRECONDITIONS
Low share supply, external liquidity donation or manipulation, floor rounding.

### ATTACK PATH
Mint minimal shares; inflate underlying value; victim deposits; victim receives zero or tiny shares; attacker captures value.

### WHAT ASSUMPTION FAILED
Underlying value was assumed proportional to share supply.

### GENERIC PATTERN
Donation-based first-deposit inflation.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / Share Inflation.

### SEARCH KEYWORDS
First, Deposit, Share, Inflation, Zero, Victim, Shares, Accounting

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
ERC4626 donation attack; reward-share inflation.

### POTENTIAL IMPACTS
Partial or total loss of deposits.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Vault deposit, LP share mint, donations, compounded positions.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Donation-based first-deposit inflation.

==================================================
## VULN-021
Source reference: Bug Deep Dive #21
======

### BUG ID
VULN-021

### TITLE
Sibling Liquidity Accounting Is Updated Without Matching AMM Mint or Burn

### CATEGORY
Accounting / State Synchronization

### SEVERITY
Critical

### ROOT CAUSE
Parent borrowing updates a sibling tree node, but settlement only visits route nodes, so the sibling's external AMM position is not updated.

### BROKEN INVARIANT
Internal tree liquidity must equal actual external AMM liquidity for every node.

### WHY THE BUG EXISTS
The code assumes every accounting-touched node will later be settled.

### ATTACK SURFACE
Segment tree borrowing, sibling propagation, settlement traversal, AMM mint/burn.

### PRECONDITIONS
Parent liquidity is borrowed or repaid and sibling is outside active route.

### ATTACK PATH
Update parent, child, and sibling accounting; settle only route; create phantom liquidity; manipulate price and withdraw against false accounting.

### WHAT ASSUMPTION FAILED
Traversal coverage was assumed to include all modified nodes.

### GENERIC PATTERN
Internal accounting mutation lacks corresponding external state mutation.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / State Synchronization.

### SEARCH KEYWORDS
Sibling, Liquidity, Accounting, Updated, Without, Matching, Mint, Burn, State, Synchronization

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Lazy settlement misses side branches; cache differs from external balance.

### POTENTIAL IMPACTS
Protocol insolvency and full fund drain.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Segment tree borrowing, sibling propagation, settlement traversal, AMM mint/burn.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Internal accounting mutation lacks corresponding external state mutation.

==================================================
## VULN-022
Source reference: Bug Deep Dive #22
======

### BUG ID
VULN-022

### TITLE
Token Operations Ignore False Return Values

### CATEGORY
Token Integration

### SEVERITY
Medium

### ROOT CAUSE
The protocol assumes token calls succeed when they return normally and does not require a true return value.

### BROKEN INVARIANT
Internal accounting must change only when the token transfer actually succeeds.

### WHY THE BUG EXISTS
ERC20 behavior was assumed uniform.

### ATTACK SURFACE
Transfer, transferFrom, approve, collateral deposit and withdrawal.

### PRECONDITIONS
A supported token returns false instead of reverting.

### ATTACK PATH
Protocol updates state; token call returns false; no assets move; accounting diverges or operation silently fails.

### WHAT ASSUMPTION FAILED
No revert was assumed to mean success.

### GENERIC PATTERN
Unchecked ERC20 boolean return.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Token Integration.

### SEARCH KEYWORDS
Token, Operations, Ignore, False, Return, Values, Integration

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
No-return tokens; fee-on-transfer; rebasing tokens.

### POTENTIAL IMPACTS
Accounting mismatch, unusable assets, possible unbacked credit.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Transfer, transferFrom, approve, collateral deposit and withdrawal.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Unchecked ERC20 boolean return.

==================================================
## VULN-023
Source reference: Bug Deep Dive #23
======

### BUG ID
VULN-023

### TITLE
Withdrawal Preview Omits JIT Penalties

### CATEGORY
Accounting / View Consistency

### SEVERITY
Medium

### ROOT CAUSE
The view returns pre-penalty balances while actual withdrawal applies a JIT liquidity penalty.

### BROKEN INVARIANT
Previewed immediate withdrawal value must match actual withdrawal within documented tolerance.

### WHY THE BUG EXISTS
Execution-only adjustments were not mirrored in view logic.

### ATTACK SURFACE
Balance query, JIT penalty, maker withdrawal, frontend integration.

### PRECONDITIONS
Position remains inside penalty window.

### ATTACK PATH
Query balance; receive high quote; withdraw immediately; receive less after penalty.

### WHAT ASSUMPTION FAILED
Stored balance was assumed equal to withdrawable balance.

### GENERIC PATTERN
Preview omits execution-time deduction.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / View Consistency.

### SEARCH KEYWORDS
Withdrawal, Preview, Omits, Penalties, Accounting, View, Consistency

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Missing exit fee, cooldown haircut, slashing, debt accrual.

### POTENTIAL IMPACTS
Incorrect UI and integration decisions.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Balance query, JIT penalty, maker withdrawal, frontend integration.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Preview omits execution-time deduction.

==================================================
## VULN-024
Source reference: Bug Deep Dive #24
======

### BUG ID
VULN-024

### TITLE
Compounded Position Preview Omits Uncollected AMM Fees

### CATEGORY
Accounting / View Consistency

### SEVERITY
Medium

### ROOT CAUSE
The query ignores external uncollected fees that the withdrawal path realizes.

### BROKEN INVARIANT
Preview must include every component of immediately withdrawable value.

### WHY THE BUG EXISTS
Internal stored balances were assumed complete.

### ATTACK SURFACE
Position query, AMM fee growth, collect, withdrawal.

### PRECONDITIONS
External fees accrued but were not collected.

### ATTACK PATH
Query understates balance; withdrawal realizes more; integrations receive inconsistent values.

### WHAT ASSUMPTION FAILED
Lazy external accrual was assumed irrelevant to views.

### GENERIC PATTERN
View simulation omits external pending value.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / View Consistency.

### SEARCH KEYWORDS
Compounded, Position, Preview, Omits, Uncollected, Fees, Accounting, View, Consistency

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Pending rewards, interest, rebases.

### POTENTIAL IMPACTS
Wrong NAV, frontend values, and execution limits.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Position query, AMM fee growth, collect, withdrawal.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
View simulation omits external pending value.

==================================================
## VULN-025
Source reference: Bug Deep Dive #25
======

### BUG ID
VULN-025

### TITLE
Cold-State Unsubscribe Exceeds the Guaranteed Gas Budget

### CATEGORY
Gas / State Management / DoS

### SEVERITY
High

### ROOT CAUSE
Gas tests use warmed storage, but production notification receives a fixed subcall gas limit and can exceed it with cold reads.

### BROKEN INVARIANT
Cleanup must finish within the external notifier's guaranteed gas budget in worst-case state.

### WHY THE BUG EXISTS
Measured test gas was assumed equal to cold production gas.

### ATTACK SURFACE
Unsubscribe callback, gauge cleanup, incentive accounting.

### PRECONDITIONS
Worst-case cold state and fixed notifier gas cap.

### ATTACK PATH
User unsubscribes; callback runs out of gas and is caught; external unsubscribe succeeds; internal gauge accounting remains; stale liquidity dilutes rewards forever.

### WHAT ASSUMPTION FAILED
Callback failure was assumed to prevent external state transition or tests were assumed realistic.

### GENERIC PATTERN
Caught cleanup failure creates cross-system state divergence.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Gas / State Management / DoS.

### SEARCH KEYWORDS
Cold, State, Unsubscribe, Exceeds, Guaranteed, Budget, Management

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Hook gas cap; bridge callback gas; receiver cleanup failure.

### POTENTIAL IMPACTS
Permanent stale accounting and reward dilution.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Unsubscribe callback, gauge cleanup, incentive accounting.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Caught cleanup failure creates cross-system state divergence.

==================================================
## VULN-026
Source reference: Bug Deep Dive #26
======

### BUG ID
VULN-026

### TITLE
Invalid Collateral Status Reduces Vault Liquidation Liability

### CATEGORY
Incentive Design / Liquidation

### SEVERITY
Medium

### ROOT CAUSE
When collateral is invalid, liquidation shifts responsibility to the shared pool and caps the vault's contribution below its normal factor.

### BROKEN INVARIANT
An agent must not reduce its liquidation liability by refusing a required collateral migration.

### WHY THE BUG EXISTS
The invalid-collateral branch was designed for safety but changes incentives.

### ATTACK SURFACE
Collateral invalidation, migration, vault liquidation, insurance pool.

### PRECONDITIONS
Governance invalidates token and owner can delay migration.

### ATTACK PATH
Keep invalid token; become liquidated; shared pool pays more; vault pays less than with valid collateral.

### WHAT ASSUMPTION FAILED
Owners were assumed to promptly migrate invalid collateral.

### GENERIC PATTERN
Failure-state branch rewards non-compliance.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Incentive Design / Liquidation.

### SEARCH KEYWORDS
Invalid, Collateral, Status, Reduces, Vault, Liquidation, Liability, Incentive, Design

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Insurance socialization; stale oracle mode benefits owner.

### POTENTIAL IMPACTS
Pool losses and strategic refusal to update collateral.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Collateral invalidation, migration, vault liquidation, insurance pool.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Failure-state branch rewards non-compliance.

==================================================
## VULN-027
Source reference: Bug Deep Dive #27
======

### BUG ID
VULN-027

### TITLE
Reward Token Upgrade Lets Owner Sweep Rewards Owed to Pool Shareholders

### CATEGORY
Accounting / Access Control

### SEVERITY
High

### ROOT CAUSE
Reward accounting reads the old wrapped-token balance while rewards arrive in the new token, so total collateral is not increased before the owner upgrades and sweeps the new token.

### BROKEN INVARIANT
All rewards earned by pooled backing must increase shareholder-owned collateral regardless of token version.

### WHY THE BUG EXISTS
Token-address upgrade and reward claim ordering were assumed synchronized.

### ATTACK SURFACE
Reward claim, token address update, collateral total, owner sweep.

### PRECONDITIONS
Reward source pays new token while pool still tracks old token.

### ATTACK PATH
Update system token; claim new-token rewards while measuring old token; claimed amount appears zero; upgrade token; owner sweeps unaccounted balance.

### WHAT ASSUMPTION FAILED
One token address was assumed active across all modules at all times.

### GENERIC PATTERN
Asset migration creates an accounting blind spot between old and new token identities.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Accounting / Access Control.

### SEARCH KEYWORDS
Reward, Token, Upgrade, Lets, Owner, Sweep, Rewards, Owed, Pool, Shareholders, Accounting, Access

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Reward-token migration; wrapper upgrade; bridge asset replacement.

### POTENTIAL IMPACTS
Theft of pooled rewards and shareholder loss.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Reward claim, token address update, collateral total, owner sweep.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Asset migration creates an accounting blind spot between old and new token identities.

==================================================
## VULN-028
Source reference: Bug Deep Dive #28
======

### BUG ID
VULN-028

### TITLE
Liquidation Has No Minimum Collateral Output Protection

### CATEGORY
Liquidation / Price Risk

### SEVERITY
Medium

### ROOT CAUSE
Liquidation payout is calculated from the execution-time oracle price without a liquidator-specified minimum output.

### BROKEN INVARIANT
A liquidator should be able to bound the collateral received for the debt burned.

### WHY THE BUG EXISTS
Liquidation was treated as an atomic fixed quote despite price movement before execution.

### ATTACK SURFACE
Liquidation entry point, oracle price, mempool, collateral payout.

### PRECONDITIONS
Asset price can fall between decision and execution.

### ATTACK PATH
Liquidator prepares transaction; price falls; transaction executes at worse payout; liquidator receives less than expected.

### WHAT ASSUMPTION FAILED
Liquidators were assumed to accept unlimited price movement.

### GENERIC PATTERN
Value-changing action lacks slippage protection.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Liquidation / Price Risk.

### SEARCH KEYWORDS
Liquidation, Minimum, Collateral, Output, Protection, Price, Risk

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Redemption, unstake, auction fill without minOut.

### POTENTIAL IMPACTS
Liquidator losses, reduced participation, weaker solvency response.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Liquidation entry point, oracle price, mempool, collateral payout.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Value-changing action lacks slippage protection.

==================================================
## VULN-029
Source reference: Bug Deep Dive #29
======

### BUG ID
VULN-029

### TITLE
Disabling Checkpoint Usage Bypasses Checkpointer Validation

### CATEGORY
Authentication / Signature Validation

### SEVERITY
High

### ROOT CAUSE
A signature flag disables the branch that loads and validates the required checkpointer, allowing chained signatures to recover against stale wallet configuration.

### BROKEN INVARIANT
A wallet behind a checkpoint must reject signatures that do not prove an allowed checkpoint.

### WHY THE BUG EXISTS
Optional parsing flag was allowed to control a mandatory security policy.

### ATTACK SURFACE
Chained signature parsing, checkpoint flags, wallet configuration recovery.

### PRECONDITIONS
Wallet configuration is behind checkpoint and signature clears the checkpointer-use flag.

### ATTACK PATH
Use stale signer/configuration; craft chained signature with flag off; skip checkpointer validation; recover valid image hash; execute wallet action.

### WHAT ASSUMPTION FAILED
Signer-controlled encoding was assumed safe to decide whether policy validation runs.

### GENERIC PATTERN
Untrusted signature flags disable mandatory authentication checks.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Authentication / Signature Validation.

### SEARCH KEYWORDS
Disabling, Checkpoint, Usage, Bypasses, Checkpointer, Validation, Authentication, Signature

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Optional domain check; skipped epoch validation; user-controlled security mode.

### POTENTIAL IMPACTS
Unauthorized wallet actions by removed signers.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Chained signature parsing, checkpoint flags, wallet configuration recovery.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Untrusted signature flags disable mandatory authentication checks.

==================================================
## VULN-030
Source reference: Bug Deep Dive #30
======

### BUG ID
VULN-030

### TITLE
Per-Call Session Signatures Can Be Replayed as a Partial Payload

### CATEGORY
Replay / Authentication

### SEVERITY
High

### ROOT CAUSE
Each call signature binds only to its call index and call hash, not the full multi-call payload; a reverted execution rolls back nonce consumption.

### BROKEN INVARIANT
Authorization for an atomic batch must not authorize a strict subset of that batch.

### WHY THE BUG EXISTS
Per-call signatures were assumed to inherit whole-payload intent and nonce use was assumed permanent before execution.

### ATTACK SURFACE
Session signatures, multicall execution, nonce rollback, mempool.

### PRECONDITIONS
Original batch reverts or is visible before execution and attacker can reconstruct a subset.

### ATTACK PATH
Observe signed batch; submit subset with reused per-call signatures and same nonce; execute intended-dependent calls alone; invalidate or harm original flow.

### WHAT ASSUMPTION FAILED
A signature over each call was assumed to authorize only the complete batch.

### GENERIC PATTERN
Partial replay from decomposable signatures plus reverted nonce.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Replay / Authentication.

### SEARCH KEYWORDS
Call, Session, Signatures, Replayed, Partial, Payload, Replay, Authentication

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Order truncation, signature splicing, front-run subset.

### POTENTIAL IMPACTS
Fund loss, state corruption, griefing, broken atomicity.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Session signatures, multicall execution, nonce rollback, mempool.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Partial replay from decomposable signatures plus reverted nonce.

==================================================
## VULN-031
Source reference: Bug Deep Dive #31
======

### BUG ID
VULN-031

### TITLE
External Self-Call Changes Caller During ERC-4337 Signature Validation

### CATEGORY
Authentication / DoS

### SEVERITY
Medium

### ROOT CAUSE
validateUserOp calls this.isValidSignature externally, so msg.sender inside caller-bound validation becomes the wallet instead of the EntryPoint.

### BROKEN INVARIANT
A signature bound to the EntryPoint must validate when invoked through the supported ERC-4337 flow.

### WHY THE BUG EXISTS
External self-call context was assumed equivalent to internal validation context.

### ATTACK SURFACE
ERC4337 validation, ERC1271, caller-bound static signatures.

### PRECONDITIONS
Static signature expects a nonzero caller such as EntryPoint.

### ATTACK PATH
EntryPoint calls validateUserOp; wallet externally calls itself; caller check sees wallet; valid signature reverts; operation is denied.

### WHAT ASSUMPTION FAILED
msg.sender was assumed to remain the original caller through self-call.

### GENERIC PATTERN
Self-call context breaks caller-bound authorization.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Authentication / DoS.

### SEARCH KEYWORDS
External, Self, Call, Changes, Caller, During, 4337, Signature, Validation, Authentication

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Proxy call context, delegatecall/call confusion, callback caller mismatch.

### POTENTIAL IMPACTS
Deterministic denial of valid user operations.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing ERC4337 validation, ERC1271, caller-bound static signatures.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Self-call context breaks caller-bound authorization.

==================================================
## VULN-032
Source reference: Bug Deep Dive #32
======

### BUG ID
VULN-032

### TITLE
Repeated ERC-4337 Caller-Binding Report Confirms Systemic Failure

### CATEGORY
Authentication / DoS

### SEVERITY
Medium

### ROOT CAUSE
The supported validation route changes caller identity before static-signature checks and propagates a revert instead of a clean invalid-signature result.

### BROKEN INVARIANT
All supported signature modes must remain usable through every advertised wallet entry point.

### WHY THE BUG EXISTS
Integration behavior was tested separately from caller-bound signature behavior.

### ATTACK SURFACE
UserOp validation, external self-call, static signatures, revert handling.

### PRECONDITIONS
Caller-bound signature mode is used under ERC-4337.

### ATTACK PATH
Submit valid caller-bound operation; self-call changes caller; validation reverts on every attempt.

### WHAT ASSUMPTION FAILED
ERC1271 and ERC4337 paths were assumed context-compatible.

### GENERIC PATTERN
Authentication module composed through a call boundary loses required context.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Authentication / DoS.

### SEARCH KEYWORDS
Repeated, 4337, Caller, Binding, Report, Confirms, Systemic, Failure, Authentication

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Meta-transactions, forwarders, proxies.

### POTENTIAL IMPACTS
Systemic DoS for one signature mode and failed integrations.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing UserOp validation, external self-call, static signatures, revert handling.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Authentication module composed through a call boundary loses required context.

==================================================
## VULN-033
Source reference: Bug Deep Dive #33
======

### BUG ID
VULN-033

### TITLE
Unbounded Domain Count Causes Bit-Shift Failure

### CATEGORY
Precision / State Management / DoS

### SEVERITY
High

### ROOT CAUSE
A computed uint8 domain maximum is not capped so normalMax plus bonusMax can exceed 255, making 1 << index invalid or zero and breaking packed-set operations.

### BROKEN INVARIANT
Every encoded selection index must be below the bit width used to store it.

### WHY THE BUG EXISTS
Each field fit uint8, but their sum was not bounded by the 256-bit encoding domain.

### ATTACK SURFACE
Drawing rollover, ticket packing, winning-number settlement, LP-driven parameter calculation.

### PRECONDITIONS
Growing prize pool raises computed bonus maximum while normal maximum remains positive.

### ATTACK PATH
Increase pool value; finalize drawing; create excessive bonus maximum; ticket insertion or winner calculation shifts by >=256; purchases or settlement fail.

### WHAT ASSUMPTION FAILED
Individual field bounds were assumed sufficient for combined index bounds.

### GENERIC PATTERN
Combined parameters exceed packed bitmap capacity.

### DETECTION HEURISTICS
Compare all equivalent paths and state transitions; test boundaries, ordering, external-call context, and conservation properties related to: Precision / State Management / DoS.

### SEARCH KEYWORDS
Unbounded, Domain, Count, Causes, Shift, Failure, Precision, State, Management

### AUDITOR MENTAL TRIGGERS
Ask whether the same operation, state, or value can be reached through another path that skips an update, check, fee, bound, or invariant.

### CODE SMELLS
Duplicated formulas, partial state updates, missing reverse transitions, unchecked external assumptions, unsafe boundaries, and view/execution divergence in the affected surface.

### COMMON VARIATIONS OF THIS BUG
Bitmask role sets, bitmap token IDs, packed flags.

### POTENTIAL IMPACTS
Blocked ticket purchase and irrecoverable drawing settlement DoS.

### REPOSITORY SCAN STRATEGY
Map the affected state variables and all writers/readers. Trace normal, alternate, failure, and recovery paths. Compare internal accounting with external balances and execution results.

### FILES TO INVESTIGATE IN FUTURE PROTOCOLS
Contracts and libraries implementing Drawing rollover, ticket packing, winning-number settlement, LP-driven parameter calculation.

### FUNCTION TYPES TO INVESTIGATE
Entry, exit, quote, settlement, callback, update, migration, recovery, and view functions touching the affected state.

### AI AUDITOR PLAYBOOK
Build a state-transition table; state the invariant; generate adversarial boundary and alternate-path sequences; reject any candidate without a concrete broken state or execution trace.

### STEP-BY-STEP DETECTION PROCESS
1. Identify the intended invariant.
2. List every relevant state transition.
3. Compare canonical and alternate paths.
4. Test extreme values, ordering changes, and failures.
5. Construct the smallest reproducible violating trace.
6. Quantify victim impact and confirm reachability.

### CANONICAL LESSON
Combined parameters exceed packed bitmap capacity.


