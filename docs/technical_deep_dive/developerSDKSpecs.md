# Veridis: Developer SDK Specifications

**Technical Documentation v1.0**  
**May 8, 2025**

**Authors:**  
Cass402 and the Veridis Engineering Team

---

## Document Control

| Version | Date       | Author           | Changes                      |
| ------- | ---------- | ---------------- | ---------------------------- |
| 0.1     | 2025-04-02 | SDK Team         | Initial draft                |
| 0.2     | 2025-04-15 | Integration Team | Added integration examples   |
| 0.3     | 2025-05-01 | API Team         | Updated API reference        |
| 1.0     | 2025-05-08 | Cass402          | Final review and publication |

**Classification:** Internal Technical Documentation  
**Distribution:** Veridis Engineering, External Developers, Technical Partners

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [SDK Architecture](#2-sdk-architecture)
3. [Installation and Setup](#3-installation-and-setup)
4. [Core SDK Components](#4-core-sdk-components)
5. [Client-Side Proof Generation](#5-client-side-proof-generation)
6. [ZK Circuit Integration](#6-zk-circuit-integration)
7. [Integration Patterns](#7-integration-patterns)
8. [Error Handling](#8-error-handling)
9. [Testing and Verification](#9-testing-and-verification)
10. [Appendices](#10-appendices)

---

## 1. Introduction

### 1.1 Purpose and Scope

This document provides comprehensive technical specifications for the Veridis Developer SDK, a suite of libraries and tools designed to enable seamless integration with the Veridis identity and attestation protocol. The SDK facilitates credential verification, zero-knowledge proof generation, and interaction with the Veridis smart contracts on StarkNet.

The document is targeted at:

- Developers building applications that leverage Veridis credentials
- Teams integrating Sybil-resistance into their protocols
- DeFi projects implementing privacy-preserving KYC
- DAO developers implementing credential-based governance

### 1.2 SDK Goals and Principles

The Veridis Developer SDK is designed according to the following principles:

1. **Privacy-First**: Enable developers to implement privacy-preserving verification without technical cryptography expertise
2. **Cross-Platform**: Support multiple development environments and frameworks
3. **Modular Design**: Allow developers to use only the components they need
4. **Performance-Optimized**: Efficient implementation for both client and server environments
5. **Developer Experience**: Intuitive API design with comprehensive documentation
6. **Security**: Follow security best practices and enable secure integration patterns

### 1.3 Key Terminology

- **SDK**: Software Development Kit - the libraries and tools for integrating with Veridis
- **Credential**: A verifiable attestation issued to a user
- **Proof**: Zero-knowledge proof demonstrating possession of a valid credential
- **Circuit**: Zero-knowledge circuit defining the verification logic
- **Wallet**: User's crypto wallet containing their identity secrets
- **Cairo**: Programming language for StarkNet smart contracts
- **StarkNet.js**: JavaScript library for interacting with StarkNet

## 2. SDK Architecture

### 2.1 System Overview

The Veridis Developer SDK consists of the following components:

```
┌─────────────────────────────────────────────────────┐
│               Application Layer                      │
├─────────────────────────────────────────────────────┤
│ ┌───────────────┐      ┌─────────────────────────┐  │
│ │  Frontend     │      │  Backend                │  │
│ │  Application  │      │  Services               │  │
│ └───────┬───────┘      └───────────┬─────────────┘  │
└─────────┼───────────────────────────┼───────────────┘
          │                           │
┌─────────▼───────────────────────────▼───────────────┐
│                 Veridis SDK Layer                    │
├─────────────────────────────────────────────────────┤
│ ┌───────────────┐      ┌─────────────────────────┐  │
│ │  Client SDK   │      │  Server SDK             │  │
│ │  Libraries    │      │  Libraries              │  │
│ └───────┬───────┘      └───────────┬─────────────┘  │
│         │                          │                │
│ ┌───────▼───────┐      ┌───────────▼─────────────┐  │
│ │  Credential   │      │  Contract                │  │
│ │  Manager      │      │  Interface               │  │
│ └───────┬───────┘      └───────────┬─────────────┘  │
│         │                          │                │
│ ┌───────▼───────┐      ┌───────────▼─────────────┐  │
│ │  ZK Proof     │      │  Transaction            │  │
│ │  Generator    │      │  Manager                │  │
│ └───────────────┘      └─────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼─────────────────────────┐
│                StarkNet Layer                      │
├───────────────────────────────────────────────────┤
│ ┌─────────────────┐     ┌───────────────────────┐ │
│ │ Veridis          │     │ StarkNet             │ │
│ │ Smart Contracts  │     │ Infrastructure       │ │
│ └─────────────────┘     └───────────────────────┘ │
└───────────────────────────────────────────────────┘
```

### 2.2 SDK Components

The Veridis SDK is organized into the following main components:

1. **Client SDK Libraries**:

   - Core library for browser and mobile applications
   - Wallet integration modules
   - Proof generation engine
   - Credential management tools

2. **Server SDK Libraries**:

   - Backend integration libraries
   - Verification services
   - Batch processing utilities
   - Administrative tools

3. **Common Components**:
   - Contract interface definitions
   - Type definitions
   - Cryptographic primitives
   - Utility functions

### 2.3 Supported Platforms

The Veridis SDK supports the following platforms and environments:

| Platform         | Supported Versions | Package                 |
| ---------------- | ------------------ | ----------------------- |
| Web (JavaScript) | ES2020+            | `@veridis/client`       |
| Node.js          | 16.x+              | `@veridis/server`       |
| React Native     | 0.65+              | `@veridis/react-native` |
| Flutter          | 2.5+               | `veridis_flutter`       |
| Python           | 3.9+               | `veridis-python`        |
| Go               | 1.18+              | `veridis-go`            |

## 3. Installation and Setup

### 3.1 Installation Instructions

#### 3.1.1 JavaScript/TypeScript

```bash
# Using npm
npm install @veridis/client @veridis/core

# Using yarn
yarn add @veridis/client @veridis/core

# Using pnpm
pnpm add @veridis/client @veridis/core
```

#### 3.1.2 Python

```bash
# Using pip
pip install veridis-python

# Using poetry
poetry add veridis-python
```

#### 3.1.3 Go

```bash
go get github.com/veridis-protocol/veridis-go
```

### 3.2 Basic Configuration

#### 3.2.1 JavaScript/TypeScript

```typescript
// Example configuration in TypeScript
import { VeridisClient, NetworkType } from "@veridis/client";

// Initialize the client
const veridis = new VeridisClient({
  network: NetworkType.MAINNET, // or NetworkType.TESTNET
  nodeUrl: "https://starknet-mainnet.infura.io/v3/YOUR_API_KEY",
  apiKey: "your_optional_api_key", // For additional services

  // Optional configuration
  defaultAttesterAddress: "0x1234...",
  defaultProofGenerationServer: "https://proofs.veridis.xyz",
  logLevel: "error", // 'debug', 'info', 'warn', 'error'
});
```

#### 3.2.2 Python

```python
# Example configuration in Python
from veridis import VeridisClient, NetworkType

# Initialize the client
veridis = VeridisClient(
    network=NetworkType.MAINNET,  # or NetworkType.TESTNET
    node_url="https://starknet-mainnet.infura.io/v3/YOUR_API_KEY",
    api_key="your_optional_api_key",  # For additional services

    # Optional configuration
    default_attester_address="0x1234...",
    default_proof_generation_server="https://proofs.veridis.xyz",
    log_level="error"  # 'debug', 'info', 'warn', 'error'
)
```

### 3.3 API Keys and Authentication

The Veridis SDK supports multiple authentication methods:

1. **API Key**: For accessing premium services and higher rate limits
2. **Wallet Authentication**: For user-specific operations
3. **OAuth Integration**: For enterprise integrations

Example API key configuration:

```typescript
// Example API key configuration
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Basic configuration...

  // Authentication
  apiKey: "your_api_key_here",
  apiSecret: "your_api_secret_here", // Only for server-side applications

  // Optional custom authentication
  authProvider: {
    getAuthHeaders: async () => {
      // Custom logic to generate authentication headers
      return {
        "X-Custom-Auth": "custom_token_here",
      };
    },
  },
});
```

## 4. Core SDK Components

### 4.1 Credential Manager

The Credential Manager handles the storage, retrieval, and management of user credentials:

```typescript
// Example credential management
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Store a credential
async function storeCredential(credential) {
  await veridis.credentials.store(credential);

  // Check storage status
  const storedCredentials = await veridis.credentials.list();
  console.log(`Stored ${storedCredentials.length} credentials`);
}

// Retrieve credentials by type
async function getKycCredentials() {
  const credentials = await veridis.credentials.getByType("KYC_BASIC");
  return credentials;
}

// Delete expired credentials
async function cleanupCredentials() {
  await veridis.credentials.deleteExpired();
}
```

#### 4.1.1 Credential Storage Options

The SDK supports multiple storage backends:

```typescript
// Configure storage backend
import { VeridisClient, StorageType } from "@veridis/client";

const veridis = new VeridisClient({
  // Basic configuration...

  // Storage configuration
  storage: {
    type: StorageType.LOCAL_STORAGE, // Default for browser
    // Alternative options:
    // type: StorageType.INDEXED_DB,
    // type: StorageType.IN_MEMORY,
    // type: StorageType.SECURE_STORAGE, // For mobile

    encryption: true, // Encrypt stored credentials
    encryptionKey: "optional_custom_key", // Or auto-generated

    // Custom storage implementation
    customStorage: {
      // Implement storage interface methods
      async get(key) {
        /* ... */
      },
      async set(key, value) {
        /* ... */
      },
      async remove(key) {
        /* ... */
      },
      async clear() {
        /* ... */
      },
    },
  },
});
```

#### 4.1.2 Credential Data Model

```typescript
// Credential data model
interface Credential {
  // Core fields
  id: string; // Unique identifier
  attestationType: number; // Type of attestation (e.g., KYC_BASIC = 1)
  subject: string; // The subject's identity commitment
  data: string; // Attestation data (hex encoded)
  nonce: string; // Randomization factor

  // Merkle proof data (for Tier-1 attestations)
  merkleRoot?: string; // Root of the Merkle tree
  merkleProof?: {
    // Proof of inclusion
    leaf: string;
    path: Array<{
      sibling: string;
      isLeft: boolean;
    }>;
  };

  // Metadata
  attester: string; // Address of the attester
  issuedAt: number; // Timestamp when issued
  expirationTime: number; // When the credential expires

  // Optional fields
  signature?: string; // Attester signature of the credential
  schemaUri?: string; // URI pointing to the credential schema
  metadata?: Record<string, any>; // Additional application-specific metadata
}
```

### 4.2 Contract Interface

The Contract Interface provides a type-safe way to interact with Veridis smart contracts:

```typescript
// Example contract interaction
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Read contract state
async function checkAttestationStatus(attester, attestationType) {
  const attestation =
    await veridis.contracts.attestationRegistry.getTier1Attestation(
      attester,
      attestationType
    );

  return {
    isValid:
      !attestation.revoked && attestation.expirationTime > Date.now() / 1000,
    merkleRoot: attestation.merkleRoot,
    expirationTime: attestation.expirationTime,
  };
}

// Write to contract (requires wallet)
async function issueAttestation(wallet, subject, attestationType, data) {
  const tx = await veridis.contracts.attestationRegistry
    .connect(wallet)
    .issueTier2Attestation(
      subject,
      attestationType,
      data,
      Math.floor(Date.now() / 1000) + 31536000, // 1 year expiry
      "ipfs://QmYjN8yFc3xBV4..." // Schema URI
    );

  return await tx.wait();
}
```

#### 4.2.1 Contract Addresses

The SDK includes built-in contract addresses for different networks:

```typescript
// Access contract addresses
import { VeridisClient, getContractAddresses } from "@veridis/client";

// Get addresses for a specific network
const addresses = getContractAddresses("mainnet");
console.log("AttestationRegistry:", addresses.attestationRegistry);
console.log("IdentityRegistry:", addresses.identityRegistry);

// Or access through the client
const veridis = new VeridisClient({
  // Configuration...
});

const attestationRegistryAddress = veridis.contracts.getAddress(
  "attestationRegistry"
);
```

#### 4.2.2 Custom Contract Interaction

For advanced use cases, the SDK allows direct contract interaction:

```typescript
// Custom contract interaction
import { VeridisClient } from "@veridis/client";
import { Contract } from "starknet";

const veridis = new VeridisClient({
  // Configuration...
});

// Create custom contract instance
async function interactWithCustomContract() {
  const customContract = new Contract(
    customAbi,
    "0x123456...",
    veridis.provider
  );

  // Call custom method
  const result = await customContract.myCustomMethod(param1, param2);
  return result;
}
```

### 4.3 Wallet Integration

The SDK integrates with various wallet providers:

```typescript
// Wallet integration example
import { VeridisClient, WalletType } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Connect to wallet
async function connectWallet() {
  // Connect to default wallet
  const wallet = await veridis.wallet.connect();

  // Or specify wallet type
  // const wallet = await veridis.wallet.connect(WalletType.ARGENT);

  console.log("Connected account:", wallet.account.address);
  return wallet;
}

// Use connected wallet
async function signMessage(message) {
  const wallet = veridis.wallet.getConnected();
  if (!wallet) {
    throw new Error("No wallet connected");
  }

  const signature = await wallet.signMessage(message);
  return signature;
}

// Disconnect wallet
function disconnectWallet() {
  veridis.wallet.disconnect();
}
```

#### 4.3.1 Supported Wallets

The SDK supports various StarkNet wallets:

| Wallet        | Type              | Environments          |
| ------------- | ----------------- | --------------------- |
| ArgentX       | Browser Extension | Web                   |
| Braavos       | Browser Extension | Web                   |
| OKX           | Browser Extension | Web                   |
| WebWallet     | In-app            | React Native, Flutter |
| Custom Signer | Any               | All                   |

#### 4.3.2 Identity Secret Management

For identity-related operations, the SDK provides secure management of identity secrets:

```typescript
// Identity secret management
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Generate new identity secret
async function createIdentity() {
  const identity = await veridis.identity.create();
  console.log("Identity commitment:", identity.commitment);

  // The secret is securely stored in the configured storage
  return identity;
}

// Use existing identity
async function useIdentity() {
  const identities = await veridis.identity.list();

  if (identities.length === 0) {
    return await createIdentity();
  }

  // Use the first identity
  return identities[0];
}
```

### 4.4 Transaction Manager

The Transaction Manager handles transaction creation, submission, and monitoring:

```typescript
// Transaction management example
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Submit a transaction
async function submitTransaction(wallet, contractMethod, ...args) {
  const tx = await veridis.transactions.submit({
    wallet,
    contract: "attestationRegistry", // Predefined contract
    method: contractMethod,
    args,
    // Optional parameters
    maxFee: "1000000000000000", // Max fee in wei
    nonce: "auto", // 'auto' or specific nonce
  });

  console.log("Transaction hash:", tx.hash);

  // Wait for confirmation
  const receipt = await veridis.transactions.waitForTransaction(tx.hash);
  return receipt;
}

// Check transaction status
async function checkTransactionStatus(txHash) {
  const status = await veridis.transactions.getStatus(txHash);
  return status; // 'NOT_RECEIVED', 'RECEIVED', 'PENDING', 'ACCEPTED_ON_L2', 'ACCEPTED_ON_L1', 'REJECTED'
}

// Estimate transaction fee
async function estimateFee(contractMethod, ...args) {
  const estimate = await veridis.transactions.estimateFee({
    contract: "attestationRegistry",
    method: contractMethod,
    args,
  });

  return {
    fee: estimate.amount,
    suggestedMaxFee: estimate.suggestedMaxFee,
  };
}
```

## 5. Client-Side Proof Generation

### 5.1 Proof Generation Process

The SDK provides a streamlined API for generating zero-knowledge proofs:

```typescript
// Proof generation example
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Generate proof for credential
async function generateProof(credentialId, options) {
  // Get the credential
  const credential = await veridis.credentials.get(credentialId);

  if (!credential) {
    throw new Error("Credential not found");
  }

  // Generate the proof
  const proof = await veridis.proofs.generate({
    credential,

    // Choose appropriate circuit based on credential type
    circuit: `${credential.attestationType}_VERIFICATION`, // e.g., "1_VERIFICATION" for KYC_BASIC

    // Provide additional public inputs (optional)
    publicInputs: {
      context: options.context || "0", // Application-specific context
      extraData: options.extraData || "0", // Additional public data
    },

    // Control nullifier generation (optional)
    nullifier: {
      enable: options.preventReuse || false,
      context: options.nullifierContext || options.context || "0",
    },

    // Performance options (optional)
    performance: {
      timeout: 60000, // 60 seconds
      useProofServer: options.useProofServer || false,
    },
  });

  return proof;
}
```

### 5.2 Local vs. Remote Proof Generation

The SDK supports both local and remote proof generation:

```typescript
// Configure proof generation
import { VeridisClient, ProofGenerationMode } from "@veridis/client";

const veridis = new VeridisClient({
  // Basic configuration...

  // Proof generation configuration
  proofGeneration: {
    // Mode options:
    // - ProofGenerationMode.LOCAL: Generate proofs locally (better privacy)
    // - ProofGenerationMode.REMOTE: Use remote proof server (better performance)
    // - ProofGenerationMode.HYBRID: Try local, fall back to remote if too slow
    mode: ProofGenerationMode.HYBRID,

    // Remote server configuration (for REMOTE or HYBRID mode)
    remoteServer: {
      url: "https://proofs.veridis.xyz",
      apiKey: "optional_api_key",
      timeout: 30000, // 30 seconds
    },

    // Performance configuration
    performance: {
      maxLocalProofTimeMs: 15000, // Switch to remote if local takes longer than 15s
      webWorkers: "auto", // or specific number of worker threads
      wasmPath: "/path/to/custom/proving.wasm", // Optional custom WASM
    },

    // Security configuration
    security: {
      // Whether to transmit the full credential to the remote server
      // If false, only sends the minimum data needed
      sendFullCredential: false,

      // Additional entropy source for cryptographic operations
      entropySource: () => window.crypto.getRandomValues(new Uint8Array(32)),
    },
  },
});
```

### 5.3 Proof Data Structure

```typescript
// Proof data structure
interface Proof {
  // Core proof data
  programHash: string; // Hash of the proving program
  proofValues: string[]; // The actual STARK proof data

  // Public inputs
  publicInputs: {
    merkleRoot: string; // Attestation Merkle root
    nullifier: string; // Nullifier (if enabled)
    hasNullifier: boolean; // Whether nullifier is included
    context: string; // Usage context
    attester: string; // Attester address
    attestationType: string; // Type of attestation
    extraData: string; // Additional public data
  };

  // Metadata
  credentialId: string; // ID of the credential used
  generatedAt: number; // When the proof was generated
  version: string; // SDK version that generated the proof
}
```

### 5.4 Proof Verification

Client-side proof verification for additional security:

```typescript
// Client-side proof verification
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Verify a proof locally (optional but recommended)
async function verifyProofLocally(proof) {
  const isValid = await veridis.proofs.verifyLocally(proof);

  if (!isValid) {
    throw new Error("Proof verification failed locally");
  }

  return isValid;
}

// Verify a proof on-chain
async function verifyProofOnChain(proof) {
  const result = await veridis.proofs.verifyOnChain(proof);

  return {
    isValid: result.isValid,
    txHash: result.transaction?.hash,
    nullifierRegistered: result.nullifierRegistered,
  };
}
```

## 6. ZK Circuit Integration

### 6.1 Standard Circuits

The SDK provides pre-built circuits for common credential verification scenarios:

| Circuit ID | Name                          | Purpose                                  | Public Inputs                 |
| ---------- | ----------------------------- | ---------------------------------------- | ----------------------------- |
| 1          | KYC_BASIC_VERIFICATION        | Verify KYC attestation                   | Attester, Root                |
| 2          | KYC_JURISDICTION_VERIFICATION | Verify user is from allowed jurisdiction | Attester, Root, Jurisdictions |
| 3          | UNIQUENESS_VERIFICATION       | Verify user is a unique human            | Attester, Root, Context       |
| 4          | AGE_VERIFICATION              | Verify user is above age threshold       | Attester, Root, MinAge        |
| 5          | CREDENTIAL_COMBINATION        | Verify multiple credentials              | Attesters, Roots              |

### 6.2 Custom Circuit Integration

For specialized verification logic, developers can integrate custom circuits:

```typescript
// Register custom circuit
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Register a custom circuit
function registerCustomCircuit() {
  veridis.circuits.register({
    id: "CUSTOM_VERIFICATION",
    name: "Custom Verification Circuit",
    description: "Custom verification logic for specialized requirements",

    // Circuit resources
    resources: {
      wasmUrl: "https://your-domain.com/circuits/custom_verification.wasm",
      witnessGeneratorUrl:
        "https://your-domain.com/circuits/custom_verification_witness.js",
      verificationKey: "0x1234...", // Public verification key
    },

    // Input mapping function
    generateInputs: (credential, options) => {
      // Transform credential into circuit inputs
      return {
        credential_hash: credential.data,
        custom_parameter: options.customParameter,
        timestamp: Math.floor(Date.now() / 1000),
        // Other circuit-specific inputs
      };
    },

    // Public input extraction
    extractPublicInputs: (inputs, proofResult) => {
      return {
        merkleRoot: credential.merkleRoot,
        attester: credential.attester,
        attestationType: credential.attestationType,
        extraData: inputs.custom_parameter,
        // Other public inputs
      };
    },
  });
}

// Use custom circuit
async function generateCustomProof(credential, customParameter) {
  const proof = await veridis.proofs.generate({
    credential,
    circuit: "CUSTOM_VERIFICATION",
    publicInputs: {
      customParameter,
    },
  });

  return proof;
}
```

### 6.3 Circuit Selection Helper

The SDK includes helpers for selecting the appropriate circuit:

```typescript
// Circuit selection example
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Select appropriate circuit based on requirements
async function selectAppropriateCircuit(credential, requirements) {
  const recommendedCircuit = await veridis.circuits.recommend({
    credential,
    requirements: {
      attestationType: requirements.attestationType,
      needsNullifier: requirements.preventReuse || false,
      requiredPredicates: requirements.predicates || [],
      requiredAttester: requirements.specificAttester,
    },
  });

  console.log("Recommended circuit:", recommendedCircuit.id);
  return recommendedCircuit.id;
}
```

## 7. Integration Patterns

### 7.1 Sybil-Resistant Applications

Implementation example for a Sybil-resistant airdrop:

```typescript
// Sybil-resistant airdrop example
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Check if user can claim airdrop
async function checkEligibility() {
  // Check if user has a valid uniqueness attestation
  const credentials = await veridis.credentials.getByType(3); // UNIQUE_HUMAN

  if (credentials.length === 0) {
    return {
      eligible: false,
      reason: "No uniqueness credential found",
    };
  }

  // Check if the credential is valid
  const credential = credentials[0];
  const attester = credential.attester;

  // Check on-chain if the attester is valid
  const isAttesterValid =
    await veridis.contracts.attesterRegistry.isTier1Attester(
      attester,
      3 // UNIQUE_HUMAN attestation type
    );

  if (!isAttesterValid) {
    return {
      eligible: false,
      reason: "Invalid attester",
    };
  }

  return {
    eligible: true,
    credential: credential.id,
  };
}

// Claim airdrop with proof of uniqueness
async function claimAirdrop(airdropContractAddress) {
  // Check eligibility
  const eligibility = await checkEligibility();

  if (!eligibility.eligible) {
    throw new Error(`Not eligible: ${eligibility.reason}`);
  }

  // Get credential
  const credential = await veridis.credentials.get(eligibility.credential);

  // Generate proof for the airdrop
  const proof = await veridis.proofs.generate({
    credential,
    circuit: "UNIQUENESS_VERIFICATION",
    publicInputs: {
      context: airdropContractAddress, // Use contract address as context
    },
    nullifier: {
      enable: true,
      context: airdropContractAddress,
    },
  });

  // Get connected wallet
  const wallet = veridis.wallet.getConnected();

  if (!wallet) {
    throw new Error("Wallet not connected");
  }

  // Create airdrop contract instance
  const airdropContract = new Contract(
    airdropAbi,
    airdropContractAddress,
    wallet.provider
  );

  // Call claim function
  const tx = await airdropContract.claim(proof.publicInputs, proof.proofValues);

  // Wait for transaction confirmation
  const receipt = await tx.wait();

  return {
    success: true,
    transactionHash: receipt.transaction_hash,
  };
}
```

### 7.2 KYC-Gated DeFi Integration

Implementation example for KYC-gated DeFi access:

```typescript
// KYC-gated DeFi example
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Verify KYC status for DeFi protocol
async function verifyKycForDeFi(defiProtocolAddress) {
  // Check for KYC credentials
  const kycCredentials = await veridis.credentials.getByType(1); // KYC_BASIC

  if (kycCredentials.length === 0) {
    return {
      verified: false,
      reason: "No KYC credential found",
      action: "Complete KYC with a supported provider",
    };
  }

  // Find a valid credential
  let validCredential = null;
  for (const credential of kycCredentials) {
    // Check expiration
    if (credential.expirationTime < Date.now() / 1000) {
      continue; // Skip expired credentials
    }

    // Verify on-chain status
    const attestation =
      await veridis.contracts.attestationRegistry.getTier1Attestation(
        credential.attester,
        credential.attestationType
      );

    if (!attestation.revoked) {
      validCredential = credential;
      break;
    }
  }

  if (!validCredential) {
    return {
      verified: false,
      reason: "No valid KYC credential found",
      action: "Refresh your KYC verification",
    };
  }

  return {
    verified: true,
    credential: validCredential.id,
  };
}

// Submit KYC verification to DeFi protocol
async function submitKycVerification(defiProtocolAddress) {
  // Check KYC status
  const kycStatus = await verifyKycForDeFi(defiProtocolAddress);

  if (!kycStatus.verified) {
    throw new Error(`KYC verification failed: ${kycStatus.reason}`);
  }

  // Get credential
  const credential = await veridis.credentials.get(kycStatus.credential);

  // Generate KYC proof
  const proof = await veridis.proofs.generate({
    credential,
    circuit: "KYC_BASIC_VERIFICATION",
    publicInputs: {
      context: defiProtocolAddress,
    },
    // No nullifier needed for KYC (can be verified multiple times)
  });

  // Get connected wallet
  const wallet = veridis.wallet.getConnected();

  if (!wallet) {
    throw new Error("Wallet not connected");
  }

  // Create DeFi protocol contract instance
  const defiContract = new Contract(
    defiProtocolAbi,
    defiProtocolAddress,
    wallet.provider
  );

  // Submit verification
  const tx = await defiContract.verifyKyc(
    proof.publicInputs,
    proof.proofValues
  );

  // Wait for confirmation
  const receipt = await tx.wait();

  return {
    success: true,
    transactionHash: receipt.transaction_hash,
  };
}
```

### 7.3 Reputation-Based Access

Implementation example for reputation-based access control:

```typescript
// Reputation-based access example
import { VeridisClient } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Verify reputation for access control
async function verifyReputation(requiredScore, application) {
  // Get reputation credentials
  const reputationCredentials = await veridis.credentials.getByType(102); // REPUTATION_SCORE

  if (reputationCredentials.length === 0) {
    return {
      access: false,
      reason: "No reputation credential found",
    };
  }

  // Find highest reputation score
  let highestScore = 0;
  let bestCredential = null;

  for (const credential of reputationCredentials) {
    // Decode the reputation data
    const reputationData = veridis.utils.decodeReputationData(credential.data);

    if (reputationData.score > highestScore) {
      highestScore = reputationData.score;
      bestCredential = credential;
    }
  }

  // Check if score meets requirement
  if (highestScore < requiredScore) {
    return {
      access: false,
      reason: `Reputation score too low (${highestScore}/${requiredScore})`,
    };
  }

  // Generate proof of sufficient reputation
  const proof = await veridis.proofs.generate({
    credential: bestCredential,
    circuit: "REPUTATION_THRESHOLD_VERIFICATION",
    publicInputs: {
      context: application,
      threshold: requiredScore.toString(),
    },
  });

  return {
    access: true,
    proof,
    score: highestScore,
  };
}

// Submit proof to application
async function accessApplication(applicationAddress, requiredScore) {
  // Verify reputation
  const reputationCheck = await verifyReputation(
    requiredScore,
    applicationAddress
  );

  if (!reputationCheck.access) {
    throw new Error(`Access denied: ${reputationCheck.reason}`);
  }

  // Get connected wallet
  const wallet = veridis.wallet.getConnected();

  if (!wallet) {
    throw new Error("Wallet not connected");
  }

  // Submit proof to application
  const applicationContract = new Contract(
    applicationAbi,
    applicationAddress,
    wallet.provider
  );

  // Access the application
  const tx = await applicationContract.access(
    reputationCheck.proof.publicInputs,
    reputationCheck.proof.proofValues
  );

  // Wait for confirmation
  const receipt = await tx.wait();

  return {
    success: true,
    transactionHash: receipt.transaction_hash,
  };
}
```

## 8. Error Handling

### 8.1 Error Types

The SDK defines the following error types:

```typescript
// Error types
enum ErrorType {
  // Configuration errors
  CONFIG_ERROR = "CONFIG_ERROR", // Invalid configuration
  NETWORK_ERROR = "NETWORK_ERROR", // Network-related errors

  // Credential errors
  CREDENTIAL_NOT_FOUND = "CREDENTIAL_NOT_FOUND", // Credential not found
  CREDENTIAL_EXPIRED = "CREDENTIAL_EXPIRED", // Credential has expired
  CREDENTIAL_REVOKED = "CREDENTIAL_REVOKED", // Credential was revoked
  CREDENTIAL_INVALID = "CREDENTIAL_INVALID", // Invalid credential format

  // Proof generation errors
  PROOF_GENERATION_ERROR = "PROOF_GENERATION_ERROR", // General proof error
  PROOF_TIMEOUT = "PROOF_TIMEOUT", // Proof generation timed out
  CIRCUIT_NOT_FOUND = "CIRCUIT_NOT_FOUND", // Circuit not found

  // Wallet errors
  WALLET_CONNECTION_ERROR = "WALLET_CONNECTION_ERROR", // Failed to connect
  WALLET_DISCONNECTED = "WALLET_DISCONNECTED", // No wallet connected
  WALLET_REJECTED = "WALLET_REJECTED", // User rejected the request

  // Transaction errors
  TRANSACTION_ERROR = "TRANSACTION_ERROR", // Transaction failed
  TRANSACTION_REJECTED = "TRANSACTION_REJECTED", // Transaction rejected

  // General errors
  INVALID_PARAMETER = "INVALID_PARAMETER", // Invalid parameter
  UNAUTHORIZED = "UNAUTHORIZED", // Unauthorized action
  INTERNAL_ERROR = "INTERNAL_ERROR", // Internal SDK error
  UNKNOWN_ERROR = "UNKNOWN_ERROR", // Unknown error
}
```

### 8.2 Error Handling Pattern

The SDK provides a consistent error handling pattern:

```typescript
// Error handling example
import { VeridisClient, VeridisError, ErrorType } from "@veridis/client";

const veridis = new VeridisClient({
  // Configuration...
});

// Example function with error handling
async function generateProofWithErrorHandling(credentialId) {
  try {
    const proof = await veridis.proofs.generate({
      credentialId,
      circuit: "KYC_BASIC_VERIFICATION",
    });

    return proof;
  } catch (error) {
    // Check if it's a VeridisError
    if (error instanceof VeridisError) {
      // Handle specific error types
      switch (error.type) {
        case ErrorType.CREDENTIAL_NOT_FOUND:
          console.error("Credential not found:", error.message);
          // Handle missing credential
          break;

        case ErrorType.CREDENTIAL_EXPIRED:
          console.error("Credential expired:", error.message);
          // Suggest refreshing the credential
          break;

        case ErrorType.PROOF_GENERATION_ERROR:
          console.error("Failed to generate proof:", error.message);
          // Provide fallback options
          break;

        case ErrorType.PROOF_TIMEOUT:
          console.error("Proof generation timed out:", error.message);
          // Suggest trying again or using remote proving
          break;

        default:
          console.error("Veridis error:", error.type, error.message);
      }

      // Access additional error data
      if (error.data) {
        console.error("Error details:", error.data);
      }
    } else {
      // Handle non-Veridis errors
      console.error("Unexpected error:", error);
    }

    // Rethrow or return error info
    throw error;
  }
}
```

### 8.3 Debugging and Logging

The SDK includes comprehensive logging and debugging capabilities:

```typescript
// Configure logging
import { VeridisClient, LogLevel } from "@veridis/client";

const veridis = new VeridisClient({
  // Basic configuration...

  // Logging configuration
  logging: {
    level: LogLevel.DEBUG, // 'error', 'warn', 'info', 'debug', 'trace'

    // Custom logger
    logger: {
      debug: (message, ...args) =>
        console.debug(`[Veridis] ${message}`, ...args),
      info: (message, ...args) => console.info(`[Veridis] ${message}`, ...args),
      warn: (message, ...args) => console.warn(`[Veridis] ${message}`, ...args),
      error: (message, ...args) =>
        console.error(`[Veridis] ${message}`, ...args),
      trace: (message, ...args) =>
        console.trace(`[Veridis] ${message}`, ...args),
    },

    // Filter specific modules
    enabledModules: ["proofs", "contracts", "credentials"],

    // Custom log formatter
    formatter: (level, message, module, timestamp) =>
      `[${timestamp.toISOString()}] [${level.toUpperCase()}] [${module}] ${message}`,
  },
});

// Debug mode for development
veridis.setDebugMode(true);

// Access logs programmatically
const recentLogs = veridis.logs.getRecent(10);
```

## 9. Testing and Verification

### 9.1 Testing Utilities

The SDK includes utilities for testing Veridis integrations:

```typescript
// Testing utilities example
import { VeridisTestUtils, NetworkType } from "@veridis/client/testing";

// Create test utils instance
const testUtils = new VeridisTestUtils({
  network: NetworkType.TESTNET,
  // Other configuration...
});

// Generate mock credentials for testing
async function setupTestCredentials() {
  // Generate mock KYC credential
  const kycCredential = await testUtils.generateMockCredential({
    attestationType: 1, // KYC_BASIC
    data: {
      kycLevel: "BASIC",
      jurisdictionCode: "US",
      identityType: "INDIVIDUAL",
      completedAt: Math.floor(Date.now() / 1000),
    },
  });

  // Generate mock uniqueness credential
  const uniquenessCredential = await testUtils.generateMockCredential({
    attestationType: 3, // UNIQUE_HUMAN
    data: {
      verificationMethod: "BIOMETRIC",
      confidenceScore: 95,
      lastVerifiedAt: Math.floor(Date.now() / 1000),
    },
  });

  return {
    kycCredential,
    uniquenessCredential,
  };
}

// Mock proof generation for testing
async function testProofGeneration() {
  // Generate a mock proof
  const mockProof = await testUtils.generateMockProof({
    circuit: "KYC_BASIC_VERIFICATION",
    publicInputs: {
      merkleRoot: "0x1234...",
      attester: "0x5678...",
      attestationType: "1",
      context: "0x0",
    },
  });

  return mockProof;
}

// Mock contract interactions
async function testContractInteraction() {
  // Mock contract call
  const mockResponse = await testUtils.mockContractCall({
    contract: "attestationRegistry",
    method: "getTier1Attestation",
    args: ["0x1234...", "1"],
    returnValue: {
      attestationType: "1",
      merkleRoot: "0x5678...",
      timestamp: Math.floor(Date.now() / 1000),
      expirationTime: Math.floor(Date.now() / 1000) + 31536000,
      revoked: false,
      schemaUri: "ipfs://Qm1234...",
    },
  });

  return mockResponse;
}
```

### 9.2 Local Testing Environment

The SDK provides a local testing environment for development:

```typescript
// Local testing environment
import { VeridisLocalEnvironment } from "@veridis/client/testing";

// Start local environment
async function setupLocalTestEnvironment() {
  const localEnv = new VeridisLocalEnvironment();

  // Start local nodes
  await localEnv.start({
    // Mock contracts automatically deployed
    mockAttestations: true,
    mockCredentials: true,

    // Local proof generation
    enableProofGeneration: true,

    // Speed up testing
    autoMineBlocks: true,
    blockTime: 100, // 100ms block time for faster testing
  });

  // Get local client configured for the test environment
  const testClient = localEnv.getClient();

  // Use test accounts
  const testAccounts = localEnv.getAccounts();
  const deployerAccount = testAccounts[0];
  const userAccount = testAccounts[1];

  return {
    localEnv,
    testClient,
    deployerAccount,
    userAccount,
  };
}

// Clean up after tests
async function cleanupTestEnvironment(localEnv) {
  await localEnv.stop();
}
```

### 9.3 Integration Testing Guide

Guidelines for testing Veridis integrations:

```typescript
// Integration testing example (using Jest)
import { VeridisClient } from "@veridis/client";
import { VeridisTestUtils } from "@veridis/client/testing";

// Test suite
describe("Veridis Integration Tests", () => {
  let veridis;
  let testUtils;
  let mockCredentials;

  // Set up before tests
  beforeAll(async () => {
    // Initialize client with testnet configuration
    veridis = new VeridisClient({
      network: "testnet",
      nodeUrl: "https://starknet-testnet.infura.io/v3/YOUR_API_KEY",
    });

    // Initialize test utilities
    testUtils = new VeridisTestUtils({ network: "testnet" });

    // Generate mock credentials
    mockCredentials = await testUtils.generateMockCredentials(2);

    // Store mock credentials in client
    for (const credential of mockCredentials) {
      await veridis.credentials.store(credential);
    }
  });

  // Test credential retrieval
  test("should retrieve stored credentials", async () => {
    const credentials = await veridis.credentials.list();
    expect(credentials.length).toBeGreaterThanOrEqual(2);

    // Check credential structure
    expect(credentials[0]).toHaveProperty("id");
    expect(credentials[0]).toHaveProperty("attestationType");
    expect(credentials[0]).toHaveProperty("attester");
  });

  // Test proof generation
  test("should generate zero-knowledge proof", async () => {
    // Get first credential
    const credential = mockCredentials[0];

    // Generate proof
    const proof = await veridis.proofs.generate({
      credential,
      circuit: "KYC_BASIC_VERIFICATION",
      publicInputs: {
        context: "0x1234",
      },
    });

    // Verify proof structure
    expect(proof).toHaveProperty("programHash");
    expect(proof).toHaveProperty("proofValues");
    expect(proof).toHaveProperty("publicInputs");
    expect(proof.publicInputs).toHaveProperty("merkleRoot");
    expect(proof.publicInputs).toHaveProperty("attester");
  });

  // Test contract interaction
  test("should interact with attestation registry", async () => {
    // Mock the contract call
    testUtils.mockContractCall({
      contract: "attestationRegistry",
      method: "getTier1Attestation",
      args: [mockCredentials[0].attester, mockCredentials[0].attestationType],
      returnValue: {
        attestationType: mockCredentials[0].attestationType,
        merkleRoot: mockCredentials[0].merkleRoot,
        timestamp: Math.floor(Date.now() / 1000) - 86400,
        expirationTime: Math.floor(Date.now() / 1000) + 31536000,
        revoked: false,
        schemaUri: "ipfs://Qm1234...",
      },
    });

    // Call the contract
    const attestation =
      await veridis.contracts.attestationRegistry.getTier1Attestation(
        mockCredentials[0].attester,
        mockCredentials[0].attestationType
      );

    // Verify attestation
    expect(attestation).toHaveProperty("merkleRoot");
    expect(attestation.merkleRoot).toBe(mockCredentials[0].merkleRoot);
    expect(attestation.revoked).toBe(false);
  });
});
```

## 10. Appendices

### 10.1 SDK Version Compatibility

Compatibility matrix for SDK versions and StarkNet versions:

| SDK Version | StarkNet Version | Cairo Version | Supported Features          |
| ----------- | ---------------- | ------------- | --------------------------- |
| 0.1.x       | 0.11.0 - 0.11.2  | 1.0           | Basic credential management |
| 0.2.x       | 0.11.0 - 0.12.0  | 1.0           | + Proof generation          |
| 0.3.x       | 0.11.0 - 0.12.1  | 1.0           | + Contract interactions     |
| 1.0.x       | 0.12.0+          | 1.0 - 2.0     | Full feature set            |

### 10.2 Common Code Patterns

#### 10.2.1 Credential Verification Flow

```typescript
// Common credential verification flow
import { VeridisClient } from "@veridis/client";

// Initialize client
const veridis = new VeridisClient({
  network: "mainnet",
  nodeUrl: "https://starknet-mainnet.infura.io/v3/YOUR_API_KEY",
});

// Connect wallet
await veridis.wallet.connect();

// Complete verification flow
async function verifyCredential(attestationType, requiredAttester) {
  // 1. Check for existing credentials
  const credentials = await veridis.credentials.getByType(attestationType);

  // 2. Filter by attester if required
  const validCredentials = requiredAttester
    ? credentials.filter((c) => c.attester === requiredAttester)
    : credentials;

  // 3. Check if we have any valid credentials
  if (validCredentials.length === 0) {
    return {
      verified: false,
      reason: "No valid credential found",
    };
  }

  // 4. Check on-chain status
  const credential = validCredentials[0];
  const attestation =
    await veridis.contracts.attestationRegistry.getTier1Attestation(
      credential.attester,
      credential.attestationType
    );

  // 5. Verify attestation is valid
  if (
    attestation.revoked ||
    attestation.expirationTime < Math.floor(Date.now() / 1000)
  ) {
    return {
      verified: false,
      reason: attestation.revoked ? "Credential revoked" : "Credential expired",
    };
  }

  return {
    verified: true,
    credential: credential.id,
  };
}
```

#### 10.2.2 Nullifier Usage Pattern

```typescript
// Nullifier usage pattern
import { VeridisClient } from "@veridis/client";

// Initialize client
const veridis = new VeridisClient({
  network: "mainnet",
  nodeUrl: "https://starknet-mainnet.infura.io/v3/YOUR_API_KEY",
});

// Generate proof with nullifier
async function generateProofWithNullifier(credentialId, context) {
  // Get the credential
  const credential = await veridis.credentials.get(credentialId);

  if (!credential) {
    throw new Error("Credential not found");
  }

  // Generate context-specific nullifier
  const proof = await veridis.proofs.generate({
    credential,
    circuit: `${credential.attestationType}_VERIFICATION`,
    publicInputs: {
      context,
    },
    nullifier: {
      enable: true,
      context,
    },
  });

  return proof;
}

// Check if nullifier has been used
async function checkNullifierStatus(nullifier) {
  const nullifierRegistry = veridis.contracts.nullifierRegistry;
  const isUsed = await nullifierRegistry.isNullifierUsed(nullifier);

  return {
    isUsed,
    // Get additional nullifier data if needed
    nullifierData: isUsed
      ? await nullifierRegistry.getNullifierData(nullifier)
      : null,
  };
}
```

#### 10.2.3 React Integration Pattern

```jsx
// React integration example
import React, { useState, useEffect } from "react";
import { VeridisProvider, useVeridis } from "@veridis/react";

// Veridis provider component
function App() {
  return (
    <VeridisProvider
      network="mainnet"
      nodeUrl="https://starknet-mainnet.infura.io/v3/YOUR_API_KEY"
    >
      <VeridisExampleComponent />
    </VeridisProvider>
  );
}

// Component using Veridis
function VeridisExampleComponent() {
  const veridis = useVeridis();
  const [credentials, setCredentials] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Load credentials on mount
  useEffect(() => {
    async function loadCredentials() {
      try {
        setLoading(true);

        // Connect wallet
        await veridis.wallet.connect();

        // Load credentials
        const creds = await veridis.credentials.list();
        setCredentials(creds);
        setError(null);
      } catch (err) {
        console.error("Failed to load credentials:", err);
        setError(err.message || "Failed to load credentials");
      } finally {
        setLoading(false);
      }
    }

    loadCredentials();
  }, [veridis]);

  // Generate proof for a credential
  async function handleGenerateProof(credentialId) {
    try {
      setLoading(true);

      // Generate proof
      const proof = await veridis.proofs.generate({
        credentialId,
        circuit: "KYC_BASIC_VERIFICATION",
      });

      console.log("Generated proof:", proof);

      // Verify proof on-chain
      const result = await veridis.proofs.verifyOnChain(proof);

      if (result.isValid) {
        alert("Proof verified successfully!");
      } else {
        alert("Proof verification failed.");
      }
    } catch (err) {
      console.error("Proof generation failed:", err);
      setError(err.message || "Proof generation failed");
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return <div>Loading...</div>;
  }

  if (error) {
    return <div>Error: {error}</div>;
  }

  return (
    <div>
      <h2>Your Credentials</h2>
      {credentials.length === 0 ? (
        <p>
          No credentials found. Complete verification to obtain credentials.
        </p>
      ) : (
        <ul>
          {credentials.map((credential) => (
            <li key={credential.id}>
              {getAttestationTypeName(credential.attestationType)} from{" "}
              {credential.attester}
              <button onClick={() => handleGenerateProof(credential.id)}>
                Generate Proof
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

// Helper to get attestation type name
function getAttestationTypeName(type) {
  const types = {
    1: "KYC Basic",
    2: "KYC Enhanced",
    3: "Uniqueness",
    4: "Country Verification",
    5: "Age Verification",
    // Add other types as needed
  };

  return types[type] || `Type ${type}`;
}
```

### 10.3 Performance Benchmarks

Benchmark results for key SDK operations:

| Operation                 | Environment | Average Time | Notes                  |
| ------------------------- | ----------- | ------------ | ---------------------- |
| Client Initialization     | Browser     | 120ms        | Cold start             |
| Client Initialization     | Node.js     | 80ms         | Cold start             |
| Credential Storage        | Browser     | 15ms         | Local storage          |
| Credential Retrieval      | Browser     | 5ms          | Local storage          |
| Proof Generation (Local)  | Browser     | 8.5s         | KYC verification       |
| Proof Generation (Local)  | Node.js     | 4.2s         | KYC verification       |
| Proof Generation (Remote) | Browser     | 2.1s         | Network dependent      |
| Contract Read             | Browser     | 350ms        | Network dependent      |
| Contract Transaction      | Browser     | 1.5s         | Excluding confirmation |
| Wallet Connection         | Browser     | 800ms        | Depends on wallet      |

### 10.4 Additional Resources

Links to additional developer resources:

- **Documentation Website**: [https://docs.veridis.xyz](https://docs.veridis.xyz)
- **GitHub Repository**: [https://github.com/veridis-protocol/veridis-sdk](https://github.com/veridis-protocol/veridis-sdk)
- **NPM Package**: [https://www.npmjs.com/package/@veridis/client](https://www.npmjs.com/package/@veridis/client)
- **Example Applications**: [https://github.com/veridis-protocol/examples](https://github.com/veridis-protocol/examples)
- **API Reference**: [https://docs.veridis.xyz/api-reference](https://docs.veridis.xyz/api-reference)
- **Tutorials**: [https://docs.veridis.xyz/tutorials](https://docs.veridis.xyz/tutorials)
- **Community Forum**: [https://forum.veridis.xyz](https://forum.veridis.xyz)
- **Discord Community**: [https://discord.gg/veridis](https://discord.gg/veridis)

---

## Document Metadata

**Document ID:** VERIDIS-SPEC-SDK-2025-001  
**Version:** 1.0  
**Date:** 2025-05-08  
**Authors:** Cass402 and the Veridis Engineering Team  
**Last Edit:** 2025-05-08 12:20:30 UTC by Cass402

**Classification:** Internal Technical Documentation  
**Distribution:** Veridis Engineering, External Developers, Technical Partners

**Document End**

```

This detailed Developer SDK Specifications document provides comprehensive guidance for developers integrating with the Veridis protocol. It covers the SDK architecture, components, client-side proof generation, ZK circuit integration, common integration patterns, and error handling, all while maintaining the professional and technical standard set by previous Veridis documentation.

The document is designed to serve as both a reference and implementation guide for developers building applications that leverage Veridis's identity and attestation capabilities for privacy-preserving verification.
```
