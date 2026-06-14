Alice enters jungle
        ↓
Main gate = dreUSDManager
       ↙         ↘
Mint path      Redeem path
   ↓               ↓
dreUSD         Withdrawal Layer
                    ↓
                 Aave V3

Profit path:
dreUSD → dreUSDs Vault → Aave yield

Travel another jungle:
OVault Bridge → LayerZero → another chain











📘x-ray Summ:

Alice wants stablecoin
↓
dreUSDManager.mint()
↓
Oracle price লাগে
↓
Sanctions check
↓
Custody vault এ money যায়
↓
dreUSD mint হয়
↓
Alice চাইলে dreUSDs এ stake করে
↓
Reward vesting শুরু
↓
Redeem করলে NFT mint হয়
↓
Keeper আসে
↓
Aave liquidity আনে
↓
Alice USDC পায়







📘FULL PROTOCOL JOURNEY

Alice enters protocol
        ↓
dreUSDManager
        ↓
Oracle + Compliance check
        ↓
dreUSD minted
        ↓
Option 1:
Hold stablecoin

Option 2:
Deposit into dreUSDs vault
        ↓
Earn yield from rewards

Option 3:
Request withdrawal
        ↓
Withdrawal NFT
        ↓
Keeper processing
        ↓
Aave liquidity
        ↓
Receive USDC

Option 4:
Bridge to another chain
        ↓
LayerZero messaging
        ↓
Receive assets on destination chain