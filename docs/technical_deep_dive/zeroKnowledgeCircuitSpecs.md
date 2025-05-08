# Veridis: Zero-Knowledge Circuit Specifications

**Technical Documentation v1.0**  
**May 8, 2025**

**Authors:**  
Cass402 and the Veridis Engineering Team

---

## Document Control

| Version | Date       | Author           | Changes                               |
| ------- | ---------- | ---------------- | ------------------------------------- |
| 0.1     | 2025-03-15 | ZK Research Team | Initial draft                         |
| 0.2     | 2025-04-01 | ZK Research Team | Added security proofs                 |
| 0.3     | 2025-04-22 | Core Dev Team    | Integration with Cairo implementation |
| 1.0     | 2025-05-08 | Cass402          | Final review and publication          |

**Classification:** Internal Technical Documentation  
**Distribution:** Veridis Engineering, Auditors, Technical Partners

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Mathematical Foundations](#2-mathematical-foundations)
3. [Core Circuit Designs](#3-core-circuit-designs)
4. [KYC Verification Circuit](#4-kyc-verification-circuit)
5. [Uniqueness Verification Circuit](#5-uniqueness-verification-circuit)
6. [Reputation Verification Circuit](#6-reputation-verification-circuit)
7. [Delegation Circuits](#7-delegation-circuits)
8. [Circuit Composition](#8-circuit-composition)
9. [StarkNet Optimization Techniques](#9-starknet-optimization-techniques)
10. [Security Analysis](#10-security-analysis)
11. [Implementation Guide](#11-implementation-guide)
12. [Appendices](#12-appendices)

---

## 1. Introduction

### 1.1 Purpose and Scope

This document provides comprehensive technical specifications for the zero-knowledge circuits implemented in the Veridis protocol. It details the mathematical constructions, constraint systems, and implementation approaches for all ZK components used to provide privacy-preserving identity and attestation verification on StarkNet.

The primary zero-knowledge circuits in Veridis are:

1. **KYC Verification Circuit**: Enables privacy-preserving verification of KYC credentials
2. **Uniqueness Verification Circuit**: Ensures one-person-one-identity without revealing individual identity
3. **Reputation Verification Circuit**: Allows private verification of attestations and reputation scores
4. **Delegation Circuits**: Enables privacy-preserving delegation of credentials
5. **Composition Circuits**: Combines multiple proofs for complex verification scenarios

### 1.2 Design Goals

The Veridis ZK circuits are designed to achieve the following objectives:

- **Privacy Preservation**: Reveal minimal information during verification
- **Computational Efficiency**: Optimize for fast proving time on consumer hardware
- **StarkNet Compatibility**: Maximize efficiency in the StarkNet execution environment
- **Security**: Ensure soundness and zero-knowledge properties
- **Flexibility**: Support diverse attestation types and verification scenarios

### 1.3 STARK Technology Overview

Veridis leverages zk-STARKs (Zero-Knowledge Scalable Transparent Arguments of Knowledge) as its primary zero-knowledge proof system, taking advantage of StarkNet's native STARK verification capabilities.

Key advantages of STARKs for Veridis include:

- **No Trusted Setup**: Transparency without requiring a trusted setup ceremony
- **Post-Quantum Security**: Resistance to quantum computing attacks
- **Native StarkNet Support**: Efficient verification in the StarkNet environment
- **Scaling Efficiency**: Logarithmic verification time relative to computation size
- **Cairo Synergy**: Natural fit with Cairo's execution model

## 2. Mathematical Foundations

### 2.1 Finite Field Arithmetic

All Veridis circuits operate over the StarkNet prime field $\mathbb{F}_p$ where:

$p = 2^{251} + 17 \cdot 2^{192} + 1$

This prime was selected to optimize performance in the StarkNet environment while providing sufficient security margins. All circuit operations are defined as constraints over this field.

### 2.2 Cryptographic Primitives

#### 2.2.1 Hash Functions

Veridis circuits utilize the following hash functions:

- **Pedersen Hash**: Primary hashing function for commitments

  - $H_{pedersen}(x, y) = x \cdot G + y \cdot H$ where $G, H$ are predetermined generators of an elliptic curve group
  - Used for Merkle tree construction and identity commitments

- **Poseidon Hash**: Used for nullifier generation and certain constraint-efficient operations
  - Based on the Poseidon permutation with StarkNet-optimized parameters
  - $H_{poseidon}(x_1, \ldots, x_n) = \text{Permutation}(x_1, \ldots, x_n, 0, \ldots, 0)[0]$

#### 2.2.2 Merkle Trees

Merkle trees in Veridis use a binary structure with Pedersen hashing:

- Leaf calculation: $\text{Leaf} = H_{pedersen}(\text{type}, \text{value})$
- Node calculation: $\text{Node} = H_{pedersen}(\text{left}, \text{right})$

The height of Merkle trees is standardized at 20 for attestation registries, allowing for over 1 million attestations per tree.

#### 2.2.3 Nullifiers

Nullifiers are cryptographic one-way identifiers used to prevent double-use of credentials:

$\text{Nullifier} = H_{poseidon}(\text{secret}, \text{context})$

Where:

- $\text{secret}$ is a user's private seed
- $\text{context}$ is the usage context (e.g., event ID, purpose)

### 2.3 STARK Proof System

Veridis uses the STARK proof system with the following parameters:

- **Security Parameter**: 128 bits (minimum)
- **Field Extension Degree**: 1 (working in base field)
- **Blowup Factor**: 8 for most circuits
- **Number of Queries**: Determined by security parameter, typically 30-40
- **FRI Parameters**:
  - Folding factor: 4
  - Max step size: 16
  - Final polynomial degree: 1

### 2.4 Constraint System Model

Veridis circuits are expressed as algebraic intermediate representations (AIR) consisting of:

1. **Trace**: Execution trace of the computation
2. **Constraints**: Polynomial equations that must be satisfied by the trace
3. **Boundary Constraints**: Values that specific trace cells must take

The general form of constraints is:
$\sum_{i} f_i(x) \cdot g_i(x) = 0$

Where $f_i$ and $g_i$ are polynomials defined over the execution trace.

## 3. Core Circuit Designs

### 3.1 Circuit Structure Overview

All Veridis zero-knowledge circuits follow a common structural pattern:

```

┌───────────────────────────────────┐
│ Public Inputs │
│ (Merkle roots, nullifiers, etc.) │
└─────────────────┬─────────────────┘
│
▼
┌───────────────────────────────────┐
│ Commitment Validation │
│ (Merkle path verification, etc.) │
└─────────────────┬─────────────────┘
│
▼
┌───────────────────────────────────┐
│ Constraint Validation │
│ (Business logic, predicates) │
└─────────────────┬─────────────────┘
│
▼
┌───────────────────────────────────┐
│ Nullifier Derivation │
│ (Prevent double-use) │
└───────────────────────────────────┘

```

### 3.2 Common Circuit Components

#### 3.2.1 Merkle Path Verification

All credential verification circuits include Merkle path verification with the following constraints:

```cairo
// Pseudocode for Merkle path verification constraints
fn verify_merkle_path(
    leaf: felt252,
    path_elements: Array<(felt252, bool)>,
    claimed_root: felt252,
) {
    var current = leaf;

    // For each element in the path
    for i in 0..path_elements.len() {
        let (sibling, is_left) = path_elements[i];

        // Constraint: current must be correctly combined with sibling
        if is_left {
            current = pedersen_hash(sibling, current);
        } else {
            current = pedersen_hash(current, sibling);
        }
    }

    // Constraint: final hash must equal the claimed root
    constrain current = claimed_root;
}
```

#### 3.2.2 Nullifier Derivation

Nullifiers are generated with the following constraint structure:

```cairo
// Pseudocode for nullifier derivation constraints
fn derive_nullifier(
    secret: felt252,
    context: felt252,
    claimed_nullifier: felt252,
) {
    // Constraint: nullifier must be correctly derived
    let computed_nullifier = poseidon_hash(secret, context);
    constrain computed_nullifier = claimed_nullifier;
}
```

### 3.3 Circuit Interface Pattern

All Veridis circuits follow a consistent interface pattern:

```cairo
struct PublicInputs {
    merkle_root: felt252,       // Attester's Merkle root
    nullifier: felt252,         // Prevents double-use if applicable
    attester: felt252,          // Attester identifier
    attestation_type: felt252,  // Type of attestation being verified
    additional_data: felt252,   // Circuit-specific public data
}

struct PrivateInputs {
    credential_secret: felt252,   // User's secret for this credential
    credential_data: Array<felt252>, // Credential-specific data
    merkle_path: Array<(felt252, bool)>, // Path from leaf to root
    additional_data: Array<felt252>, // Circuit-specific private data
}

// Circuit interface
fn verify_circuit(
    private_inputs: PrivateInputs,
    public_inputs: PublicInputs,
) -> bool
```

## 4. KYC Verification Circuit

### 4.1 Circuit Purpose

The KYC verification circuit enables a user to prove they possess a valid KYC credential from a trusted attester without revealing any personal information. It supports selectively proving specific attributes (e.g., "age ≥ 18" or "country ≠ restricted list").

### 4.2 Public and Private Inputs

**Public Inputs:**

- `merkle_root`: Merkle root of the KYC attestation tree
- `nullifier`: (Optional) Nullifier to prevent double-use in specific contexts
- `attester`: Public identifier of the KYC attestation issuer
- `attestation_type`: Type identifier for KYC attestation
- `attribute_predicate`: Encoded representation of the attribute being proved

**Private Inputs:**

- `kyc_secret`: User's secret for this KYC credential
- `personal_data`: User's actual KYC data (name, birthdate, address, etc.)
- `merkle_path`: Merkle proof path connecting user's leaf to the root
- `attester_signature`: Signature from attester on the KYC data

### 4.3 Constraint System

The KYC verification circuit implements the following constraints:

#### 4.3.1 Credential Validity Constraints

```cairo
// Pseudocode for KYC validity constraints
fn verify_kyc_validity(
    kyc_secret: felt252,
    personal_data: KycData,
    attester_signature: Signature,
    attester_public_key: felt252,
) {
    // Constraint: KYC data must be correctly signed by attester
    let message = hash_kyc_data(personal_data);
    constrain verify_signature(attester_public_key, message, attester_signature) = true;

    // Constraint: KYC leaf must be correctly formed
    let leaf = compute_kyc_leaf(kyc_secret, personal_data);
    // Additional constraints will verify this leaf is in the Merkle tree
}
```

#### 4.3.2 Attribute Predicate Constraints

```cairo
// Pseudocode for attribute predicate constraints
fn verify_attribute_predicate(
    personal_data: KycData,
    predicate_type: u8,
    predicate_params: Array<felt252>,
    predicate_result: bool,
) {
    // Different constraint paths depending on predicate type
    if predicate_type == AGE_PREDICATE {
        let age = compute_age(personal_data.birthdate);
        let min_age = predicate_params[0];
        constrain (age >= min_age) = predicate_result;
    } else if predicate_type == COUNTRY_PREDICATE {
        let country_code = personal_data.country_code;
        let allowed = is_country_in_list(country_code, predicate_params);
        constrain allowed = predicate_result;
    } else if predicate_type == EXPIRATION_PREDICATE {
        let expiry = personal_data.expiry_date;
        let current_time = predicate_params[0];
        constrain (expiry > current_time) = predicate_result;
    }
    // Additional predicates as needed
}
```

### 4.4 Circuit Diagram

KYC Verification Circuit Logical Flow:

```
┌──────────────────────┐
│ Public Inputs        │
│ - Merkle root        │
│ - Attester ID        │
│ - Predicate encoding │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Verify KYC Signature │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Compute KYC Leaf     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Verify Merkle Path   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Check Predicate      │
│ (age, country, etc.) │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Generate Nullifier   │
│ (if applicable)      │
└──────────────────────┘
```

### 4.5 Security Properties

The KYC Verification Circuit guarantees:

1. **Soundness**: Only users with valid KYC credentials can generate valid proofs
2. **Zero-Knowledge**: No information about the user's personal data is revealed beyond the specified predicate
3. **Non-Transferability**: Credentials cannot be transferred between users
4. **Selective Disclosure**: Only the specific predicate result is disclosed, not the underlying data

## 5. Uniqueness Verification Circuit

### 5.1 Circuit Purpose

The Uniqueness Verification Circuit enables a user to prove they possess a valid "unique human" credential without revealing their identity. This circuit is essential for Sybil resistance in airdrops, governance, and other one-person-one-action scenarios.

### 5.2 Public and Private Inputs

**Public Inputs:**

- `merkle_root`: Merkle root of the uniqueness attestation tree
- `nullifier`: Nullifier preventing double-participation
- `attester`: Public identifier of the uniqueness attestation issuer
- `attestation_type`: Type identifier for uniqueness attestation
- `event_id`: Identifier for the event/context requiring uniqueness

**Private Inputs:**

- `identity_secret`: User's core identity secret
- `uniqueness_proof`: Data proving user's uniqueness (e.g., biometric commitment)
- `merkle_path`: Merkle proof path connecting user's leaf to the root
- `commitment_randomness`: Randomness used in commitments

### 5.3 Constraint System

#### 5.3.1 Uniqueness Credential Constraints

```cairo
// Pseudocode for uniqueness credential constraints
fn verify_uniqueness_credential(
    identity_secret: felt252,
    uniqueness_proof: UniquenessProof,
    attester_public_key: felt252,
) {
    // Constraint: Uniqueness proof must be valid
    // This depends on the specific uniqueness mechanism (biometric, social, etc.)
    constrain is_valid_uniqueness_proof(uniqueness_proof, attester_public_key) = true;

    // Constraint: Identity commitment must be correctly formed
    let commitment = commit_to_identity(identity_secret, uniqueness_proof);
    // Additional constraints will verify this commitment is in the Merkle tree
}
```

#### 5.3.2 Nullifier Constraints

```cairo
// Pseudocode for nullifier constraints
fn verify_uniqueness_nullifier(
    identity_secret: felt252,
    event_id: felt252,
    claimed_nullifier: felt252,
) {
    // Constraint: Nullifier must be correctly derived
    let computed_nullifier = poseidon_hash(identity_secret, event_id);
    constrain computed_nullifier = claimed_nullifier;
}
```

### 5.4 Circuit Diagram

Uniqueness Verification Circuit Logical Flow:

```
┌──────────────────────┐
│ Public Inputs        │
│ - Merkle root        │
│ - Event ID           │
│ - Nullifier          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Verify Uniqueness    │
│ Credential Validity  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Compute Identity     │
│ Commitment           │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Verify Merkle Path   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Derive Event-Specific│
│ Nullifier            │
└──────────────────────┘
```

### 5.5 Security Properties

The Uniqueness Verification Circuit guarantees:

1. **One-Person-One-Action**: Each unique person can only generate one valid proof per event
2. **Identity Privacy**: No information about the user's identity is revealed
3. **Cross-Event Unlinkability**: Proofs for different events cannot be linked to the same person
4. **Non-Transferability**: Uniqueness credentials cannot be transferred between users

## 6. Reputation Verification Circuit

### 6.1 Circuit Purpose

The Reputation Verification Circuit enables a user to prove they possess reputation attestations or scores above certain thresholds without revealing the exact scores or the full set of attestations they possess.

### 6.2 Public and Private Inputs

**Public Inputs:**

- `merkle_root`: Merkle root of the reputation attestation tree
- `attester`: Public identifier of the reputation attestation issuer
- `attestation_type`: Type identifier for reputation attestation
- `threshold`: Minimum score or requirement being verified
- `context_id`: Context for the reputation (e.g., platform, category)

**Private Inputs:**

- `identity_secret`: User's core identity secret
- `reputation_data`: User's actual reputation data (scores, badges, etc.)
- `merkle_path`: Merkle proof path connecting user's leaf to the root
- `metadata`: Additional data about the reputation attestations

### 6.3 Constraint System

#### 6.3.1 Reputation Validation Constraints

```cairo
// Pseudocode for reputation validation constraints
fn verify_reputation_validity(
    identity_secret: felt252,
    reputation_data: ReputationData,
    attester_public_key: felt252,
) {
    // Constraint: Reputation data must be properly attested
    let data_hash = hash_reputation_data(reputation_data);
    constrain is_valid_attestation(data_hash, attester_public_key, reputation_data.signature) = true;

    // Constraint: Reputation leaf must be correctly formed
    let leaf = compute_reputation_leaf(identity_secret, reputation_data);
    // Additional constraints will verify this leaf is in the Merkle tree
}
```

#### 6.3.2 Threshold Constraints

```cairo
// Pseudocode for threshold constraints
fn verify_threshold(
    reputation_data: ReputationData,
    threshold_type: u8,
    threshold_value: felt252,
) {
    // Different constraint paths depending on threshold type
    if threshold_type == SCORE_THRESHOLD {
        constrain reputation_data.score >= threshold_value;
    } else if threshold_type == BADGE_REQUIREMENT {
        constrain has_badge(reputation_data.badges, threshold_value) = true;
    } else if threshold_type == ACTIVITY_THRESHOLD {
        constrain reputation_data.activity_count >= threshold_value;
    }
    // Additional threshold types as needed
}
```

### 6.4 Circuit Diagram

Reputation Verification Circuit Logical Flow:

```
┌──────────────────────┐
│ Public Inputs        │
│ - Merkle root        │
│ - Threshold data     │
│ - Context ID         │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Verify Reputation    │
│ Attestation Validity │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Compute Reputation   │
│ Commitment           │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Verify Merkle Path   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Check Threshold      │
│ Requirements         │
└──────────────────────┘
```

### 6.5 Security Properties

The Reputation Verification Circuit guarantees:

1. **Score Privacy**: The exact reputation scores are not revealed, only that they meet thresholds
2. **Attestation Validity**: Only valid attestations from recognized issuers are accepted
3. **Minimum Disclosure**: Only the necessary reputation information is revealed
4. **Contextual Separation**: Reputation in different contexts remains separate

## 7. Delegation Circuits

### 7.1 Circuit Purpose

The Delegation Circuits enable privacy-preserving delegation of credentials and attestations. Users can delegate verification authority to others without revealing the delegation relationship publicly.

### 7.2 Delegation Creation Circuit

#### 7.2.1 Public and Private Inputs

**Public Inputs:**

- `delegation_commitment`: Commitment to the delegation relationship
- `nullifier`: Nullifier to prevent double-delegation if applicable
- `constraints_hash`: Hash of delegation constraints

**Private Inputs:**

- `delegator_secret`: Delegator's identity secret
- `delegate_key`: Public key of the delegate
- `credential_reference`: Reference to the delegated credential
- `constraints`: Constraints on the delegation usage

#### 7.2.2 Constraint System

```cairo
// Pseudocode for delegation creation constraints
fn create_delegation_constraints(
    delegator_secret: felt252,
    delegate_key: felt252,
    credential_reference: CredentialRef,
    constraints: DelegationConstraints,
    claimed_commitment: felt252,
    claimed_nullifier: felt252,
) {
    // Constraint: Delegator must possess the credential
    constrain has_credential(delegator_secret, credential_reference) = true;

    // Constraint: Delegation commitment must be correctly formed
    let computed_commitment = pedersen_hash(
        delegate_key,
        hash_credential_ref(credential_reference),
        hash_constraints(constraints)
    );
    constrain computed_commitment = claimed_commitment;

    // Constraint: Nullifier must be correctly derived
    let computed_nullifier = poseidon_hash(delegator_secret, "delegation");
    constrain computed_nullifier = claimed_nullifier;
}
```

### 7.3 Delegation Usage Circuit

#### 7.3.1 Public and Private Inputs

**Public Inputs:**

- `attestation_root`: Root of the attestation tree
- `usage_nullifier`: Nullifier for this usage of delegation
- `result_commitment`: Commitment to the verification result

**Private Inputs:**

- `delegate_secret`: Delegate's private key
- `delegation_data`: Details of the delegation
- `credential_proof`: Proof of the delegated credential
- `usage_context`: Context in which delegation is being used

#### 7.3.2 Constraint System

```cairo
// Pseudocode for delegation usage constraints
fn use_delegation_constraints(
    delegate_secret: felt252,
    delegation_data: DelegationData,
    credential_proof: CredentialProof,
    usage_context: felt252,
    claimed_nullifier: felt252,
) {
    // Constraint: Delegate must be the intended recipient
    constrain is_intended_delegate(delegate_secret, delegation_data) = true;

    // Constraint: Delegation must be valid for this usage context
    constrain is_valid_for_context(delegation_data.constraints, usage_context) = true;

    // Constraint: Credential being used must match the delegated credential
    constrain matches_delegated_credential(credential_proof, delegation_data.credential_ref) = true;

    // Constraint: Usage nullifier must be correctly derived
    let computed_nullifier = poseidon_hash(delegate_secret, delegation_data.id, usage_context);
    constrain computed_nullifier = claimed_nullifier;
}
```

### 7.4 Security Properties

The Delegation Circuits guarantee:

1. **Private Relationship**: The delegation relationship is not publicly visible
2. **Constrained Usage**: Delegates can only use the delegation within specified constraints
3. **Revocability**: Delegations can be revoked by the delegator
4. **Non-Transferability**: Delegations cannot be transferred to other delegates
5. **Accountability**: Delegation usage can be tracked through nullifiers (for auditing)

## 8. Circuit Composition

### 8.1 Multi-Credential Verification

Veridis supports combining multiple credential verifications in a single proof through circuit composition.

#### 8.1.1 Parallel Composition

```cairo
// Pseudocode for parallel credential verification
fn verify_multiple_credentials(
    // Private inputs
    identity_secret: felt252,
    credential_set: Array<Credential>,
    merkle_paths: Array<MerklePath>,

    // Public inputs
    merkle_roots: Array<felt252>,
    attesters: Array<felt252>,
    requirements: Array<Requirement>,
) {
    // Verify each credential in parallel
    for i in 0..credential_set.len() {
        let credential = credential_set[i];
        let path = merkle_paths[i];
        let root = merkle_roots[i];
        let attester = attesters[i];
        let requirement = requirements[i];

        // Verify this credential meets its requirement
        constrain verify_credential(
            identity_secret,
            credential,
            path,
            root,
            attester,
            requirement
        ) = true;
    }
}
```

#### 8.1.2 Logical Combination

```cairo
// Pseudocode for logical combination of credentials
fn verify_credential_logic(
    // Private inputs
    identity_secret: felt252,
    credential_set: Array<Credential>,
    merkle_paths: Array<MerklePath>,

    // Public inputs
    merkle_roots: Array<felt252>,
    attesters: Array<felt252>,
    logic_expression: LogicExpression,
    requirements: Array<Requirement>,
) {
    // Evaluate each credential's validity
    let mut validity_results: Array<bool> = [];
    for i in 0..credential_set.len() {
        let credential = credential_set[i];
        let path = merkle_paths[i];
        let root = merkle_roots[i];
        let attester = attesters[i];
        let requirement = requirements[i];

        let is_valid = verify_credential(
            identity_secret,
            credential,
            path,
            root,
            attester,
            requirement
        );
        validity_results.push(is_valid);
    }

    // Evaluate the logical expression
    let result = evaluate_logic(logic_expression, validity_results);
    constrain result = true;
}
```

### 8.2 Recursive Composition

For more complex verification scenarios, Veridis supports recursive composition where one proof verifies the validity of another proof.

```cairo
// Conceptual pseudocode for recursive verification
fn verify_recursive(
    // Private inputs
    inner_proof: Proof,
    inner_private_inputs: PrivateInputs,

    // Public inputs
    inner_public_inputs: PublicInputs,
    outer_requirements: Requirements,
) {
    // Verify the inner proof is valid
    constrain verify_stark_proof(inner_proof, inner_public_inputs) = true;

    // Verify the result meets the outer requirements
    constrain meets_requirements(inner_public_inputs, outer_requirements) = true;
}
```

## 9. StarkNet Optimization Techniques

### 9.1 Cairo-Specific Optimizations

#### 9.1.1 Field Operations

```cairo
// Optimized field multiplication in Cairo
fn optimized_mul(a: felt252, b: felt252) -> felt252 {
    // Cairo natively supports efficient field arithmetic
    return a * b;
}

// Optimized hash computation with hints
fn optimized_pedersen(a: felt252, b: felt252) -> felt252 {
    // Using Cairo's built-in Pedersen hash
    return pedersen(a, b);
}
```

#### 9.1.2 Memory Access Patterns

```cairo
// Optimized memory access for Cairo execution trace
fn optimized_merkle_verification(
    leaf: felt252,
    path: Array<(felt252, bool)>,
    root: felt252,
) -> bool {
    // Cairo-optimized implementation with efficient memory access
    var current = leaf;

    // Unrolling small loops and minimizing memory operations
    for i in 0..path.len() {
        let (sibling, is_left) = path[i];

        // Using Cairo's efficient branching
        if is_left {
            current = pedersen(sibling, current);
        } else {
            current = pedersen(current, sibling);
        }
    }

    return current == root;
}
```

### 9.2 STARK-Specific Optimizations

#### 9.2.1 AIR Optimization

```
// Example of optimized AIR constraints for Merkle verification
// These would be expressed as polynomial constraints in the actual implementation

// For each step i in the computation trace:
Constraint1: (current_i - hash(left_i, right_i)) * selector_i = 0
Constraint2: (left_i - (is_left_i * sibling_i + (1-is_left_i) * current_{i-1})) * selector_i = 0
Constraint3: (right_i - (is_left_i * current_{i-1} + (1-is_left_i) * sibling_i)) * selector_i = 0
```

#### 9.2.2 Trace Generation Optimization

```cairo
// Efficient trace generation with minimal branching
fn generate_optimized_trace(
    private_inputs: PrivateInputs,
    public_inputs: PublicInputs,
) -> ComputationTrace {
    let mut trace = ComputationTrace::new();

    // Pre-compute frequently used values
    let precomputed_hashes = precompute_hashes(private_inputs);

    // Populate trace with minimal branching
    // ...

    return trace;
}
```

### 9.3 Batch Verification

```cairo
// Pseudocode for batch verification optimization
fn batch_verify(
    proofs: Array<Proof>,
    public_inputs_array: Array<PublicInputs>,
) -> bool {
    // StarkNet-optimized batch verification
    // This leverages StarkNet's batch verification capabilities
    // to amortize verification costs

    // Optional: combine multiple proofs into a single verification
    let combined_result = combine_verifications(proofs, public_inputs_array);

    return combined_result;
}
```

## 10. Security Analysis

### 10.1 Cryptographic Security Properties

#### 10.1.1 Soundness

Veridis circuits guarantee soundness with the following security bounds:

- **Statistical Soundness Error**: $2^{-128}$ (minimum)
- **Computational Soundness**: Based on the discrete logarithm problem in the StarkNet field

Soundness guarantees that no adversary can generate a valid proof for a false statement except with negligible probability.

#### 10.1.2 Zero-Knowledge

Veridis circuits achieve zero-knowledge through:

- **Perfect Completeness**: Honest provers always succeed
- **Perfect Zero-Knowledge**: Simulator indistinguishability for all circuits
- **Witness Indistinguishability**: For predicates with multiple valid witnesses

The simulator for Veridis proofs can generate indistinguishable proofs without knowledge of the private inputs by:

1. Sampling random values for internal trace elements
2. Working backward to ensure consistency with public inputs
3. Constructing a simulated proof using the STARK proving system

#### 10.1.3 Non-Malleability

Veridis proofs are non-malleable by design:

- Public inputs are cryptographically bound to the proof
- Groth16-style binding is used for proof elements
- Hash-based challenge derivation prevents tampering

### 10.2 Attack Vectors and Mitigations

#### 10.2.1 Replay Attacks

**Vector**: Reusing legitimate proofs in different contexts.

**Mitigation**:

- Context-specific nullifiers
- Inclusion of time-bounds in public inputs
- Application-specific identifiers in proofs

#### 10.2.2 Grinding Attacks

**Vector**: Searching for favorable randomness in proof generation.

**Mitigation**:

- Deterministic challenge generation
- Fiat-Shamir transformation with domain separation
- Public input binding to randomness

#### 10.2.3 Information Leakage

**Vector**: Inadvertent revelation of private information through side channels.

**Mitigation**:

- Constant-time implementation of critical operations
- Careful handling of error cases
- Minimization of public inputs to only essential information

### 10.3 Formal Security Analysis

#### 10.3.1 Security Assumptions

Veridis circuits rely on the following cryptographic assumptions:

1. **Discrete Logarithm Assumption**: Finding $x$ given $g^x$ in the StarkNet field is computationally infeasible
2. **Collision Resistance**: Finding inputs that produce the same hash output is computationally infeasible
3. **Random Oracle Model**: The hash functions used behave like random oracles

#### 10.3.2 Security Reduction

The security of Veridis circuits reduces to:

- The security of the STARK proof system
- The collision resistance of Pedersen and Poseidon hashes
- The security of the underlying StarkNet platform

#### 10.3.3 Information Theoretic Analysis

Analysis of information leakage in Veridis circuits:

- **Perfect Zero-Knowledge**: For the core credential verification circuits
- **Statistical Zero-Knowledge**: For certain optimized components
- **Computational Zero-Knowledge**: For the overall protocol

## 11. Implementation Guide

### 11.1 Circuit Implementation in Cairo

#### 11.1.1 Core Circuit Structure

```cairo
// Example Cairo implementation of a basic verification circuit
#[starknet::contract]
mod VerificationCircuit {
    use array::ArrayTrait;
    use veridis::merkle::verify_merkle_inclusion;
    use veridis::hash::{pedersen_hash, poseidon_hash};

    // Public inputs structure
    #[derive(Drop, Serde)]
    struct PublicInputs {
        merkle_root: felt252,
        nullifier: felt252,
        attester: felt252,
        attestation_type: felt252,
    }

    // Generate STARK proof
    fn generate_proof(
        // Private inputs
        identity_secret: felt252,
        credential_data: Array<felt252>,
        merkle_path: Array<(felt252, bool)>,

        // Public inputs
        public_inputs: PublicInputs,
    ) -> Array<felt252> {
        // 1. Verify the credential is included in the Merkle tree
        let leaf = compute_credential_leaf(identity_secret, credential_data);
        assert(verify_merkle_inclusion(
            leaf,
            merkle_path,
            public_inputs.merkle_root
        ), 'Invalid Merkle proof');

        // 2. Check credential validity
        assert(is_valid_credential(credential_data), 'Invalid credential');

        // 3. Derive and check nullifier
        let computed_nullifier = poseidon_hash(identity_secret, public_inputs.attestation_type);
        assert(computed_nullifier == public_inputs.nullifier, 'Invalid nullifier');

        // 4. Generate and return STARK proof
        // This is a simplified representation - actual proof generation
        // would be more complex and involve the STARK proving system
        return generate_stark_proof(/* program hash, private data, etc. */);
    }

    // Additional helper functions
    // ...
}
```

#### 11.1.2 Testing Circuits

```cairo
// Example test for a verification circuit
#[test]
fn test_kyc_verification_circuit() {
    // 1. Setup test data
    let identity_secret = 123456;
    let kyc_data = setup_test_kyc_data();
    let merkle_path = setup_test_merkle_path();

    let public_inputs = PublicInputs {
        merkle_root: setup_test_merkle_root(),
        nullifier: poseidon_hash(identity_secret, KYC_ATTESTATION_TYPE),
        attester: TEST_ATTESTER_ID,
        attestation_type: KYC_ATTESTATION_TYPE,
    };

    // 2. Generate proof
    let proof = generate_proof(identity_secret, kyc_data, merkle_path, public_inputs);

    // 3. Verify proof
    let is_valid = verify_proof(proof, public_inputs);
    assert(is_valid, 'Proof verification failed');

    // 4. Test invalid cases
    // ...
}
```

### 11.2 Performance Considerations

#### 11.2.1 Circuit Size Metrics

| Circuit Type        | Constraints | Trace Length | Typical Proving Time | Verification Gas |
| ------------------- | ----------- | ------------ | -------------------- | ---------------- |
| KYC Verification    | ~150,000    | ~250,000     | 3-8 seconds          | ~200,000         |
| Uniqueness          | ~100,000    | ~150,000     | 2-5 seconds          | ~150,000         |
| Reputation          | ~120,000    | ~200,000     | 2-6 seconds          | ~180,000         |
| Delegation Creation | ~80,000     | ~120,000     | 1-4 seconds          | ~120,000         |
| Delegation Usage    | ~130,000    | ~220,000     | 2-7 seconds          | ~180,000         |

#### 11.2.2 Optimization Guidelines

1. **Minimize Hashing Operations**: Each hash adds significant constraints
2. **Use Built-in Cairo Functions**: Leverage Cairo's native operations when possible
3. **Batch Similar Operations**: Group similar operations to reduce trace size
4. **Precompute Where Possible**: Calculate static values outside the circuit
5. **Optimize Memory Access Patterns**: Minimize random access to reduce constraints

### 11.3 Integration with StarkNet Contracts

```cairo
// Example of ZK verifier integration in a StarkNet contract
#[starknet::contract]
mod ZkVerifier {
    use starknet::ContractAddress;
    use veridis::proof::{Proof, PublicInputs};

    #[storage]
    struct Storage {
        // Storage for verification keys, etc.
        verification_keys: LegacyMap::<felt252, VerificationKey>,
        nullifiers: LegacyMap::<felt252, bool>,
    }

    #[external(v0)]
    fn verify_credential_proof(
        ref self: ContractState,
        proof: Proof,
        public_inputs: PublicInputs,
    ) -> bool {
        // 1. Get the verification key for this program
        let verification_key = self.verification_keys.read(public_inputs.program_hash);

        // 2. Verify the STARK proof
        let is_valid = stark_verify(
            verification_key,
            public_inputs.to_array(),
            proof
        );

        // 3. If valid and nullifier is present, register it
        if is_valid && public_inputs.has_nullifier {
            // Check nullifier hasn't been used
            assert(
                !self.nullifiers.read(public_inputs.nullifier),
                'Nullifier already used'
            );

            // Register nullifier
            self.nullifiers.write(public_inputs.nullifier, true);
        }

        return is_valid;
    }

    // Additional methods for managing verification keys, etc.
    // ...
}
```

## 12. Appendices

### 12.1 Circuit Optimization Examples

#### 12.1.1 Optimized Merkle Verification

```cairo
// Highly optimized Merkle verification in Cairo
fn optimized_merkle_verification(
    leaf: felt252,
    path: Array<(felt252, bool)>,
    root: felt252,
) -> bool {
    // This implementation includes multiple optimizations:
    // 1. Loop unrolling for common path lengths
    // 2. Minimizing variable reassignments
    // 3. Efficient branching using Cairo's if/else

    var current = leaf;

    // Handle common case of depth 20 efficiently
    if path.len() == 20 {
        // Unrolled loop for depth 20
        // Each iteration manually expanded
        let (sibling0, is_left0) = *path.at(0);
        current = if is_left0 {
            pedersen_hash(sibling0, current)
        } else {
            pedersen_hash(current, sibling0)
        };

        // Repeat for all 20 levels (showing just first two here)
        let (sibling1, is_left1) = *path.at(1);
        current = if is_left1 {
            pedersen_hash(sibling1, current)
        } else {
            pedersen_hash(current, sibling1)
        };

        // Remaining levels...
    } else {
        // Generic case for other depths
        let mut i: u32 = 0;
        loop {
            if i >= path.len() {
                break;
            }

            let (sibling, is_left) = *path.at(i);
            current = if is_left {
                pedersen_hash(sibling, current)
            } else {
                pedersen_hash(current, sibling)
            };

            i += 1;
        }
    }

    return current == root;
}
```

### 12.2 Sample Proof Verification

```cairo
// Example of complete verification function
fn verify_kyc_proof(
    proof: Array<felt252>,
    public_inputs: KycPublicInputs,
) -> bool {
    // 1. Check proof structure
    assert(is_valid_proof_structure(proof), 'Invalid proof structure');

    // 2. Extract verification key for this circuit
    let verification_key = get_verification_key(KYC_PROGRAM_HASH);

    // 3. Prepare public inputs in required format
    let formatted_inputs = format_public_inputs(public_inputs);

    // 4. Perform STARK verification
    let verification_result = stark_verify(
        verification_key,
        formatted_inputs,
        proof
    );

    // 5. Additional application-specific checks
    if verification_result {
        // Check nullifier hasn't been used before
        if is_nullifier_used(public_inputs.nullifier) {
            return false;
        }

        // Check attester is valid
        if !is_valid_attester(public_inputs.attester, KYC_ATTESTATION_TYPE) {
            return false;
        }
    }

    return verification_result;
}
```

### 12.3 Glossary of Terms

**AIR**: Algebraic Intermediate Representation - the format used to express computations in the STARK proof system.

**Constraints**: Mathematical equations that must be satisfied by a valid computation.

**Merkle Tree**: A tree data structure used for efficient verification of large data sets.

**Nullifier**: A one-way identifier used to prevent double-use of credentials.

**Pedersen Hash**: A hash function based on elliptic curve operations, used in Veridis for commitments.

**Poseidon Hash**: A hash function optimized for zk-SNARKs and STARKs, used in Veridis for nullifiers.

**STARK**: Scalable Transparent Argument of Knowledge - the zero-knowledge proof system used in Veridis.

**Trace**: The execution trace of a computation, representing all intermediate values.

**Verification Key**: The public parameters needed to verify a STARK proof.

**zk-STARK**: Zero-Knowledge Scalable Transparent Argument of Knowledge - a privacy-preserving proof system with no trusted setup.

---

## Document Metadata

**Document ID:** VERIDIS-SPEC-ZK-2025-001  
**Version:** 1.0  
**Date:** 2025-05-08  
**Authors:** Cass402 and the Veridis Engineering Team  
**Last Edit:** 2025-05-08 06:37:35 UTC by Cass402

**Classification:** Internal Technical Documentation  
**Distribution:** Veridis Engineering, Auditors, Technical Partners

**Document End**

```

This detailed technical specification document outlines the zero-knowledge circuits used in the Veridis protocol. It provides comprehensive information on the mathematical foundations, circuit designs, implementation details, and security properties of each ZK component, all leveraging zk-STARKs to take full advantage of StarkNet's native capabilities.

The document would be valuable for developers implementing the system, auditors reviewing the security, and technical partners integrating with Veridis. I've maintained the same level of technical depth and professionalism as in the whitepaper while focusing specifically on the ZK circuit specifications.
```
