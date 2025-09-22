# 🎓 Learn-to-Earn Protocol

A smart contract protocol built on Stacks that rewards users with STX tokens for completing educational modules and passing quizzes.

## ✨ Features

- 📚 **Learning Modules**: Create and manage educational content
- 🧠 **Interactive Quizzes**: Test knowledge with multiple-choice questions
- 🏆 **STX Rewards**: Earn cryptocurrency for learning achievements
- 👤 **User Profiles**: Track progress, streaks, and experience points
- 🎯 **Difficulty Levels**: Beginner to Expert content tiers
- ⭐ **Review System**: Rate and review completed modules
- 📊 **Analytics**: Monitor completion rates and contract statistics

## 🚀 Quick Start

### Prerequisites

- Node.js (v16 or higher)
- Clarinet CLI
- Stacks wallet

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/learn-to-earn-protocol.git
cd learn-to-earn-protocol
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
clarinet console
```

4. Deploy the contract:
```bash
clarinet deploy
```

## 🎯 Usage

### For Educators

1. **Create Learning Module**:
```clarity
(contract-call? .learn-to-earn create-module 
  "Introduction to Blockchain" 
  "Learn the basics of blockchain technology" 
  u50 
  u1)
```

2. **Add Quiz Questions**:
```clarity
(contract-call? .learn-to-earn create-quiz 
  u1 
  "What is blockchain?" 
  (list "Database" "Distributed ledger" "Software" "Website") 
  u2 
  u70 
  u3)
```

### For Learners

1. **Complete Module**:
```clarity
(contract-call? .learn-to-earn complete-module u1 u85)
```

2. **Take Quiz**:
```clarity
(contract-call? .learn-to-earn take-quiz u1 u2)
```

3. **Claim Rewards**:
```clarity
(contract-call? .learn-to-earn claim-reward u1)
```

### For Contract Funding

```clarity
(contract-call? .learn-to-earn fund-contract u1000)
```

## 🌐 Web Interface

The protocol includes a responsive web interface built with vanilla HTML, CSS, and JavaScript:

1. Open `web/index.html` in your browser
2. Connect your Stacks wallet
3. Browse available modules
4. Complete quizzes and earn rewards
5. Track your progress in the profile section

### Key Features:
- 📱 **Responsive Design**: Works on desktop and mobile
- ♿ **Accessibility**: ARIA labels and keyboard navigation
- 🎨 **Modern UI**: Clean, intuitive interface
- 🔄 **Real-time Updates**: Dynamic content loading
- 📊 **Progress Tracking**: Visual progress indicators

## 📋 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `create-module` | Create a new learning module | title, description, reward-amount, difficulty-level |
| `create-quiz` | Add quiz to a module | module-id, question, options, correct-answer, passing-score, max-attempts |
| `complete-module` | Mark module as completed | module-id, score |
| `take-quiz` | Submit quiz answer | quiz-id, answer |
| `claim-reward` | Claim STX reward | module-id |
| `submit-review` | Rate and review module | module-id, rating, review |
| `fund-contract` | Add STX to contract | amount |

### Read-only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-module` | Get module details | Module data |
| `get-user-progress` | Get user's progress | Progress data |
| `get-quiz` | Get quiz details | Quiz data |
| `get-user-profile` | Get user profile | Profile data |
| `get-contract-stats` | Get contract statistics | Stats data |

## 🏗️ Architecture

```
learn-to-earn-protocol/
├── contracts/
│   └── learn-to-earn.clar    # Main smart contract
├── web/
│   ├── index.html            # Web interface
│   ├── styles.css            # Styling
│   └── script.js             # JavaScript logic
├── tests/
│   └── learn-to-earn_test.ts # Contract tests
└── README.md
```

## 🔧 Configuration

### Platform Settings

- **Platform Fee**: 5% (configurable by contract owner)
- **Cooldown Period**: 10 blocks between quiz attempts
- **Max Attempts**: Configurable per quiz
- **Difficulty Levels**: 1-5 (Beginner to Expert)

### Reward Structure

- Rewards are distributed in STX
- Platform takes a small fee from each reward
- Users can claim rewards after module completion
- Bonus experience points for difficulty levels

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

Run specific tests:
```bash
clarinet test tests/learn-to-earn_test.ts
```

## 🛠️ Development

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract locally:
```bash
::deploy_contracts
```

3. Interact with contract:
```clarity
(contract-call? .learn-to-earn get-contract-stats)
```

### Contract Deployment

Deploy to testnet:
```bash
clarinet deploy --testnet
```

Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## 📊 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | ERR_UNAUTHORIZED | Not authorized to perform action |
| u101 | ERR_INVALID_MODULE | Module does not exist |
| u102 | ERR_ALREADY_COMPLETED | Module already completed |
| u103 | ERR_INSUFFICIENT_FUNDS | Not enough STX in contract |
| u104 | ERR_INVALID_QUIZ | Quiz does not exist |
| u105 | ERR_QUIZ_NOT_PASSED | Quiz score too low |
| u106 | ERR_REWARD_ALREADY_CLAIMED | Reward already claimed |
| u107 | ERR_MODULE_NOT_ACTIVE | Module is not active |
| u108 | ERR_INVALID_SCORE | Score out of valid range |
| u109 | ERR_COOLDOWN_ACTIVE | Cooldown period active |

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)

## 🎉 Acknowledgments

- Stacks Foundation for the blockchain platform
- Hiro team for Clarinet development tools
- Community contributors and testers

---

Built with ❤️ on Stacks blockchain
