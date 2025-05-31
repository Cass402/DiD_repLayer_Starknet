# Veridis: Incremental Testnet Alpha Roadmap

This document outlines the phased rollout of Veridis, a decentralized identity and reputation layer for StarkNet. Each Testnet Alpha version builds upon the last, culminating in a privacy-preserving, dual-tier attestation system with zero-knowledge verification capabilities.

## Core Assumptions:

- Each sprint is 2 weeks
- Backend: Cairo v2.11.4 + Rust services
- Frontend: TypeScript/React
- Target: StarkNet v0.11+ with v3 transactions

---

## Testnet Alpha v0.1: Basic Identity Registration on StarkNet

**Sprint Goal:** Establish foundational identity registration system with NFT-based identity tokens and basic metadata storage.
**Release Window:** Weeks 1-2

**Key Features Introduced/Demoed:**

- Deploy basic Identity Registry contract using OpenZeppelin components (Ownable, Upgradeable, ERC721)
- Users can register a unique identity, receiving an NFT representing their identity
- Basic metadata storage (IPFS URIs) linked to identity NFTs
- Simple event emission for identity creation and updates
- Admin functions for contract management and upgrades

**Focus Areas from Technical Documentation:**

- `smartContractArchitecture.md`: Identity Registry component architecture, OpenZeppelin integration
- `whitepaper.md`: Core identity concepts, user sovereignty principles
- Basic StarkNet contract deployment and ERC721 functionality

**Project Directory Structure (`Veridis_Alpha_v0.1/`):**

```plaintext
Veridis_Alpha_v0.1/
├── .gitignore
├── Scarb.toml # Cairo project manifest
├── LICENSE
├── package.json # Node.js/TypeScript project manifest
├── README.md # Alpha v0.1 setup and usage
├── contracts/
│   ├── core/
│   │   ├── IIdentityRegistry.cairo
│   │   └── IdentityRegistry.cairo # Core identity registration with OpenZeppelin components
│   └── interfaces/
│       └── IVeridisCore.cairo # Basic interface definitions
├── docs/
│   └── Technical/ # Contains technical documentation
├── scripts/
│   ├── build_contracts.sh # Compiles Cairo contracts using Scarb
│   ├── deploy_contracts.ts # Deploys contracts to StarkNet testnet
│   └── setup_testnet.sh # Basic testnet setup script
├── src/ # Rust backend services (minimal for now)
│   ├── services/
│   │   └── identity_service.rs # Basic identity management helpers
│   └── main.rs # Simple CLI for contract interactions
├── sdk/
│   └── typescript/
│       ├── package.json
│       ├── src/
│       │   ├── index.ts
│       │   └── identity_client.ts # Basic client for identity operations
│       └── tsconfig.json
├── tests/
│   ├── contracts/
│   │   └── identity_registry.test.ts # Cairo contract tests using Starknet Foundry
│   └── unit/
│       └── identity_service.test.rs # Rust unit tests
└── ui/ # Basic React UI
    └── identity_app/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── components/
        │   │   └── IdentityRegistration.tsx
        │   └── services/
        │       └── starknet.service.ts # StarkNet wallet integration
        └── public/
            └── index.html
```

**Key File Descriptions for Alpha v0.1:**

- `contracts/core/IdentityRegistry.cairo`: Core contract implementing identity registration using OpenZeppelin's ERC721, Ownable, and Upgradeable components
- `sdk/typescript/src/identity_client.ts`: TypeScript SDK for registering identities, updating metadata, and querying identity information
- `ui/identity_app/src/components/IdentityRegistration.tsx`: React component for wallet connection and identity registration
- `scripts/deploy_contracts.ts`: Deployment script for StarkNet testnet using Starkli or similar tools

---

## Testnet Alpha v0.2: Basic Attestation Registry

**Sprint Goal:** Implement the core attestation system allowing trusted attesters to issue signed attestations about identities.
**Release Window:** Weeks 3-4

**Key Features Introduced/Demoed (on top of v0.1):**

- Deploy Attestation Registry contract with attester management
- Attesters can issue signed attestations about specific identities
- Basic attestation data structure with schema versioning
- Attestation verification and query functionality
- Event emission for attestation lifecycle management

**Focus Areas from Technical Documentation:**

- `smartContractArchitecture.md`: Attestation Registry architecture, storage optimization
- `whitepaper.md`: Verifiable credentials concepts, trust anchoring
- Attester authorization and access control patterns

**Project Directory Structure (`Veridis_Alpha_v0.2/`):**

```plaintext
Veridis_Alpha_v0.2/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.2
├── contracts/
│   ├── core/
│   │   ├── IIdentityRegistry.cairo
│   │   ├── IdentityRegistry.cairo
│   │   ├── IAttestationRegistry.cairo
│   │   └── AttestationRegistry.cairo # New: Core attestation management
│   ├── governance/
│   │   ├── IAttesterRegistry.cairo
│   │   └── AttesterRegistry.cairo # New: Manages authorized attesters
│   └── interfaces/
│       └── IVeridisCore.cairo # Updated with attestation interfaces
├── docs/
│   └── Technical/
├── scripts/
│   ├── build_contracts.sh
│   ├── deploy_contracts.ts # Updated to deploy attestation contracts
│   └── setup_attesters.ts # New: Script to authorize initial attesters
├── src/
│   ├── services/
│   │   ├── identity_service.rs
│   │   └── attestation_service.rs # New: Attestation management logic
│   └── main.rs
├── sdk/
│   └── typescript/
│       ├── package.json
│       ├── src/
│       │   ├── index.ts
│       │   ├── identity_client.ts
│       │   └── attestation_client.ts # New: Attestation operations SDK
│       └── tsconfig.json
├── tests/
│   ├── contracts/
│   │   ├── identity_registry.test.ts
│   │   ├── attestation_registry.test.ts # New
│   │   └── attester_registry.test.ts # New
│   └── unit/
│       ├── identity_service.test.rs
│       └── attestation_service.test.rs # New
└── ui/
    └── identity_app/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── components/
        │   │   ├── IdentityRegistration.tsx
        │   │   ├── AttestationIssuance.tsx # New: For attesters
        │   │   └── AttestationViewer.tsx # New: View attestations
        │   └── services/
        │       ├── starknet.service.ts
        │       └── attestation.service.ts # New
        └── public/
            └── index.html
```

**Key File Descriptions/Changes for Alpha v0.2:**

- `contracts/core/AttestationRegistry.cairo`: Contract for issuing, storing, and verifying attestations with schema support
- `contracts/governance/AttesterRegistry.cairo`: Manages authorized attesters with role-based access control
- `sdk/typescript/src/attestation_client.ts`: SDK functions for attestation issuance, verification, and querying
- `ui/identity_app/src/components/AttestationIssuance.tsx`: Interface for authorized attesters to issue attestations

---

## Testnet Alpha v0.3: Basic Zero-Knowledge Proof Verification

**Sprint Goal:** Introduce ZK proof capabilities for basic identity verification without revealing sensitive attestation data.
**Release Window:** Weeks 5-6

**Key Features Introduced/Demoed (on top of v0.2):**

- Deploy ZK Verifier contract for basic proof verification
- Simple Cairo circuits for proving attestation possession without revealing content
- Generate and verify ZK proofs that prove "I have a valid attestation of type X"
- Integration with StarkNet's native STARK proof system
- Basic nullifier system to prevent double-use of proofs

**Focus Areas from Technical Documentation:**

- `whitepaper.md`: Zero-knowledge implementation, privacy-preserving mechanisms
- `smartContractArchitecture.md`: ZK Verifier component architecture
- Cairo circuit development for identity proofs

**Project Directory Structure (`Veridis_Alpha_v0.3/`):**

```plaintext
Veridis_Alpha_v0.3/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.3
├── circuits/
│   ├── basic_attestation_proof.cairo # New: Cairo circuit for attestation proofs
│   └── nullifier_generation.cairo # New: Nullifier circuits
├── contracts/
│   ├── core/
│   │   ├── IIdentityRegistry.cairo
│   │   ├── IdentityRegistry.cairo
│   │   ├── IAttestationRegistry.cairo
│   │   ├── AttestationRegistry.cairo
│   │   ├── IZKVerifier.cairo
│   │   └── ZKVerifier.cairo # New: ZK proof verification
│   ├── governance/
│   │   ├── IAttesterRegistry.cairo
│   │   └── AttesterRegistry.cairo
│   ├── privacy/
│   │   ├── INullifierRegistry.cairo
│   │   └── NullifierRegistry.cairo # New: Prevents double-usage
│   └── interfaces/
│       └── IVeridisCore.cairo # Updated with ZK interfaces
├── docs/
│   └── Technical/
├── scripts/
│   ├── build_contracts.sh
│   ├── compile_circuits.sh # New: Compiles Cairo circuits
│   ├── deploy_contracts.ts # Updated for ZK contracts
│   └── setup_attesters.ts
├── src/
│   ├── services/
│   │   ├── identity_service.rs
│   │   ├── attestation_service.rs
│   │   └── zk_service.rs # New: ZK proof generation helpers
│   └── main.rs
├── sdk/
│   └── typescript/
│       ├── package.json
│       ├── src/
│       │   ├── index.ts
│       │   ├── identity_client.ts
│       │   ├── attestation_client.ts
│       │   └── zk_client.ts # New: ZK proof operations
│       └── tsconfig.json
├── tests/
│   ├── contracts/
│   │   ├── identity_registry.test.ts
│   │   ├── attestation_registry.test.ts
│   │   ├── attester_registry.test.ts
│   │   ├── zk_verifier.test.ts # New
│   │   └── nullifier_registry.test.ts # New
│   ├── circuits/
│   │   └── basic_attestation_proof.test.ts # New: Circuit tests
│   └── unit/
│       ├── identity_service.test.rs
│       ├── attestation_service.test.rs
│       └── zk_service.test.rs # New
└── ui/
    └── identity_app/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── components/
        │   │   ├── IdentityRegistration.tsx
        │   │   ├── AttestationIssuance.tsx
        │   │   ├── AttestationViewer.tsx
        │   │   └── ZKProofGenerator.tsx # New: Generate and submit ZK proofs
        │   └── services/
        │       ├── starknet.service.ts
        │       ├── attestation.service.ts
        │       └── zk.service.ts # New
        └── public/
            └── index.html
```

**Key File Descriptions/Changes for Alpha v0.3:**

- `circuits/basic_attestation_proof.cairo`: Cairo circuit proving possession of valid attestation without revealing details
- `contracts/core/ZKVerifier.cairo`: Contract for verifying STARK proofs generated by the circuits
- `contracts/privacy/NullifierRegistry.cairo`: Prevents double-use of the same attestation in ZK proofs
- `src/services/zk_service.rs`: Rust service for generating Cairo circuit inputs and managing proof data

---

## Testnet Alpha v0.4: Merkle Attestation Trees

**Sprint Goal:** Implement Merkle tree-based attestation storage for efficient batch operations and privacy-preserving inclusion proofs.
**Release Window:** Weeks 7-8

**Key Features Introduced/Demoed (on top of v0.3):**

- Attesters can batch attestations into Merkle trees and publish only the root on-chain
- Users can prove attestation inclusion using Merkle proofs without revealing other attestations
- Efficient storage and gas optimization for large attestation sets
- Tree update mechanisms for adding new attestations
- Integration with existing ZK proof system for Merkle inclusion verification

**Focus Areas from Technical Documentation:**

- `whitepaper.md`: Merkle attestations, privacy benefits of tree structures
- `smartContractArchitecture.md`: Optimized storage patterns, batch operations
- Merkle tree construction and verification in Cairo

**Project Directory Structure (`Veridis_Alpha_v0.4/`):**

```plaintext
Veridis_Alpha_v0.4/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.4
├── circuits/
│   ├── basic_attestation_proof.cairo
│   ├── nullifier_generation.cairo
│   └── merkle_inclusion_proof.cairo # New: Proves inclusion in Merkle tree
├── contracts/
│   ├── core/
│   │   ├── IIdentityRegistry.cairo
│   │   ├── IdentityRegistry.cairo
│   │   ├── IAttestationRegistry.cairo
│   │   ├── AttestationRegistry.cairo # Updated: Merkle root storage
│   │   ├── IZKVerifier.cairo
│   │   └── ZKVerifier.cairo # Updated: Merkle proof verification
│   ├── governance/
│   │   ├── IAttesterRegistry.cairo
│   │   └── AttesterRegistry.cairo
│   ├── privacy/
│   │   ├── INullifierRegistry.cairo
│   │   └── NullifierRegistry.cairo
│   ├── trees/
│   │   ├── IMerkleAttestationTree.cairo
│   │   └── MerkleAttestationTree.cairo # New: Merkle tree management
│   └── interfaces/
│       └── IVeridisCore.cairo # Updated with Merkle interfaces
├── docs/
│   └── Technical/
├── scripts/
│   ├── build_contracts.sh
│   ├── compile_circuits.sh # Updated for new circuits
│   ├── deploy_contracts.ts # Updated for Merkle contracts
│   ├── setup_attesters.ts
│   └── generate_merkle_tree.ts # New: Helper for Merkle tree generation
├── src/
│   ├── services/
│   │   ├── identity_service.rs
│   │   ├── attestation_service.rs
│   │   ├── zk_service.rs
│   │   └── merkle_service.rs # New: Merkle tree operations
│   └── main.rs
├── sdk/
│   └── typescript/
│       ├── package.json
│       ├── src/
│       │   ├── index.ts
│       │   ├── identity_client.ts
│       │   ├── attestation_client.ts
│       │   ├── zk_client.ts
│       │   └── merkle_client.ts # New: Merkle tree operations
│       └── tsconfig.json
├── tests/
│   ├── contracts/
│   │   ├── identity_registry.test.ts
│   │   ├── attestation_registry.test.ts
│   │   ├── attester_registry.test.ts
│   │   ├── zk_verifier.test.ts
│   │   ├── nullifier_registry.test.ts
│   │   └── merkle_attestation_tree.test.ts # New
│   ├── circuits/
│   │   ├── basic_attestation_proof.test.ts
│   │   └── merkle_inclusion_proof.test.ts # New
│   └── unit/
│       ├── identity_service.test.rs
│       ├── attestation_service.test.rs
│       ├── zk_service.test.rs
│       └── merkle_service.test.rs # New
└── ui/
    └── identity_app/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── components/
        │   │   ├── IdentityRegistration.tsx
        │   │   ├── AttestationIssuance.tsx # Updated: Batch issuance
        │   │   ├── AttestationViewer.tsx
        │   │   ├── ZKProofGenerator.tsx
        │   │   └── MerkleTreeViewer.tsx # New: View Merkle tree status
        │   └── services/
        │       ├── starknet.service.ts
        │       ├── attestation.service.ts
        │       ├── zk.service.ts
        │       └── merkle.service.ts # New
        └── public/
            └── index.html
```

**Key File Descriptions/Changes for Alpha v0.4:**

- `circuits/merkle_inclusion_proof.cairo`: Cairo circuit for proving inclusion in a Merkle tree
- `contracts/trees/MerkleAttestationTree.cairo`: Contract managing Merkle tree roots and verification
- `src/services/merkle_service.rs`: Rust service for Merkle tree construction, proof generation, and verification
- `scripts/generate_merkle_tree.ts`: Helper script for attesters to batch attestations into Merkle trees

---

## Testnet Alpha v0.5: Dual-Tier Attestation Model

**Sprint Goal:** Implement the core dual-tier system separating high-trust (Tier 1) and community-driven (Tier 2) attestations.
**Release Window:** Weeks 9-10

**Key Features Introduced/Demoed (on top of v0.4):**

- Clear separation between Tier 1 (regulated, high-trust) and Tier 2 (community, experimental) attestations
- Different verification requirements and trust assumptions for each tier
- Tier 1 attestations require governance approval for attesters
- Tier 2 attestations allow permissionless community participation
- Updated ZK circuits to specify tier in proofs
- Governance mechanisms for tier management

**Focus Areas from Technical Documentation:**

- `whitepaper.md`: Dual-tier attestation model, trust separation
- `smartContractArchitecture.md`: Component-based governance, access control
- Governance integration with OpenZeppelin components

**Project Directory Structure (`Veridis_Alpha_v0.5/`):**

```plaintext
Veridis_Alpha_v0.5/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.5
├── circuits/
│   ├── basic_attestation_proof.cairo
│   ├── nullifier_generation.cairo
│   ├── merkle_inclusion_proof.cairo
│   └── tier_specific_proof.cairo # New: Tier-aware ZK proofs
├── contracts/
│   ├── core/
│   │   ├── IIdentityRegistry.cairo
│   │   ├── IdentityRegistry.cairo
│   │   ├── IAttestationRegistry.cairo
│   │   ├── AttestationRegistry.cairo # Updated: Tier-aware storage
│   │   ├── IZKVerifier.cairo
│   │   └── ZKVerifier.cairo # Updated: Tier verification
│   ├── governance/
│   │   ├── IAttesterRegistry.cairo
│   │   ├── AttesterRegistry.cairo # Updated: Tier-based permissions
│   │   ├── ITierGovernance.cairo
│   │   └── TierGovernance.cairo # New: Governance for tier management
│   ├── privacy/
│   │   ├── INullifierRegistry.cairo
│   │   └── NullifierRegistry.cairo # Updated: Tier-specific nullifiers
│   ├── trees/
│   │   ├── IMerkleAttestationTree.cairo
│   │   └── MerkleAttestationTree.cairo # Updated: Tier separation
│   ├── tiers/
│   │   ├── ITier1Registry.cairo
│   │   ├── Tier1Registry.cairo # New: High-trust attestations
│   │   ├── ITier2Registry.cairo
│   │   └── Tier2Registry.cairo # New: Community attestations
│   └── interfaces/
│       └── IVeridisCore.cairo # Updated with tier interfaces
├── docs/
│   └── Technical/
├── scripts/
│   ├── build_contracts.sh
│   ├── compile_circuits.sh # Updated for tier circuits
│   ├── deploy_contracts.ts # Updated for tier contracts
│   ├── setup_attesters.ts # Updated: Tier-based setup
│   ├── generate_merkle_tree.ts
│   └── setup_governance.ts # New: Initialize governance
├── src/
│   ├── services/
│   │   ├── identity_service.rs
│   │   ├── attestation_service.rs # Updated: Tier-aware operations
│   │   ├── zk_service.rs # Updated: Tier-specific proofs
│   │   ├── merkle_service.rs
│   │   └── governance_service.rs # New: Governance operations
│   └── main.rs
├── sdk/
│   └── typescript/
│       ├── package.json
│       ├── src/
│       │   ├── index.ts
│       │   ├── identity_client.ts
│       │   ├── attestation_client.ts # Updated: Tier operations
│       │   ├── zk_client.ts # Updated: Tier-specific proofs
│       │   ├── merkle_client.ts
│       │   └── governance_client.ts # New: Governance interactions
│       └── tsconfig.json
├── tests/
│   ├── contracts/
│   │   ├── identity_registry.test.ts
│   │   ├── attestation_registry.test.ts
│   │   ├── attester_registry.test.ts
│   │   ├── zk_verifier.test.ts
│   │   ├── nullifier_registry.test.ts
│   │   ├── merkle_attestation_tree.test.ts
│   │   ├── tier1_registry.test.ts # New
│   │   ├── tier2_registry.test.ts # New
│   │   └── tier_governance.test.ts # New
│   ├── circuits/
│   │   ├── basic_attestation_proof.test.ts
│   │   ├── merkle_inclusion_proof.test.ts
│   │   └── tier_specific_proof.test.ts # New
│   └── unit/
│       ├── identity_service.test.rs
│       ├── attestation_service.test.rs
│       ├── zk_service.test.rs
│       ├── merkle_service.test.rs
│       └── governance_service.test.rs # New
└── ui/
    └── identity_app/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── components/
        │   │   ├── IdentityRegistration.tsx
        │   │   ├── AttestationIssuance.tsx # Updated: Tier selection
        │   │   ├── AttestationViewer.tsx # Updated: Tier filtering
        │   │   ├── ZKProofGenerator.tsx # Updated: Tier-specific proofs
        │   │   ├── MerkleTreeViewer.tsx
        │   │   └── GovernanceDashboard.tsx # New: Governance interface
        │   └── services/
        │       ├── starknet.service.ts
        │       ├── attestation.service.ts
        │       ├── zk.service.ts
        │       ├── merkle.service.ts
        │       └── governance.service.ts # New
        └── public/
            └── index.html
```

**Key File Descriptions/Changes for Alpha v0.5:**

- `contracts/tiers/Tier1Registry.cairo` \& `Tier2Registry.cairo`: Separate contracts for managing high-trust vs community attestations
- `contracts/governance/TierGovernance.cairo`: Governance system for managing tier permissions and upgrades
- `circuits/tier_specific_proof.cairo`: ZK circuits that include tier information in proofs
- `ui/identity_app/src/components/GovernanceDashboard.tsx`: Interface for governance participation and tier management

---

## Testnet Alpha v0.6: Advanced Privacy Features (Selective Disclosure)

**Sprint Goal:** Implement selective disclosure mechanisms allowing users to reveal only specific attributes of their attestations.
**Release Window:** Weeks 11-12

**Key Features Introduced/Demoed (on top of v0.5):**

- ZK circuits for proving specific attributes without revealing full attestation content
- Schema-based attestations with granular disclosure controls
- Commitment schemes for individual attestation attributes
- Proof generation for statements like "age > 18" without revealing exact age
- Integration with existing tier system for attribute-specific policies

**Focus Areas from Technical Documentation:**

- `whitepaper.md`: Selective disclosure principles, privacy-preserving compliance
- Advanced ZK circuit design for attribute proofs
- Schema management and validation

**Project Directory Structure (`Veridis_Alpha_v0.6/`):**

```plaintext
Veridis_Alpha_v0.6/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.6
├── circuits/
│   ├── basic_attestation_proof.cairo
│   ├── nullifier_generation.cairo
│   ├── merkle_inclusion_proof.cairo
│   ├── tier_specific_proof.cairo
│   ├── selective_disclosure.cairo # New: Attribute-specific proofs
│   └── range_proof.cairo # New: Prove attribute ranges
├── contracts/
│   ├── core/
│   │   ├── IIdentityRegistry.cairo
│   │   ├── IdentityRegistry.cairo
│   │   ├── IAttestationRegistry.cairo
│   │   ├── AttestationRegistry.cairo # Updated: Schema support
│   │   ├── IZKVerifier.cairo
│   │   └── ZKVerifier.cairo # Updated: Selective disclosure verification
│   ├── governance/
│   │   ├── IAttesterRegistry.cairo
│   │   ├── AttesterRegistry.cairo
│   │   ├── ITierGovernance.cairo
│   │   └── TierGovernance.cairo
│   ├── privacy/
│   │   ├── INullifierRegistry.cairo
│   │   ├── NullifierRegistry.cairo
│   │   ├── ISchemaRegistry.cairo
│   │   └── SchemaRegistry.cairo # New: Manages attestation schemas
│   ├── trees/
│   │   ├── IMerkleAttestationTree.cairo
│   │   └── MerkleAttestationTree.cairo
│   ├── tiers/
│   │   ├── ITier1Registry.cairo
│   │   ├── Tier1Registry.cairo
│   │   ├── ITier2Registry.cairo
│   │   └── Tier2Registry.cairo
│   ├── disclosure/
│   │   ├── ISelectiveDisclosure.cairo
│   │   └── SelectiveDisclosure.cairo # New: Handles selective disclosure
│   └── interfaces/
│       └── IVeridisCore.cairo # Updated with disclosure interfaces
├── docs/
│   └── Technical/
├── scripts/
│   ├── build_contracts.sh
│   ├── compile_circuits.sh # Updated for disclosure circuits
│   ├── deploy_contracts.ts # Updated for disclosure contracts
│   ├── setup_attesters.ts
│   ├── generate_merkle_tree.ts
│   ├── setup_governance.ts
│   └── create_schemas.ts # New: Create attestation schemas
├── src/
│   ├── services/
│   │   ├── identity_service.rs
│   │   ├── attestation_service.rs
│   │   ├── zk_service.rs # Updated: Selective disclosure proofs
│   │   ├── merkle_service.rs
│   │   ├── governance_service.rs
│   │   └── schema_service.rs # New: Schema management
│   └── main.rs
├── sdk/
│   └── typescript/
│       ├── package.json
│       ├── src/
│       │   ├── index.ts
│       │   ├── identity_client.ts
│       │   ├── attestation_client.ts
│       │   ├── zk_client.ts # Updated: Selective disclosure
│       │   ├── merkle_client.ts
│       │   ├── governance_client.ts
│       │   └── schema_client.ts # New: Schema operations
│       └── tsconfig.json
├── tests/
│   ├── contracts/
│   │   ├── identity_registry.test.ts
│   │   ├── attestation_registry.test.ts
│   │   ├── attester_registry.test.ts
│   │   ├── zk_verifier.test.ts
│   │   ├── nullifier_registry.test.ts
│   │   ├── merkle_attestation_tree.test.ts
│   │   ├── tier1_registry.test.ts
│   │   ├── tier2_registry.test.ts
│   │   ├── tier_governance.test.ts
│   │   ├── schema_registry.test.ts # New
│   │   └── selective_disclosure.test.ts # New
│   ├── circuits/
│   │   ├── basic_attestation_proof.test.ts
│   │   ├── merkle_inclusion_proof.test.ts
│   │   ├── tier_specific_proof.test.ts
│   │   ├── selective_disclosure.test.ts # New
│   │   └── range_proof.test.ts # New
│   └── unit/
│       ├── identity_service.test.rs
│       ├── attestation_service.test.rs
│       ├── zk_service.test.rs
│       ├── merkle_service.test.rs
│       ├── governance_service.test.rs
│       └── schema_service.test.rs # New
└── ui/
    └── identity_app/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── components/
        │   │   ├── IdentityRegistration.tsx
        │   │   ├── AttestationIssuance.tsx # Updated: Schema-based
        │   │   ├── AttestationViewer.tsx
        │   │   ├── ZKProofGenerator.tsx # Updated: Selective disclosure
        │   │   ├── MerkleTreeViewer.tsx
        │   │   ├── GovernanceDashboard.tsx
        │   │   ├── SchemaCreator.tsx # New: Create attestation schemas
        │   │   └── DisclosureControl.tsx # New: Control what to disclose
        │   └── services/
        │       ├── starknet.service.ts
        │       ├── attestation.service.ts
        │       ├── zk.service.ts
        │       ├── merkle.service.ts
        │       ├── governance.service.ts
        │       └── schema.service.ts # New
        └── public/
            └── index.html
```

**Key File Descriptions/Changes for Alpha v0.6:**

- `circuits/selective_disclosure.cairo`: ZK circuits for proving specific attributes without revealing others
- `contracts/privacy/SchemaRegistry.cairo`: Manages standardized attestation schemas and validation rules
- `contracts/disclosure/SelectiveDisclosure.cairo`: Handles selective disclosure requests and verification
- `src/services/schema_service.rs`: Rust service for schema creation, validation, and management

---

## Testnet Alpha v0.7: Cross-Chain Identity Bridges (Ethereum L1 Integration)

**Sprint Goal:** Enable cross-chain identity verification between StarkNet and Ethereum L1 using message passing and proof verification.
**Release Window:** Weeks 13-14

**Key Features Introduced/Demoed (on top of v0.6):**

- Deploy L1 verification contracts on Ethereum for StarkNet identity proofs
- Cross-chain message passing for identity attestation anchoring
- L1 smart contracts that can verify StarkNet STARK proofs of identity
- Bridge contracts for syncing identity state between L1 and L2
- Demonstration of L1 dApp using StarkNet identity without migration

**Focus Areas from Technical Documentation:**

- `whitepaper.md`: L1-L2 interoperability concepts
- StarkNet-Ethereum messaging and proof verification
- Cross-chain state synchronization patterns

**Project Directory Structure (`Veridis_Alpha_v0.7/`):**

```plaintext
Veridis_Alpha_v0.7/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.7
├── circuits/
│   ├── basic_attestation_proof.cairo
│   ├── nullifier_generation.cairo
│   ├── merkle_inclusion_proof.cairo
│   ├── tier_specific_proof.cairo
│   ├── selective_disclosure.cairo
│   ├── range_proof.cairo
│   └── cross_chain_identity_proof.cairo # New: L1-compatible proofs
├── contracts/
│   ├── starknet/ # Existing StarkNet contracts
│   │   ├── core/
│   │   ├── governance/
│   │   ├── privacy/
│   │   ├── trees/
│   │   ├── tiers/
│   │   ├── disclosure/
│   │   └── interfaces/
│   ├── ethereum/ # New: Ethereum L1 contracts
│   │   ├── core/
│   │   │   ├── IVeridisL1Gateway.sol
│   │   │   └── VeridisL1Gateway.sol # L1 gateway contract
│   │   ├── verification/
│   │   │   ├── IStarkProofVerifier.sol
│   │   │   └── StarkProofVerifier.sol # Verifies StarkNet proofs on L1
│   │   └── bridges/
│   │       ├── IIdentityBridge.sol
│   │       └── IdentityBridge.sol # Cross-chain state sync
│   └── interfaces/
│       └── ICrossChainCore.sol # Cross-chain interfaces
├── docs/
│   └── Technical/
├── scripts/
│   ├── starknet/
│   │   ├── build_contracts.sh
│   │   ├── compile_circuits.sh
│   │   ├── deploy_contracts.ts
│   │   └── setup_cross_chain.ts # New: Configure cross-chain
│   ├── ethereum/
│   │   ├── deploy_l1_contracts.ts # New: Deploy L1 contracts
│   │   └── verify_integration.ts # New: Test L1-L2 integration
│   └── setup_bridge.ts # New: Initialize bridge
├── src/
│   ├── services/
│   │   ├── identity_service.rs
│   │   ├── attestation_service.rs
│   │   ├── zk_service.rs
│   │   ├── merkle_service.rs
│   │   ├── governance_service.rs
│   │   ├── schema_service.rs
│   │   └── bridge_service.rs # New: Cross-chain operations
│   ├── relayer/
│   │   └── main.rs # New: Message relayer service
│   └── main.rs
├── sdk/
│   └── typescript/
│       ├── package.json
│       ├── src/
│       │   ├── index.ts
│       │   ├── identity_client.ts
│       │   ├── attestation_client.ts
│       │   ├── zk_client.ts
│       │   ├── merkle_client.ts
│       │   ├── governance_client.ts
│       │   ├── schema_client.ts
│       │   └── bridge_client.ts # New: Cross-chain operations
│       └── tsconfig.json
├── tests/
│   ├── starknet/
│   │   # All existing StarkNet tests
│   ├── ethereum/
│   │   ├── VeridisL1Gateway.test.ts # New
│   │   ├── StarkProofVerifier.test.ts # New
│   │   └── IdentityBridge.test.ts # New
│   ├── integration/
│   │   └── cross_chain.test.ts # New: End-to-end L1-L2 tests
│   └── unit/
│       ├── bridge_service.test.rs # New
│       └── # Existing unit tests
└── ui/
    └── identity_app/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── components/
        │   │   ├── # Existing components
        │   │   ├── CrossChainVerifier.tsx # New: L1 verification interface
        │   │   └── BridgeMonitor.tsx # New: Monitor bridge status
        │   └── services/
        │       ├── # Existing services
        │       └── bridge.service.ts # New
        └── public/
            └── index.html
```

**Key File Descriptions/Changes for Alpha v0.7:**

- `contracts/ethereum/core/VeridisL1Gateway.sol`: Ethereum contract that accepts and verifies StarkNet identity proofs
- `contracts/ethereum/verification/StarkProofVerifier.sol`: L1 contract for verifying STARK proofs from StarkNet
- `src/relayer/main.rs`: Service that relays messages and proofs between L1 and L2
- `circuits/cross_chain_identity_proof.cairo`: Cairo circuits optimized for L1 verification

---

## Testnet Alpha v0.8: Reputation Scoring and Analytics

**Sprint Goal:** Implement on-chain reputation calculation based on attestation history and community interactions.
**Release Window:** Weeks 15-16

**Key Features Introduced/Demoed (on top of v0.7):**

- Reputation scoring algorithm based on attestation types, attesters, and historical behavior
- On-chain reputation state with privacy-preserving computation
- Analytics dashboard for reputation metrics and trends
- ZK proofs for reputation thresholds without revealing exact scores
- Integration with existing dual-tier system for reputation-based access

**Focus Areas from Technical Documentation:**

- `whitepaper.md`: Reputation layer concepts, community-driven trust
- On-chain analytics and scoring mechanisms
- Privacy-preserving reputation computation

**Project Directory Structure (`Veridis_Alpha_v0.8/`):**

```plaintext
Veridis_Alpha_v0.8/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.8
├── circuits/
│   ├── # Existing circuits
│   ├── reputation_threshold_proof.cairo # New: Prove reputation > threshold
│   └── reputation_calculation.cairo # New: Privacy-preserving scoring
├── contracts/
│   ├── starknet/
│   │   ├── # Existing StarkNet contracts
│   │   ├── reputation/
│   │   │   ├── IReputationRegistry.cairo
│   │   │   ├── ReputationRegistry.cairo # New: Reputation state management
│   │   │   ├── IReputationCalculator.cairo
│   │   │   └── ReputationCalculator.cairo # New: Scoring algorithm
│   │   └── analytics/
│   │       ├── IAnalyticsEngine.cairo
│   │       └── AnalyticsEngine.cairo # New: On-chain analytics
│   ├── ethereum/
│   │   # Existing Ethereum contracts
│   └── interfaces/
│       └── IReputationCore.cairo # New: Reputation interfaces
├── docs/
│   └── Technical/
├── scripts/
│   ├── starknet/
│   │   ├── # Existing scripts
│   │   ├── deploy_reputation.ts # New: Deploy reputation contracts
│   │   └── calculate_initial_scores.ts # New: Bootstrap reputation
│   ├── ethereum/
│   │   # Existing scripts
│   └── analytics/
│       └── generate_reports.ts # New: Analytics reporting
├── src/
│   ├── services/
│   │   ├── # Existing services
│   │   ├── reputation_service.rs # New: Reputation calculation
│   │   └── analytics_service.rs # New: Analytics and reporting
│   ├── relayer/
│   │   └── main.rs
│   └── main.rs
├── sdk/
│   └── typescript/
│       ├── package.json
│       ├── src/
│       │   ├── # Existing clients
│       │   ├── reputation_client.ts # New: Reputation operations
│       │   └── analytics_client.ts # New: Analytics queries
│       └── tsconfig.json
├── tests/
│   ├── starknet/
│   │   ├── # Existing tests
│   │   ├── reputation_registry.test.ts # New
│   │   ├── reputation_calculator.test.ts # New
│   │   └── analytics_engine.test.ts # New
│   ├── ethereum/
│   │   # Existing tests
│   ├── integration/
│   │   ├── cross_chain.test.ts
│   │   └── reputation_flow.test.ts # New: End-to-end reputation tests
│   └── unit/
│       ├── # Existing tests
│       ├── reputation_service.test.rs # New
│       └── analytics_service.test.rs # New
└── ui/
    └── identity_app/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── components/
        │   │   ├── # Existing components
        │   │   ├── ReputationDashboard.tsx # New: User reputation view
        │   │   ├── AnalyticsDashboard.tsx # New: System analytics
        │   │   └── ReputationProof.tsx # New: Generate reputation proofs
        │   └── services/
        │       ├── # Existing services
        │       ├── reputation.service.ts # New
        │       └── analytics.service.ts # New
        └── public/
            └── index.html
```

**Key File Descriptions/Changes for Alpha v0.8:**

- `contracts/starknet/reputation/ReputationRegistry.cairo`: Manages user reputation scores with privacy protections
- `contracts/starknet/reputation/ReputationCalculator.cairo`: Implements reputation scoring algorithm based on attestations
- `circuits/reputation_threshold_proof.cairo`: ZK proof for reputation level without revealing exact score
- `src/services/reputation_service.rs`: Rust service for reputation calculation and management

---

## Testnet Alpha v0.9: Governance and DAO Integration

**Sprint Goal:** Implement comprehensive governance mechanisms and demonstrate integration with external DAOs using Veridis identity.
**Release Window:** Weeks 17-18

**Key Features Introduced/Demoed (on top of v0.8):**

- On-chain governance for protocol parameters and tier management
- Integration with popular DAO frameworks (e.g., Compound Governor, Snapshot)
- Identity-based voting with Sybil resistance
- Delegation mechanisms for governance participation
- Proposal system for protocol upgrades and parameter changes

**Focus Areas from Technical Documentation:**

- `smartContractArchitecture.md`: Governance component architecture
- DAO integration patterns and standards compliance
- Democratic participation with identity verification

**Project Directory Structure (`Veridis_Alpha_v0.9/`):**

```plaintext
Veridis_Alpha_v0.9/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.9
├── circuits/
│   ├── # Existing circuits
│   ├── governance_eligibility_proof.cairo # New: Prove voting eligibility
│   └── delegation_proof.cairo # New: Prove delegation authority
├── contracts/
│   ├── starknet/
│   │   ├── # Existing StarkNet contracts
│   │   ├── governance/
│   │   │   ├── # Existing governance contracts (updated)
│   │   │   ├── IVeridisGovernor.cairo
│   │   │   ├── VeridisGovernor.cairo # New: Main governance contract
│   │   │   ├── IProposalRegistry.cairo
│   │   │   ├── ProposalRegistry.cairo # New: Proposal management
│   │   │   ├── IDelegationRegistry.cairo
│   │   │   └── DelegationRegistry.cairo # New: Voting delegation
│   │   └── integrations/
│   │       ├── IDAOAdapter.cairo
│   │       └── DAOAdapter.cairo # New: External DAO integration
│   ├── ethereum/
│   │   ├── # Existing Ethereum contracts
│   │   └── governance/
│   │       ├── IVeridisGovernorL1.sol
│   │       └── VeridisGovernorL1.sol # New: L1 governance mirror
│   └── interfaces/
│       └── IGovernanceCore.cairo # New: Governance interfaces
├── docs/
│   └── Technical/
├── scripts/
│   ├── starknet/
│   │   ├── # Existing scripts
│   │   ├── deploy_governance.ts # New: Deploy governance contracts
│   │   ├── create_proposal.ts # New: Create governance proposals
│   │   └── setup_dao_integration.ts # New: Configure DAO adapters
│   ├── ethereum/
│   │   ├── # Existing scripts
│   │   └── deploy_l1_governance.ts # New: Deploy L1 governance
│   └── governance/
│       └── bootstrap_governance.ts # New: Initialize governance
├── src/
│   ├── services/
│   │   ├── # Existing services
│   │   ├── governance_service.rs # New: Governance operations
│   │   └── dao_service.rs # New: DAO integration logic
│   ├── relayer/
│   │   └── main.rs # Updated: Governance message relaying
│   └── main.rs
├── sdk/
│   └── typescript/
│       ├── package.json
│       ├── src/
│       │   ├── # Existing clients
│       │   ├── governance_client.ts # Updated: Full governance ops
│       │   └── dao_client.ts # New: DAO integration
│       └── tsconfig.json
├── tests/
│   ├── starknet/
│   │   ├── # Existing tests
│   │   ├── veridis_governor.test.ts # New
│   │   ├── proposal_registry.test.ts # New
│   │   ├── delegation_registry.test.ts # New
│   │   └── dao_adapter.test.ts # New
│   ├── ethereum/
│   │   ├── # Existing tests
│   │   └── VeridisGovernorL1.test.ts # New
│   ├── integration/
│   │   ├── cross_chain.test.ts
│   │   ├── reputation_flow.test.ts
│   │   └── governance_flow.test.ts # New: End-to-end governance tests
│   └── unit/
│       ├── # Existing tests
│       ├── governance_service.test.rs # New
│       └── dao_service.test.rs # New
└── ui/
    └── identity_app/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── components/
        │   │   ├── # Existing components
        │   │   ├── GovernanceDashboard.tsx # Updated: Full governance UI
        │   │   ├── ProposalCreator.tsx # New: Create proposals
        │   │   ├── VotingInterface.tsx # New: Vote on proposals
        │   │   ├── DelegationManager.tsx # New: Manage delegations
        │   │   └── DAOIntegration.tsx # New: External DAO connections
        │   └── services/
        │       ├── # Existing services
        │       ├── governance.service.ts # Updated: Full governance
        │       └── dao.service.ts # New
        └── public/
            └── index.html
```

**Key File Descriptions/Changes for Alpha v0.9:**

- `contracts/starknet/governance/VeridisGovernor.cairo`: Main governance contract with proposal creation, voting, and execution
- `contracts/starknet/governance/DelegationRegistry.cairo`: Allows users to delegate voting power while maintaining privacy
- `contracts/starknet/integrations/DAOAdapter.cairo`: Adapter for integrating with external DAO frameworks
- `src/services/governance_service.rs`: Rust service for governance operations and proposal management

---

## Testnet Alpha v0.10: Enterprise KYC Integration

**Sprint Goal:** Implement enterprise-grade KYC integration with privacy-preserving compliance features for institutional adoption.
**Release Window:** Weeks 19-20

**Key Features Introduced/Demoed (on top of v0.9):**

- Integration with enterprise KYC providers (e.g., Chainalysis, Jumio)
- Privacy-preserving compliance verification without storing PII on-chain
- Institutional attester onboarding with enhanced due diligence
- Compliance dashboard for regulatory reporting
- AML screening integration with zero-knowledge proofs

**Focus Areas from Technical Documentation:**

- `whitepaper.md`: Privacy-preserving compliance, regulatory considerations
- Enterprise integration patterns and data privacy requirements
- Institutional-grade security and auditability

**Project Directory Structure (`Veridis_Alpha_v0.10/`):**

```plaintext
Veridis_Alpha_v0.10/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.10
├── circuits/
│   ├── # Existing circuits
│   ├── kyc_verification_proof.cairo # New: Prove KYC without revealing data
│   ├── aml_screening_proof.cairo # New: AML compliance proofs
│   └── institutional_attestation.cairo # New: Enterprise attestation circuits
├── contracts/
│   ├── starknet/
│   │   ├── # Existing StarkNet contracts
│   │   ├── compliance/
│   │   │   ├── IKYCRegistry.cairo
│   │   │   ├── KYCRegistry.cairo # New: KYC verification registry
│   │   │   ├── IAMLScreening.cairo
│   │   │   ├── AMLScreening.cairo # New: AML compliance checks
│   │   │   ├── IInstitutionalRegistry.cairo
│   │   │   └── InstitutionalRegistry.cairo # New: Enterprise attesters
│   │   └── reporting/
│   │       ├── IComplianceReporting.cairo
│   │       └── ComplianceReporting.cairo # New: Regulatory reporting
│   ├── ethereum/
│   │   ├── # Existing Ethereum contracts
│   │   └── compliance/
│   │       ├── IKYCVerifierL1.sol
│   │       └── KYCVerifierL1.sol # New: L1 KYC verification
│   └── interfaces/
│       └── IComplianceCore.cairo # New: Compliance interfaces
├── docs/
│   └── Technical/
├── scripts/
│   ├── starknet/
│   │   ├── # Existing scripts
│   │   ├── deploy_compliance.ts # New: Deploy compliance contracts
│   │   └── setup_kyc_providers.ts # New: Configure KYC integrations
│   ├── ethereum/
│   │   ├── # Existing scripts
│   │   └── deploy_l1_compliance.ts # New: Deploy L1 compliance
│   └── compliance/
│       └── bootstrap_enterprise.ts # New: Enterprise onboarding
├── src/
│   ├── services/
│   │   ├── # Existing services
│   │   ├── kyc_service.rs # New: KYC provider integration
│   │   ├── aml_service.rs # New: AML screening service
│   │   └── compliance_service.rs # New: Compliance management
│   ├── integrations/
│   │   ├── chainalysis.rs # New: Chainalysis integration
│   │   ├── jumio.rs # New: Jumio KYC integration
│   │   └── sumsub.rs # New: Sum&Sub integration
│   ├── relayer/
│   │   └── main.rs
│   └── main.rs
├── sdk/
│   └── typescript/
│       ├── package.json
│       ├── src/
│       │   ├── # Existing clients
│       │   ├── kyc_client.ts # New: KYC operations
│       │   ├── compliance_client.ts # New: Compliance operations
│       │   └── institutional_client.ts # New: Enterprise features
│       └── tsconfig.json
├── tests/
│   ├── starknet/
│   │   ├── # Existing tests
│   │   ├── kyc_registry.test.ts # New
│   │   ├── aml_screening.test.ts # New
│   │   ├── institutional_registry.test.ts # New
│   │   └── compliance_reporting.test.ts # New
│   ├── ethereum/
│   │   ├── # Existing tests
│   │   └── KYCVerifierL1.test.ts # New
│   ├── integration/
│   │   ├── # Existing integration tests
│   │   └── kyc_flow.test.ts # New: End-to-end KYC tests
│   └── unit/
│       ├── # Existing tests
│       ├── kyc_service.test.rs # New
│       ├── aml_service.test.rs # New
│       └── compliance_service.test.rs # New
└── ui/
    └── identity_app/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── components/
        │   │   ├── # Existing components
        │   │   ├── KYCOnboarding.tsx # New: KYC flow for users
        │   │   ├── ComplianceDashboard.tsx # New: Enterprise compliance view
        │   │   ├── InstitutionalPanel.tsx # New: Enterprise attester tools
        │   │   └── AMLScreening.tsx # New: AML verification interface
        │   └── services/
        │       ├── # Existing services
        │       ├── kyc.service.ts # New
        │       └── compliance.service.ts # New
        └── public/
            └── index.html
```

**Key File Descriptions/Changes for Alpha v0.10:**

- `contracts/starknet/compliance/KYCRegistry.cairo`: Manages KYC verification status with privacy preservation
- `contracts/starknet/compliance/AMLScreening.cairo`: AML compliance checking with zero-knowledge proofs
- `src/integrations/chainalysis.rs`: Integration with Chainalysis for AML screening
- `circuits/kyc_verification_proof.cairo`: ZK circuits for proving KYC compliance without revealing personal data

---

## Testnet Alpha v0.11: Mobile SDK and Wallet Integration

**Sprint Goal:** Develop mobile SDK and integrate with popular StarkNet wallets for seamless user experience.
**Release Window:** Weeks 21-22

**Key Features Introduced/Demoed (on top of v0.10):**

- React Native SDK for mobile app integration
- Wallet integrations (Argent, Braavos, StarkNet.js)
- Mobile-optimized ZK proof generation
- Biometric authentication for identity access
- QR code-based attestation sharing and verification

**Focus Areas from Technical Documentation:**

- Mobile user experience optimization
- Wallet integration patterns and standards
- Performance optimization for mobile devices

**Project Directory Structure (`Veridis_Alpha_v0.11/`):**

```plaintext
Veridis_Alpha_v0.11/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.11
├── circuits/
│   # All existing circuits (optimized for mobile)
├── contracts/
│   # All existing contracts
├── docs/
│   └── Technical/
├── scripts/
│   # All existing scripts
├── src/
│   # All existing Rust services
├── sdk/
│   ├── typescript/
│   │   # Existing TypeScript SDK
│   ├── react-native/
│   │   ├── package.json
│   │   ├── src/
│   │   │   ├── index.ts
│   │   │   ├── VeridisProvider.tsx # React Native context provider
│   │   │   ├── hooks/
│   │   │   │   ├── useIdentity.ts
│   │   │   │   ├── useAttestations.ts
│   │   │   │   └── useZKProofs.ts
│   │   │   ├── components/
│   │   │   │   ├── IdentityCard.tsx
│   │   │   │   ├── AttestationList.tsx
│   │   │   │   └── QRCodeScanner.tsx
│   │   │   ├── services/
│   │   │   │   ├── mobile-wallet.service.ts
│   │   │   │   ├── biometric.service.ts
│   │   │   │   └── qr-code.service.ts
│   │   │   └── utils/
│   │   │       ├── mobile-zk.utils.ts # Mobile-optimized ZK
│   │   │       └── storage.utils.ts # Secure mobile storage
│   │   ├── android/
│   │   │   └── # Android-specific modules
│   │   ├── ios/
│   │   │   └── # iOS-specific modules
│   │   └── tsconfig.json
│   └── wallet-integrations/
│       ├── argent/
│       │   ├── package.json
│       │   └── src/
│       │       └── argent-adapter.ts
│       ├── braavos/
│       │   ├── package.json
│       │   └── src/
│       │       └── braavos-adapter.ts
│       └── starknetjs/
│           ├── package.json
│           └── src/
│               └── starknetjs-adapter.ts
├── tests/
│   ├── # All existing tests
│   ├── mobile/
│   │   ├── react-native.test.ts # React Native SDK tests
│   │   └── wallet-integration.test.ts # Wallet integration tests
│   └── e2e/
│       └── mobile-flow.test.ts # End-to-end mobile tests
└── ui/
    ├── identity_app/
    │   # Existing web app
    └── mobile_demo/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── screens/
        │   │   ├── IdentityScreen.tsx
        │   │   ├── AttestationsScreen.tsx
        │   │   ├── QRScannerScreen.tsx
        │   │   └── WalletConnectScreen.tsx
        │   ├── components/
        │   │   ├── BiometricAuth.tsx
        │   │   ├── WalletSelector.tsx
        │   │   └── ProofGenerator.tsx
        │   └── navigation/
        │       └── AppNavigator.tsx
        ├── android/
        │   └── # Android app configuration
        ├── ios/
        │   └── # iOS app configuration
        └── metro.config.js
```

**Key File Descriptions/Changes for Alpha v0.11:**

- `sdk/react-native/src/VeridisProvider.tsx`: React Native context provider for Veridis functionality
- `sdk/react-native/src/services/mobile-wallet.service.ts`: Service for integrating with mobile wallets
- `sdk/wallet-integrations/`: Separate adapters for different StarkNet wallets
- `ui/mobile_demo/`: Complete React Native demo app showcasing mobile capabilities

---

## Testnet Alpha v0.12: Performance Optimization and Scaling

**Sprint Goal:** Optimize performance for high-throughput applications with batch processing and caching mechanisms.
**Release Window:** Weeks 23-24

**Key Features Introduced/Demoed (on top of v0.11):**

- Batch processing for attestation issuance and verification
- Redis caching layer for frequently accessed data
- Optimized Cairo circuits for faster proof generation
- Database indexing and query optimization
- Load testing and performance benchmarking

**Focus Areas from Technical Documentation:**

- `smartContractArchitecture.md`: Gas optimization, batch operations
- High-throughput processing patterns
- Caching strategies and data management

**Project Directory Structure (`Veridis_Alpha_v0.12/`):**

```plaintext
Veridis_Alpha_v0.12/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.12
├── circuits/
│   ├── # All existing circuits (optimized)
│   └── optimized/
│       ├── batch_attestation_proof.cairo # Optimized batch processing
│       └── fast_verification.cairo # Speed-optimized verification
├── contracts/
│   ├── starknet/
│   │   ├── # All existing contracts (optimized)
│   │   └── optimized/
│   │       ├── BatchProcessor.cairo # Batch operations contract
│   │       └── CacheManager.cairo # On-chain caching helpers
│   └── ethereum/
│       # All existing contracts
├── docs/
│   └── Technical/
│       └── Performance/
│           ├── optimization-guide.md
│           └── benchmarks.md
├── scripts/
│   ├── # All existing scripts
│   ├── optimization/
│   │   ├── benchmark.ts # Performance benchmarking
│   │   ├── load-test.ts # Load testing scripts
│   │   └── profile-circuits.ts # Circuit profiling
│   └── deployment/
│       └── production-deploy.ts # Production deployment
├── src/
│   ├── services/
│   │   ├── # All existing services (optimized)
│   │   ├── cache_service.rs # Redis caching service
│   │   └── batch_service.rs # Batch processing service
│   ├── optimization/
│   │   ├── circuit_optimizer.rs # Circuit optimization tools
│   │   └── query_optimizer.rs # Database query optimization
│   ├── relayer/
│   │   └── main.rs # Optimized relayer
│   └── main.rs
├── infrastructure/
│   ├── docker/
│   │   ├── redis.yml # Redis cache configuration
│   │   ├── postgres.yml # Optimized database config
│   │   └── monitoring.yml # Performance monitoring
│   ├── kubernetes/
│   │   ├── cache-deployment.yaml
│   │   ├── batch-processor.yaml
│   │   └── scaling-config.yaml
│   └── terraform/
│       └── infrastructure.tf # Infrastructure as code
├── sdk/
│   ├── typescript/
│   │   ├── # Existing SDK (optimized)
│   │   └── src/
│   │       ├── batch/
│   │       │   ├── batch-client.ts # Batch operations
│   │       │   └── queue-manager.ts # Request queuing
│   │       └── cache/
│   │           └── cache-client.ts # Client-side caching
│   ├── react-native/
│   │   # Existing mobile SDK (optimized)
│   └── wallet-integrations/
│       # Existing wallet integrations
├── tests/
│   ├── # All existing tests
│   ├── performance/
│   │   ├── load-testing.test.ts
│   │   ├── batch-processing.test.ts
│   │   └── cache-performance.test.ts
│   └── benchmarks/
│       ├── circuit-benchmarks.test.ts
│       └── throughput-benchmarks.test.ts
└── ui/
    ├── identity_app/
    │   ├── # Existing web app (optimized)
    │   └── src/
    │       ├── components/
    │       │   └── PerformanceMonitor.tsx # Performance monitoring UI
    │       └── utils/
    │           └── batch-operations.ts # Batch UI operations
    ├── mobile_demo/
    │   # Existing mobile demo (optimized)
    └── admin_dashboard/
        ├── package.json
        └── src/
            ├── App.tsx
            ├── components/
            │   ├── SystemMetrics.tsx
            │   ├── PerformanceDashboard.tsx
            │   └── OptimizationTools.tsx
            └── services/
                └── monitoring.service.ts
```

**Key File Descriptions/Changes for Alpha v0.12:**

- `src/services/cache_service.rs`: Redis-based caching service for frequently accessed data
- `src/services/batch_service.rs`: Service for batching operations to improve throughput
- `circuits/optimized/batch_attestation_proof.cairo`: Optimized circuits for batch processing
- `infrastructure/`: Complete infrastructure setup with monitoring and scaling

---

## Testnet Alpha v0.13: Advanced Security Features

**Sprint Goal:** Implement advanced security features including rate limiting, anomaly detection, and security monitoring.
**Release Window:** Weeks 25-26

**Key Features Introduced/Demoed (on top of v0.12):**

- Rate limiting and DDoS protection
- Anomaly detection for suspicious patterns
- Security event monitoring and alerting
- Multi-signature controls for critical operations
- Automated security scanning and vulnerability assessment

**Focus Areas from Technical Documentation:**

- Security architecture and threat modeling
- Operational security best practices
- Incident response and monitoring

**Project Directory Structure (`Veridis_Alpha_v0.13/`):**

```plaintext
Veridis_Alpha_v0.13/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.13
├── circuits/
│   # All existing circuits
├── contracts/
│   ├── starknet/
│   │   ├── # All existing contracts
│   │   └── security/
│   │       ├── IMultiSigController.cairo
│   │       ├── MultiSigController.cairo # Multi-sig for critical ops
│   │       ├── IRateLimiter.cairo
│   │       ├── RateLimiter.cairo # On-chain rate limiting
│   │       ├── ISecurityModule.cairo
│   │       └── SecurityModule.cairo # Security controls
│   └── ethereum/
│       # All existing contracts
├── docs/
│   └── Technical/
│       └── Security/
│           ├── security-architecture.md
│           ├── threat-model.md
│           └── incident-response.md
├── scripts/
│   ├── # All existing scripts
│   └── security/
│       ├── vulnerability-scan.ts # Security scanning
│       ├── penetration-test.ts # Automated pen testing
│       └── security-audit.ts # Security audit tools
├── src/
│   ├── services/
│   │   ├── # All existing services
│   │   ├── security_service.rs # Security monitoring service
│   │   ├── rate_limiter.rs # Rate limiting service
│   │   └── anomaly_detector.rs # Anomaly detection
│   ├── security/
│   │   ├── threat_detector.rs # Threat detection engine
│   │   ├── incident_responder.rs # Incident response automation
│   │   └── vulnerability_scanner.rs # Vulnerability scanning
│   ├── relayer/
│   │   └── main.rs
│   └── main.rs
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   └── alerts.yml
│   ├── grafana/
│   │   ├── dashboards/
│   │   │   ├── security-dashboard.json
│   │   │   └── threat-monitoring.json
│   │   └── datasources/
│   │       └── prometheus.yml
│   └── elasticsearch/
│       ├── logstash.conf
│       └── kibana.yml
├── infrastructure/
│   ├── # All existing infrastructure
│   └── security/
│       ├── waf.yml # Web Application Firewall
│       ├── ids.yml # Intrusion Detection System
│       └── siem.yml # Security Information and Event Management
├── sdk/
│   ├── typescript/
│   │   ├── # Existing SDK
│   │   └── src/
│   │       └── security/
│   │           ├── security-client.ts # Security operations
│   │           └── audit-client.ts # Audit trail
│   ├── react-native/
│   │   # Existing mobile SDK
│   └── wallet-integrations/
│       # Existing wallet integrations
├── tests/
│   ├── # All existing tests
│   ├── security/
│   │   ├── penetration.test.ts # Penetration testing
│   │   ├── vulnerability.test.ts # Vulnerability testing
│   │   ├── rate-limiting.test.ts # Rate limiting tests
│   │   └── anomaly-detection.test.ts # Anomaly detection tests
│   └── chaos/
│       └── chaos-engineering.test.ts # Chaos engineering tests
└── ui/
    ├── identity_app/
    │   # Existing web app
    ├── mobile_demo/
    │   # Existing mobile demo
    └── security_dashboard/
        ├── package.json
        └── src/
            ├── App.tsx
            ├── components/
            │   ├── ThreatMonitor.tsx
            │   ├── SecurityAlerts.tsx
            │   ├── AuditLog.tsx
            │   └── IncidentResponse.tsx
            └── services/
                └── security.service.ts
```

**Key File Descriptions/Changes for Alpha v0.13:**

- `contracts/starknet/security/MultiSigController.cairo`: Multi-signature controls for critical protocol operations
- `src/services/security_service.rs`: Comprehensive security monitoring and incident response
- `src/security/threat_detector.rs`: Real-time threat detection and automated response
- `monitoring/`: Complete monitoring stack with Prometheus, Grafana, and ELK

---

## Testnet Alpha v0.14: Developer Tools and Documentation

**Sprint Goal:** Create comprehensive developer tools, documentation, and example applications for ecosystem adoption.
**Release Window:** Weeks 27-28

**Key Features Introduced/Demoed (on top of v0.13):**

- Complete developer documentation and tutorials
- Code generation tools for attestation schemas
- Example applications demonstrating different use cases
- Developer portal with interactive examples
- Testing frameworks and mocking tools

**Focus Areas from Technical Documentation:**

- Developer experience optimization
- Documentation completeness and clarity
- Example application development

**Project Directory Structure (`Veridis_Alpha_v0.14/`):**

```plaintext
Veridis_Alpha_v0.14/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Updated for Alpha v0.14
├── circuits/
│   # All existing circuits
├── contracts/
│   # All existing contracts
├── docs/
│   ├── Technical/
│   │   # All existing technical docs
│   ├── Developer/
│   │   ├── getting-started.md
│   │   ├── api-reference.md
│   │   ├── tutorials/
│   │   │   ├── basic-integration.md
│   │   │   ├── attestation-issuance.md
│   │   │   ├── zk-proof-generation.md
│   │   │   └── cross-chain-integration.md
│   │   ├── examples/
│   │   │   ├── simple-voting-dapp.md
│   │   │   ├── kyc-integration.md
│   │   │   └── reputation-system.md
│   │   └── best-practices/
│   │       ├── security.md
│   │       ├── performance.md
│   │       └── privacy.md
│   └── API/
│       ├── contract-interfaces.md
│       ├── sdk-reference.md
│       └── rest-api.md
├── scripts/
│   ├── # All existing scripts
│   └── developer-tools/
│       ├── scaffold-dapp.ts # Create new dApp boilerplate
│       ├── generate-schema.ts # Generate attestation schemas
│       ├── deploy-local.ts # Local development deployment
│       └── test-harness.ts # Testing framework setup
├── src/
│   ├── # All existing services
│   └── developer-tools/
│       ├── schema_generator.rs # Schema generation tools
│       ├── mock_services.rs # Mocking for development
│       └── test_helpers.rs # Testing utilities
├── tools/
│   ├── cli/
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── main.rs # Veridis CLI tool
│   │       ├── commands/
│   │       │   ├── init.rs # Initialize new project
│   │       │   ├── deploy.rs # Deploy contracts
│   │       │   ├── attest.rs # Issue attestations
│   │       │   └── verify.rs # Verify attestations
│   │       └── utils/
│   │           └── config.rs # Configuration management
│   ├── schema-generator/
│   │   ├── package.json
│   │   └── src/
│   │       ├── generator.ts # Schema generation logic
│   │       ├── templates/ # Schema templates
│   │       └── validators/ # Schema validation
│   └── testing/
│       ├── package.json
│       └── src/
│           ├── mock-server.ts # Mock API server
│           ├── test-data.ts # Test data generators
│           └── fixtures/ # Test fixtures
├── examples/
│   ├── simple-voting/
│   │   ├── package.json
│   │   ├── contracts/
│   │   │   └── VotingDApp.cairo
│   │   ├── src/
│   │   │   └── App.tsx
│   │   └── README.md
│   ├── kyc-dapp/
│   │   ├── package.json
│   │   ├── contracts/
│   │   │   └── KYCDApp.cairo
│   │   ├── src/
│   │   │   └── App.tsx
│   │   └── README.md
│   ├── reputation-system/
│   │   ├── package.json
│   │   ├── contracts/
│   │   │   └── ReputationDApp.cairo
│   │   ├── src/
│   │   │   └── App.tsx
│   │   └── README.md
│   └── cross-chain-bridge/
│       ├── package.json
│       ├── contracts/
│       │   ├── starknet/
│       │   │   └── BridgeDApp.cairo
│       │   └── ethereum/
│       │       └── BridgeDApp.sol
│       ├── src/
│       │   └── App.tsx
│       └── README.md
├── sdk/
│   ├── # All existing SDKs
│   └── testing/
│       ├── package.json
│       └── src/
│           ├── mock-providers.ts # Mock service providers
│           ├── test-utils.ts # Testing utilities
│           └── fixtures/ # Test data fixtures
├── tests/
│   # All existing tests
└── ui/
    ├── # All existing UIs
    └── developer_portal/
        ├── package.json
        ├── src/
        │   ├── App.tsx
        │   ├── pages/
        │   │   ├── GettingStarted.tsx
        │   │   ├── APIReference.tsx
        │   │   ├── Tutorials.tsx
        │   │   ├── Examples.tsx
        │   │   └── Playground.tsx
        │   ├── components/
        │   │   ├── CodeExample.tsx
        │   │   ├── InteractiveDemo.tsx
        │   │   └── APIExplorer.tsx
        │   └── services/
        │       └── documentation.service.ts
        ├── public/
        │   └── index.html
        └── docs-config.json
```

**Key File Descriptions/Changes for Alpha v0.14:**

- `tools/cli/src/main.rs`: Command-line interface for developers to interact with Veridis
- `examples/`: Complete example applications demonstrating different use cases
- `docs/Developer/`: Comprehensive developer documentation with tutorials and guides
- `ui/developer_portal/`: Interactive developer portal with live examples and API explorer

---

## Testnet Alpha v0.15: Production Readiness and Mainnet Preparation

**Sprint Goal:** Finalize production readiness with comprehensive audits, stress testing, and mainnet deployment preparation.
**Release Window:** Weeks 29-30

**Key Features Introduced/Demoed (on top of v0.14):**

- Complete security audit integration and remediation
- Mainnet deployment scripts and procedures
- Comprehensive stress testing and load validation
- Final optimizations and bug fixes
- Community testing program and bug bounties

**Focus Areas from Technical Documentation:**

- Production deployment best practices
- Security audit compliance
- Mainnet transition planning

**Project Directory Structure (`Veridis_Alpha_v0.15/`):**

```plaintext
Veridis_Alpha_v0.15/
├── .gitignore
├── Scarb.toml
├── LICENSE
├── package.json
├── README.md # Final production-ready documentation
├── circuits/
│   # All existing circuits (audit-ready)
├── contracts/
│   # All existing contracts (audit-ready)
├── docs/
│   ├── # All existing documentation
│   ├── Audit/
│   │   ├── audit-report.md
│   │   ├── remediation.md
│   │   └── security-checklist.md
│   ├── Mainnet/
│   │   ├── deployment-guide.md
│   │   ├── migration-plan.md
│   │   └── rollback-procedures.md
│   └── Community/
│       ├── bug-bounty.md
│       ├── testing-program.md
│       └── governance-transition.md
├── scripts/
│   ├── # All existing scripts
│   ├── mainnet/
│   │   ├── deploy-mainnet.ts # Mainnet deployment
│   │   ├── verify-deployment.ts # Deployment verification
│   │   ├── migration-script.ts # Data migration
│   │   └── rollback-script.ts # Emergency rollback
│   ├── audit/
│   │   ├── audit-prep.ts # Audit preparation
│   │   ├── coverage-report.ts # Code coverage
│   │   └── security-scan.ts # Final security scan
│   └── stress-testing/
│       ├── load-test-mainnet.ts # Mainnet load testing
│       ├── stress-test.ts # Stress testing
│       └── performance-validation.ts # Performance validation
├── src/
│   # All existing services (production-ready)
├── deployment/
│   ├── mainnet/
│   │   ├── contracts.json # Mainnet contract addresses
│   │   ├── config.json # Mainnet configuration
│   │   └── verification.json # Deployment verification
│   ├── testnet/
│   │   └── # Testnet deployment configs
│   └── local/
│       └── # Local development configs
├── audits/
│   ├── security-audit-1.pdf
│   ├── security-audit-2.pdf
│   ├── formal-verification.pdf
│   └── remediation-report.md
├── bug-bounty/
│   ├── program-details.md
│   ├── scope.md
│   ├── rewards.md
│   └── submission-template.md
├── community/
│   ├── testing-program/
│   │   ├── test-scenarios.md
│   │   ├── incentives.md
│   │   └── feedback-form.md
│   ├── governance/
│   │   ├── transition-plan.md
│   │   ├── dao-structure.md
│   │   └── voting-procedures.md
│   └── marketing/
│       ├── launch-plan.md
│       ├── partnerships.md
│       └── ecosystem-integration.md
├── infrastructure/
│   ├── # All existing infrastructure
│   └── mainnet/
│       ├── production.yml # Production infrastructure
│       ├── monitoring.yml # Production monitoring
│       ├── backup.yml # Backup procedures
│       └── disaster-recovery.yml # Disaster recovery
├── sdk/
│   # All existing SDKs (production versions)
├── tests/
│   ├── # All existing tests
│   ├── mainnet/
│   │   ├── mainnet-integration.test.ts
│   │   ├── performance-validation.test.ts
│   │   └── stress-testing.test.ts
│   └── audit/
│       ├── security-compliance.test.ts
│       ├── formal-verification.test.ts
│       └── audit-checklist.test.ts
└── ui/
    ├── # All existing UIs (production-ready)
    └── mainnet_dashboard/
        ├── package.json
        └── src/
            ├── App.tsx
            ├── components/
            │   ├── NetworkStatus.tsx
            │   ├── ProtocolMetrics.tsx
            │   ├── GovernanceActivity.tsx
            │   └── EcosystemStats.tsx
            └── services/
                └── mainnet.service.ts
```

**Key File Descriptions/Changes for Alpha v0.15:**

- `scripts/mainnet/deploy-mainnet.ts`: Production deployment script with comprehensive validation
- `audits/`: Complete audit reports and remediation documentation
- `community/`: Community programs including bug bounty and testing initiatives
- `deployment/mainnet/`: Mainnet-specific configuration and deployment artifacts

---

This incremental roadmap builds Veridis from basic identity registration to a full-featured, production-ready decentralized identity and reputation layer for StarkNet. Each alpha version introduces new capabilities while maintaining backward compatibility and security best practices, culminating in a comprehensive privacy-preserving identity solution ready for mainnet deployment and ecosystem adoption[^1][^2][^3].
