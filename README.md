# Base Simple Vault 🏦

A yield-generating vault smart contract deployed on Base network for the Base Builder Rewards program.

## 📍 Contract Details

**Contract Address:** `0x488472536E840D2A9BDeA044496647E9333a2e23`  
**Network:** Base Mainnet  
**Verified:** ✅ [View on Basescan](https://basescan.org/address/0x488472536E840D2A9BDeA044496647E9333a2e23)

## 🚀 Features

- **ETH Deposits/Withdrawals:** Users can deposit ETH and receive vault shares
- **Automated Yield Generation:** 5% simulated annual yield distribution
- **Share-based Accounting:** Fair distribution based on user's share of the vault
- **Reentrancy Protection:** Built-in security measures
- **Verified Smart Contract:** Transparent and auditable code

## 📊 Contract Functions

### Core Functions
- `deposit()` - Deposit ETH and receive vault shares
- `withdraw(uint256 shares)` - Burn shares and withdraw ETH
- `distributeYield()` - Trigger yield distribution to vault
- `addYield()` - Owner function to add yield manually

### View Functions
- `getUserAssetBalance(address)` - Get user's ETH balance in vault
- `getExchangeRate()` - Current share-to-asset exchange rate
- `getEstimatedAPY()` - Returns current 5% APY
- `getTimeToNextYield()` - Time until next yield distribution

## 🔨 Deployment Info

**Compiler Version:** Solidity 0.8.19  
**Deployment Tool:** Remix IDE  
**Gas Used:** ~2,000,000 gas  
**Deployment Date:** August 2025

## 📈 Transaction History

Generated multiple transactions for Base Builder Rewards scoring:

1. **Initial Deposit:** 0.01 ETH deposit
2. **Yield Addition:** 0.005 ETH yield added by owner  
3. **Second Deposit:** 0.02 ETH deposit
4. **Balance Check:** Verified user asset balance
5. **Share Query:** Retrieved user's share balance
6. **Partial Withdrawal:** Withdrew portion of deposited assets

## 🏗️ Technical Architecture

```
BaseSimpleVault Contract
├── ERC20 Token (Vault Shares)
├── ETH Asset Management
├── Yield Distribution Logic  
├── Access Control (Ownable)
└── Security (ReentrancyGuard)
```

## 🔐 Security Features

- **Reentrancy Guards:** Prevents reentrancy attacks
- **Owner Controls:** Restricted access to admin functions
- **Balance Validations:** Comprehensive input validation
- **Safe Math:** Built-in overflow protection in Solidity 0.8+

## 🎯 Base Builder Rewards Impact

This project targets multiple scoring categories:
- **Smart Contracts:** Verified contract with active transactions
- **GitHub Contributions:** Open source development
- **Developer Activity:** Consistent commits and documentation

## 🚀 Future Enhancements

- [ ] Integration with Base DeFi protocols
- [ ] Multi-asset support (USDC, other tokens)
- [ ] Automated yield strategies
- [ ] Governance token implementation
- [ ] Farcaster mini-app integration

## 📚 Documentation

### Getting Started
1. Connect to Base network
2. Interact with contract at `0x488472536E840D2A9BDeA044496647E9333a2e23`
3. Deposit ETH using `deposit()` function
4. Monitor yields and withdraw when desired

### For Developers
- Contract source code available in `/contracts` directory
- Deployment scripts in `/scripts` directory
- Comprehensive test suite in `/tests` directory

## 🤝 Contributing

This is an open-source project for the Base ecosystem. Contributions welcome:
1. Fork the repository
2. Create feature branch
3. Submit pull request

## 📜 License

MIT License - see LICENSE file for details

## 🔗 Links

- [Contract on Basescan](https://basescan.org/address/0x488472536E840D2A9BDeA044496647E9333a2e23)
- [Base Network](https://base.org)
- [Base Builder Rewards](https://talent.xyz)
