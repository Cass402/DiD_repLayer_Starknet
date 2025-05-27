# Veridis: Cairo Optimization Patterns

**Technical Documentation v1.0**  
**May 27, 2025**

**Authors:**  
Cass402 and the Veridis Engineering Team

---

## Document Control

| Version | Date       | Author            | Changes                      |
| ------- | ---------- | ----------------- | ---------------------------- |
| 0.1     | 2025-05-01 | Optimization Team | Initial draft                |
| 0.2     | 2025-05-12 | Performance Team  | Added benchmark results      |
| 0.3     | 2025-05-20 | Security Team     | Security review feedback     |
| 1.0     | 2025-05-27 | Cass402           | Final review and publication |

**Classification:** Internal Technical Documentation  
**Distribution:** Veridis Engineering, Auditors, Technical Partners

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Memory and Storage Optimization](#2-memory-and-storage-optimization)
3. [Computation Optimization](#3-computation-optimization)
4. [Gas Optimization Techniques](#4-gas-optimization-techniques)
5. [Loop Optimization](#5-loop-optimization)
6. [Advanced Optimization Patterns](#6-advanced-optimization-patterns)
7. [Testing and Benchmarking](#7-testing-and-benchmarking)
8. [Common Anti-Patterns](#8-common-anti-patterns)
9. [Appendices](#9-appendices)

---

## 1. Introduction

### 1.1 Purpose and Scope

This document provides a comprehensive guide to optimization patterns for Cairo smart contracts in the Veridis protocol. It details techniques for improving performance, reducing gas costs, and optimizing storage in Cairo, with a focus on the specific requirements of privacy-preserving identity and attestation systems.

The techniques described in this document have been tested and validated in the Veridis production environment, and represent the current best practices for Cairo optimization as of May 2025.

### 1.2 Cairo Optimization Principles

Cairo optimization follows these core principles:

1. **Storage Efficiency**: Minimize the number and size of storage operations
2. **Computational Efficiency**: Reduce the number and complexity of operations
3. **Memory Management**: Optimize memory usage and access patterns
4. **Gas Optimization**: Minimize transaction costs for users
5. **Readability vs. Optimization**: Balance code clarity with performance
6. **Security**: Never sacrifice security for optimization

### 1.3 Performance Metrics

When optimizing Cairo contracts, we focus on the following key metrics:

1. **Gas Cost**: The computational cost of executing functions
2. **Storage Slots**: The number of storage slots used
3. **Execution Steps**: The number of Cairo VM steps required
4. **Transaction Size**: The size of the transaction data
5. **Memory Footprint**: The amount of memory used during execution

## 2. Memory and Storage Optimization

### 2.1 Storage Layout Optimization

#### 2.1.1 Packing Variables

Cairo allows packing multiple values into a single felt252 for storage efficiency:

```cairo
// Inefficient storage layout
#[storage]
struct Storage {
    is_active: bool,         // 1 bit stored in 1 felt252
    user_type: u8,           // 8 bits stored in 1 felt252
    creation_time: u64,      // 64 bits stored in 1 felt252
    // Each uses a full storage slot
}

// Optimized storage layout
#[storage]
struct Storage {
    packed_data: felt252,    // Packs multiple values in 1 felt252
}

// Bitwise operations to pack/unpack
fn pack_data(is_active: bool, user_type: u8, creation_time: u64) -> felt252 {
    let mut result: felt252 = 0;

    // Pack is_active into bit 0
    if is_active {
        result += 1;
    }

    // Pack user_type into bits 1-8
    result += (user_type.into() << 1);

    // Pack creation_time into bits 9-72
    result += (creation_time.into() << 9);

    return result;
}

fn unpack_is_active(packed_data: felt252) -> bool {
    return (packed_data & 1) != 0;
}

fn unpack_user_type(packed_data: felt252) -> u8 {
    return ((packed_data >> 1) & 0xFF).try_into().unwrap();
}

fn unpack_creation_time(packed_data: felt252) -> u64 {
    return ((packed_data >> 9) & 0xFFFFFFFFFFFFFFFF).try_into().unwrap();
}
```

`````

#### 2.1.2 Strategic Storage Layout

Organize storage to optimize for most frequent access patterns:

```cairo
// Before optimization: Random storage layout
#[storage]
struct Storage {
    identities: LegacyMap::<u256, Identity>,
    identity_count: u256,
    identity_owners: LegacyMap::<ContractAddress, u256>,
    active_identities: LegacyMap::<u256, bool>,
    // Other fields...
}

// After optimization: Grouped by access pattern
#[storage]
struct Storage {
    // Core identity data (frequently accessed together)
    identities: LegacyMap::<u256, Identity>,
    identity_owners: LegacyMap::<ContractAddress, u256>,

    // Metadata (less frequently accessed)
    identity_count: u256,
    active_identities: LegacyMap::<u256, bool>,

    // Rarely accessed administrative data
    admin: ContractAddress,
    paused: bool,
}
```

#### 2.1.3 Storage Slot Reuse

Reuse storage slots for mutually exclusive states:

```cairo
// Inefficient: Separate storage for different states
#[storage]
struct Storage {
    pending_attestations: LegacyMap::<u256, PendingAttestation>,
    active_attestations: LegacyMap::<u256, ActiveAttestation>,
    revoked_attestations: LegacyMap::<u256, RevokedAttestation>,
}

// Optimized: Single storage with type tag
#[storage]
struct Storage {
    attestations: LegacyMap::<u256, AttestationData>,
    attestation_states: LegacyMap::<u256, u8>, // 1=pending, 2=active, 3=revoked
}

// Access based on state
fn get_attestation_data(ref self: ContractState, id: u256) -> AttestationData {
    let state = self.attestation_states.read(id);
    let data = self.attestations.read(id);

    assert(state != 0, 'Attestation not found');

    return data;
}
```

### 2.2 Memory Management Techniques

#### 2.2.1 Array Reuse

Reuse arrays to avoid unnecessary allocations:

```cairo
// Inefficient: Creating new arrays repeatedly
fn process_values(values: Array<felt252>) -> Array<felt252> {
    // Create new array for intermediate results
    let mut intermediate: Array<felt252> = ArrayTrait::new();

    // Process values
    let mut i: u32 = 0;
    loop {
        if i >= values.len() {
            break;
        }

        let processed = process_value(*values.at(i));
        intermediate.append(processed);

        i += 1;
    }

    // Create another new array for final results
    let mut results: Array<felt252> = ArrayTrait::new();

    i = 0;
    loop {
        if i >= intermediate.len() {
            break;
        }

        let final_value = finalize_value(*intermediate.at(i));
        results.append(final_value);

        i += 1;
    }

    return results;
}

// Optimized: Reusing the original array
fn process_values_optimized(ref values: Array<felt252>) {
    let mut i: u32 = 0;
    loop {
        if i >= values.len() {
            break;
        }

        // Process in-place
        let processed = process_value(*values.at(i));
        let final_value = finalize_value(processed);

        // Update original array
        values.set(i, final_value);

        i += 1;
    }

    // Original array now contains the results
}
```

#### 2.2.2 Snapshot Pattern

Use snapshots for efficient array manipulation:

```cairo
// Using the snapshot pattern to avoid copying arrays
fn process_array_segment(array: @Array<felt252>, start: u32, end: u32) -> felt252 {
    // Take a snapshot instead of copying
    let mut sum: felt252 = 0;
    let mut i: u32 = start;

    loop {
        if i >= end || i >= array.len() {
            break;
        }

        sum += *array.at(i);
        i += 1;
    }

    return sum;
}

// Usage:
fn main() {
    let mut data: Array<felt252> = ArrayTrait::new();
    // ... populate data ...

    // Take a snapshot to pass to the function
    let sum_first_half = process_array_segment(@data, 0, data.len() / 2);
    let sum_second_half = process_array_segment(@data, data.len() / 2, data.len());

    // No array copies were needed
}
```

#### 2.2.3 In-Place Updates

Update arrays in-place when possible:

```cairo
// Before: Creating new array for results
fn increment_all(values: Array<felt252>) -> Array<felt252> {
    let mut results: Array<felt252> = ArrayTrait::new();
    let mut i: u32 = 0;

    loop {
        if i >= values.len() {
            break;
        }

        results.append(*values.at(i) + 1);
        i += 1;
    }

    return results;
}

// After: Modifying array in-place
fn increment_all_inplace(ref values: Array<felt252>) {
    let mut i: u32 = 0;

    loop {
        if i >= values.len() {
            break;
        }

        values.set(i, *values.at(i) + 1);
        i += 1;
    }
}
```

## 3. Computation Optimization

### 3.1 Efficient Math Operations

#### 3.1.1 Bit Shifting vs. Multiplication/Division

Use bit shifting for powers of 2:

```cairo
// Inefficient: Using multiplication/division
fn compute_value(x: u64) -> u64 {
    // Multiply by 8
    let a = x * 8;

    // Divide by 16
    let b = x / 16;

    // Multiply by 2
    let c = x * 2;

    return a + b + c;
}

// Optimized: Using bit shifts
fn compute_value_optimized(x: u64) -> u64 {
    // Multiply by 8 using left shift by 3
    let a = x << 3;

    // Divide by 16 using right shift by 4
    let b = x >> 4;

    // Multiply by 2 using left shift by 1
    let c = x << 1;

    return a + b + c;
}
```

#### 3.1.2 Replacing Expensive Operations

Optimize expensive operations:

```cairo
// Inefficient: Using modulo operations
fn is_even(x: u64) -> bool {
    return x % 2 == 0;
}

// Optimized: Using bitwise AND
fn is_even_optimized(x: u64) -> bool {
    return (x & 1) == 0;
}

// Inefficient: Using power function
fn compute_power_of_2(exponent: u8) -> u64 {
    return pow(2, exponent.into());
}

// Optimized: Using bit shifting
fn compute_power_of_2_optimized(exponent: u8) -> u64 {
    return 1_u64 << exponent;
}
```

#### 3.1.3 Lookup Tables for Complex Calculations

Use lookup tables for complex but fixed calculations:

```cairo
// Inefficient: Computing values repeatedly
fn get_weight(category: u8) -> u64 {
    if category == 1 {
        return 1000;
    } else if category == 2 {
        return 2500;
    } else if category == 3 {
        return 4000;
    } else if category == 4 {
        return 5500;
    } else if category == 5 {
        return 8000;
    } else {
        return 1000; // Default
    }
}

// Optimized: Using a lookup table
fn get_weight_optimized(category: u8) -> u64 {
    // Define lookup table
    let weights: Array<u64> = array![1000, 2500, 4000, 5500, 8000];

    // Check bounds and return value
    if category == 0 || category > weights.len().try_into().unwrap() {
        return 1000; // Default
    }

    return *weights.at((category - 1).into());
}
```

### 3.2 Avoiding Redundant Computations

#### 3.2.1 Caching Intermediate Results

Cache results of expensive operations:

```cairo
// Inefficient: Recomputing the same value
fn process_credential(
    ref self: ContractState,
    credential_id: u256,
    data: Array<felt252>
) -> felt252 {
    // Expensive operation called multiple times
    let credential = self.get_credential_by_id(credential_id);

    if !self.is_credential_valid(credential_id) {
        return 0;
    }

    let result = self.compute_credential_hash(credential_id, data);

    if self.should_store_result(credential_id) {
        self.store_result(credential_id, result);
    }

    return result;
}

// Optimized: Caching the credential
fn process_credential_optimized(
    ref self: ContractState,
    credential_id: u256,
    data: Array<felt252>
) -> felt252 {
    // Call expensive operation once and cache the result
    let credential = self.get_credential_by_id(credential_id);

    if !self.is_credential_valid_internal(credential) {
        return 0;
    }

    let result = self.compute_credential_hash_internal(credential, data);

    if self.should_store_result_internal(credential) {
        self.store_result(credential_id, result);
    }

    return result;
}
```

#### 3.2.2 Lazy Evaluation

Compute values only when needed:

```cairo
// Inefficient: Computing values eagerly
fn validate_attestation(
    ref self: ContractState,
    attestation_id: u256
) -> bool {
    // Compute all validations upfront
    let is_registered = self.check_attestation_registered(attestation_id);
    let is_not_expired = self.check_attestation_not_expired(attestation_id);
    let is_not_revoked = self.check_attestation_not_revoked(attestation_id);
    let has_valid_signature = self.check_attestation_signature(attestation_id);

    // Return combined result
    return is_registered && is_not_expired && is_not_revoked && has_valid_signature;
}

// Optimized: Using lazy evaluation
fn validate_attestation_optimized(
    ref self: ContractState,
    attestation_id: u256
) -> bool {
    // Check conditions in order of increasing computation cost
    // Return early on failure

    if !self.check_attestation_registered(attestation_id) {
        return false;
    }

    if !self.check_attestation_not_revoked(attestation_id) {
        return false;
    }

    if !self.check_attestation_not_expired(attestation_id) {
        return false;
    }

    // Only check signature if all other validations pass
    return self.check_attestation_signature(attestation_id);
}
```

#### 3.2.3 Precalculating Constants

Precalculate constants rather than computing them repeatedly:

```cairo
// Inefficient: Recalculating constants
fn calculate_time_window(ref self: ContractState, period_days: u64) -> u64 {
    // Convert days to seconds every time
    return period_days * 24 * 60 * 60;
}

// Optimized: Using precalculated constants
const SECONDS_PER_DAY: u64 = 86400; // 24 * 60 * 60

fn calculate_time_window_optimized(ref self: ContractState, period_days: u64) -> u64 {
    return period_days * SECONDS_PER_DAY;
}
```

### 3.3 Function Call Optimization

#### 3.3.1 Internal vs. External Calls

Use internal functions when possible:

```cairo
// Inefficient: Using external calls for internal logic
#[external(v0)]
fn process_attestation(ref self: ContractState, attestation_id: u256) -> bool {
    if self.is_valid_attestation(attestation_id) {
        self.mark_attestation_processed(attestation_id);
        return true;
    }
    return false;
}

#[external(v0)]
fn is_valid_attestation(self: @ContractState, attestation_id: u256) -> bool {
    // Validation logic
    let attestation = self.attestations.read(attestation_id);
    return attestation.expiration_time > get_block_timestamp() && !attestation.revoked;
}

#[external(v0)]
fn mark_attestation_processed(ref self: ContractState, attestation_id: u256) {
    // Processing logic
    let mut attestation = self.attestations.read(attestation_id);
    attestation.processed = true;
    self.attestations.write(attestation_id, attestation);
}

// Optimized: Using internal functions
#[external(v0)]
fn process_attestation_optimized(ref self: ContractState, attestation_id: u256) -> bool {
    if self.is_valid_attestation_internal(attestation_id) {
        self.mark_attestation_processed_internal(attestation_id);
        return true;
    }
    return false;
}

// Internal function (not accessible externally)
fn is_valid_attestation_internal(self: @ContractState, attestation_id: u256) -> bool {
    // Same validation logic, but internal
    let attestation = self.attestations.read(attestation_id);
    return attestation.expiration_time > get_block_timestamp() && !attestation.revoked;
}

// Internal function (not accessible externally)
fn mark_attestation_processed_internal(ref self: ContractState, attestation_id: u256) {
    // Same processing logic, but internal
    let mut attestation = self.attestations.read(attestation_id);
    attestation.processed = true;
    self.attestations.write(attestation_id, attestation);
}
```

#### 3.3.2 Function Inlining

Inline small, frequently called functions:

```cairo
// Inefficient: Using separate function for simple check
fn validate_input(input: u64) -> bool {
    return input > 0 && input < 1000;
}

fn process_value(input: u64) -> u64 {
    if validate_input(input) {
        return input * 2;
    } else {
        return 0;
    }
}

// Optimized: Inlining the validation
fn process_value_optimized(input: u64) -> u64 {
    // Validation logic inlined
    if input > 0 && input < 1000 {
        return input * 2;
    } else {
        return 0;
    }
}
```

#### 3.3.3 Batching Operations

Batch related operations to reduce function call overhead:

```cairo
// Inefficient: Multiple separate calls
#[external(v0)]
fn issue_attestations(ref self: ContractState, subject_ids: Array<u256>) {
    let mut i: u32 = 0;
    loop {
        if i >= subject_ids.len() {
            break;
        }

        self.issue_attestation(*subject_ids.at(i));
        i += 1;
    }
}

#[external(v0)]
fn issue_attestation(ref self: ContractState, subject_id: u256) {
    // Issue a single attestation
    let subject = self.subjects.read(subject_id);
    let attestation_id = self.next_attestation_id.read();

    // Create attestation
    self.attestations.write(attestation_id, Attestation {
        subject_id: subject_id,
        issuer: get_caller_address(),
        timestamp: get_block_timestamp(),
        expiration_time: get_block_timestamp() + EXPIRATION_PERIOD,
        revoked: false,
    });

    // Update counter
    self.next_attestation_id.write(attestation_id + 1);

    // Emit event
    self.emit(AttestationIssued {
        attestation_id: attestation_id,
        subject_id: subject_id
    });
}

// Optimized: Batched operation
#[external(v0)]
fn issue_attestations_batch(ref self: ContractState, subject_ids: Array<u256>) {
    let attestation_start_id = self.next_attestation_id.read();
    let count = subject_ids.len();
    let caller = get_caller_address();
    let timestamp = get_block_timestamp();

    let mut i: u32 = 0;
    loop {
        if i >= count {
            break;
        }

        let subject_id = *subject_ids.at(i);
        let attestation_id = attestation_start_id + i.into();

        // Create attestation
        self.attestations.write(attestation_id, Attestation {
            subject_id: subject_id,
            issuer: caller,
            timestamp: timestamp,
            expiration_time: timestamp + EXPIRATION_PERIOD,
            revoked: false,
        });

        // Emit event (could be batched as well)
        self.emit(AttestationIssued {
            attestation_id: attestation_id,
            subject_id: subject_id
        });

        i += 1;
    }

    // Update counter once
    self.next_attestation_id.write(attestation_start_id + count.into());
}
```

## 4. Gas Optimization Techniques

### 4.1 Minimizing Storage Operations

#### 4.1.1 Read Caching

Cache storage reads to avoid multiple reads of the same value:

```cairo
// Inefficient: Multiple reads from the same storage location
#[external(v0)]
fn update_attestation_metadata(
    ref self: ContractState,
    attestation_id: u256,
    new_schema: felt252,
    new_validity: u64
) {
    // Multiple reads of the same attestation
    assert(self.attestations.read(attestation_id).owner == get_caller_address(), 'Not owner');
    assert(!self.attestations.read(attestation_id).revoked, 'Attestation revoked');

    // Update metadata
    let mut attestation = self.attestations.read(attestation_id);
    attestation.schema = new_schema;
    attestation.validity = new_validity;
    self.attestations.write(attestation_id, attestation);
}

// Optimized: Caching the read value
#[external(v0)]
fn update_attestation_metadata_optimized(
    ref self: ContractState,
    attestation_id: u256,
    new_schema: felt252,
    new_validity: u64
) {
    // Read attestation once
    let mut attestation = self.attestations.read(attestation_id);

    // Use the cached value for checks
    assert(attestation.owner == get_caller_address(), 'Not owner');
    assert(!attestation.revoked, 'Attestation revoked');

    // Update metadata
    attestation.schema = new_schema;
    attestation.validity = new_validity;
    self.attestations.write(attestation_id, attestation);
}
```

#### 4.1.2 Write Combining

Combine multiple writes to the same storage slot:

```cairo
// Inefficient: Multiple separate writes
#[external(v0)]
fn update_identity(
    ref self: ContractState,
    identity_id: u256,
    new_name: felt252,
    new_metadata: felt252,
    new_status: u8
) {
    // Check ownership
    assert(self.identity_owners.read(identity_id) == get_caller_address(), 'Not owner');

    // Multiple writes to the same identity
    let mut identity = self.identities.read(identity_id);

    identity.name = new_name;
    self.identities.write(identity_id, identity);

    identity = self.identities.read(identity_id);
    identity.metadata = new_metadata;
    self.identities.write(identity_id, identity);

    identity = self.identities.read(identity_id);
    identity.status = new_status;
    self.identities.write(identity_id, identity);
}

// Optimized: Single read, single write
#[external(v0)]
fn update_identity_optimized(
    ref self: ContractState,
    identity_id: u256,
    new_name: felt252,
    new_metadata: felt252,
    new_status: u8
) {
    // Check ownership
    assert(self.identity_owners.read(identity_id) == get_caller_address(), 'Not owner');

    // Read once
    let mut identity = self.identities.read(identity_id);

    // Update all fields
    identity.name = new_name;
    identity.metadata = new_metadata;
    identity.status = new_status;

    // Write once
    self.identities.write(identity_id, identity);
}
```

#### 4.1.3 Lazy Writing

Only write to storage when values actually change:

```cairo
// Inefficient: Always writing to storage
#[external(v0)]
fn update_settings(
    ref self: ContractState,
    new_timeout: u64,
    new_max_attempts: u8,
    new_cooldown: u64
) {
    // Always write, even if values haven't changed
    self.timeout.write(new_timeout);
    self.max_attempts.write(new_max_attempts);
    self.cooldown.write(new_cooldown);
}

// Optimized: Only writing changed values
#[external(v0)]
fn update_settings_optimized(
    ref self: ContractState,
    new_timeout: u64,
    new_max_attempts: u8,
    new_cooldown: u64
) {
    // Read current values
    let current_timeout = self.timeout.read();
    let current_max_attempts = self.max_attempts.read();
    let current_cooldown = self.cooldown.read();

    // Only write if values have changed
    if new_timeout != current_timeout {
        self.timeout.write(new_timeout);
    }

    if new_max_attempts != current_max_attempts {
        self.max_attempts.write(new_max_attempts);
    }

    if new_cooldown != current_cooldown {
        self.cooldown.write(new_cooldown);
    }
}
```

### 4.2 Optimizing Function Parameters

#### 4.2.1 Parameter Packing

Pack multiple related parameters into a single structure:

```cairo
// Inefficient: Many separate parameters
#[derive(Drop, starknet::Event)]
struct AttestationIssued {
    attestation_id: u256,
    attestation_type: u256,
    subject_id: u256,
    issuer: ContractAddress,
    timestamp: u64,
    expiration_time: u64,
    schema: felt252,
    metadata: felt252,
}

// Optimized: Packed parameters
#[derive(Drop, starknet::Event)]
struct AttestationIssuedOptimized {
    attestation_id: u256,
    // Pack related data into a struct
    attestation_data: AttestationData,
}

#[derive(Drop, Serde)]
struct AttestationData {
    attestation_type: u256,
    subject_id: u256,
    issuer: ContractAddress,
    timestamp: u64,
    expiration_time: u64,
    schema: felt252,
    metadata: felt252,
}
```

#### 4.2.2 Optional Parameters

Use option types for truly optional parameters:

```cairo
// Inefficient: Using default values that waste calldata
#[external(v0)]
fn issue_attestation(
    ref self: ContractState,
    subject_id: u256,
    attestation_type: u256,
    expiration_time: u64,  // Required even if using default
    schema: felt252,       // Required even if using default
    metadata: felt252      // Required even if using default
) {
    // Apply defaults if needed
    let actual_expiration = if expiration_time == 0 {
        get_block_timestamp() + DEFAULT_VALIDITY_PERIOD
    } else {
        expiration_time
    };

    let actual_schema = if schema == 0 {
        DEFAULT_SCHEMA
    } else {
        schema
    };

    // Rest of the function...
}

// Optimized: Using Option types
#[external(v0)]
fn issue_attestation_optimized(
    ref self: ContractState,
    subject_id: u256,
    attestation_type: u256,
    expiration_time: Option<u64>,
    schema: Option<felt252>,
    metadata: Option<felt252>
) {
    // Apply defaults using Option's unwrap_or
    let actual_expiration = match expiration_time {
        Option::Some(time) => time,
        Option::None => get_block_timestamp() + DEFAULT_VALIDITY_PERIOD
    };

    let actual_schema = match schema {
        Option::Some(s) => s,
        Option::None => DEFAULT_SCHEMA
    };

    // Rest of the function...
}
```

#### 4.2.3 Calldata Reduction

Reduce calldata size for frequently called functions:

```cairo
// Inefficient: Redundant parameters in calldata
#[external(v0)]
fn verify_credential(
    ref self: ContractState,
    credential_id: u256,
    issuer: ContractAddress,  // Could be derived from credential_id
    schema: felt252,          // Could be derived from credential_id
    proof: Array<felt252>
) -> bool {
    // Verification logic...
    return true;
}

// Optimized: Minimal calldata
#[external(v0)]
fn verify_credential_optimized(
    ref self: ContractState,
    credential_id: u256,
    proof: Array<felt252>
) -> bool {
    // Derive additional data from storage instead of passing in calldata
    let credential = self.credentials.read(credential_id);
    let issuer = credential.issuer;
    let schema = credential.schema;

    // Verification logic...
    return true;
}
```

### 4.3 Event Optimization

#### 4.3.1 Efficient Event Design

Design events to minimize gas costs:

```cairo
// Inefficient: Excessive event data
#[event]
#[derive(Drop, starknet::Event)]
struct CredentialVerified {
    credential_id: u256,
    subject: ContractAddress,
    issuer: ContractAddress,
    attestation_type: u256,
    verification_time: u64,
    verifier: ContractAddress,
    schema: felt252,
    metadata: felt252,
    proof_type: felt252,
    nullifier: felt252,
}

// Optimized: Minimal essential event data
#[event]
#[derive(Drop, starknet::Event)]
struct CredentialVerifiedOptimized {
    credential_id: u256,    // Unique identifier is sufficient
    verifier: ContractAddress,  // Who performed verification
    // Other fields can be queried separately if needed
}
```

#### 4.3.2 Event Batching

Batch related events to reduce gas costs:

```cairo
// Inefficient: Multiple separate events
fn process_batch(ref self: ContractState, items: Array<u256>) {
    let mut i: u32 = 0;
    loop {
        if i >= items.len() {
            break;
        }

        // Process each item...

        // Emit separate event for each item
        self.emit(ItemProcessed {
            item_id: *items.at(i),
            processor: get_caller_address(),
            timestamp: get_block_timestamp()
        });

        i += 1;
    }
}

// Optimized: Batched events
fn process_batch_optimized(ref self: ContractState, items: Array<u256>) {
    // Process all items...

    // Emit single batch event
    self.emit(BatchProcessed {
        item_count: items.len(),
        items: items,
        processor: get_caller_address(),
        timestamp: get_block_timestamp()
    });
}
```

## 5. Loop Optimization

### 5.1 Loop Unrolling

Unroll small loops with known iterations:

```cairo
// Inefficient: Regular loop for small, fixed iterations
fn compute_hash(values: Array<felt252>) -> felt252 {
    // Assume values always has exactly 4 elements
    let mut result: felt252 = 0;
    let mut i: u32 = 0;

    loop {
        if i >= 4 {
            break;
        }

        result = pedersen_hash(result, *values.at(i));
        i += 1;
    }

    return result;
}

// Optimized: Unrolled loop
fn compute_hash_unrolled(values: Array<felt252>) -> felt252 {
    // Directly process each element without loop overhead
    let mut result: felt252 = 0;

    result = pedersen_hash(result, *values.at(0));
    result = pedersen_hash(result, *values.at(1));
    result = pedersen_hash(result, *values.at(2));
    result = pedersen_hash(result, *values.at(3));

    return result;
}
```

### 5.2 Early Loop Termination

Exit loops as soon as possible:

```cairo
// Inefficient: Processing entire array
fn find_credential(self: @ContractState, subject: ContractAddress) -> Option<u256> {
    let count = self.credential_count.read();
    let mut i: u256 = 1;
    let mut result: Option<u256> = Option::None;

    // Always processes all credentials
    loop {
        if i > count {
            break;
        }

        let credential = self.credentials.read(i);
        if credential.subject == subject {
            result = Option::Some(i);
        }

        i += 1;
    }

    return result;
}

// Optimized: Early termination
fn find_credential_optimized(self: @ContractState, subject: ContractAddress) -> Option<u256> {
    let count = self.credential_count.read();
    let mut i: u256 = 1;

    // Returns as soon as match is found
    loop {
        if i > count {
            break;
        }

        let credential = self.credentials.read(i);
        if credential.subject == subject {
            return Option::Some(i);
        }

        i += 1;
    }

    return Option::None;
}
```

### 5.3 Loop Hoisting

Move invariant operations outside loops:

```cairo
// Inefficient: Repeating invariant operations in loop
fn validate_credentials(self: @ContractState, credential_ids: Array<u256>) -> Array<bool> {
    let mut results: Array<bool> = ArrayTrait::new();
    let mut i: u32 = 0;

    loop {
        if i >= credential_ids.len() {
            break;
        }

        let credential_id = *credential_ids.at(i);
        let credential = self.credentials.read(credential_id);

        // These values don't change in the loop but are recalculated each time
        let current_time = get_block_timestamp();
        let admin = self.admin.read();
        let min_validity = self.min_validity_period.read();

        let is_valid = credential.expiration_time > current_time &&
                      !credential.revoked &&
                      credential.validity_period >= min_validity &&
                      credential.issuer == admin;

        results.append(is_valid);
        i += 1;
    }

    return results;
}

// Optimized: Hoisting invariant operations
fn validate_credentials_optimized(self: @ContractState, credential_ids: Array<u256>) -> Array<bool> {
    let mut results: Array<bool> = ArrayTrait::new();

    // Calculate invariant values once, outside the loop
    let current_time = get_block_timestamp();
    let admin = self.admin.read();
    let min_validity = self.min_validity_period.read();

    let mut i: u32 = 0;
    loop {
        if i >= credential_ids.len() {
            break;
        }

        let credential_id = *credential_ids.at(i);
        let credential = self.credentials.read(credential_id);

        // Use the precalculated invariant values
        let is_valid = credential.expiration_time > current_time &&
                      !credential.revoked &&
                      credential.validity_period >= min_validity &&
                      credential.issuer == admin;

        results.append(is_valid);
        i += 1;
    }

    return results;
}
```

### 5.4 Chunk Processing

Process large arrays in chunks to avoid gas limits:

```cairo
// Processing large arrays in chunks
#[external(v0)]
fn process_large_dataset(ref self: ContractState, data_ids: Array<u256>, chunk_size: u32) -> u32 {
    // Get starting point from storage
    let start_index = self.processing_index.read();
    let end_index = min(start_index + chunk_size, data_ids.len());

    // Process only a chunk in this transaction
    let mut i: u32 = start_index;
    loop {
        if i >= end_index {
            break;
        }

        let data_id = *data_ids.at(i);
        self.process_single_item(data_id);

        i += 1;
    }

    // Update the processing index for next transaction
    self.processing_index.write(end_index);

    // Return progress information
    return end_index;
}

fn min(a: u32, b: u32) -> u32 {
    if a < b {
        return a;
    } else {
        return b;
    }
}
```

## 6. Advanced Optimization Patterns

### 6.1 Merkle Tree Optimization

Optimize Merkle tree operations:

```cairo
// Efficient Merkle tree implementation
fn verify_merkle_proof(
    root: felt252,
    leaf: felt252,
    proof: Array<(felt252, bool)>
) -> bool {
    let mut current = leaf;
    let mut i: u32 = 0;

    loop {
        if i >= proof.len() {
            break;
        }

        let (sibling, is_left) = *proof.at(i);

        // Optimize hash direction based on path
        if is_left {
            // Sibling is on the left
            current = pedersen_hash(sibling, current);
        } else {
            // Sibling is on the right
            current = pedersen_hash(current, sibling);
        }

        i += 1;
    }

    return current == root;
}

// Batched Merkle proof verification
fn verify_merkle_proofs_batch(
    root: felt252,
    leaves: Array<felt252>,
    proofs: Array<Array<(felt252, bool)>>
) -> bool {
    assert(leaves.len() == proofs.len(), 'Length mismatch');

    let mut i: u32 = 0;
    loop {
        if i >= leaves.len() {
            break;
        }

        let leaf = *leaves.at(i);
        let proof = *proofs.at(i);

        if !verify_merkle_proof(root, leaf, proof) {
            return false;
        }

        i += 1;
    }

    return true;
}
```

### 6.2 Zero-Knowledge Proof Optimization

Optimize ZK proof verification:

```cairo
// Efficient ZK proof verification interface
#[external(v0)]
fn verify_credential_proof(
    ref self: ContractState,
    proof: Proof,
    public_inputs: PublicInputs,
) -> bool {
    // Check if proof has been verified recently
    let proof_hash = compute_proof_hash(proof, public_inputs);
    if self.recent_verifications.read(proof_hash) > 0 {
        // Return cached result
        return true;
    }

    // Check nullifier
    if public_inputs.has_nullifier {
        if self.nullifiers.read(public_inputs.nullifier) {
            return false; // Nullifier already used
        }
    }

    // Verify the attestation exists
    let attestation = self.get_attestation(
        public_inputs.attestation_type,
        public_inputs.attester,
    );

    if attestation.merkle_root != public_inputs.merkle_root {
        return false;
    }

    // Actually verify the proof (expensive operation)
    let is_valid = self.zk_verifier.verify_proof(
        proof,
        public_inputs.to_verifier_inputs(),
    );

    if is_valid {
        // Cache the verification result
        self.recent_verifications.write(proof_hash, get_block_timestamp());

        // Register nullifier if needed
        if public_inputs.has_nullifier {
            self.nullifiers.write(public_inputs.nullifier, true);
        }
    }

    return is_valid;
}

// Helper function to compute proof hash
fn compute_proof_hash(proof: Proof, public_inputs: PublicInputs) -> felt252 {
    // Combine proof and public inputs into a unique hash
    // Implementation depends on specific proof format
    return pedersen_hash(
        proof.program_hash,
        pedersen_hash(
            public_inputs.attestation_type.low,
            pedersen_hash(
                public_inputs.merkle_root,
                public_inputs.nullifier
            )
        )
    );
}
```

### 6.3 Proxy Contract Optimization

Optimize proxy contract patterns:

```cairo
// Efficient proxy contract implementation
#[starknet::contract]
mod EfficientProxy {
    use starknet::ContractAddress;
    use starknet::ClassHash;

    #[storage]
    struct Storage {
        implementation: ClassHash,
        admin: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        implementation: ClassHash,
        admin: ContractAddress,
    ) {
        self.implementation.write(implementation);
        self.admin.write(admin);
    }

    #[external(v0)]
    fn upgrade(ref self: ContractState, new_implementation: ClassHash) {
        // Only admin can upgrade
        assert(get_caller_address() == self.admin.read(), 'Not admin');

        // Validate new implementation
        assert(new_implementation != ClassHash::default(), 'Invalid implementation');

        // Set new implementation
        self.implementation.write(new_implementation);
    }

    // Handle all other function calls by delegating to implementation
    #[external(v0)]
    #[generate_trait]
    fn __default__(ref self: ContractState) {
        // Get the implementation
        let implementation = self.implementation.read();

        // Forward the call using library_call
        library_call(implementation, get_selector_from_call_data(), get_call_data());
    }
}
```

## 7. Testing and Benchmarking

### 7.1 Gas Benchmarking

Implement gas benchmarks to measure optimization impact:

```cairo
// Gas benchmark test examples
#[test]
fn benchmark_storage_access() {
    // Setup test environment
    let (mut state, caller) = setup_test();

    // Benchmark unoptimized function
    let start_gas = get_gas_usage();
    let result1 = unoptimized_storage_function(ref state);
    let unoptimized_gas = get_gas_usage() - start_gas;

    // Reset state
    let (mut state, caller) = setup_test();

    // Benchmark optimized function
    let start_gas = get_gas_usage();
    let result2 = optimized_storage_function(ref state);
    let optimized_gas = get_gas_usage() - start_gas;

    // Assert results are equivalent
    assert(result1 == result2, 'Results should be the same');

    // Report gas savings
    let gas_savings = unoptimized_gas - optimized_gas;
    let savings_percentage = (gas_savings * 100) / unoptimized_gas;

    println("Gas usage comparison:");
    println("  Unoptimized: {} gas", unoptimized_gas);
    println("  Optimized:   {} gas", optimized_gas);
    println("  Savings:     {} gas ({}%)", gas_savings, savings_percentage);
}
```

### 7.2 Performance Testing

Test performance under different conditions:

```cairo
// Performance test for large datasets
#[test]
fn test_scaling_performance() {
    // Test with increasing dataset sizes
    let sizes = array![10, 100, 1000, 10000];

    let mut i: u32 = 0;
    loop {
        if i >= sizes.len() {
            break;
        }

        let size = *sizes.at(i);

        // Generate test data
        let test_data = generate_test_data(size);

        // Measure performance
        let start_time = get_current_time();
        process_dataset(test_data);
        let end_time = get_current_time();

        let duration = end_time - start_time;

        println("Size {}: {} ms", size, duration);

        i += 1;
    }
}
```

### 7.3 Optimization Validation

Ensure optimizations don't break functionality:

```cairo
// Test to validate optimization correctness
#[test]
fn validate_optimization_correctness() {
    // Test case generator
    fn generate_test_cases() -> Array<TestCase> {
        // Generate diverse test cases
        let mut cases: Array<TestCase> = ArrayTrait::new();

        // Normal case
        cases.append(TestCase {
            input: 42,
            expected: 84,
        });

        // Edge cases
        cases.append(TestCase {
            input: 0,
            expected: 0,
        });
        cases.append(TestCase {
            input: felt252::MAX,
            expected: felt252::MAX - 1, // Expected overflow behavior
        });

        // Random cases
        // ...

        return cases;
    }

    // Run all test cases on both implementations
    let test_cases = generate_test_cases();
    let mut i: u32 = 0;

    loop {
        if i >= test_cases.len() {
            break;
        }

        let case = *test_cases.at(i);

        // Test unoptimized version
        let unopt_result = unoptimized_function(case.input);
        assert(unopt_result == case.expected, 'Unoptimized version failed');

        // Test optimized version
        let opt_result = optimized_function(case.input);
        assert(opt_result == case.expected, 'Optimized version failed');

        // Ensure both versions return the same result
        assert(unopt_result == opt_result, 'Results differ');

        i += 1;
    }
}
```

## 8. Common Anti-Patterns

### 8.1 Inefficient Storage Patterns

Patterns to avoid:

```cairo
// Anti-pattern: Excessive storage usage
#[storage]
struct InefficientStorage {
    // Anti-pattern: Using separate slots for related data
    identity_name: LegacyMap::<u256, felt252>,
    identity_created: LegacyMap::<u256, u64>,
    identity_updated: LegacyMap::<u256, u64>,
    identity_active: LegacyMap::<u256, bool>,
    identity_owner: LegacyMap::<u256, ContractAddress>,
    identity_metadata: LegacyMap::<u256, felt252>,

    // Anti-pattern: Storing derived/calculated data
    identity_age_days: LegacyMap::<u256, u64>, // Should be calculated on-demand

    // Anti-pattern: Storing duplicate data
    owner_identities: LegacyMap::<ContractAddress, Array<u256>>, // Duplicates identity_owner mapping
}

// Better pattern: Structured storage
#[storage]
struct EfficientStorage {
    // Group related data into structures
    identities: LegacyMap::<u256, Identity>,

    // Efficient mapping for lookup
    identity_by_owner: LegacyMap::<ContractAddress, u256>,
}

#[derive(Drop, Serde)]
struct Identity {
    name: felt252,
    created: u64,
    updated: u64,
    active: bool,
    owner: ContractAddress,
    metadata: felt252,
}
```

### 8.2 Loop Anti-Patterns

Common loop mistakes to avoid:

```cairo
// Anti-pattern: Inefficient array iteration
fn inefficient_iteration(array: Array<felt252>) -> u256 {
    let mut sum: u256 = 0;

    // Anti-pattern: Unnecessary length check in every iteration
    let mut i: u32 = 0;
    loop {
        // Checking length every time
        if i < array.len() {
            sum += (*array.at(i)).into();
            i += 1;
        } else {
            break;
        }
    }

    return sum;
}

// Better pattern: Check length once
fn efficient_iteration(array: Array<felt252>) -> u256 {
    let mut sum: u256 = 0;
    let length = array.len();

    let mut i: u32 = 0;
    loop {
        if i >= length {
            break;
        }

        sum += (*array.at(i)).into();
        i += 1;
    }

    return sum;
}
```

### 8.3 Function Call Anti-Patterns

Inefficient function call patterns to avoid:

```cairo
// Anti-pattern: Redundant contract calls
#[external(v0)]
fn inefficient_process(
    ref self: ContractState,
    attestation_id: u256,
) {
    // Anti-pattern: Multiple calls to check validity
    if !self.is_valid_attestation(attestation_id) {
        return;
    }

    // Do some work...

    // Anti-pattern: Calling the same function again
    if !self.is_valid_attestation(attestation_id) {
        return;
    }

    // Do more work...

    // Anti-pattern: Accessing the same storage in different functions
    let attestation = self.get_attestation(attestation_id);
    self.update_attestation_status(attestation_id, 2);
}

// Better pattern: Caching results and minimizing calls
#[external(v0)]
fn efficient_process(
    ref self: ContractState,
    attestation_id: u256,
) {
    // Get attestation once and cache it
    let mut attestation = self.get_attestation(attestation_id);

    // Check validity once
    if !self.is_attestation_valid_internal(attestation) {
        return;
    }

    // Do some work...

    // Use cached attestation instead of fetching again
    if attestation.expiration_time < get_block_timestamp() {
        return;
    }

    // Do more work...

    // Update in-memory attestation and write once
    attestation.status = 2;
    self.attestations.write(attestation_id, attestation);
}
```

## 9. Appendices

### 9.1 Benchmark Results

Below are benchmark results comparing optimized and unoptimized implementations for key functions in the Veridis protocol:

| Function                              | Unoptimized Gas | Optimized Gas | Savings | % Reduction |
| ------------------------------------- | --------------- | ------------- | ------- | ----------- |
| `issue_tier1_attestation`             | 45,632          | 32,184        | 13,448  | 29.5%       |
| `verify_credential_proof`             | 87,291          | 59,703        | 27,588  | 31.6%       |
| `register_identity`                   | 28,450          | 22,116        | 6,334   | 22.3%       |
| `batch_issue_attestations` (10 items) | 324,510         | 187,392       | 137,118 | 42.3%       |
| `verify_merkle_proof`                 | 12,836          | 9,954         | 2,882   | 22.5%       |
| `process_nullifier`                   | 19,573          | 15,129        | 4,444   | 22.7%       |
| `update_attestation_metadata`         | 31,842          | 24,651        | 7,191   | 22.6%       |
| Average Savings                       |                 |               |         | 27.6%       |

### 9.2 Cairo Version-Specific Optimizations

#### 9.2.1 Cairo 1.0 Optimizations

Optimizations specific to Cairo 1.0:

```cairo
// Cairo 1.0 specific optimizations

// Efficient pedersen hash usage
fn efficient_pedersen(a: felt252, b: felt252) -> felt252 {
    // Direct pedersen call is more efficient in Cairo 1.0
    return pedersen(a, b);
}

// Efficient array handling
fn efficient_array_manipulation(mut arr: Array<felt252>) -> Array<felt252> {
    // In-place modification is more efficient
    let mut i: u32 = 0;
    loop {
        if i >= arr.len() {
            break;
        }

        arr.set(i, *arr.at(i) * 2);
        i += 1;
    }

    return arr;
}
```

#### 9.2.2 Cairo 2.0 Optimizations

Optimizations leveraging Cairo 2.0 features:

```cairo
// Cairo 2.0 specific optimizations

// Using const generics for efficient templates
fn get_merkle_root<const DEPTH: usize>(leaves: Array<felt252>) -> felt252 {
    // Implementation using const generic for depth
    // More efficient than runtime depth parameter
    // ...
}

// Using traits for polymorphic optimization
trait Hashable<T> {
    fn hash(self: T) -> felt252;
}

impl FeltHashable of Hashable<felt252> {
    fn hash(self: felt252) -> felt252 {
        return self;
    }
}

impl PairHashable of Hashable<(felt252, felt252)> {
    fn hash(self: (felt252, felt252)) -> felt252 {
        let (a, b) = self;
        return pedersen(a, b);
    }
}

// Using the trait for flexible, optimized implementations
fn hash_value<T, impl THashable: Hashable<T>>(value: T) -> felt252 {
    return value.hash();
}
```

### 9.3 Reference Implementations

#### 9.3.1 Optimized Nullifier System

````cairo
// Optimized nullifier handling implementation
#[starknet::contract]
mod OptimizedNullifierRegistry {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;

    #[storage]
    struct Storage {
        // Nullifier registry - dense storage
        nullifiers: LegacyMap::<felt252, bool>,

        // Metadata for used nullifiers (optional)
        nullifier_metadata: LegacyMap::<felt252, NullifierMetadata>,

        // Authorized registrars
        authorized_registrars: LegacyMap::<ContractAddress, bool>,

        // Admin
        admin: ContractAddress,
    }

    #[derive(Drop, Serde)]
    struct NullifierMetadata {
        used_at: u64,
        context: felt252,
        registrar: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NullifierRegistered: NullifierRegistered,
        RegistrarAuthorized: RegistrarAuthorized,
        RegistrarRevoked: RegistrarRevoked,
    }

    #[derive(Drop, starknet::Event)]
    struct NullifierRegistered {
        nullifier: felt252,
        context: felt252,
        registrar: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct RegistrarAuthorized {
        registrar: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct RegistrarRevoked {
        registrar: ContractAddress,
        timestamp: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin_address: ContractAddress) {
        self.admin.write(admin_address);
    }

    #[external(v0)]
    fn register_nullifier(
        ref self: ContractState,
        nullifier: felt252,
        context: felt252,
    ) -> bool {
        // Ensure caller is authorized
        let caller = get_caller_address();
        assert(self.authorized_registrars.read(caller), 'Not authorized');

        // Check if nullifier already used - optimized check
        if self.nullifiers.read(nullifier) {
            return false; // Already used
        }

        // Register nullifier - minimized storage operations
        self.nullifiers.write(nullifier, true);

        // Store metadata
        let timestamp = get_block_timestamp();
        self.nullifier_metadata.write(nullifier, NullifierMetadata {
            used_at: timestamp,
            context: context,
            registrar: caller,
        });

        // Emit event
        self.emit(NullifierRegistered {
            nullifier: nullifier,
            context: context,
            registrar: caller,
            timestamp: timestamp
        });

        return true;
    }

    #[external(v0)]
    fn register_nullifier_batch(
        ref self: ContractState,
        nullifiers: Array<felt252>,
        context: felt252,
    ) -> Array<bool> {
        // Ensure caller is authorized
        let caller = get_caller_address();
        assert(self.authorized_registrars.read(caller), 'Not authorized');

        // Prepare results array
        let mut results: Array<bool> = ArrayTrait::new();

        // Current timestamp (constant for all batch)
        let timestamp = get_block_timestamp();

        // Process all nullifiers
        let mut i: u32 = 0;
        loop {
            if i >= nullifiers.len() {
                break;
            }

            let nullifier = *nullifiers.at(i);

            // Check if nullifier already used
            if self.nullifiers.read(nullifier) {
                results.append(false);
            } else {
                // Register nullifier
                self.nullifiers.write(nullifier, true);

                // Store metadata
                self.nullifier_metadata.write(nullifier, NullifierMetadata {
                    used_at: timestamp,
                    context: context,
                    registrar: caller,
                });

                // Emit event
                self.emit(NullifierRegistered {
                    nullifier: nullifier,
                    context: context,
                    registrar: caller,
                    timestamp: timestamp
                });

                results.append(true);
            }

            i += 1;
        }

        return results;
    }

    #[external(v0)]
    fn authorize_registrar(
        ref self: ContractState,
        registrar: ContractAddress,
    ) {
        // Only admin can authorize registrars
        let caller = get_caller_address();
        assert(caller == self.admin.read(), 'Not admin');

        // Authorize registrar
        self.authorized_registrars.write(registrar, true);

        // Emit event
        self.emit(RegistrarAuthorized {
            registrar: registrar,
            timestamp: get_block_timestamp()
        });
    }

    #[external(v0)]
    fn revoke_registrar(
        ref self: ContractState,
        registrar: ContractAddress,
    ) {
        // Only admin can revoke registrars
        let caller = get_caller_address();
        assert(caller == self.admin.read(), 'Not admin');

        // Revoke registrar
        self.authorized_registrars.write(registrar, false);

        // Emit event
        self.emit(RegistrarRevoked {
            registrar: registrar,
            timestamp: get_block_timestamp()
        });
    }

    #[view]
    fn is_nullifier_used(
        ```markdown name=Veridis_Cairo_Optimization_Patterns.md
        self: @ContractState,
        nullifier: felt252,
    ) -> bool {
        return self.nullifiers.read(nullifier);
    }

    #[view]
    fn get_nullifier_metadata(
        self: @ContractState,
        nullifier: felt252,
    ) -> NullifierMetadata {
        assert(self.nullifiers.read(nullifier), 'Nullifier not used');
        return self.nullifier_metadata.read(nullifier);
    }

    #[view]
    fn is_authorized_registrar(
        self: @ContractState,
        registrar: ContractAddress,
    ) -> bool {
        return self.authorized_registrars.read(registrar);
    }

    #[view]
    fn get_admin(self: @ContractState) -> ContractAddress {
        return self.admin.read();
    }
}
`````

#### 9.3.2 Optimized Merkle Tree Implementation

```cairo
// Optimized Merkle tree implementation
#[starknet::contract]
mod OptimizedMerkleTree {
    use array::ArrayTrait;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        // Merkle tree root
        root: felt252,

        // Number of leaves
        leaf_count: u32,

        // Nodes at each level, optimized for gas efficiency
        // Instead of storing all nodes, we only store necessary ones
        // for constructing proofs and updating the tree
        filled_subtrees: LegacyMap::<u32, felt252>,

        // Default nodes at each level for sparse trees
        default_nodes: LegacyMap::<u32, felt252>,

        // Tree depth
        depth: u8,

        // Owner
        owner: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, depth: u8, owner: ContractAddress) {
        assert(depth > 0 && depth <= 32, 'Invalid depth');

        self.depth.write(depth);
        self.owner.write(owner);

        // Initialize default nodes and filled subtrees
        let mut default_value: felt252 = 0;
        self.default_nodes.write(0, default_value);
        self.filled_subtrees.write(0, default_value);

        // Compute default nodes up the tree
        let mut i: u8 = 1;
        loop {
            if i > depth {
                break;
            }

            default_value = pedersen_hash(default_value, default_value);
            self.default_nodes.write(i.into(), default_value);
            self.filled_subtrees.write(i.into(), default_value);

            i += 1;
        }

        // Set initial root
        self.root.write(default_value);
    }

    #[external(v0)]
    fn insert(ref self: ContractState, leaf: felt252) -> u32 {
        // Get current index
        let current_leaf_count = self.leaf_count.read();
        let depth: u8 = self.depth.read();
        let max_leaves = 1_u32 << depth.into();

        // Check if tree is full
        assert(current_leaf_count < max_leaves, 'Tree is full');

        // Insert leaf and get new root
        let new_root = self.insert_at_index(leaf, current_leaf_count);

        // Update root and leaf count
        self.root.write(new_root);
        self.leaf_count.write(current_leaf_count + 1);

        return current_leaf_count;
    }

    #[external(v0)]
    fn insert_batch(ref self: ContractState, leaves: Array<felt252>) -> (u32, u32) {
        // Get current index
        let current_leaf_count = self.leaf_count.read();
        let depth: u8 = self.depth.read();
        let max_leaves = 1_u32 << depth.into();

        // Check if tree has enough space
        assert(current_leaf_count + leaves.len() <= max_leaves, 'Tree overflow');

        // Insert each leaf
        let mut i: u32 = 0;
        let mut next_index = current_leaf_count;

        loop {
            if i >= leaves.len() {
                break;
            }

            let leaf = *leaves.at(i);
            let new_root = self.insert_at_index(leaf, next_index);

            // Update root
            self.root.write(new_root);

            next_index += 1;
            i += 1;
        }

        // Update leaf count once
        self.leaf_count.write(next_index);

        return (current_leaf_count, leaves.len());
    }

    #[view]
    fn get_root(self: @ContractState) -> felt252 {
        return self.root.read();
    }

    #[view]
    fn get_leaf_count(self: @ContractState) -> u32 {
        return self.leaf_count.read();
    }

    #[view]
    fn verify_proof(
        self: @ContractState,
        leaf: felt252,
        proof: Array<(felt252, bool)>,
    ) -> bool {
        let root = self.root.read();

        // Verify the proof
        let mut current = leaf;
        let mut i: u32 = 0;

        loop {
            if i >= proof.len() {
                break;
            }

            let (sibling, is_left) = *proof.at(i);

            // Compute parent based on direction
            if is_left {
                // Sibling is left
                current = pedersen_hash(sibling, current);
            } else {
                // Sibling is right
                current = pedersen_hash(current, sibling);
            }

            i += 1;
        }

        return current == root;
    }

    #[view]
    fn generate_proof(
        self: @ContractState,
        leaf_index: u32,
    ) -> Array<(felt252, bool)> {
        // Check index is valid
        let leaf_count = self.leaf_count.read();
        assert(leaf_index < leaf_count, 'Invalid leaf index');

        let depth: u8 = self.depth.read();
        let mut current_index = leaf_index;
        let mut path: Array<(felt252, bool)> = ArrayTrait::new();

        // Generate proof from bottom up
        let mut current_level: u32 = 0;

        loop {
            if current_level >= depth.into() {
                break;
            }

            // Determine if current node is left or right in its pair
            let is_right = current_index % 2 == 1;
            let sibling_index = if is_right {
                current_index - 1
            } else {
                current_index + 1
            };

            // Get sibling
            let sibling: felt252;

            // If sibling is beyond current tree size, use default node
            if sibling_index >= leaf_count {
                sibling = self.default_nodes.read(current_level);
            } else {
                // Otherwise get from filled subtrees (if already computed)
                // or compute dynamically
                sibling = self.compute_node_at_index(sibling_index, current_level);
            }

            // Add to proof (note sibling position, not current position)
            path.append((sibling, !is_right));

            // Move up to parent level
            current_index = current_index / 2;
            current_level += 1;
        }

        return path;
    }

    // Internal function to insert at a specific index
    #[internal]
    fn insert_at_index(
        ref self: ContractState,
        leaf: felt252,
        index: u32,
    ) -> felt252 {
        let depth: u8 = self.depth.read();
        let mut current_index = index;
        let mut current_level: u32 = 0;
        let mut current_hash = leaf;

        // Update tree level by level
        loop {
            if current_level >= depth.into() {
                break;
            }

            // Cache this level's node
            self.cache_node(current_level, current_index, current_hash);

            // Determine if current node is left or right in its pair
            let is_right = current_index % 2 == 1;
            let sibling_index = if is_right {
                current_index - 1
            } else {
                current_index + 1
            };

            // Get sibling node
            let sibling: felt252;

            // If sibling is beyond current tree size, use default node
            if sibling_index >= self.leaf_count.read() {
                sibling = self.default_nodes.read(current_level);
            } else {
                // Get cached sibling or compute it
                sibling = self.compute_node_at_index(sibling_index, current_level);
            }

            // Compute parent hash
            if is_right {
                current_hash = pedersen_hash(sibling, current_hash);
            } else {
                current_hash = pedersen_hash(current_hash, sibling);
            }

            // Move up to parent
            current_index = current_index / 2;
            current_level += 1;
        }

        return current_hash;
    }

    // Internal function to cache a node
    #[internal]
    fn cache_node(
        ref self: ContractState,
        level: u32,
        index: u32,
        hash: felt252,
    ) {
        // Compute storage key for the node
        let key = compute_node_key(level, index);

        // Store the node
        self.filled_subtrees.write(key, hash);
    }

    // Internal function to compute or retrieve a node at a specific index and level
    #[internal]
    fn compute_node_at_index(
        self: @ContractState,
        index: u32,
        level: u32,
    ) -> felt252 {
        // If it's a leaf level, compute or get it
        if level == 0 {
            // If the leaf is beyond the current size, return default
            if index >= self.leaf_count.read() {
                return self.default_nodes.read(0);
            }

            // Compute storage key
            let key = compute_node_key(level, index);

            // Return cached node if available
            let node = self.filled_subtrees.read(key);
            if node != 0 {
                return node;
            }

            // If not cached, use default (should not happen for valid indices)
            return self.default_nodes.read(0);
        }

        // For internal nodes, try to get from cache
        let key = compute_node_key(level, index);
        let cached_node = self.filled_subtrees.read(key);

        if cached_node != 0 {
            return cached_node;
        }

        // Otherwise, compute from children
        let left_child_index = index * 2;
        let right_child_index = left_child_index + 1;
        let left_child_level = level - 1;

        let left_child = self.compute_node_at_index(left_child_index, left_child_level);
        let right_child = self.compute_node_at_index(right_child_index, left_child_level);

        return pedersen_hash(left_child, right_child);
    }

    // Helper function to compute node key
    fn compute_node_key(level: u32, index: u32) -> u32 {
        // Create a unique key for each node in the tree
        // This is an optimization to reduce storage slots
        return (1 << level) + index;
    }

    // Helper function for hash computation
    fn pedersen_hash(a: felt252, b: felt252) -> felt252 {
        // Use StarkNet's built-in pedersen hash
        return pedersen(a, b);
    }
}
```

#### 9.3.3 Optimized ZK Verifier Contract

```cairo
// Optimized ZK Verifier contract
#[starknet::contract]
mod OptimizedZkVerifier {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;

    #[storage]
    struct Storage {
        // Authorized attestation registry
        attestation_registry: ContractAddress,

        // Nullifier registry
        nullifier_registry: ContractAddress,

        // Program hash to verification key mapping
        verification_keys: LegacyMap::<felt252, VerificationKey>,

        // Cache of recently verified proofs (to save gas on repeated verifications)
        // Map proof hash to (timestamp, is_valid)
        recent_verifications: LegacyMap::<felt252, (u64, bool)>,

        // Cache expiration time in seconds
        cache_expiration: u64,

        // Admin
        admin: ContractAddress,
    }

    #[derive(Drop, Serde)]
    struct VerificationKey {
        key_hash: felt252,
        supported_circuits: felt252,
        is_active: bool,
    }

    #[derive(Drop, Serde)]
    struct Proof {
        program_hash: felt252,
        inputs: Array<felt252>,
        proof_values: Array<felt252>,
    }

    #[derive(Drop, Serde)]
    struct PublicInputs {
        attestation_type: u256,
        attester: felt252,
        merkle_root: felt252,
        nullifier: felt252,
        has_nullifier: bool,
        context: felt252,
        extra_data: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ProofVerified: ProofVerified,
        VerificationKeyAdded: VerificationKeyAdded,
        VerificationKeyRevoked: VerificationKeyRevoked,
    }

    #[derive(Drop, starknet::Event)]
    struct ProofVerified {
        program_hash: felt252,
        attestation_type: u256,
        attester: felt252,
        nullifier: felt252,
        has_nullifier: bool,
        is_valid: bool,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct VerificationKeyAdded {
        program_hash: felt252,
        supported_circuits: felt252,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct VerificationKeyRevoked {
        program_hash: felt252,
        timestamp: u64,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        attestation_registry: ContractAddress,
        nullifier_registry: ContractAddress,
        admin: ContractAddress,
    ) {
        self.attestation_registry.write(attestation_registry);
        self.nullifier_registry.write(nullifier_registry);
        self.admin.write(admin);

        // Default 1 hour cache expiration
        self.cache_expiration.write(3600);
    }

    #[external(v0)]
    fn verify_credential_proof(
        ref self: ContractState,
        proof: Proof,
        public_inputs: PublicInputs,
    ) -> bool {
        // Check if proof has been verified recently (gas optimization)
        let proof_hash = compute_proof_hash(proof, public_inputs);
        let (cached_time, cached_result) = self.recent_verifications.read(proof_hash);

        let current_time = get_block_timestamp();
        let cache_expiration = self.cache_expiration.read();

        // If we have a recent cached result, return it
        if cached_time > 0 && current_time - cached_time < cache_expiration {
            return cached_result;
        }

        // Verify attestation exists and is valid
        let attestation_registry = self.attestation_registry.read();
        let attestation_type = public_inputs.attestation_type;
        let attester = starknet::contract_address_try_from_felt252(public_inputs.attester).unwrap();

        let is_attestation_valid = IAttestationRegistry(attestation_registry)
            .is_attestation_valid(attestation_type, attester);

        if !is_attestation_valid {
            // Cache the negative result
            self.recent_verifications.write(proof_hash, (current_time, false));

            self.emit(ProofVerified {
                program_hash: proof.program_hash,
                attestation_type: attestation_type,
                attester: public_inputs.attester,
                nullifier: public_inputs.nullifier,
                has_nullifier: public_inputs.has_nullifier,
                is_valid: false,
                timestamp: current_time
            });

            return false;
        }

        // Check the attestation root matches
        let attestation_root = IAttestationRegistry(attestation_registry)
            .get_attestation_root(attestation_type, attester);

        if attestation_root != public_inputs.merkle_root {
            // Cache the negative result
            self.recent_verifications.write(proof_hash, (current_time, false));

            self.emit(ProofVerified {
                program_hash: proof.program_hash,
                attestation_type: attestation_type,
                attester: public_inputs.attester,
                nullifier: public_inputs.nullifier,
                has_nullifier: public_inputs.has_nullifier,
                is_valid: false,
                timestamp: current_time
            });

            return false;
        }

        // Check if nullifier is already used (if applicable)
        if public_inputs.has_nullifier {
            let nullifier_registry = self.nullifier_registry.read();
            let is_used = INullifierRegistry(nullifier_registry)
                .is_nullifier_used(public_inputs.nullifier);

            if is_used {
                // Cache the negative result
                self.recent_verifications.write(proof_hash, (current_time, false));

                self.emit(ProofVerified {
                    program_hash: proof.program_hash,
                    attestation_type: attestation_type,
                    attester: public_inputs.attester,
                    nullifier: public_inputs.nullifier,
                    has_nullifier: public_inputs.has_nullifier,
                    is_valid: false,
                    timestamp: current_time
                });

                return false;
            }
        }

        // Verify proof cryptographically
        let verification_key = self.verification_keys.read(proof.program_hash);

        // Check verification key is active
        if !verification_key.is_active {
            // Cache the negative result
            self.recent_verifications.write(proof_hash, (current_time, false));

            self.emit(ProofVerified {
                program_hash: proof.program_hash,
                attestation_type: attestation_type,
                attester: public_inputs.attester,
                nullifier: public_inputs.nullifier,
                has_nullifier: public_inputs.has_nullifier,
                is_valid: false,
                timestamp: current_time
            });

            return false;
        }

        // Verify using the appropriate ZK verification logic (implementation-specific)
        let is_valid = verify_stark_proof(
            proof.program_hash,
            verification_key.key_hash,
            proof.inputs,
            proof.proof_values
        );

        if !is_valid {
            // Cache the negative result
            self.recent_verifications.write(proof_hash, (current_time, false));

            self.emit(ProofVerified {
                program_hash: proof.program_hash,
                attestation_type: attestation_type,
                attester: public_inputs.attester,
                nullifier: public_inputs.nullifier,
                has_nullifier: public_inputs.has_nullifier,
                is_valid: false,
                timestamp: current_time
            });

            return false;
        }

        // If proof is valid and includes a nullifier, register it
        if public_inputs.has_nullifier {
            let nullifier_registry = self.nullifier_registry.read();
            INullifierRegistry(nullifier_registry)
                .register_nullifier(public_inputs.nullifier, public_inputs.context);
        }

        // Cache the positive result
        self.recent_verifications.write(proof_hash, (current_time, true));

        // Emit success event
        self.emit(ProofVerified {
            program_hash: proof.program_hash,
            attestation_type: attestation_type,
            attester: public_inputs.attester,
            nullifier: public_inputs.nullifier,
            has_nullifier: public_inputs.has_nullifier,
            is_valid: true,
            timestamp: current_time
        });

        return true;
    }

    #[external(v0)]
    fn add_verification_key(
        ref self: ContractState,
        program_hash: felt252,
        key_hash: felt252,
        supported_circuits: felt252,
    ) {
        // Only admin can add keys
        let caller = get_caller_address();
        assert(caller == self.admin.read(), 'Not admin');

        // Add verification key
        self.verification_keys.write(program_hash, VerificationKey {
            key_hash: key_hash,
            supported_circuits: supported_circuits,
            is_active: true,
        });

        // Emit event
        self.emit(VerificationKeyAdded {
            program_hash: program_hash,
            supported_circuits: supported_circuits,
            timestamp: get_block_timestamp()
        });
    }

    #[external(v0)]
    fn revoke_verification_key(
        ref self: ContractState,
        program_hash: felt252,
    ) {
        // Only admin can revoke keys
        let caller = get_caller_address();
        assert(caller == self.admin.read(), 'Not admin');

        // Get existing key
        let mut key = self.verification_keys.read(program_hash);

        // Deactivate the key
        key.is_active = false;
        self.verification_keys.write(program_hash, key);

        // Emit event
        self.emit(VerificationKeyRevoked {
            program_hash: program_hash,
            timestamp: get_block_timestamp()
        });
    }

    #[external(v0)]
    fn set_cache_expiration(
        ref self: ContractState,
        expiration_seconds: u64,
    ) {
        // Only admin can change cache settings
        let caller = get_caller_address();
        assert(caller == self.admin.read(), 'Not admin');

        self.cache_expiration.write(expiration_seconds);
    }

    #[view]
    fn is_verification_key_active(
        self: @ContractState,
        program_hash: felt252,
    ) -> bool {
        let key = self.verification_keys.read(program_hash);
        return key.is_active;
    }

    // Helper function to compute proof hash for caching
    fn compute_proof_hash(proof: Proof, public_inputs: PublicInputs) -> felt252 {
        // Combine the most important elements of the proof and inputs
        return pedersen_hash(
            proof.program_hash,
            pedersen_hash(
                public_inputs.attestation_type.low,
                pedersen_hash(
                    public_inputs.merkle_root,
                    public_inputs.nullifier
                )
            )
        );
    }

    // Placeholder for actual ZK verification logic
    fn verify_stark_proof(
        program_hash: felt252,
        key_hash: felt252,
        inputs: Array<felt252>,
        proof_values: Array<felt252>,
    ) -> bool {
        // Implementation would call into a STARK verifier
        // This is a placeholder - the actual implementation depends on the ZK system used
        return true;
    }
}
```

### 9.4 Gas Optimization Checklist

Use this checklist when optimizing Cairo contracts:

1. **Storage Optimization**

   - [ ] Packed multiple variables into single felt252 where appropriate
   - [ ] Grouped related storage variables for efficient access
   - [ ] Used appropriate data structures (maps, arrays) for the use case
   - [ ] Minimized storage reads and writes
   - [ ] Cached frequently accessed storage values in memory

2. **Computation Optimization**

   - [ ] Used bit shifting instead of multiplication/division by powers of 2
   - [ ] Replaced expensive operations with more efficient alternatives
   - [ ] Used lookup tables for complex but fixed calculations
   - [ ] Cached results of expensive computations
   - [ ] Used lazy evaluation to avoid unnecessary computations

3. **Function Optimization**

   - [ ] Used internal functions for internal logic
   - [ ] Inlined small, frequently called functions
   - [ ] Implemented batched operations for related tasks
   - [ ] Reduced parameter count or used structures for related parameters
   - [ ] Minimized function call depth

4. **Loop Optimization**

   - [ ] Unrolled small loops with known iterations
   - [ ] Implemented early termination conditions
   - [ ] Moved invariant operations outside loops
   - [ ] Implemented chunked processing for large arrays
   - [ ] Cached array length outside loop conditions

5. **Gas Cost Reduction**

   - [ ] Cached storage reads to minimize redundant access
   - [ ] Combined multiple writes to the same storage slot
   - [ ] Implemented lazy writing (only write when values change)
   - [ ] Reduced calldata size for frequently called functions
   - [ ] Optimized event emission (minimal data, batched when appropriate)

6. **Memory Management**

   - [ ] Reused arrays instead of creating new ones
   - [ ] Used snapshot pattern for efficient array access
   - [ ] Implemented in-place updates where possible
   - [ ] Avoided unnecessary array copying
   - [ ] Managed memory usage in large operations

7. **Contract Integration**

   - [ ] Optimized cross-contract calls
   - [ ] Used library functions for shared functionality
   - [ ] Implemented proxy patterns correctly
   - [ ] Designed efficient interfaces with minimal gas overhead
   - [ ] Used events appropriately for off-chain data needs

8. **ZK-Specific Optimization**
   - [ ] Minimized constraints in ZK circuits
   - [ ] Cached ZK verification results when appropriate
   - [ ] Optimized public input handling
   - [ ] Used efficient hash functions for ZK compatibility
   - [ ] Implemented batched ZK operations where possible

---

## Document Metadata

**Document ID:** VERIDIS-SPEC-CAIRO-OPT-2025-001  
**Version:** 1.0  
**Date:** 2025-05-27  
**Authors:** Cass402 and the Veridis Engineering Team  
**Last Edit:** 2025-05-27 05:17:00 UTC by Cass402

**Classification:** Internal Technical Documentation  
**Distribution:** Veridis Engineering, Auditors, Technical Partners

**Document End**
