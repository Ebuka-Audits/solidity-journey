# LendingPool Protocol (Educational DeFi Prototype)

A Solidity-based educational lending protocol prototype designed to explore core DeFi lending mechanics such as collateralization, borrowing, repayment logic, interest accrual, liquidity management, and liquidation systems.

This project was built primarily for learning protocol architecture, smart contract security patterns, and financial state accounting in decentralized systems.

---

# Features

- Collateralized borrowing system
- Liquidity pool accounting
- Borrow interest accrual
- Passive deposit interest accrual
- Overcollateralized loans
- Loan repayment mechanics
- Partial repayment support
- Governance-controlled interest rates
- Reentrancy protection
- Real-time user balance calculations
- Collateral lockup system
- Loan duration tracking
- Liquidation mechanics (in newer versions)

---

# Protocol Design

## Borrowing

Users can:
1. Deposit funds
2. Lock part of deposits as collateral
3. Borrow against collateral

Loans are overcollateralized to protect protocol solvency.

**Collateral Requirement Example:**
- 150%–200% collateralization ratio depending on version

---

## Interest System

### Borrow Interest

Interest accrues over time based on borrowed principal:

Interest = (r × P × t) / (10000 × 365 days)

Where:
- P = borrowed principal
- r = interest rate in basis points
- t = elapsed time

---

### Deposit Interest (older versions)

Some earlier versions included passive deposit yield:
- Monthly compounding reward
- Applied during user interactions (deposit/withdraw)

---

# Evolution From Previous Versions

## Membership & Access Control

Later versions introduced:
- Member registration system
- Address approval mechanism
- User blocking functionality

This added controlled protocol participation.

---

## Liquidation System

Earlier versions allowed indefinite loans.

New versions introduced:
- MAX_LOAN_DURATION
- Liquidation function
- Collateral seizure on overdue loans

This improved protocol solvency.

---

## Collateral Improvements

Evolution from:
- basic collateral checks

To:
- stricter collateral requirements
- enforced collateral lockups
- safer borrowing constraints

---

## Repayment Logic Improvements

Improvements include:
- partial repayment support
- clearer interest handling
- better debt state transitions
- reset logic for loan cycles

---

## Security Enhancements

- Reentrancy protection
- Liquidity validation checks
- Borrow restrictions
- Collateral lock enforcement
- Governance access control
- Rate limiting (in some versions)

---

# Known Limitations

This is an educational prototype and NOT production ready.

Limitations include:

- No ERC20 token integration
- No real asset custody
- No oracle price feeds
- Simplified liquidation mechanics
- Internal accounting only
- No liquidation incentives
- No full risk engine (health factor system)

---

# Security Notes

This project is built for learning:
- Solidity development
- DeFi protocol design
- Smart contract security patterns
- Financial state modeling

It has NOT been audited and should NOT be used with real funds.

---

# Concepts Explored

- Overcollateralized lending
- Liquidity pool accounting
- Debt tracking systems
- Interest accrual mechanics
- Liquidation design
- Protocol solvency logic
- State transitions in financial contracts

---

# Future Improvements

- ERC20 token support
- Oracle integration (price feeds)
- Health factor-based liquidation
- DAO governance system
- Multi-asset collateral support
- Advanced interest indexing system
- Incentivized liquidations
- Intrest on Deposits

---

# Tech Stack

- Solidity ^0.8.x
- OpenZepellin Ownable contract
- OpenZepellin ReentrancyGuard

---

# Disclaimer

This project is strictly for educational purposes only.
Do not deploy or use with real assets.
