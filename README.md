# 🛡️ Safenet - Occupational Safety Violation Tracker

[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-5546FF?style=flat-square&logo=stacks)](https://stacks.co/)
[![Clarity](https://img.shields.io/badge/Smart%20Contracts-Clarity-8B5CF6?style=flat-square)](https://clarity-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](https://opensource.org/licenses/MIT)

## 🎯 Overview

**Safenet** is a revolutionary blockchain-based occupational safety violation tracking system that empowers whistleblowers with anonymous reporting capabilities and token-based rewards. Built on the Stacks blockchain, Safenet creates a transparent, immutable, and incentivized ecosystem for workplace safety compliance.

## ✨ Key Features

### 🚨 **Safety Violation Tracking**
- **Anonymous Reporting**: Secure, anonymous violation submissions with cryptographic protection
- **Comprehensive Documentation**: Detailed incident recording with evidence support
- **Severity Classification**: Multi-level severity system (Critical, High, Medium, Low)
- **Status Tracking**: Real-time violation status updates and resolution tracking
- **Immutable Records**: Tamper-proof violation history on the blockchain

### 🎁 **Whistleblower Token Rewards**
- **Incentivized Reporting**: Token rewards for valid safety violation reports
- **Performance-Based Rewards**: Higher rewards for critical safety discoveries
- **Reputation System**: Build whistleblower credibility through verified contributions
- **Token Distribution**: Automated reward distribution upon violation verification
- **Anti-Fraud Protection**: Robust validation system to prevent false claims

### 🏢 **Workplace Safety Management**
- **Multi-Company Support**: Track violations across different organizations
- **Department-Level Tracking**: Detailed departmental safety performance monitoring
- **Compliance Scoring**: Automated safety compliance scoring and ranking
- **Resolution Management**: Track remediation efforts and completion status
- **Regulatory Reporting**: Export capabilities for regulatory compliance

### 🔒 **Privacy & Security**
- **Anonymous Reporting**: Zero-knowledge reporting system protecting whistleblower identity
- **Encrypted Evidence**: Secure evidence storage with access controls
- **Audit Trail**: Complete immutable audit trail for all activities
- **Access Control**: Role-based permissions for different user types
- **Data Protection**: GDPR and privacy law compliant data handling

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Safenet System                      │
├─────────────────────────────────────────────────────────┤
│  🖥️  Frontend Interface                                │
│  ├── Anonymous Reporting Portal                         │
│  ├── Company Safety Dashboard                           │
│  ├── Whistleblower Token Tracker                        │
│  └── Regulatory Compliance Reports                      │
├─────────────────────────────────────────────────────────┤
│  🔗 Smart Contracts (Clarity)                          │
│  ├── safety-tracker.clar (Violation Management)         │
│  └── whistleblower-tokens.clar (Reward System)          │
├─────────────────────────────────────────────────────────┤
│  ⛓️  Stacks Blockchain                                  │
│  ├── Immutable Violation Records                        │
│  ├── Anonymous Reporter Protection                      │
│  ├── Token-Based Incentive System                       │
│  └── Compliance Audit Trail                             │
└─────────────────────────────────────────────────────────┘
```

## 🔧 Smart Contract Components

### **1. Safety Tracker Contract** (`safety-tracker.clar`)
- Violation recording and management system
- Company and department registration
- Severity classification and status tracking
- Resolution management and compliance scoring
- Anonymous reporting with privacy protection

### **2. Whistleblower Token Contract** (`whistleblower-tokens.clar`)
- Token reward system for verified reports
- Reputation tracking and performance metrics
- Anti-fraud validation mechanisms
- Automated reward distribution
- Whistleblower profile management

## 📊 Data Structures

### **Safety Violation Record**
```clarity
{
  violation-id: uint,
  company-id: uint,
  department: (string-ascii 50),
  violation-type: (string-ascii 100),
  severity: (string-ascii 20),
  description: (string-ascii 500),
  evidence-hash: (string-ascii 64),
  reporter-hash: (string-ascii 64),
  status: (string-ascii 20),
  reported-date: uint,
  resolution-date: (optional uint),
  resolution-notes: (optional (string-ascii 300))
}
```

### **Company Profile**
```clarity
{
  company-id: uint,
  company-name: (string-ascii 100),
  industry: (string-ascii 50),
  registration-date: uint,
  total-violations: uint,
  resolved-violations: uint,
  compliance-score: uint,
  status: (string-ascii 20)
}
```

### **Whistleblower Token Record**
```clarity
{
  reporter-hash: (string-ascii 64),
  total-reports: uint,
  verified-reports: uint,
  reputation-score: uint,
  total-tokens-earned: uint,
  last-report-date: uint,
  status: (string-ascii 20)
}
```

### **Token Reward**
```clarity
{
  reward-id: uint,
  violation-id: uint,
  reporter-hash: (string-ascii 64),
  reward-amount: uint,
  reward-date: uint,
  verification-status: (string-ascii 20)
}
```

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) v16 or higher
- [Stacks Wallet](https://www.hiro.so/wallet) for blockchain interaction

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/haskegodiya4/Safenet.git
   cd Safenet
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Run tests**
   ```bash
   npm test
   ```

4. **Check contract syntax**
   ```bash
   clarinet check
   ```

## 🧪 Usage Examples

### **Register a Company**
```clarity
(register-company 
  "SafeTech Industries" 
  "Manufacturing")
```

### **Report a Safety Violation**
```clarity
(report-violation 
  u1                              ; company-id
  "Production Floor"              ; department
  "Unsafe Chemical Handling"     ; violation-type
  "critical"                      ; severity
  "Workers exposed to toxic fumes without proper ventilation or PPE"
  "abc123def456..."              ; evidence-hash
)
```

### **Claim Token Reward**
```clarity
(claim-reward u1)  ; violation-id
```

### **Update Violation Status**
```clarity
(update-violation-status 
  u1              ; violation-id
  "resolved"      ; new-status
  "Installed new ventilation system and provided proper PPE training")
```

## ⚠️ **Violation Severity Levels**

- **🔴 Critical**: Immediate threat to life or health (50 tokens)
- **🟠 High**: Serious safety risk requiring urgent attention (30 tokens)
- **🟡 Medium**: Moderate safety concern needing timely resolution (15 tokens)
- **🟢 Low**: Minor safety improvement opportunity (5 tokens)

## 🎁 **Token Reward System**

### **Reward Structure**
- Base reward amount determined by violation severity
- Bonus multipliers for repeat valid reporters (up to 2x)
- Reputation-based reward scaling
- Anti-spam protection with validation requirements

### **Verification Process**
1. Violation reported anonymously
2. Company has 30 days to respond/resolve
3. Independent verification through evidence review
4. Token rewards distributed upon verification
5. Reputation scores updated based on validity

## 🔒 **Privacy Protection**

### **Anonymous Reporting**
- Cryptographic hash-based identity protection
- No personal information stored on-chain
- Optional secure communication channels
- Evidence anonymization protocols

### **Data Security**
- Encrypted evidence storage
- Access-controlled resolution notes
- Immutable audit trails
- GDPR compliant data handling

## 📈 **Benefits**

### **For Workers**
- 💰 **Financial Incentives**: Earn tokens for reporting safety violations
- 🛡️ **Anonymous Protection**: Report safely without fear of retaliation
- 🏆 **Reputation Building**: Build credibility as a safety advocate
- 📱 **Easy Access**: Simple, user-friendly reporting interface

### **For Companies**
- 📊 **Early Detection**: Identify safety issues before they escalate
- 🎯 **Compliance Improvement**: Track and improve safety compliance scores
- 💡 **Cost Reduction**: Prevent costly accidents and regulatory fines
- 📈 **Reputation Management**: Demonstrate commitment to worker safety

### **For Regulators**
- 🔍 **Real-time Monitoring**: Access to live safety violation data
- 📋 **Compliance Tracking**: Monitor industry safety performance
- 📊 **Data-Driven Policy**: Make informed regulatory decisions
- 🏛️ **Transparent Reporting**: Immutable audit trails for investigations

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
npm test

# Check contract syntax
clarinet check

# Generate code coverage report
npm run coverage
```

## 🤝 Contributing

We welcome contributions from the safety, blockchain, and open-source communities! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For questions, issues, or feature requests:
- 📧 Email: support@safenet.workplace
- 💬 Discord: [Safenet Community](https://discord.gg/safenet)
- 🐛 Issues: [GitHub Issues](https://github.com/haskegodiya4/Safenet/issues)

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)
- [Workplace Safety Resources](https://www.osha.gov/)

---

**Built with ❤️ for workplace safety and worker protection**
