# Veridis: Merkle Tree Implementation Guide

**Technical Documentation v1.0**  
**May 8, 2025**

**Authors:**  
Cass402 and the Veridis Engineering Team

---

## Document Control

| Version | Date       | Author              | Changes                       |
| ------- | ---------- | ------------------- | ----------------------------- |
| 0.1     | 2025-03-22 | Cryptography Team   | Initial draft                 |
| 0.2     | 2025-04-07 | Smart Contract Team | Added contract implementation |
| 0.3     | 2025-04-25 | Performance Team    | Added optimization techniques |
| 1.0     | 2025-05-08 | Cass402             | Final review and publication  |

**Classification:** Internal Technical Documentation  
**Distribution:** Veridis Engineering, Auditors, Technical Partners

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Merkle Tree Architecture](#2-merkle-tree-architecture)
3. [Cryptographic Foundations](#3-cryptographic-foundations)
4. [Tree Types and Applications](#4-tree-types-and-applications)
5. [Implementation in Cairo](#5-implementation-in-cairo)
6. [Contract Integration](#6-contract-integration)
7. [Security Analysis](#7-security-analysis)
8. [Performance Optimization](#8-performance-optimization)
9. [Testing and Verification](#9-testing-and-verification)
10. [Appendices](#10-appendices)

---

## 1. Introduction

### 1.1 Purpose and Scope

This document provides a comprehensive technical specification of the Merkle tree implementation used in the Veridis protocol. Merkle trees are fundamental data structures that enable efficient and verifiable storage of large datasets, particularly attestations and credentials, while minimizing on-chain storage requirements.

The scope of this document encompasses:

- The mathematical and cryptographic foundations of Merkle trees
- Different tree types used in Veridis and their applications
- Implementation details in Cairo for StarkNet
- Integration with other protocol components
- Security considerations and optimizations

### 1.2 Role in the Veridis Protocol

Merkle trees serve several critical functions in the Veridis identity and attestation system:

1. **Scalable Attestation Storage**: Enabling Tier-1 attesters to issue large batches of attestations without prohibitive storage costs
2. **Privacy-Preserving Verification**: Allowing users to prove inclusion of their credential in an attester's dataset without revealing other credentials
3. **Efficient Revocation**: Supporting efficient revocation of specific credentials without affecting others
4. **Selective Disclosure**: Facilitating zero-knowledge proofs about credential properties
5. **Data Integrity**: Ensuring tamper-evident storage of credential data

### 1.3 Key Terminology

- **Merkle Tree**: A tree data structure where each non-leaf node is the hash of its child nodes
- **Merkle Root**: The root hash representing the entire tree
- **Merkle Proof**: A path from a leaf node to the root, enabling verification of leaf inclusion
- **Leaf Node**: End node containing the actual data (credential or attestation)
- **Internal Node**: Non-leaf node that is the hash of its children
- **Witness**: The sibling hashes needed to verify a leaf's inclusion
- **Inclusion Proof**: Demonstration that a leaf is part of the tree

## 2. Merkle Tree Architecture

### 2.1 System Overview

The Veridis Merkle tree system consists of the following components:

1. **Tree Builders**: Off-chain components for constructing and updating trees
2. **On-chain Registry**: Contracts for storing and verifying Merkle roots
3. **Verification Library**: Cairo functions for verifying inclusion proofs
4. **Integration Components**: Interfaces with attestation and verification systems

```

┌─────────────────────────────────────────────┐
│ Off-Chain Layer │
├─────────────────────────────────────────────┤
│ ┌───────────────┐ ┌─────────────────┐ │
│ │ Attestation │ │ Merkle Tree │ │
│ │ Generator │─────►│ Builder │ │
│ └───────────────┘ └────────┬────────┘ │
│ │ │
│ ┌───────────────┐ ┌─────────▼──────────┐│
│ │ Merkle Proof │◄────│ Merkle Root + ││
│ │ Generator │ │ Tree Data ││
│ └───────┬───────┘ └───────────────────┬┘│
└─────────┼───────────────────────────┬─────┘
│ │
┌─────────▼───────┐ │
│ │ │
│ User Wallet │ │
│ │ │
│ ┌─────────────┐ │ ┌───────────────▼──────┐
│ │ Identity + │ │ │ │
│ │ Proof Data │ │ │ StarkNet Chain │
│ └──────┬──────┘ │ │ │
│ │ │ │ ┌──────────────────┐ │
└────────┼────────┘ │ │ Attestation │ │
│ │ │ Registry │ │
│ │ └──────────────────┘ │
┌────────▼────────┐ │ │
│ │ │ ┌──────────────────┐ │
│ Zero-Knowledge │ │ │ Merkle │ │
│ Proof │──►│ │ Verification │ │
│ │ │ │ Library │ │
└─────────────────┘ │ └──────────────────┘ │
└──────────────────────┘

```

### 2.2 Tree Lifecycle

The lifecycle of a Merkle tree in the Veridis protocol consists of the following stages:

1. **Creation**: Off-chain generation of leaves from attestation data
2. **Building**: Construction of the tree and computation of the root
3. **Registration**: Publishing the root on-chain in the Attestation Registry
4. **Proof Generation**: Creating inclusion proofs for specific credentials
5. **Verification**: On-chain validation of inclusion proofs
6. **Updating**: Adding, removing, or modifying leaves and updating the root
7. **Revocation**: Replacing the tree with a new version excluding revoked credentials

### 2.3 System Components

#### 2.3.1 Off-Chain Components

- **Tree Builder**: Creates and manages Merkle trees from attestation data
- **Proof Generator**: Creates inclusion proofs for specific leaves
- **Tree Storage**: Stores the complete tree data for proof generation

#### 2.3.2 On-Chain Components

- **Merkle Verification Library**: Cairo functions for verifying inclusion proofs
- **Attestation Registry**: Stores Merkle roots of attestation trees
- **Integration Contracts**: Systems that leverage Merkle verification

## 3. Cryptographic Foundations

### 3.1 Hash Function

Veridis Merkle trees use the Pedersen hash function, which is natively supported in Cairo and StarkNet:

````cairo
fn pedersen_hash(a: felt252, b: felt252) -> felt252 {
    // Use Cairo's built-in Pedersen hash
    return pedersen(a, b);
}

The Pedersen hash was chosen for the following reasons:

- **Native Support**: Efficient implementation in Cairo
- **ZK-Friendly**: Efficiently provable in zero-knowledge circuits
- **Security**: Strong cryptographic guarantees
- **Determinism**: Consistent results for the same inputs

### 3.2 Tree Construction

#### 3.2.1 Leaf Construction

Leaves in Veridis Merkle trees are constructed from attestation data:

```cairo
fn compute_leaf(
    attestation_type: u256,
    subject: felt252,
    data: felt252,
    nonce: felt252,
) -> felt252 {
    // First hash attestation data
    let data_hash = pedersen_hash(
        pedersen_hash(attestation_type.low.into(), attestation_type.high.into()),
        pedersen_hash(subject, data)
    );

    // Then hash with nonce for uniqueness
    return pedersen_hash(data_hash, nonce);
}
````

#### 3.2.2 Node Construction

Internal nodes are constructed by hashing child nodes:

```cairo
fn compute_node(left: felt252, right: felt252) -> felt252 {
    // Sort inputs for deterministic ordering
    if left <= right {
        return pedersen_hash(left, right);
    } else {
        return pedersen_hash(right, left);
    }
}
```

#### 3.2.3 Tree Building

The tree is built bottom-up from leaves to root:

```cairo
fn build_tree(leaves: Array<felt252>) -> felt252 {
    // If single leaf, it's the root
    if leaves.len() == 1 {
        return *leaves.at(0);
    }

    // Create next level
    let mut next_level: Array<felt252> = ArrayTrait::new();
    let mut i: u32 = 0;

    // Process pairs of nodes
    while i < leaves.len() {
        if i + 1 < leaves.len() {
            // Hash pair of nodes
            let node = compute_node(*leaves.at(i), *leaves.at(i + 1));
            next_level.append(node);
        } else {
            // Odd node, promote to next level
            next_level.append(*leaves.at(i));
        }
        i += 2;
    }

    // Recursively build next level
    return build_tree(next_level);
}
```

### 3.3 Proof Structure

A Merkle proof consists of:

1. **Leaf Value**: The value of the leaf being proven
2. **Siblings**: The sibling hashes needed to recompute the path to the root
3. **Path Directions**: Whether each sibling is to the left or right (encoded as booleans)

```cairo
#[derive(Drop, Serde)]
struct MerkleProof {
    leaf: felt252,                 // Value of the leaf
    path: Array<(felt252, bool)>,  // Pairs of (sibling, is_left)
}
```

The `is_left` boolean indicates whether the sibling is to the left (true) or right (false) of the current path node.

## 4. Tree Types and Applications

### 4.1 Attestation Merkle Trees

#### 4.1.1 Structure

Attestation Merkle trees store batches of attestations issued by Tier-1 attesters:

```cairo
#[derive(Drop, Serde)]
struct AttestationTree {
    root: felt252,
    attester: ContractAddress,
    attestation_type: u256,
    leaf_count: u32,
    timestamp: u64,
}
```

#### 4.1.2 Leaf Structure

Leaves in attestation trees contain:

```cairo
#[derive(Drop, Serde)]
struct AttestationLeaf {
    subject: felt252,           // Typically a user's identity commitment
    data: felt252,              // Attestation-specific data
    validity: u64,              // Validity period
    metadata: felt252,          // Additional metadata
    nonce: felt252,             // Randomization factor
}
```

#### 4.1.3 Application

Attestation trees are primarily used for:

- KYC attestations (proving a user has completed KYC)
- Uniqueness attestations (proving a user is a unique human)
- Batch credential issuance (efficiently storing many credentials)

### 4.2 Revocation Merkle Trees

#### 4.2.1 Structure

Revocation trees track which credentials have been revoked:

```cairo
#[derive(Drop, Serde)]
struct RevocationTree {
    root: felt252,
    attestation_tree_root: felt252,  // The root of the attestation tree this revokes from
    revoked_count: u32,
    timestamp: u64,
}
```

#### 4.2.2 Leaf Structure

Leaves in revocation trees contain:

```cairo
#[derive(Drop, Serde)]
struct RevocationLeaf {
    nullifier: felt252,         // Unique identifier of revoked credential
    reason_code: u8,            // Reason for revocation
    timestamp: u64,             // When it was revoked
}
```

#### 4.2.3 Application

Revocation trees are used for:

- Tracking compromised credentials
- Implementing expiry mechanisms
- Invalidating credentials when information changes

### 4.3 Sparse Merkle Trees

#### 4.3.1 Structure

Sparse Merkle trees optimize for trees with many empty leaves:

```cairo
#[derive(Drop, Serde)]
struct SparseMerkleTree {
    root: felt252,
    depth: u8,
    non_empty_leaves: u32,
}
```

#### 4.3.2 Default Nodes

Sparse trees use default nodes for empty positions:

```cairo
fn compute_default_nodes(depth: u8) -> Array<felt252> {
    let mut default_nodes: Array<felt252> = ArrayTrait::new();

    // Add leaf level default (typically zero)
    default_nodes.append(0);

    // Compute default nodes up the tree
    let mut current_level = 0;
    while current_level < depth {
        let prev_default = *default_nodes.at(current_level);
        let new_default = pedersen_hash(prev_default, prev_default);
        default_nodes.append(new_default);
        current_level += 1;
    }

    return default_nodes;
}
```

#### 4.3.3 Application

Sparse Merkle trees are used for:

- Registry-style data structures
- Mapping-like on-chain structures
- Efficient updates to large datasets

### 4.4 Incremental Merkle Trees

#### 4.4.1 Structure

Incremental Merkle trees support efficient updates:

```cairo
#[derive(Drop, Serde)]
struct IncrementalMerkleTree {
    root: felt252,
    depth: u8,
    filled_subtrees: Array<felt252>,
    next_index: u32,
}
```

#### 4.4.2 Update Mechanism

Adding a leaf to an incremental tree:

```cairo
fn insert_leaf(
    ref tree: IncrementalMerkleTree,
    leaf: felt252,
) -> felt252 {
    let mut current_index = tree.next_index;
    let mut current_hash = leaf;

    // Update filled subtrees and compute new root
    let mut i: u8 = 0;
    while i < tree.depth {
        // If current bit is 0, this is the rightmost node at this level
        if (current_index & (1 << i)) == 0 {
            // Store the current hash at this level
            if i < tree.filled_subtrees.len() {
                tree.filled_subtrees.set(i, current_hash);
            } else {
                tree.filled_subtrees.append(current_hash);
            }

            // Current hash becomes hash of itself with the default node
            current_hash = pedersen_hash(current_hash, ZERO_VALUE);
        } else {
            // Current hash becomes hash of the stored hash with itself
            let stored_hash = *tree.filled_subtrees.at(i);
            current_hash = pedersen_hash(stored_hash, current_hash);
        }

        i += 1;
    }

    // Update tree state
    tree.root = current_hash;
    tree.next_index = current_index + 1;

    return current_hash;
}
```

#### 4.4.3 Application

Incremental Merkle trees are used for:

- Nullifier sets that grow over time
- Continuous attestation systems
- Append-only credential stores

## 5. Implementation in Cairo

### 5.1 Core Merkle Library

The core Merkle verification library implemented in Cairo:

```cairo
#[starknet::contract]
mod MerkleLib {
    use array::ArrayTrait;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    #[derive(Drop, Serde)]
    struct MerkleProof {
        leaf: felt252,
        path: Array<(felt252, bool)>,
    }

    #[external(v0)]
    fn verify_merkle_proof(
        self: @ContractState,
        root: felt252,
        proof: MerkleProof,
    ) -> bool {
        // Start with the leaf
        let mut current = proof.leaf;

        // Trace path to the root
        let mut i: u32 = 0;
        loop {
            if i >= proof.path.len() {
                break;
            }

            let (sibling, is_left) = *proof.path.at(i);

            // Compute parent based on path direction
            if is_left {
                // Sibling is on the left
                current = pedersen_hash(sibling, current);
            } else {
                // Sibling is on the right
                current = pedersen_hash(current, sibling);
            }

            i += 1;
        }

        // Check if computed root matches the expected root
        return current == root;
    }

    #[external(v0)]
    fn compute_merkle_root(
        self: @ContractState,
        leaves: Array<felt252>,
    ) -> felt252 {
        // Handle empty tree
        if leaves.len() == 0 {
            return 0;
        }

        // Handle single leaf
        if leaves.len() == 1 {
            return *leaves.at(0);
        }

        // Build level by level
        let mut current_level = leaves;

        loop {
            // If we have a single node, we've reached the root
            if current_level.len() == 1 {
                return *current_level.at(0);
            }

            // Create next level
            let mut next_level: Array<felt252> = ArrayTrait::new();
            let mut i: u32 = 0;

            // Process pairs
            while i < current_level.len() {
                if i + 1 < current_level.len() {
                    // Hash pair
                    let left = *current_level.at(i);
                    let right = *current_level.at(i + 1);
                    next_level.append(pedersen_hash(left, right));
                } else {
                    // Promote single node
                    next_level.append(*current_level.at(i));
                }

                i += 2;
            }

            // Move up a level
            current_level = next_level;
        }
    }

    #[external(v0)]
    fn generate_proof(
        self: @ContractState,
        leaves: Array<felt252>,
        leaf_index: u32,
    ) -> MerkleProof {
        // Validate index
        assert(leaf_index < leaves.len(), 'Invalid leaf index');

        // Get the leaf value
        let leaf = *leaves.at(leaf_index);

        // Initialize proof
        let mut path: Array<(felt252, bool)> = ArrayTrait::new();

        // Track current level and index
        let mut current_level = leaves;
        let mut current_index = leaf_index;

        // Build proof from bottom up
        while current_level.len() > 1 {
            // Determine if current node is left or right in its pair
            let is_right = current_index % 2 == 1;

            // Get sibling index
            let sibling_index = if is_right {
                current_index - 1
            } else {
                current_index + 1
            };

            // Add sibling to proof if it exists
            if sibling_index < current_level.len() {
                let sibling = *current_level.at(sibling_index);
                path.append((sibling, !is_right)); // sibling direction is opposite
            } else {
                // Use zero for missing siblings (incomplete last level)
                path.append((0, !is_right));
            }

            // Move to next level
            let mut next_level: Array<felt252> = ArrayTrait::new();
            let mut i: u32 = 0;
            while i < current_level.len() {
                if i + 1 < current_level.len() {
                    // Hash pair
                    let left = *current_level.at(i);
                    let right = *current_level.at(i + 1);
                    next_level.append(pedersen_hash(left, right));
                } else {
                    // Promote single node
                    next_level.append(*current_level.at(i));
                }

                i += 2;
            }

            // Update for next iteration
            current_index = current_index / 2;
            current_level = next_level;
        }

        return MerkleProof { leaf: leaf, path: path };
    }

    // Internal helper function
    fn pedersen_hash(a: felt252, b: felt252) -> felt252 {
        // Call StarkNet's built-in pedersen hash
        return pedersen(a, b);
    }
}
```

### 5.2 Sparse Merkle Tree Implementation

Implementation of a Sparse Merkle Tree in Cairo:

```cairo
#[starknet::contract]
mod SparseMerkleLib {
    use array::ArrayTrait;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        // Default nodes at each level
        default_nodes: LegacyMap<u8, felt252>,
        max_depth: u8,
    }

    #[constructor]
    fn constructor(ref self: ContractState, depth: u8) {
        assert(depth > 0 && depth <= 32, 'Invalid depth');

        // Initialize default nodes
        let mut default_value: felt252 = 0;
        self.default_nodes.write(0, default_value);

        // Compute default nodes up the tree
        let mut i: u8 = 1;
        while i <= depth {
            default_value = pedersen_hash(default_value, default_value);
            self.default_nodes.write(i, default_value);
            i += 1;
        }

        // Store max depth
        self.max_depth.write(depth);
    }

    #[external(v0)]
    fn get_root_for_path(
        self: @ContractState,
        key: felt252,
        value: felt252,
        siblings: Array<felt252>,
    ) -> felt252 {
        // Validate depth
        assert(siblings.len() == self.max_depth.read().into(), 'Invalid proof length');

        // Start with the leaf value or default if zero
        let mut current_value = value;
        if current_value == 0 {
            current_value = self.default_nodes.read(0);
        }

        // Get key bits (path in the tree)
        let mut path_bits: Array<bool> = get_bits(key, self.max_depth.read());

        // Compute root by combining with siblings
        let mut i: u32 = 0;
        while i < siblings.len() {
            let sibling = *siblings.at(i);
            let path_bit = *path_bits.at(i);

            // If path bit is 0, current value is left child
            if path_bit {
                current_value = pedersen_hash(sibling, current_value);
            } else {
                current_value = pedersen_hash(current_value, sibling);
            }

            i += 1;
        }

        return current_value;
    }

    #[external(v0)]
    fn verify_sparse_proof(
        self: @ContractState,
        root: felt252,
        key: felt252,
        value: felt252,
        siblings: Array<felt252>,
    ) -> bool {
        let computed_root = self.get_root_for_path(key, value, siblings);
        return computed_root == root;
    }

    // Helper to get bits of a felt252 as booleans (MSB first)
    fn get_bits(value: felt252, num_bits: u8) -> Array<bool> {
        let mut result: Array<bool> = ArrayTrait::new();
        let mut i: u8 = 0;

        while i < num_bits {
            // Check bit at position (num_bits - 1 - i)
            let bit_position = num_bits - 1 - i;
            let mask = 1 << bit_position;
            let bit_value = (value & mask) != 0;
            result.append(bit_value);

            i += 1;
        }

        return result;
    }

    // Internal helper function
    fn pedersen_hash(a: felt252, b: felt252) -> felt252 {
        return pedersen(a, b);
    }
}
```

### 5.3 Incremental Merkle Tree Implementation

Implementation of an Incremental Merkle Tree in Cairo:

```cairo
#[starknet::contract]
mod IncrementalMerkleLib {
    use array::ArrayTrait;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        // Tree state
        roots: LegacyMap<u32, felt252>,
        filled_subtrees: LegacyMap<u32, felt252>,
        current_root_index: u32,
        next_index: u32,

        // Tree parameters
        max_depth: u8,
        zero_values: LegacyMap<u8, felt252>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, depth: u8) {
        assert(depth > 0 && depth <= 32, 'Invalid depth');

        // Initialize zero values
        let mut zero_value: felt252 = 0;
        self.zero_values.write(0, zero_value);

        // Initialize filled subtrees
        self.filled_subtrees.write(0, zero_value);

        // Initialize higher-level zero values and filled subtrees
        let mut i: u8 = 1;
        while i <= depth {
            zero_value = pedersen_hash(zero_value, zero_value);
            self.zero_values.write(i, zero_value);
            self.filled_subtrees.write(i.into(), zero_value);
            i += 1;
        }

        // Store depth
        self.max_depth.write(depth);

        // Initialize root
        self.roots.write(0, zero_value);
    }

    #[external(v0)]
    fn insert(ref self: ContractState, leaf: felt252) -> u32 {
        // Get current insertion index
        let index = self.next_index.read();

        // Ensure we haven't exceeded capacity
        let max_leaf_count = 1 << self.max_depth.read();
        assert(index < max_leaf_count, 'Tree full');

        // Insert leaf and get new root
        let new_root = self.insert_at_index(leaf, index);

        // Update state
        let new_root_index = self.current_root_index.read() + 1;
        self.current_root_index.write(new_root_index);
        self.roots.write(new_root_index, new_root);
        self.next_index.write(index + 1);

        return index;
    }

    #[external(v0)]
    fn insert_batch(
        ref self: ContractState,
        leaves: Array<felt252>,
    ) -> (u32, u32) {
        let starting_index = self.next_index.read();
        let mut i: u32 = 0;

        // Insert each leaf
        while i < leaves.len() {
            self.insert(*leaves.at(i));
            i += 1;
        }

        return (starting_index, leaves.len());
    }

    #[internal]
    fn insert_at_index(
        ref self: ContractState,
        leaf: felt252,
        index: u32,
    ) -> felt252 {
        let max_depth = self.max_depth.read();
        let mut current_index = index;
        let mut current_hash = leaf;
        let mut current_level: u32 = 0;

        // Traverse from leaf to root
        while current_level < max_depth.into() {
            // Determine if current node is left or right in its pair
            let is_right = current_index % 2 == 1;
            let sibling_index = if is_right {
                current_index - 1
            } else {
                current_index + 1
            };

            let sibling: felt252;

            // If the sibling index is beyond current tree size, use zero value
            if sibling_index == self.next_index.read() {
                sibling = self.zero_values.read(current_level.try_into().unwrap());
            } else if sibling_index > self.next_index.read() {
                sibling = self.zero_values.read(current_level.try_into().unwrap());
            } else if is_right {
                // Sibling is a left node that's already filled
                sibling = self.filled_subtrees.read(current_level);
            } else {
                // Sibling doesn't exist yet, use zero value
                sibling = self.zero_values.read(current_level.try_into().unwrap());
            }

            // Hash current with sibling based on position
            if is_right {
                current_hash = pedersen_hash(sibling, current_hash);
            } else {
                // Update filled subtree at this level
                self.filled_subtrees.write(current_level, current_hash);
                current_hash = pedersen_hash(current_hash, sibling);
            }

            // Move up to next level
            current_index = current_index / 2;
            current_level += 1;
        }

        return current_hash;
    }

    #[view]
    fn get_root(self: @ContractState) -> felt252 {
        return self.roots.read(self.current_root_index.read());
    }

    #[view]
    fn get_root_at_index(self: @ContractState, index: u32) -> felt252 {
        assert(index <= self.current_root_index.read(), 'Invalid root index');
        return self.roots.read(index);
    }

    #[view]
    fn get_leaf_count(self: @ContractState) -> u32 {
        return self.next_index.read();
    }

    // Internal helper function
    fn pedersen_hash(a: felt252, b: felt252) -> felt252 {
        return pedersen(a, b);
    }
}
```

### 5.4 Multi-Proof Verification

Implementation of batch proof verification for multiple leaves:

```cairo
#[starknet::contract]
mod MultiProofLib {
    use array::ArrayTrait;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    #[derive(Drop, Serde)]
    struct MultiProof {
        leaves: Array<felt252>,
        indices: Array<u32>,
        siblings: Array<felt252>,
    }

    #[external(v0)]
    fn verify_multi_proof(
        self: @ContractState,
        root: felt252,
        proof: MultiProof,
        total_leaves: u32,
    ) -> bool {
        // Validate inputs
        assert(proof.leaves.len() == proof.indices.len(), 'Leaves/indices mismatch');
        assert(proof.leaves.len() > 0, 'Empty proof');

        // Determine tree depth from total leaves
        let depth = compute_depth(total_leaves);

        // Set up bitfield to track which nodes we have
        let mut bitfield: Array<bool> = ArrayTrait::new();
        let mut values: Array<felt252> = ArrayTrait::new();

        // Initialize with leaf positions
        let mut i: u32 = 0;
        while i < proof.indices.len() {
            let position = proof.indices.at(i) + total_leaves;
            ensure_bitfield_size(ref bitfield, *position + 1);
            bitfield.set(*position, true);

            ensure_array_size(ref values, *position + 1);
            values.set(*position, *proof.leaves.at(i));

            i += 1;
        }

        // Track current sibling index
        let mut sibling_idx: u32 = 0;

        // Process level by level from bottom to top
        let mut level_size = total_leaves;
        let mut level_offset = 0;

        while level_size > 1 {
            let mut j: u32 = 0;
            while j < level_size {
                let current_node = level_offset + j;
                let is_left = j % 2 == 0;
                let sibling = if is_left { current_node + 1 } else { current_node - 1 };

                // If both current and sibling are known, compute parent
                if j + 1 < level_size && bitfield.at(current_node) && bitfield.at(sibling) {
                    let parent = level_offset + level_size + (j / 2);
                    let parent_value = compute_parent(
                        *values.at(current_node),
                        *values.at(sibling),
                        is_left
                    );

                    // Store parent value
                    ensure_bitfield_size(ref bitfield, parent + 1);
                    bitfield.set(parent, true);

                    ensure_array_size(ref values, parent + 1);
                    values.set(parent, parent_value);
                }
                // If only current is known, use sibling from proof
                else if bitfield.at(current_node) {
                    assert(sibling_idx < proof.siblings.len(), 'Insufficient siblings');
                    let parent = level_offset + level_size + (j / 2);
                    let parent_value = compute_parent(
                        *values.at(current_node),
                        *proof.siblings.at(sibling_idx),
                        is_left
                    );

                    // Store parent value
                    ensure_bitfield_size(ref bitfield, parent + 1);
                    bitfield.set(parent, true);

                    ensure_array_size(ref values, parent + 1);
                    values.set(parent, parent_value);

                    sibling_idx += 1;
                }

                j += 2;
            }

            // Move to next level
            level_offset += level_size;
            level_size = (level_size + 1) / 2;
        }

        // Check if computed root matches expected root
        return values.at(values.len() - 1) == root;
    }

    // Helper function to compute parent node
    fn compute_parent(left: felt252, right: felt252, is_left_child: bool) -> felt252 {
        if is_left_child {
            return pedersen_hash(left, right);
        } else {
            return pedersen_hash(right, left);
        }
    }

    // Compute tree depth needed for given leaf count
    fn compute_depth(leaf_count: u32) -> u32 {
        let mut depth: u32 = 0;
        let mut max_leaves: u32 = 1;

        while max_leaves < leaf_count {
            max_leaves *= 2;
            depth += 1;
        }

        return depth;
    }

    // Ensure bitfield has at least the required size
    fn ensure_bitfield_size(ref bitfield: Array<bool>, size: u32) {
        while bitfield.len() < size {
            bitfield.append(false);
        }
    }

    // Ensure array has at least the required size
    fn ensure_array_size(ref arr: Array<felt252>, size: u32) {
        while arr.len() < size {
            arr.append(0);
        }
    }

    // Internal helper function
    fn pedersen_hash(a: felt252, b: felt252) -> felt252 {
        return pedersen(a, b);
    }
}
```

## 6. Contract Integration

### 6.1 Integration with Attestation Registry

Example integration of Merkle trees with the Attestation Registry:

```cairo
#[starknet::contract]
mod AttestationRegistry {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use veridis::merkle::{IMerkleLib, MerkleProof};

    #[storage]
    struct Storage {
        // Tier-1 attestation storage (attester, type) -> attestation data
        tier1_attestations: LegacyMap::<(ContractAddress, u256), AttestationData>,

        // Reference to Merkle Lib contract
        merkle_lib: ContractAddress,

        // Reference to Attester Registry
        attester_registry: ContractAddress,
    }

    #[derive(Drop, Serde)]
    struct AttestationData {
        attestation_type: u256,
        merkle_root: felt252,
        timestamp: u64,
        expiration_time: u64,
        revoked: bool,
        schema_uri: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Tier1AttestationIssued: Tier1AttestationIssued,
        Tier1AttestationRevoked: Tier1AttestationRevoked,
    }

    #[derive(Drop, starknet::Event)]
    struct Tier1AttestationIssued {
        attester: ContractAddress,
        attestation_type: u256,
        merkle_root: felt252,
        expiration_time: u64,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct Tier1AttestationRevoked {
        attester: ContractAddress,
        attestation_type: u256,
        timestamp: u64,
    }

    #[external(v0)]
    fn issue_tier1_attestation(
        ref self: ContractState,
        attestation_type: u256,
        merkle_root: felt252,
        expiration_time: u64,
        schema_uri: felt252,
    ) {
        let caller = get_caller_address();

        // Check caller is a valid Tier-1 attester
        let attester_registry = IAttesterRegistry(self.attester_registry.read());
        assert(attester_registry.is_tier1_attester(caller, attestation_type), 'Not a Tier-1 attester');

        // Create attestation data
        let attestation = AttestationData {
            attestation_type: attestation_type,
            merkle_root: merkle_root,
            timestamp: get_block_timestamp(),
            expiration_time: expiration_time,
            revoked: false,
            schema_uri: schema_uri,
        };

        // Store attestation
        self.tier1_attestations.write((caller, attestation_type), attestation);

        // Emit event
        self.emit(Tier1AttestationIssued {
            attester: caller,
            attestation_type: attestation_type,
            merkle_root: merkle_root,
            expiration_time: expiration_time,
            timestamp: get_block_timestamp()
        });
    }

    #[external(v0)]
    fn verify_tier1_attestation(
        self: @ContractState,
        attester: ContractAddress,
        attestation_type: u256,
        leaf: felt252,
        proof: MerkleProof,
    ) -> bool {
        // Get attestation data
        let attestation = self.tier1_attestations.read((attester, attestation_type));

        // Check attestation exists and is not revoked or expired
        if attestation.merkle_root == 0 || attestation.revoked {
            return false;
        }

        // Check expiration if applicable
        if attestation.expiration_time != 0 && get_block_timestamp() > attestation.expiration_time {
            return false;
        }

        // Verify the Merkle proof
        let merkle_lib = IMerkleLib(self.merkle_lib.read());
        let proof_valid = merkle_lib.verify_merkle_proof(
            attestation.merkle_root,
            MerkleProof { leaf: leaf, path: proof.path }
        );

        return proof_valid;
    }

    #[external(v0)]
    fn revoke_tier1_attestation(
        ref self: ContractState,
        attestation_type: u256,
    ) {
        let caller = get_caller_address();

        // Get attestation
        let mut attestation = self.tier1_attestations.read((caller, attestation_type));
        assert(attestation.merkle_root != 0, 'Attestation not found');
        assert(!attestation.revoked, 'Already revoked');

        // Revoke
        attestation.revoked = true;
        self.tier1_attestations.write((caller, attestation_type), attestation);

        // Emit event
        self.emit(Tier1AttestationRevoked {
            attester: caller,
            attestation_type: attestation_type,
            timestamp: get_block_timestamp()
        });
    }
}
```

### 6.2 Integration with ZK Verifier

Example integration of Merkle verification in the ZK Verifier:

```cairo
// Inside ZK circuit definition
fn attestation_membership_circuit(
    // Private inputs
    identity_secret: felt252,
    credential_data: CredentialData,
    merkle_path: Array<(felt252, bool)>,

    // Public inputs
    merkle_root: felt252,
    attester: felt252,
    attestation_type: felt252,
    leaf_hash: felt252,
) {
    // 1. Compute the leaf hash
    let computed_leaf = compute_credential_leaf(
        identity_secret,
        credential_data
    );

    // 2. Constrain leaf hash matches claimed value
    constrain computed_leaf = leaf_hash;

    // 3. Verify Merkle path
    let computed_root = compute_merkle_root_from_path(
        leaf_hash,
        merkle_path
    );

    // 4. Constrain computed root matches claimed root
    constrain computed_root = merkle_root;
}

// Function to compute credential leaf in circuit
fn compute_credential_leaf(
    identity_secret: felt252,
    credential_data: CredentialData,
) -> felt252 {
    // Hash credential data
    let credential_hash = poseidon_hash(
        credential_data.attestation_type,
        poseidon_hash(
            credential_data.subject_commitment,
            credential_data.data
        )
    );

    // Bind to identity secret
    return poseidon_hash(identity_secret, credential_hash);
}

// Function to compute Merkle root from path in circuit
fn compute_merkle_root_from_path(
    leaf: felt252,
    path: Array<(felt252, bool)>,
) -> felt252 {
    let mut current = leaf;

    for i in 0..path.len() {
        let (sibling, is_left) = path[i];

        // Branch based on direction
        if is_left {
            current = poseidon_hash(sibling, current);
        } else {
            current = poseidon_hash(current, sibling);
        }
    }

    return current;
}
```

### 6.3 Integration with Nullifier Registry

Example of using Merkle trees for efficient nullifier storage:

```cairo
#[starknet::contract]
mod MerkleNullifierRegistry {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use veridis::merkle::{IMerkleLib, MerkleProof};

    #[storage]
    struct Storage {
        // Nullifier Merkle tree root
        nullifier_root: felt252,

        // Authorized registrars
        authorized_registrars: LegacyMap::<ContractAddress, bool>,

        // Merkle tree implementation
        incremental_merkle: ContractAddress,

        // Admin
        admin: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NullifierRegistered: NullifierRegistered,
    }

    #[derive(Drop, starknet::Event)]
    struct NullifierRegistered {
        nullifier: felt252,
        registrar: ContractAddress,
        index: u32,
        timestamp: u64,
    }

    #[external(v0)]
    fn register_nullifier(
        ref self: ContractState,
        nullifier: felt252,
    ) -> u32 {
        // Check authorization
        let caller = get_caller_address();
        assert(self.authorized_registrars.read(caller), 'Not authorized');

        // Add nullifier to Merkle tree
        let incremental_merkle = IIncrementalMerkleLib(self.incremental_merkle.read());
        let index = incremental_merkle.insert(nullifier);

        // Update root
        self.nullifier_root.write(incremental_merkle.get_root());

        // Emit event
        self.emit(NullifierRegistered {
            nullifier: nullifier,
            registrar: caller,
            index: index,
            timestamp: get_block_timestamp()
        });

        return index;
    }

    #[external(v0)]
    fn register_nullifier_batch(
        ref self: ContractState,
        nullifiers: Array<felt252>,
    ) -> (u32, u32) {
        // Check authorization
        let caller = get_caller_address();
        assert(self.authorized_registrars.read(caller), 'Not authorized');

        // Add nullifiers to Merkle tree
        let incremental_merkle = IIncrementalMerkleLib(self.incremental_merkle.read());
        let insertion_result = incremental_merkle.insert_batch(nullifiers);

        // Update root
        self.nullifier_root.write(incremental_merkle.get_root());

        // Emit events (could be optimized with a batch event)
        let starting_index = insertion_result.0;
        let count = insertion_result.1;
        let timestamp = get_block_timestamp();

        let mut i: u32 = 0;
        while i < count {
            self.emit(NullifierRegistered {
                nullifier: *nullifiers.at(i),
                registrar: caller,
                index: starting_index + i,
                timestamp: timestamp
            });

            i += 1;
        }

        return insertion_result;
    }

    #[view]
    fn is_nullifier_registered(
        self: @ContractState,
        nullifier: felt252,
        index: u32,
        proof: MerkleProof,
    ) -> bool {
        // Check claimed nullifier matches leaf in proof
        assert(nullifier == proof.leaf, 'Leaf mismatch');

        // Verify the proof against current root
        let merkle_lib = IMerkleLib(self.merkle_lib.read());
        return merkle_lib.verify_merkle_proof(
            self.nullifier_root.read(),
            proof
        );
    }

    #[view]
    fn get_nullifier_root(self: @ContractState) -> felt252 {
        return self.nullifier_root.read();
    }
}
```

## 7. Security Analysis

### 7.1 Threat Model

The Merkle tree implementation must defend against the following threats:

1. **Data Tampering**: Attempts to alter attestation data after issuance
2. **Proof Forgery**: Creating false proofs of inclusion for data not in the tree
3. **Attester Impersonation**: Unauthorized entities registering attestation roots
4. **Tree Manipulation**: Improper tree construction affecting verification
5. **Second Preimage Attacks**: Finding different data that generates the same path

### 7.2 Security Properties

The Veridis Merkle tree implementation guarantees the following security properties:

#### 7.2.1 Integrity

Merkle trees ensure the integrity of attestation data through:

- Cryptographic binding of leaf data via hash functions
- Deterministic root calculation from leaves
- Tamper evidence due to hash function properties

#### 7.2.2 Verifiability

The system enables efficient verification of data inclusion:

- Logarithmic proof size relative to tree size
- Standardized verification process
- Public roots that can be verified by any party

#### 7.2.3 Non-Repudiation

The attestation system ensures non-repudiation:

- Roots are signed/published by attesters
- Historical roots are maintained on-chain
- Events provide an audit trail of attestation issuance

#### 7.2.4 Privacy Preservation

Merkle trees contribute to privacy by:

- Revealing only the minimum data needed for verification
- Allowing selective disclosure of attestations
- Supporting zero-knowledge proofs about tree contents

### 7.3 Attack Vectors and Mitigations

#### 7.3.1 Second Preimage Attack

**Vector**: Finding different input data that produces the same leaf hash.

**Mitigation**:

- Use of cryptographically secure hash functions (Pedersen)
- Structured leaf format with type information
- Inclusion of nonces or random elements in leaf construction

#### 7.3.2 Rogue Root Publication

**Vector**: Unauthorized attesters publishing attestation roots.

**Mitigation**:

- Strict validation of attester authorization
- Registry of approved Tier-1 attesters
- Separation between Tier-1 and Tier-2 attestations
- Event logging for audit trails

#### 7.3.3 Incorrect Tree Construction

**Vector**: Improperly constructed trees leading to invalid proofs.

**Mitigation**:

- Standardized tree construction libraries
- Deterministic ordering of siblings
- Consistent hashing procedure
- Standard testing vectors for verification

#### 7.3.4 Replay Attacks

**Vector**: Reusing valid proofs across different contexts.

**Mitigation**:

- Context binding in proof verification
- Attester and attestation type included in verification
- Timestamp and expiration checks

### 7.4 Formal Security Analysis

#### 7.4.1 Merkle Tree Properties

The security of a Merkle tree with height $h$ is characterized by:

1. **Collision Resistance**: Finding two different sets of leaves that produce the same root has probability approximately $2^{-128}$ with the Pedersen hash.

2. **Second-Preimage Resistance**: Given a set of leaves $L$ with root $R$, finding a different set of leaves $L'$ with the same root has probability $\approx 2^{-128}$.

3. **Proof Size**: A proof for a tree with $n$ leaves requires $\log_2(n)$ hash values, making proofs compact and efficient to verify.

#### 7.4.2 Security Model

The security model assumes:

- The Pedersen hash function is collision-resistant
- The attester registry correctly verifies attesters
- Attesters maintain the secrecy of their private keys
- The chain maintains integrity of published roots

Under these assumptions, the probability of successfully forging a proof for a leaf not in a tree is negligible.

## 8. Performance Optimization

### 8.1 Tree Construction Optimization

#### 8.1.1 Batch Tree Building

For large trees, batch construction is more efficient:

```cairo
fn build_tree_optimized(leaves: Array<felt252>) -> felt252 {
    // Handle base cases
    let leaf_count = leaves.len();
    if leaf_count == 0 {
        return 0;
    }
    if leaf_count == 1 {
        return *leaves.at(0);
    }

    // Calculate tree parameters
    let next_power_of_two = next_pow2(leaf_count);

    // Allocate space for the entire tree
    let mut tree_size = 2 * next_power_of_two - 1;
    let mut tree: Array<felt252> = ArrayTrait::new();

    // Initialize array with zeros
    let mut i: u32 = 0;
    while i < tree_size {
        tree.append(0);
        i += 1;
    }

    // Copy leaves to the tree
    i = 0;
    while i < leaf_count {
        tree.set(next_power_of_two - 1 + i, *leaves.at(i));
        i += 1;
    }

    // Fill remaining leaves with zeros
    while i < next_power_of_two {
        tree.set(next_power_of_two - 1 + i, 0);
        i += 1;
    }

    // Build tree from bottom up
    i = next_power_of_two - 2;
    loop {
        if i >= tree_size {
            break;
        }

        let left_child = *tree.at(2 * i + 1);
        let right_child = *tree.at(2 * i + 2);
        tree.set(i, pedersen_hash(left_child, right_child));

        if i == 0 {
            break;
        }
        i -= 1;
    }

    // Return root
    return *tree.at(0);
}

// Helper for next power of 2
fn next_pow2(x: u32) -> u32 {
    let mut v = x;
    v -= 1;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v += 1;
    return v;
}
```

#### 8.1.2 Incremental Updates

For trees that change frequently, incremental updates are more efficient:

```cairo
fn update_leaf(
    ref tree: Array<felt252>,
    leaf_index: u32,
    new_value: felt252,
    leaf_count: u32,
) -> felt252 {
    // Calculate tree parameters
    let next_power_of_two = next_pow2(leaf_count);
    let tree_size = 2 * next_power_of_two - 1;

    // Update leaf
    let node_index = next_power_of_two - 1 + leaf_index;
    tree.set(node_index, new_value);

    // Update path to root
    let mut current = (node_index - 1) / 2;
    while current < tree_size {
        let left_child = 2 * current + 1;
        let right_child = 2 * current + 2;

        tree.set(current, pedersen_hash(*tree.at(left_child), *tree.at(right_child)));

        if current == 0 {
            break;
        }
        current = (current - 1) / 2;
    }

    // Return new root
    return *tree.at(0);
}
```

### 8.2 Proof Generation Optimization

#### 8.2.1 Pre-Computing Tree Nodes

Storing intermediate nodes for efficient proof generation:

```cairo
// Example of optimized proof generation with precomputed tree
fn generate_proof_optimized(
    tree: Array<felt252>,
    leaf_index: u32,
    leaf_count: u32,
) -> MerkleProof {
    // Calculate tree parameters
    let next_power_of_two = next_pow2(leaf_count);
    let node_index = next_power_of_two - 1 + leaf_index;

    // Get leaf value
    let leaf = *tree.at(node_index);

    // Generate proof
    let mut path: Array<(felt252, bool)> = ArrayTrait::new();
    let mut current = node_index;

    while current > 0 {
        // Determine if node is left or right child
        let is_right = current % 2 == 1;

        // Get sibling index
        let sibling = if is_right { current - 1 } else { current + 1 };

        // Get sibling value
        let sibling_value = *tree.at(sibling);

        // Add to proof (sibling, is_sibling_left)
        path.append((sibling_value, !is_right));

        // Move to parent
        current = (current - 1) / 2;
    }

    return MerkleProof { leaf: leaf, path: path };
}
```

#### 8.2.2 Multi-Proof Optimization

For generating proofs for multiple leaves efficiently:

```cairo
fn generate_multi_proof(
    tree: Array<felt252>,
    indices: Array<u32>,
    leaf_count: u32,
) -> MultiProof {
    // Calculate tree parameters
    let next_power_of_two = next_pow2(leaf_count);

    // Collect leaf values
    let mut leaves: Array<felt252> = ArrayTrait::new();
    let mut i: u32 = 0;
    while i < indices.len() {
        let node_index = next_power_of_two - 1 + *indices.at(i);
        leaves.append(*tree.at(node_index));
        i += 1;
    }

    // Track nodes that need to be included in the proof
    let mut required_nodes: Array<u32> = ArrayTrait::new();
    let mut proof_nodes: Array<u32> = ArrayTrait::new();

    // Start with leaf nodes
    i = 0;
    while i < indices.len() {
        let node_index = next_power_of_two - 1 + *indices.at(i);
        required_nodes.append(node_index);
        i += 1;
    }

    // Process level by level
    let mut current_level_size = next_power_of_two;
    while current_level_size > 1 {
        let mut next_required: Array<u32> = ArrayTrait::new();
        let mut j: u32 = 0;

        while j < required_nodes.len() {
            let node = *required_nodes.at(j);

            // Get sibling
            let is_right = node % 2 == 1;
            let sibling = if is_right { node - 1 } else { node + 1 };

            // If sibling is not in required nodes, add to proof
            if !array_contains(required_nodes, sibling) {
                proof_nodes.append(sibling);
            }

            // Add parent to next level's required nodes
            let parent = (node - 1) / 2;
            if !array_contains(next_required, parent) {
                next_required.append(parent);
            }

            j += 1;
        }

        // Move to next level
        required_nodes = next_required;
        current_level_size = current_level_size / 2;
    }

    // Extract sibling values
    let mut siblings: Array<felt252> = ArrayTrait::new();
    i = 0;
    while i < proof_nodes.len() {
        siblings.append(*tree.at(*proof_nodes.at(i)));
        i += 1;
    }

    return MultiProof {
        leaves: leaves,
        indices: indices,
        siblings: siblings
    };
}

// Helper to check if array contains a value
fn array_contains(arr: Array<u32>, value: u32) -> bool {
    let mut i: u32 = 0;
    while i < arr.len() {
        if *arr.at(i) == value {
            return true;
        }
        i += 1;
    }
    return false;
}
```

### 8.3 Verification Optimization

#### 8.3.1 Gas-Optimized Verification

Optimizing the verification process for StarkNet:

```cairo
// Gas-optimized verification
fn verify_merkle_proof_optimized(
    root: felt252,
    leaf: felt252,
    siblings: Array<felt252>,
    path_directions: Array<bool>,
) -> bool {
    // Check input validity
    assert(siblings.len() == path_directions.len(), 'Input length mismatch');

    // Start from the leaf
    let mut computed_node = leaf;

    // Traverse the path
    let mut i: u32 = 0;
    while i < siblings.len() {
        let sibling = *siblings.at(i);
        let is_left = *path_directions.at(i);

        // Compute parent based on direction
        if is_left {
            // Sibling is left
            computed_node = pedersen_hash(sibling, computed_node);
        } else {
            // Sibling is right
            computed_node = pedersen_hash(computed_node, sibling);
        }

        i += 1;
    }

    // Check if computed root matches expected root
    return computed_node == root;
}
```

#### 8.3.2 Batch Verification

For verifying multiple proofs in a single transaction:

```cairo
fn verify_merkle_proofs_batch(
    root: felt252,
    leaves: Array<felt252>,
    siblings_batch: Array<Array<felt252>>,
    path_directions_batch: Array<Array<bool>>,
) -> Array<bool> {
    let mut results: Array<bool> = ArrayTrait::new();

    // Verify each proof
    let mut i: u32 = 0;
    while i < leaves.len() {
        let is_valid = verify_merkle_proof_optimized(
            root,
            *leaves.at(i),
            *siblings_batch.at(i),
            *path_directions_batch.at(i)
        );

        results.append(is_valid);
        i += 1;
    }

    return results;
}
```

### 8.4 Storage Optimization

#### 8.4.1 Pruned Trees

For large trees, storing a pruned representation can save space:

```cairo
#[derive(Drop, Serde)]
struct PrunedMerkleTree {
    root: felt252,
    known_nodes: LegacyMap::<u32, felt252>,  // Map of position to node value
}

fn store_pruned_tree(
    full_tree: Array<felt252>,
    important_indices: Array<u32>,
) -> PrunedMerkleTree {
    // Create pruned tree with the root
    let mut pruned = PrunedMerkleTree {
        root: *full_tree.at(0),
        known_nodes: LegacyMap::new(),
    };

    // Start with leaf indices
    let mut required_nodes: Array<u32> = important_indices;

    // Process all required nodes
    let mut i: u32 = 0;
    while i < required_nodes.len() {
        let node_index = *required_nodes.at(i);

        // Store this node
        pruned.known_nodes.write(node_index, *full_tree.at(node_index));

        // Add parent to required nodes if not already there
        if node_index > 0 {
            let parent = (node_index - 1) / 2;
            if !array_contains(required_nodes, parent) {
                required_nodes.append(parent);
            }
        }

        // Add sibling to required nodes
        let is_right = node_index % 2 == 1;
        let sibling = if is_right { node_index - 1 } else { node_index + 1 };
        if !array_contains(required_nodes, sibling) && sibling < full_tree.len() {
            pruned.known_nodes.write(sibling, *full_tree.at(sibling));
        }

        i += 1;
    }

    return pruned;
}
```

#### 8.4.2 Sparse Storage

For sparse Merkle trees, only storing non-default nodes:

```cairo
#[derive(Drop, Serde)]
struct SparseMerkleStorage {
    root: felt252,
    non_empty_leaves: LegacyMap::<felt252, felt252>,  // Map key to value
    default_nodes: Array<felt252>,  // Default nodes at each level
}

fn update_sparse_tree(
    ref tree: SparseMerkleStorage,
    key: felt252,
    value: felt252,
    proof: Array<felt252>,
) -> felt252 {
    let depth = proof.len();

    // If value is default, remove from storage
    if value == tree.default_nodes.at(0) {
        tree.non_empty_leaves.write(key, 0);
    } else {
        // Store non-default value
        tree.non_empty_leaves.write(key, value);
    }

    // Compute new root with updated value
    let mut current_value = value;
    let key_bits = get_bits(key, depth.try_into().unwrap());

    // Trace path to the root
    let mut i: u32 = 0;
    while i < depth {
        let sibling = *proof.at(i);
        let path_bit = *key_bits.at(i);

        // Compute parent based on path direction
        if path_bit {
            current_value = pedersen_hash(sibling, current_value);
        } else {
            current_value = pedersen_hash(current_value, sibling);
        }

        i += 1;
    }

    // Update root
    tree.root = current_value;

    return current_value;
}
```

#### 8.4.3 Commitment-Based Storage

Using commitments to represent large trees:

```cairo
#[derive(Drop, Serde)]
struct MerkleCommitment {
    root: felt252,                     // Tree root
    total_leaves: u32,                 // Number of leaves
    metadata_commitment: felt252,      // Commitment to additional metadata
}

fn create_commitment(
    leaves: Array<felt252>,
    metadata: felt252,
) -> MerkleCommitment {
    // Compute the tree root
    let root = build_tree(leaves);

    // Create commitment
    return MerkleCommitment {
        root: root,
        total_leaves: leaves.len(),
        metadata_commitment: pedersen_hash(root, metadata),
    };
}
```

## 9. Testing and Verification

### 9.1 Unit Testing

The Merkle tree implementation includes comprehensive unit tests:

```cairo
// Example unit tests for Merkle tree implementation
#[test]
fn test_empty_tree() {
    // Empty tree should have predefined root
    let root = build_tree(ArrayTrait::new());
    assert(root == 0, 'Empty tree root incorrect');
}

#[test]
fn test_single_leaf_tree() {
    // Single leaf tree should have root equal to the leaf
    let leaves = array![0x123];
    let root = build_tree(leaves);
    assert(root == 0x123, 'Single leaf root incorrect');
}

#[test]
fn test_two_leaf_tree() {
    // Two leaf tree
    let leaves = array![0x123, 0x456];
    let root = build_tree(leaves);
    let expected = pedersen_hash(0x123, 0x456);
    assert(root == expected, 'Two leaf root incorrect');
}

#[test]
fn test_proof_verification() {
    // Create a tree with multiple leaves
    let leaves = array![0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8];
    let root = build_tree(leaves);

    // Generate proof for leaf at index 3
    let proof = generate_proof(leaves, 3);

    // Verify the proof
    let is_valid = verify_merkle_proof(root, proof);
    assert(is_valid, 'Valid proof rejected');

    // Modify leaf and verify proof fails
    let invalid_proof = MerkleProof {
        leaf: 0x9,  // Wrong leaf
        path: proof.path
    };
    let is_valid = verify_merkle_proof(root, invalid_proof);
    assert(!is_valid, 'Invalid proof accepted');
}

#[test]
fn test_sparse_merkle_tree() {
    // Create sparse Merkle tree
    let tree = SparseMerkleLib::constructor(20);  // 20-level tree

    // Insert some key-value pairs
    let key1 = 0x123;
    let value1 = 0x456;
    let key2 = 0x789;
    let value2 = 0xabc;

    // Update tree with first pair
    let proof1 = generate_empty_proof(20);
    let root1 = tree.update_sparse_tree(key1, value1, proof1);

    // Generate proof for key1
    let proof2 = generate_proof_for_key(tree, key1);

    // Verify proof for key1
    let is_valid = tree.verify_sparse_proof(root1, key1, value1, proof2);
    assert(is_valid, 'Valid sparse proof rejected');

    // Update tree with second pair
    let root2 = tree.update_sparse_tree(key2, value2, generate_proof_for_key(tree, key2));

    // Verify both keys
    assert(
        tree.verify_sparse_proof(root2, key1, value1, generate_proof_for_key(tree, key1)),
        'Key1 verification failed after update'
    );
    assert(
        tree.verify_sparse_proof(root2, key2, value2, generate_proof_for_key(tree, key2)),
        'Key2 verification failed'
    );
}
```

### 9.2 Integration Testing

Integration tests verify the Merkle tree system works with other components:

```cairo
// Example integration test with Attestation Registry
#[test]
fn test_attestation_registry_integration() {
    // Set up test environment
    let (mut state, contracts, addresses) = setup_test_environment();

    // Create test attestation batch
    let credentials = create_test_credentials(10);
    let leaves = compute_credential_leaves(credentials);

    // Build Merkle tree
    let root = build_tree(leaves);

    // Register attestation in registry
    register_tier1_attestation(
        ref state,
        contracts,
        addresses.attester,
        ATTESTATION_TYPE_KYC,
        root
    );

    // Generate proof for a credential
    let proof = generate_proof(leaves, 3);

    // Verify attestation using registry
    let is_valid = verify_tier1_attestation(
        state,
        contracts,
        addresses.attester,
        ATTESTATION_TYPE_KYC,
        leaves[3],
        proof
    );

    assert(is_valid, 'Attestation verification failed');
}

// Example integration test with ZK Verifier
#[test]
fn test_zk_verifier_integration() {
    // Set up test environment
    let (mut state, contracts, addresses) = setup_test_environment();

    // Create test credentials and Merkle tree
    let credentials = create_test_credentials(5);
    let leaves = compute_credential_leaves(credentials);
    let root = build_tree(leaves);

    // Register attestation
    register_tier1_attestation(
        ref state,
        contracts,
        addresses.attester,
        ATTESTATION_TYPE_KYC,
        root
    );

    // Generate ZK proof for credential inclusion
    let credential_index = 2;
    let merkle_proof = generate_proof(leaves, credential_index);
    let zk_proof = generate_credential_zk_proof(
        credentials[credential_index],
        merkle_proof,
        addresses.attester,
        ATTESTATION_TYPE_KYC
    );

    // Verify ZK proof
    let is_valid = verify_credential_proof(
        state,
        contracts,
        zk_proof.proof,
        zk_proof.public_inputs
    );

    assert(is_valid, 'ZK credential verification failed');
}
```

### 9.3 Property-Based Testing

Property-based tests verify the Merkle tree implementation satisfies key invariants:

```cairo
// Example property-based test for Merkle trees
#[test]
property test_merkle_tree_commutativity(leaves: Array<felt252>) {
    // Verify that shuffling leaves produces a different root
    let root1 = build_tree(leaves);

    // Create shuffled copy
    let mut shuffled = leaves.clone();
    shuffle_array(ref shuffled);

    // Verify roots are different for different leaf orders
    let root2 = build_tree(shuffled);
    assert(
        leaves.len() <= 1 || root1 != root2,
        'Tree should depend on leaf order'
    );
}

#[test]
property test_proof_for_all_leaves(leaves: Array<felt252>) {
    // Skip empty trees
    if leaves.len() == 0 {
        return;
    }

    // Build the tree
    let root = build_tree(leaves);

    // Test proof for each leaf
    let mut i: u32 = 0;
    while i < leaves.len() {
        let proof = generate_proof(leaves, i);
        let is_valid = verify_merkle_proof(root, proof);
        assert(is_valid, 'Proof invalid for leaf {i}');
        i += 1;
    }
}

#[test]
property test_tree_determinism(
    leaves1: Array<felt252>,
    leaves2: Array<felt252>
) {
    // Verify that identical leaf sets produce identical roots
    if array_equals(leaves1, leaves2) {
        let root1 = build_tree(leaves1);
        let root2 = build_tree(leaves2);
        assert(root1 == root2, 'Identical leaves should produce same root');
    }
}
```

### 9.4 Benchmarking

Performance benchmarks for the Merkle tree implementation:

```cairo
// Example benchmarking function
#[test]
fn benchmark_tree_construction() {
    // Benchmark different tree sizes
    let sizes = array![10, 100, 1000, 10000];

    let mut i: u32 = 0;
    while i < sizes.len() {
        let size = *sizes.at(i);

        // Generate test leaves
        let leaves = generate_test_leaves(size);

        // Measure construction time
        let start_time = get_block_timestamp();
        let root = build_tree(leaves);
        let end_time = get_block_timestamp();

        println("Tree size: {}, Construction time: {} ms", size, end_time - start_time);

        i += 1;
    }
}
```

## 10. Appendices

### 10.1 Standard Test Vectors

To ensure consistent implementation and testing, Veridis defines standard test vectors:

```cairo
// Standard Merkle tree test vectors
struct MerkleTestVector {
    leaves: Array<felt252>,
    expected_root: felt252,
    test_leaf_index: u32,
    expected_proof: Array<(felt252, bool)>,
}

// Standard test vectors
const TEST_VECTOR_1: MerkleTestVector = MerkleTestVector {
    leaves: array![0x1, 0x2, 0x3, 0x4],
    expected_root: 0x11AE53a2D2923EB2Fdd7C22B75e045A5D44A12E2e2D5EC34FDB19E5F42E98912,
    test_leaf_index: 2,
    expected_proof: array![
        (0x4, false),
        (0x76B7ED1D52E94F9ED482EA38228F057F3E40C47F47530823B7AE498C1A91CF51, true)
    ],
};

const TEST_VECTOR_2: MerkleTestVector = MerkleTestVector {
    leaves: array![0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x10, 0x11],
    expected_root: 0x2C5F3A9A67BE22Ecaf9A0811FB1F2CB81A1A4808A8Bc793Ecb9CCB0A6Ecf6C75,
    test_leaf_index: 5,
    expected_proof: array![
        (0x10, false),
        (0x6A3AB685263DF8C231C36538C9BB7EDC32D1BDE70F548630952EB2CBD733789A, true),
        (0x88FC12A6Eb5F16Fb673F5Eb0218FC20089D2B9A9B65Fa2F3526B26539d2E3B8E, true)
    ],
};
```

### 10.2 Merkle Tree Variants

The Veridis protocol supports several Merkle tree variants for different use cases:

| Variant         | Description                                | Primary Application          |
| --------------- | ------------------------------------------ | ---------------------------- |
| Standard Binary | Traditional binary Merkle tree             | Attestation batches          |
| Sparse          | Efficient for trees with many empty leaves | Mapping-style storage        |
| Incremental     | Optimized for growing trees                | Nullifier sets               |
| Sorted          | Leaves are sorted before tree construction | Order-independent proofs     |
| Compact         | Reduced proof size through optimization    | Mobile-friendly verification |
| Multi-Proof     | Efficient proofs for multiple leaves       | Batch verification           |

### 10.3 Integration Examples

#### 10.3.1 Attestation Issuance Example

```cairo
// Example of issuing attestations using Merkle trees
fn issue_batch_attestations(
    attestation_type: u256,
    subjects: Array<felt252>,
    data: Array<felt252>,
    expiration_time: u64,
) -> felt252 {
    // Create leaves from attestation data
    let mut leaves: Array<felt252> = ArrayTrait::new();
    let mut i: u32 = 0;

    // Generate random nonce for this batch
    let batch_nonce = generate_random_nonce();

    while i < subjects.len() {
        // Create leaf for each attestation
        let leaf = compute_attestation_leaf(
            attestation_type,
            *subjects.at(i),
            *data.at(i),
            batch_nonce,
            expiration_time
        );

        leaves.append(leaf);
        i += 1;
    }

    // Build Merkle tree
    let root = build_tree(leaves);

    // Register root in attestation registry
    attestation_registry.issue_tier1_attestation(
        attestation_type,
        root,
        expiration_time,
        get_schema_uri(attestation_type)
    );

    // Store full tree data off-chain (implementation-specific)
    store_tree_data_off_chain(root, leaves, subjects, data);

    return root;
}
```

#### 10.3.2 Proof Generation for User Example

```cairo
// Example of generating a proof for a specific user
fn generate_proof_for_user(
    attestation_root: felt252,
    user_identity: felt252,
    attestation_type: u256,
) -> MerkleProof {
    // Look up the tree data (implementation-specific)
    let tree_data = load_tree_data(attestation_root);

    // Find the leaf index for this user
    let mut leaf_index: Option<u32> = None;
    let mut i: u32 = 0;

    while i < tree_data.subjects.len() {
        if *tree_data.subjects.at(i) == user_identity {
            leaf_index = Option::Some(i);
            break;
        }
        i += 1;
    }

    assert(leaf_index.is_some(), 'User not in attestation batch');

    // Generate Merkle proof
    return generate_proof(tree_data.leaves, leaf_index.unwrap());
}
```

#### 10.3.3 ZK Circuit Integration Example

```cairo
// Example ZK circuit for Merkle proof verification
fn merkle_proof_circuit(
    // Private inputs
    leaf: felt252,
    path: Array<(felt252, bool)>,

    // Public inputs
    root: felt252,
) {
    // Recompute the root
    let mut current = leaf;

    for i in 0..path.len() {
        let (sibling, is_left) = path[i];

        // Compute parent
        if is_left {
            // Sibling is on the left
            current = poseidon_hash(sibling, current);
        } else {
            // Sibling is on the right
            current = poseidon_hash(current, sibling);
        }
    }

    // Constrain computed root to match public input
    constrain current = root;
}
```

### 10.4 Recommended Parameters

Recommended parameters for Merkle tree implementation in different scenarios:

| Use Case                       | Tree Depth | Node Count | Type        | Optimization                          |
| ------------------------------ | ---------- | ---------- | ----------- | ------------------------------------- |
| Small Attestation Batch (<100) | 7-10       | <1,000     | Standard    | In-memory full tree                   |
| Medium Batch (100-10,000)      | 14-20      | <1M        | Standard    | Pruned storage                        |
| Large Batch (>10,000)          | 20-30      | >1M        | Incremental | Off-chain storage with indexed lookup |
| Mapping-Style Storage          | 160-256    | Sparse     | Sparse      | Default node optimization             |
| Nullifier Registry             | Growing    | Unlimited  | Incremental | Append-only optimization              |
| Cross-Chain Verification       | <20        | <1M        | Standard    | Optimized for proof size              |

---

## Document Metadata

**Document ID:** VERIDIS-SPEC-MRK-2025-001
**Version:** 1.0
**Date:** 2025-05-08
**Authors:** Cass402 and the Veridis Engineering Team
**Last Edit:** 2025-05-08 10:42:29 UTC by Cass402

**Classification:** Internal Technical Documentation
**Distribution:** Veridis Engineering, Auditors, Technical Partners

**Document End**
