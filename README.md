# Tokenized Business Continuity Crisis Communication

A blockchain-based crisis communication system for managing business continuity during emergencies.

## Features

- **Crisis Communicator Verification**: Validates business crisis communicators
- **Communication Planning**: Plans crisis communications with structured protocols
- **Message Coordination**: Coordinates crisis messages across multiple channels
- **Stakeholder Management**: Manages crisis stakeholders and their communication preferences
- **Recovery Communication**: Manages recovery communications and status updates

## Architecture

The system consists of five smart contracts:

1. `crisis-communicator-verification.clar` - Handles communicator authentication and authorization
2. `communication-planning.clar` - Manages crisis communication plans and protocols
3. `message-coordination.clar` - Coordinates message distribution and tracking
4. `stakeholder-management.clar` - Manages stakeholder information and preferences
5. `recovery-communication.clar` - Handles recovery phase communications

## Getting Started

### Prerequisites

- Clarinet CLI
- Node.js 16+
- Vitest for testing

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Usage

Each contract provides specific functionality for crisis communication management:

- Use the verification contract to authorize communicators
- Create communication plans using the planning contract
- Coordinate messages through the message coordination contract
- Manage stakeholders with the stakeholder management contract
- Handle recovery communications with the recovery contract

## Testing

Run the test suite:

\`\`\`
npm test
\`\`\`

Tests cover all contract functions, error conditions, and edge cases.

## License

MIT License
