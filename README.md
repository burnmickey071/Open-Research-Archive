# 📚 Open Research Archive

A decentralized research paper archive built on Stacks blockchain that provides timestamped proof of research claims to prevent plagiarism and establish priority claims.

## 🌟 Features

- 📝 **Submit Research Papers**: Upload research with cryptographic hash for integrity
- ⏰ **Timestamp Claims**: Immutable blockchain timestamps for priority claims  
- 🔍 **Plagiarism Prevention**: Check if content already exists before submission
- 📊 **Citation Tracking**: Add and track citations between papers
- ✅ **Verification System**: Contract owner can verify legitimate research
- 👤 **Author Profiles**: Track all papers by author
- 💰 **Fee-based Submissions**: Prevents spam with configurable fees

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet with STX tokens

### Installation

```bash
git clone <repository-url>
cd research-archive
clarinet check
```

### Deployment

```bash
clarinet deploy --testnet
```

## 📖 Usage

### Submit Research Paper

```clarity
(contract-call? .research-archive submit-research 
    "My Research Title" 
    0x1234567890abcdef1234567890abcdef12345678 
    "Computer Science")
```

### Check Content Exists

```clarity
(contract-call? .research-archive check-content-exists 
    0x1234567890abcdef1234567890abcdef12345678)
```

### Verify Timestamp Claim

```clarity
(contract-call? .research-archive verify-timestamp-claim 
    0x1234567890abcdef1234567890abcdef12345678 
    u1640995200)
```

### Add Citation

```clarity
(contract-call? .research-archive add-citation 
    u2 
    u1 
    "This paper builds upon the methodology described in...")
```

### Get Research Paper

```clarity
(contract-call? .research-archive get-research-paper u1)
```

## 🏗️ Contract Structure

### Data Maps

- `research-papers`: Stores paper metadata and timestamps
- `author-papers`: Maps authors to their submitted papers  
- `content-hashes`: Prevents duplicate content submission
- `research-citations`: Tracks citations between papers
- `paper-citations-count`: Citation counts for each paper

### Key Functions

- `submit-research`: Submit new research with fee payment
- `verify-research`: Owner verification of legitimate research
- `add-citation`: Link papers through citations
- `verify-timestamp-claim`: Check priority claims against existing submissions

## 💡 Use Cases

- 🎓 **Academic Researchers**: Establish priority claims for discoveries
- 🏢 **Research Institutions**: Create verifiable publication records  
- 📰 **Journalists**: Timestamp investigative findings
- 💼 **Corporate R&D**: Protect intellectual property claims
- 🔬 **Independent Researchers**: Build credible research portfolios

## ⚙️ Configuration

- **Submission Fee**: Currently 1 STX (configurable by owner)
- **Max Papers per Author**: 100 papers
- **Title Length**: Up to 200 characters
- **Category Length**: Up to 50 characters
- **Citation Context**: Up to 500 characters

## 🔒 Security Features

- Content hash verification prevents tampering
- Blockchain timestamps provide immutable proof
- Fee mechanism prevents spam submissions
- Owner verification adds credibility layer
- Duplicate content detection

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions:
- Open an issue on GitHub
- Check existing documentation
- Review contract functions and error codes
```

**Git Commit Message:**
```
feat: implement MVP research archive with timestamped submissions and plagiarism prevention
```

**GitHub Pull Request Title:**
```
🚀 Add Open Research Archive MVP - Timestamped Research Submissions
```

**GitHub Pull Request Description:**
```
## 📚 Open Research Archive MVP

This PR introduces a complete MVP for a decentralized research archive system built on Stacks blockchain.

### ✨ Features Added

- **Research Submission System**: Submit papers with cryptographic hashes and blockchain timestamps
- **Plagiarism Prevention**: Check content existence before submission to prevent duplicates  
- **Citation Tracking**: Link papers through citations with context
- **Author Management**: Track all papers by author with comprehensive profiles
- **Verification System**: Owner-controlled verification for research legitimacy
- **Fee-based Submissions**: Configurable STX fees to prevent spam
- **Timestamp Claims**: Verify priority claims against existing submissions

### 🏗️ Technical Implementation

- Complete Clarity smart contract (150+ lines)
- Comprehensive data mapping system for papers, authors, and citations
- Error handling with descriptive error codes
- Read-only functions for data queries
- Public functions for core operations

### 📖 Documentation

- Detailed README with usage examples
- Clear setup and deployment instructions  
- Use cases and configuration options
- Security features overview

### 🎯 Use Cases

Perfect for academic researchers, institutions, journalists, and anyone needing to establish timestamped proof of research claims and prevent plagiarism.

Ready for immediate deployment and testing on Stacks testnet.
