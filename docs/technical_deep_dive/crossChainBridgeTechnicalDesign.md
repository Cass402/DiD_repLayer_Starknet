# Veridis: Cross-Chain Bridge Technical Design

**Technical Documentation v1.0**  
**May 27, 2025**

**Authors:**  
Cass402 and the Veridis Engineering Team

---

## Document Control

| Version | Date       | Author           | Changes                      |
| ------- | ---------- | ---------------- | ---------------------------- |
| 0.1     | 2025-04-20 | Bridge Team      | Initial draft                |
| 0.2     | 2025-05-10 | Security Team    | Added security analysis      |
| 0.3     | 2025-05-18 | Integration Team | Updated chain integrations   |
| 1.0     | 2025-05-27 | Cass402          | Final review and publication |

**Classification:** Internal Technical Documentation  
**Distribution:** Veridis Engineering, Auditors, Technical Partners

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Bridge Architecture](#2-bridge-architecture)
3. [Cross-Chain Message Passing](#3-cross-chain-message-passing)
4. [State Verification Mechanisms](#4-state-verification-mechanisms)
5. [Trust Model and Security](#5-trust-model-and-security)
6. [Supported Chains](#6-supported-chains)
7. [Cross-Chain Attestation Protocol](#7-cross-chain-attestation-protocol)
8. [Implementation Design](#8-implementation-design)
9. [Failure Recovery Procedures](#9-failure-recovery-procedures)
10. [Performance Considerations](#10-performance-considerations)
11. [Testing and Verification](#11-testing-and-verification)
12. [Appendices](#12-appendices)

---

## 1. Introduction

### 1.1 Purpose and Scope

This document provides a comprehensive technical design for the Veridis Cross-Chain Bridge, a system that enables secure and privacy-preserving verification of Veridis attestations across multiple blockchain networks. The bridge extends the utility of Veridis identities and attestations beyond StarkNet, allowing applications on other chains to leverage Veridis's privacy-preserving verification capabilities.

The scope of this document encompasses:

- The architectural design of the cross-chain bridge system
- Cross-chain message passing protocols and verification mechanisms
- Security model and trust assumptions
- Technical implementation details for supported chains
- Recovery procedures and performance optimizations

### 1.2 Design Goals

The Veridis Cross-Chain Bridge is designed according to the following principles:

1. **Privacy Preservation**: Maintain the same privacy guarantees across all integrated chains
2. **Security**: Implement robust security measures with minimal trust assumptions
3. **Decentralization**: Avoid centralized components and single points of failure
4. **Efficiency**: Minimize gas costs and latency for cross-chain verifications
5. **Extensibility**: Support easy integration of additional chains
6. **Usability**: Provide a seamless experience for developers and end-users

### 1.3 Key Terminology

- **Bridge**: System facilitating communication between different blockchain networks
- **Cross-Chain Message**: Data transmitted between different blockchain networks
- **Light Client**: Simplified blockchain client that verifies block headers without processing full blocks
- **Relayer**: Entity responsible for transmitting messages between chains
- **State Proof**: Cryptographic proof of state inclusion on the source chain
- **Attestation Relay**: Process of making attestations available on destination chains
- **State Root**: Cryptographic commitment to the entire state of a blockchain
- **Zero-Knowledge Verification**: Verification of proofs without revealing underlying data

## 2. Bridge Architecture

### 2.1 System Overview

The Veridis Cross-Chain Bridge consists of the following core components:

```

┌─────────────────────────────────────────────────────┐
│ StarkNet (Source) │
├─────────────────────────────────────────────────────┤
│ ┌───────────────┐ ┌─────────────────────────┐ │
│ │ Attestation │ │ Bridge │ │
│ │ Registry │─────►│ Contracts │ │
│ └───────────────┘ └─────────┬───────────────┘ │
└─────────────────────────────────┬─────────────────┬─┘
│ │
State Roots│ │ Messages
│ │
┌─────────────────────────────────▼─────────────────▼─┐
│ Relayer Network │
├───────────────────────────────────────────────────┬─┤
│ ┌───────────────┐ ┌─────────────────────────┐│ │
│ │ State Root │ │ Message ││ │
│ │ Relayers │ │ Relayers ││ │
│ └───────┬───────┘ └───────────┬─────────────┘│ │
└─────────┼───────────────────────────┼──────────────┘
│ │
┌─────────▼───────────┐ ┌───────────▼───────────────┐
│ Destination Chain │ │ Destination Chain │
│ Light Client │ │ Verifier Contracts │
└─────────────────────┘ └───────────────────────────┘

```

### 2.2 Component Description

#### 2.2.1 StarkNet Components

- **Attestation Registry**: Source of truth for attestations on StarkNet
- **Bridge Contracts**: Smart contracts on StarkNet that:
  - Prepare attestation data for cross-chain transmission
  - Maintain state roots for verification
  - Handle message passing to destination chains

#### 2.2.2 Relayer Network

- **State Root Relayers**: Transmit StarkNet state roots to destination chains
- **Message Relayers**: Relay attestation-related messages between chains
- **Relayer Selection Mechanism**: Protocol for selecting relayers to ensure liveness and security

#### 2.2.3 Destination Chain Components

- **Light Client**: On-chain implementation that verifies StarkNet state roots
- **Verifier Contracts**: Smart contracts that:
  - Verify attestation proofs against StarkNet state roots
  - Provide interfaces for applications to verify Veridis attestations
  - Cache verified attestation data for gas optimization

### 2.3 Data Flow

The typical data flow in the Veridis Cross-Chain Bridge involves the following steps:

1. **Attestation Issuance**: Attesters issue attestations on StarkNet through the Attestation Registry
2. **State Root Publishing**: StarkNet state roots are published to the Bridge Contract
3. **State Root Relay**: Relayers transmit StarkNet state roots to destination chain Light Clients
4. **User Proof Generation**: Users generate proofs of their attestations for cross-chain verification
5. **Proof Submission**: Users submit proofs to Verifier Contracts on destination chains
6. **Verification**: Verifier Contracts verify proofs against the latest state root
7. **Application Integration**: Applications on destination chains use verification results

## 3. Cross-Chain Message Passing

### 3.1 Message Types

The bridge supports the following types of messages:

#### 3.1.1 State Root Messages

```cairo
// StarkNet bridge contract
struct StateRootMessage {
    block_number: felt252,
    state_root: felt252,
    timestamp: felt252,
    sequencer_address: felt252,
    signature: (felt252, felt252),
}
```

#### 3.1.2 Attestation Relay Messages

```cairo
// StarkNet bridge contract
struct AttestationRelayMessage {
    attestation_type: u256,
    attester: felt252,
    merkle_root: felt252,
    expiration_time: felt252,
    nullifier_root: felt252, // Optional, for nullifier synchronization
    schema_uri: felt252,
}
```

#### 3.1.3 Bridge Control Messages

```cairo
// StarkNet bridge contract
struct BridgeControlMessage {
    message_type: felt252, // PAUSE, UNPAUSE, UPDATE_RELAYERS, etc.
    parameters: Array<felt252>, // Parameters for the control action
    authorization: felt252, // Governance authorization
}
```

### 3.2 Message Serialization

Messages are serialized using a standardized format for cross-chain transmission:

```cairo
// StarkNet bridge contract
fn serialize_message(message: Message) -> Array<felt252> {
    let mut serialized = ArrayTrait::new();

    // Add message header
    serialized.append(VERIDIS_BRIDGE_MESSAGE_HEADER);
    serialized.append(message.version);
    serialized.append(message.message_type);
    serialized.append(message.source_chain_id);
    serialized.append(message.destination_chain_id);
    serialized.append(message.nonce);

    // Add message body (depends on message type)
    match message.message_type {
        STATE_ROOT_MESSAGE => {
            serialized.append(message.payload.block_number);
            serialized.append(message.payload.state_root);
            // Additional state root fields...
        },
        ATTESTATION_RELAY_MESSAGE => {
            serialized.append(message.payload.attestation_type.low);
            serialized.append(message.payload.attestation_type.high);
            serialized.append(message.payload.attester);
            // Additional attestation fields...
        },
        BRIDGE_CONTROL_MESSAGE => {
            serialized.append(message.payload.message_type);
            // Additional control fields...
        },
        _ => {
            // Error: unsupported message type
        }
    }

    return serialized;
}
```

### 3.3 Cross-Chain Transport Protocols

The bridge leverages different cross-chain transport protocols depending on the destination chain:

#### 3.3.1 Ethereum Transport

For Ethereum and EVM-compatible chains, the bridge uses:

1. **Optimistic Relay**:

   - Messages are relayed by watchers who observe StarkNet events
   - A challenge period allows for disputing invalid messages
   - After the challenge period, messages are considered final

2. **ZK Verification** (for high-value operations):
   - StarkNet state transitions are proven via zk-STARKs
   - State roots are verified through a STARK verifier on Ethereum
   - Higher security but more expensive and slower

#### 3.3.2 Cosmos Transport

For Cosmos-based chains, the bridge uses the Inter-Blockchain Communication (IBC) protocol:

1. **IBC Packets**:
   - Messages are encoded as IBC packets
   - Light client verification ensures validity
   - Connection and channel abstractions manage the communication

#### 3.3.3 Other Chain Transports

For other chains, specialized transport protocols are implemented:

1. **Polkadot**: XCMP (Cross-Consensus Message Passing)
2. **Solana**: Wormhole message passing
3. **Algorand**: Custom bridge implementation

### 3.4 Message Ordering and Delivery Guarantees

The bridge provides the following guarantees for message delivery:

1. **Eventual Delivery**: Messages will eventually be delivered if the relayer network is functioning
2. **Order Preservation**: Messages from the same source to the same destination are delivered in order
3. **At-Least-Once Delivery**: Messages may be delivered multiple times, but never lost
4. **Idempotent Processing**: Duplicate messages are detected and processed only once

## 4. State Verification Mechanisms

### 4.1 StarkNet State Verification

#### 4.1.1 State Root Structure

StarkNet state roots are structured as follows:

```
StarkNet State Root
├── Global State Root - Merkle-Patricia Trie root of all contract states
├── Block Number - The block number this state root corresponds to
├── Block Hash - Hash of the block header
├── Timestamp - Block timestamp
└── Sequencer Signature - Signature from the sequencer (in Sequencer Mode)
```

#### 4.1.2 Light Client Implementation

The Light Client maintains a minimal but sufficient view of the StarkNet chain:

```solidity
// Ethereum implementation
contract StarkNetLightClient {
    // Latest verified state roots
    mapping(uint256 => bytes32) public stateRoots;

    // Block number to timestamp mapping
    mapping(uint256 => uint256) public blockTimestamps;

    // The latest verified block number
    uint256 public latestBlockNumber;

    // The finality parameter (number of blocks for finality)
    uint256 public finalityParameter;

    // Core verification functions
    function updateState(
        StateRootData calldata newStateRoot,
        bytes calldata proof
    ) external {
        // Verify the proof against the current state
        require(verifyStateTransition(
            stateRoots[latestBlockNumber],
            newStateRoot,
            proof
        ), "Invalid state transition");

        // Update state
        uint256 blockNumber = newStateRoot.blockNumber;
        stateRoots[blockNumber] = newStateRoot.root;
        blockTimestamps[blockNumber] = newStateRoot.timestamp;

        // Update latest block number
        if (blockNumber > latestBlockNumber) {
            latestBlockNumber = blockNumber;
        }

        emit StateRootUpdated(blockNumber, newStateRoot.root);
    }

    // Verification methods differ based on StarkNet's operation mode
    function verifyStateTransition(
        bytes32 oldStateRoot,
        StateRootData calldata newStateRoot,
        bytes calldata proof
    ) internal view returns (bool) {
        // Implementation depends on verification mechanism
        if (isZkVerificationEnabled) {
            return verifyStateTransitionZk(oldStateRoot, newStateRoot, proof);
        } else {
            return verifyStateTransitionOptimistic(oldStateRoot, newStateRoot, proof);
        }
    }

    // Additional verification and utility functions...
}
```

### 4.2 Verification Methods

The bridge supports multiple verification methods depending on security requirements:

#### 4.2.1 Optimistic Verification

For standard operations, optimistic verification is used:

1. **State Root Submission**: Relayers submit StarkNet state roots to the Light Client
2. **Challenge Period**: A window during which anyone can challenge the validity of submitted roots
3. **Stake Requirement**: Relayers must stake assets that can be slashed if they submit invalid data
4. **Verification**: After the challenge period, the state root is considered valid if not challenged

```solidity
// Ethereum implementation
function submitStateRootOptimistic(
    StateRootData calldata stateRoot,
    bytes calldata signature
) external {
    // Verify sequencer signature
    require(verifySequencerSignature(
        stateRoot.blockNumber,
        stateRoot.root,
        stateRoot.timestamp,
        signature
    ), "Invalid sequencer signature");

    // Create a new state root proposal
    uint256 proposalId = nextProposalId++;
    proposals[proposalId] = StateRootProposal({
        stateRoot: stateRoot,
        proposer: msg.sender,
        proposalTime: block.timestamp,
        challengeEndTime: block.timestamp + CHALLENGE_PERIOD,
        status: ProposalStatus.Pending
    });

    // Lock proposer's stake
    stakingContract.lockStake(msg.sender, REQUIRED_STAKE);

    emit StateRootProposed(proposalId, stateRoot.blockNumber, stateRoot.root);
}
```

#### 4.2.2 ZK Verification

For high-security operations, zero-knowledge verification is used:

1. **STARK Proof Generation**: Proofs of StarkNet state transitions are generated
2. **On-Chain Verification**: The STARK proof is verified on the destination chain
3. **Immediate Finality**: Once verified, the state root is immediately considered valid

```solidity
// Ethereum implementation
function submitStateRootZk(
    StateRootData calldata stateRoot,
    bytes calldata starkProof
) external {
    // Verify the STARK proof
    require(starkVerifier.verify(
        stateRoot.blockNumber,
        stateRoots[stateRoot.blockNumber - 1],
        stateRoot.root,
        starkProof
    ), "Invalid STARK proof");

    // Update state immediately (no challenge period)
    stateRoots[stateRoot.blockNumber] = stateRoot.root;
    blockTimestamps[stateRoot.blockNumber] = stateRoot.timestamp;

    // Update latest block number
    if (stateRoot.blockNumber > latestBlockNumber) {
        latestBlockNumber = stateRoot.blockNumber;
    }

    emit StateRootUpdated(stateRoot.blockNumber, stateRoot.root);
}
```

### 4.3 Merkle Proof Verification

Once state roots are verified, attestation verification uses Merkle proofs:

```solidity
// Ethereum implementation
function verifyAttestationInclusion(
    uint256 attestationType,
    address attester,
    bytes32 merkleRoot,
    bytes32 leafHash,
    bytes32[] calldata merkleProof,
    uint256 blockNumber
) public view returns (bool) {
    // Get the verified state root for the given block
    bytes32 stateRoot = stateRoots[blockNumber];
    require(stateRoot != bytes32(0), "State root not available");

    // Verify the attestation registry state against the state root
    require(verifyRegistryState(
        stateRoot,
        attestationType,
        attester,
        merkleRoot,
        blockNumber
    ), "Invalid registry state");

    // Verify the Merkle proof against the attestation Merkle root
    return verifyMerkleProof(
        merkleRoot,
        leafHash,
        merkleProof
    );
}
```

## 5. Trust Model and Security

### 5.1 Trust Assumptions

The bridge operates under the following trust assumptions:

#### 5.1.1 Core Trust Assumptions

1. **StarkNet Security**: The source chain (StarkNet) operates correctly
2. **Destination Chain Security**: Destination chains operate correctly
3. **Cryptographic Assumptions**: Standard cryptographic assumptions about hash functions, signatures, etc.

#### 5.1.2 Method-Specific Trust Assumptions

1. **Optimistic Verification**:

   - At least one honest watcher monitors proposed state roots
   - Economic incentives are sufficient to prevent collusion
   - Challenge mechanism functions correctly

2. **ZK Verification**:
   - STARK cryptographic assumptions hold
   - STARK verification contracts are correctly implemented
   - No critical bugs in the verification system

#### 5.1.3 Relayer Assumptions

1. **Liveness**: Sufficient relayers are operational to ensure message delivery
2. **Economic Security**: Slashing and reward mechanisms properly incentivize honest behavior
3. **Diversity**: Relayers are sufficiently decentralized to prevent coordinated attacks

### 5.2 Threat Model

The bridge's security design addresses the following threats:

#### 5.2.1 Malicious Relayers

**Threat**: Relayers may submit invalid state roots or messages

**Mitigations**:

- Economic staking requirements with slashing conditions
- Challenge period for optimistic verification
- Cryptographic verification for ZK approach
- Relayer reputation system
- Multi-signature requirements for critical operations

#### 5.2.2 Data Withholding

**Threat**: Relayers may withhold messages to censor specific users or transactions

**Mitigations**:

- Multiple redundant relayers
- Economic incentives for timely message delivery
- Permissionless relayer system allowing anyone to participate
- Monitoring systems to detect censorship attempts

#### 5.2.3 Replay Attacks

**Threat**: Valid messages may be replayed on the same or different chains

**Mitigations**:

- Unique nonce for each message
- Destination chain ID included in message
- Message execution records to prevent duplicate processing
- Timeout mechanisms for expired messages

#### 5.2.4 Sybil Attacks

**Threat**: An attacker may create multiple relayer identities to control the network

**Mitigations**:

- Substantial staking requirements
- Reputation-based selection
- Weighted selection based on stake and performance
- Regular rotation of active relayer sets

### 5.3 Security Mechanisms

#### 5.3.1 Economic Security

The bridge implements economic security through:

1. **Staking Requirements**:

   - Relayers must stake a significant amount of assets
   - Minimum stake: 5,000 ETH (or equivalent) for State Root Relayers
   - Minimum stake: 1,000 ETH (or equivalent) for Message Relayers

2. **Slashing Conditions**:

   - Invalid state root submission: 50% of stake
   - Proven censorship: 25% of stake
   - Repeated timeouts: 10% of stake

3. **Reward Structure**:
   - Base fee for successful message delivery
   - Premium for high-priority messages
   - Reputation multiplier for consistent performance

#### 5.3.2 Cryptographic Security

Cryptographic security is ensured through:

1. **Signature Schemes**:

   - StarkNet Sequencer: ECDSA over STARK curve
   - Relayers: Schnorr signatures for aggregation efficiency
   - Bridge Governance: Multi-signature threshold scheme

2. **Proof Systems**:

   - STARK proofs for state transition verification
   - Merkle proofs for state inclusion verification
   - Zero-knowledge proofs for privacy-preserving verification

3. **Key Management**:
   - Distributed key generation for shared keys
   - Hardware security module requirements for relayers
   - Key rotation schedules for long-term security

#### 5.3.3 Operational Security

Operational security measures include:

1. **Monitoring and Alerting**:

   - Real-time monitoring of bridge operations
   - Anomaly detection systems
   - Emergency response procedures

2. **Rate Limiting and Circuit Breakers**:

   - Graduated rate limits for message processing
   - Automatic circuit breakers for abnormal activity
   - Manual emergency pause capabilities

3. **Upgradeability and Governance**:
   - Time-locked upgrades with verification period
   - Multi-signature requirements for critical changes
   - Governance-controlled parameters for flexibility

## 6. Supported Chains

### 6.1 Ethereum and EVM Chains

#### 6.1.1 Ethereum Mainnet Integration

```solidity
// Ethereum implementation
contract VeridisBridgeEthereum {
    // StarkNet Light Client reference
    StarkNetLightClient public lightClient;

    // Verified attestation registry
    mapping(address => mapping(uint256 => AttestationData)) public verifiedAttestations;

    // Nullifier registry
    mapping(bytes32 => bool) public nullifiers;

    // Bridge contract on StarkNet
    uint256 public starknetBridgeAddress;

    // Core verification function
    function verifyAttestation(
        uint256 attestationType,
        address attester,
        bytes32 merkleRoot,
        uint256 blockNumber,
        bytes calldata proof
    ) external returns (bool) {
        // Verify against light client state
        require(lightClient.verifyAttestationInclusion(
            attestationType,
            attester,
            merkleRoot,
            blockNumber,
            proof
        ), "Invalid attestation proof");

        // Store verified attestation
        verifiedAttestations[attester][attestationType] = AttestationData({
            merkleRoot: merkleRoot,
            verifiedAt: block.timestamp,
            blockNumber: blockNumber
        });

        emit AttestationVerified(attester, attestationType, merkleRoot);
        return true;
    }

    // Zero-knowledge credential verification
    function verifyCredentialZk(
        ZkProof calldata proof,
        VerificationPublicInputs calldata publicInputs
    ) external returns (bool) {
        // Verify the credential's attestation is registered
        AttestationData storage attestation = verifiedAttestations[
            address(uint160(publicInputs.attester))
        ][publicInputs.attestationType];

        require(attestation.merkleRoot == publicInputs.merkleRoot,
                "Attestation not verified on this chain");

        // Verify the ZK proof
        require(zkVerifier.verify(proof, publicInputs), "Invalid ZK proof");

        // Check nullifier if required
        if (publicInputs.hasNullifier) {
            require(!nullifiers[publicInputs.nullifier], "Nullifier already used");
            nullifiers[publicInputs.nullifier] = true;
        }

        emit CredentialVerified(
            publicInputs.attestationType,
            publicInputs.attester,
            publicInputs.hasNullifier ? publicInputs.nullifier : bytes32(0)
        );

        return true;
    }

    // Additional bridge functions...
}
```

#### 6.1.2 Other EVM Chains

The bridge supports the following EVM-compatible chains with similar implementations:

1. **Polygon**:

   - Custom gas optimizations for Polygon's fee structure
   - Checkpointing integration for additional security

2. **Arbitrum**:

   - Integration with Arbitrum's Nitro sequencing
   - Optimized message passing using Arbitrum's native bridge

3. **Optimism**:
   - L2-to-L2 message passing optimization
   - Direct attestation relay via Optimism's message passing

### 6.2 Cosmos Ecosystem

#### 6.2.1 Cosmos Integration

```go
// Cosmos implementation
package veridisbridge

import (
    "github.com/cosmos/cosmos-sdk/types"
    "github.com/cosmos/ibc-go/modules/core/exported"
)

// Bridge Keeper
type Keeper struct {
    storeKey         sdk.StoreKey
    cdc              codec.BinaryCodec
    lightClientKeeper LightClientKeeper
    ibcKeeper        ibckeeper.Keeper
}

// Verify attestation from StarkNet
func (k Keeper) VerifyAttestation(
    ctx sdk.Context,
    attestationType uint64,
    attester string,
    merkleRoot []byte,
    blockNumber uint64,
    proof []byte,
) (bool, error) {
    // Verify against light client state
    valid, err := k.lightClientKeeper.VerifyAttestationInclusion(
        ctx,
        attestationType,
        attester,
        merkleRoot,
        blockNumber,
        proof,
    )
    if err != nil || !valid {
        return false, err
    }

    // Store verified attestation
    k.SetVerifiedAttestation(
        ctx,
        attester,
        attestationType,
        merkleRoot,
        blockNumber,
    )

    // Emit event
    ctx.EventManager().EmitEvent(
        sdk.NewEvent(
            "attestation_verified",
            sdk.NewAttribute("attester", attester),
            sdk.NewAttribute("attestation_type", fmt.Sprintf("%d", attestationType)),
            sdk.NewAttribute("merkle_root", hex.EncodeToString(merkleRoot)),
        ),
    )

    return true, nil
}

// Verify ZK proof of credential
func (k Keeper) VerifyCredentialZk(
    ctx sdk.Context,
    proof []byte,
    publicInputs VerificationPublicInputs,
) (bool, error) {
    // Verify the credential's attestation is registered
    attestation, found := k.GetVerifiedAttestation(
        ctx,
        publicInputs.Attester,
        publicInputs.AttestationType,
    )
    if !found || !bytes.Equal(attestation.MerkleRoot, publicInputs.MerkleRoot) {
        return false, errors.New("attestation not verified on this chain")
    }

    // Verify the ZK proof
    valid, err := k.zkVerifier.Verify(proof, publicInputs)
    if err != nil || !valid {
        return false, errors.New("invalid ZK proof")
    }

    // Check nullifier if required
    if publicInputs.HasNullifier {
        if k.IsNullifierUsed(ctx, publicInputs.Nullifier) {
            return false, errors.New("nullifier already used")
        }
        k.SetNullifier(ctx, publicInputs.Nullifier)
    }

    // Emit event
    ctx.EventManager().EmitEvent(
        sdk.NewEvent(
            "credential_verified",
            sdk.NewAttribute("attestation_type", fmt.Sprintf("%d", publicInputs.AttestationType)),
            sdk.NewAttribute("attester", publicInputs.Attester),
        ),
    )

    return true, nil
}
```

#### 6.2.2 Supported Cosmos Chains

The bridge supports the following Cosmos-based chains:

1. **Cosmos Hub**:

   - Integration with the Cosmos Hub for broad ecosystem connectivity
   - Use of IBC for secure cross-chain communication

2. **Osmosis**:

   - Specialized integration for DeFi applications
   - Optimized for attestation-based compliance in DeFi

3. **Axelar**:
   - Integration with Axelar's General Message Passing
   - Expanded reach to additional connected networks

### 6.3 Other Supported Chains

#### 6.3.1 Solana Integration

```rust
// Solana implementation
use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint,
    entrypoint::ProgramResult,
    pubkey::Pubkey,
    program_error::ProgramError,
};

// Program ID: [Veridis Bridge Program ID]
entrypoint!(process_instruction);

// Main processing function
pub fn process_instruction(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    instruction_data: &[u8],
) -> ProgramResult {
    // Parse instruction type
    let instruction = VeridisBridgeInstruction::unpack(instruction_data)?;

    match instruction {
        VeridisBridgeInstruction::VerifyAttestation {
            attestation_type,
            attester,
            merkle_root,
            block_number,
            proof,
        } => {
            verify_attestation(
                program_id,
                accounts,
                attestation_type,
                attester,
                merkle_root,
                block_number,
                &proof,
            )
        },
        VeridisBridgeInstruction::VerifyCredentialZk {
            proof,
            public_inputs,
        } => {
            verify_credential_zk(
                program_id,
                accounts,
                &proof,
                &public_inputs,
            )
        },
        // Other instructions...
    }
}

// Verify attestation from StarkNet
fn verify_attestation(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    attestation_type: u64,
    attester: [u8; 32],
    merkle_root: [u8; 32],
    block_number: u64,
    proof: &[u8],
) -> ProgramResult {
    let account_iter = &mut accounts.iter();

    // Get account references
    let light_client_account = next_account_info(account_iter)?;
    let verified_attestations_account = next_account_info(account_iter)?;
    let payer = next_account_info(account_iter)?;

    // Check ownership
    if light_client_account.owner != program_id {
        return Err(ProgramError::IncorrectProgramId);
    }

    // Verify against light client state
    if !verify_attestation_inclusion(
        light_client_account,
        attestation_type,
        &attester,
        &merkle_root,
        block_number,
        proof,
    )? {
        return Err(ProgramError::InvalidArgument);
    }

    // Store verified attestation
    store_verified_attestation(
        verified_attestations_account,
        &attester,
        attestation_type,
        &merkle_root,
        block_number,
    )?;

    Ok(())
}
```

#### 6.3.2 Polkadot Integration

```rust
// Polkadot implementation
use frame_support::{
    decl_module, decl_storage, decl_event, decl_error,
    dispatch::DispatchResult,
};
use frame_system::ensure_signed;

#[frame_support::pallet]
pub mod veridis_bridge {
    use super::*;

    #[pallet::storage]
    #[pallet::getter(fn verified_attestations)]
    pub type VerifiedAttestations<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat, T::AccountId,  // attester
        Blake2_128Concat, u64,          // attestation_type
        AttestationData,
    >;

    #[pallet::storage]
    #[pallet::getter(fn nullifiers)]
    pub type Nullifiers<T: Config> = StorageMap<
        _,
        Blake2_128Concat, [u8; 32],     // nullifier
        bool,
        ValueQuery,
    >;

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        #[pallet::weight(10_000)]
        pub fn verify_attestation(
            origin: OriginFor<T>,
            attestation_type: u64,
            attester: T::AccountId,
            merkle_root: [u8; 32],
            block_number: u64,
            proof: Vec<u8>,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Verify against light client state
            ensure!(
                T::LightClient::verify_attestation_inclusion(
                    attestation_type,
                    &attester,
                    &merkle_root,
                    block_number,
                    &proof,
                ),
                Error::<T>::InvalidAttestationProof
            );

            // Store verified attestation
            VerifiedAttestations::<T>::insert(
                attester.clone(),
                attestation_type,
                AttestationData {
                    merkle_root,
                    verified_at: <frame_system::Pallet<T>>::block_number(),
                    block_number,
                },
            );

            // Emit event
            Self::deposit_event(Event::AttestationVerified(
                attester,
                attestation_type,
                merkle_root,
            ));

            Ok(())
        }

        #[pallet::weight(15_000)]
        pub fn verify_credential_zk(
            origin: OriginFor<T>,
            proof: Vec<u8>,
            public_inputs: VerificationPublicInputs,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Verify the credential's attestation is registered
            let attestation = VerifiedAttestations::<T>::get(
                public_inputs.attester.clone(),
                public_inputs.attestation_type,
            ).ok_or(Error::<T>::AttestationNotVerified)?;

            ensure!(
                attestation.merkle_root == public_inputs.merkle_root,
                Error::<T>::AttestationMismatch
            );

            // Verify the ZK proof
            ensure!(
                T::ZkVerifier::verify(&proof, &public_inputs),
                Error::<T>::InvalidZkProof
            );

            // Check nullifier if required
            if public_inputs.has_nullifier {
                ensure!(
                    !Nullifiers::<T>::contains_key(public_inputs.nullifier),
                    Error::<T>::NullifierAlreadyUsed
                );
                Nullifiers::<T>::insert(public_inputs.nullifier, true);
            }

            // Emit event
            Self::deposit_event(Event::CredentialVerified(
                public_inputs.attestation_type,
                public_inputs.attester,
                public_inputs.has_nullifier,
                public_inputs.nullifier,
            ));

            Ok(())
        }
    }
}
```

## 7. Cross-Chain Attestation Protocol

### 7.1 Attestation Relay Protocol

The protocol for relaying attestations across chains consists of the following steps:

1. **Attestation Registration**:

   - Attesters register attestations on StarkNet through the Attestation Registry
   - The bridge monitors for new attestation events

2. **Merkle Root Relay**:

   - Merkle roots of attestation trees are relayed to destination chains
   - State roots containing these Merkle roots are verified on destination chains

3. **User Proof Generation**:

   - Users generate Merkle proofs of their attestation inclusion
   - These proofs can be presented on any supported destination chain

4. **Cross-Chain Verification**:
   - Users submit proofs to Verifier Contracts on destination chains
   - Verifiers check proofs against the latest verified state roots

### 7.2 Zero-Knowledge Credential Verification

For privacy-preserving verification, the protocol extends with ZK proofs:

1. **Credential ZK Proof Generation**:

   - Users generate zero-knowledge proofs of credential possession
   - These proofs reveal only the minimum necessary information

2. **Cross-Chain ZK Verification**:
   - Users submit ZK proofs to destination chain verifiers
   - Verifiers check that the underlying attestation is valid
   - Verifiers validate the ZK proof to confirm credential properties

```cairo
// StarkNet implementation
#[external(v0)]
fn prepare_cross_chain_verification(
    ref self: ContractState,
    attestation_type: u256,
    attester: ContractAddress,
    destination_chain_id: felt252,
) -> CrossChainVerificationData {
    // Get attestation data
    let attestation = self.attestation_registry.get_tier1_attestation(
        attester,
        attestation_type
    );

    // Verify attestation exists and is valid
    assert(!attestation.revoked, 'Attestation revoked');
    assert(attestation.expiration_time > get_block_timestamp(), 'Attestation expired');

    // Get latest state root info for the attestation
    let state_info = self.get_state_root_info(attestation.merkle_root);

    // Prepare cross-chain verification data
    return CrossChainVerificationData {
        attestation_type: attestation_type,
        attester: attester.into(),
        merkle_root: attestation.merkle_root,
        block_number: state_info.block_number,
        state_root: state_info.state_root,
        destination_chain_id: destination_chain_id,
    };
}
```

### 7.3 Nullifier Synchronization

To prevent double-use of credentials across chains, nullifiers are synchronized:

1. **Nullifier Registration**:

   - When a nullifier is used on the source chain, it's registered in the Nullifier Registry
   - The bridge monitors for new nullifier registrations

2. **Nullifier Relay**:

   - New nullifiers are relayed to all destination chains
   - Nullifier Merkle trees are maintained for efficient verification

3. **Cross-Chain Nullifier Verification**:
   - When verifying credentials on destination chains, nullifiers are checked
   - If a nullifier was used on any chain, it's considered used everywhere

```solidity
// Ethereum implementation
function syncNullifiers(
    bytes32[] calldata nullifiers,
    bytes32 nullifierRoot,
    bytes calldata proof,
    uint256 blockNumber
) external {
    // Verify the nullifier root against the StarkNet state
    require(lightClient.verifyNullifierRoot(
        nullifierRoot,
        blockNumber,
        proof
    ), "Invalid nullifier root proof");

    // Verify the nullifiers against the nullifier root
    require(verifyNullifiersInclusion(
        nullifiers,
        nullifierRoot,
        proof
    ), "Invalid nullifier inclusion proof");

    // Register all nullifiers
    for (uint i = 0; i < nullifiers.length; i++) {
        if (!isNullifierUsed(nullifiers[i])) {
            setNullifierUsed(nullifiers[i]);
            emit NullifierSynced(nullifiers[i]);
        }
    }
}
```

### 7.4 Cross-Chain Identity

The bridge also supports cross-chain identity functionality:

1. **Identity Commitment Relay**:

   - Users can register their identity commitments on StarkNet
   - These commitments can be relayed to destination chains

2. **Cross-Chain Identity Verification**:

   - Users can prove ownership of the same identity across chains
   - This enables consistent identity across the ecosystem

3. **Cross-Chain Reputation**:
   - Reputation and attestations from multiple chains can be combined
   - Provides a holistic view of user reputation across the ecosystem

## 8. Implementation Design

### 8.1 StarkNet Bridge Contract

The core StarkNet bridge contract implementation:

```cairo
#[starknet::contract]
mod VeridisBridge {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;

    #[storage]
    struct Storage {
        // Governance
        governance: ContractAddress,

        // Attestation Registry reference
        attestation_registry: ContractAddress,

        // Nullifier Registry reference
        nullifier_registry: ContractAddress,

        // State roots
        state_roots: LegacyMap::<u256, felt252>,
        latest_block_number: u256,

        // Destination chains
        supported_chains: LegacyMap::<felt252, bool>,

        // Relayers
        authorized_relayers: LegacyMap::<ContractAddress, bool>,

        // Operational state
        paused: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StateRootPublished: StateRootPublished,
        AttestationRelayed: AttestationRelayed,
        NullifierRelayed: NullifierRelayed,
        ChainAdded: ChainAdded,
        ChainRemoved: ChainRemoved,
        RelayerAdded: RelayerAdded,
        RelayerRemoved: RelayerRemoved,
        BridgePaused: BridgePaused,
        BridgeUnpaused: BridgeUnpaused,
    }

    #[derive(Drop, starknet::Event)]
    struct StateRootPublished {
        block_number: u256,
        state_root: felt252,
        timestamp: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct AttestationRelayed {
        attestation_type: u256,
        attester: ContractAddress,
        merkle_root: felt252,
        destination_chain: felt252,
    }

    // Constructor
    #[constructor]
    fn constructor(
        ref self: ContractState,
        governance: ContractAddress,
        attestation_registry: ContractAddress,
        nullifier_registry: ContractAddress,
    ) {
        self.governance.write(governance);
        self.attestation_registry.write(attestation_registry);
        self.nullifier_registry.write(nullifier_registry);
    }

    // Publish state root
    #[external(v0)]
    fn publish_state_root(
        ref self: ContractState,
        block_number: u256,
        state_root: felt252,
    ) {
        // Only governance can publish state roots
        let caller = get_caller_address();
        assert(caller == self.governance.read(), 'Not governance');

        // Store state root
        self.state_roots.write(block_number, state_root);

        // Update latest block number if needed
        let current_latest = self.latest_block_number.read();
        if block_number > current_latest {
            self.latest_block_number.write(block_number);
        }

        // Emit event
        self.emit(StateRootPublished {
            block_number: block_number,
            state_root: state_root,
            timestamp: get_block_timestamp().into(),
        });
    }

    // Relay attestation
    #[external(v0)]
    fn relay_attestation(
        ref self: ContractState,
        attestation_type: u256,
        attester: ContractAddress,
        destination_chain: felt252,
    ) {
        // Check not paused
        assert(!self.paused.read(), 'Bridge paused');

        // Only authorized relayers
        let caller = get_caller_address();
        assert(self.authorized_relayers.read(caller), 'Not authorized relayer');

        // Check destination chain is supported
        assert(self.supported_chains.read(destination_chain), 'Unsupported chain');

        // Get attestation from registry
        let attestation = self.get_attestation(attestation_type, attester);

        // Check attestation is valid
        assert(!attestation.revoked, 'Attestation revoked');

        // Emit event for relayers to pick up
        self.emit(AttestationRelayed {
            attestation_type: attestation_type,
            attester: attester,
            merkle_root: attestation.merkle_root,
            destination_chain: destination_chain,
        });
    }

    // Get verification data for cross-chain verification
    #[view]
    fn get_verification_data(
        self: @ContractState,
        attestation_type: u256,
        attester: ContractAddress,
    ) -> VerificationData {
        // Get attestation from registry
        let attestation = self.get_attestation(attestation_type, attester);

        // Find block number containing this attestation
        let block_number = self.find_block_for_attestation(
            attestation_type,
            attester,
            attestation.merkle_root,
        );

        // Get state root for that block
        let state_root = self.state_roots.read(block_number);

        return VerificationData {
            attestation_type: attestation_type,
            attester: attester,
            merkle_root: attestation.merkle_root,
            block_number: block_number,
            state_root: state_root,
        };
    }

    // Internal function to get attestation
    #[internal]
    fn get_attestation(
        self: @ContractState,
        attestation_type: u256,
        attester: ContractAddress,
    ) -> AttestationData {
        let attestation_registry = IAttestationRegistry(self.attestation_registry.read());
        return attestation_registry.get_tier1_attestation(attester, attestation_type);
    }

    // Governance functions for managing the bridge
    #[external(v0)]
    fn add_supported_chain(
        ref self: ContractState,
        chain_id: felt252,
    ) {
        // Only governance can add chains
        let caller = get_caller_address();
        assert(caller == self.governance.read(), 'Not governance');

        self.supported_chains.write(chain_id, true);

        self.emit(ChainAdded { chain_id: chain_id });
    }

    #[external(v0)]
    fn remove_supported_chain(
        ref self: ContractState,
        chain_id: felt252,
    ) {
        // Only governance can remove chains
        let caller = get_caller_address();
        assert(caller == self.governance.read(), 'Not governance');

        self.supported_chains.write(chain_id, false);

        self.emit(ChainRemoved { chain_id: chain_id });
    }

    #[external(v0)]
    fn add_relayer(
        ref self: ContractState,
        relayer: ContractAddress,
    ) {
        // Only governance can add relayers
        let caller = get_caller_address();
        assert(caller == self.governance.read(), 'Not governance');

        self.authorized_relayers.write(relayer, true);

        self.emit(RelayerAdded { relayer: relayer });
    }

    #[external(v0)]
    fn remove_relayer(
        ref self: ContractState,
        relayer: ContractAddress,
    ) {
        // Only governance can remove relayers
        let caller = get_caller_address();
        assert(caller == self.governance.read(), 'Not governance');

        self.authorized_relayers.write(relayer, false);

        self.emit(RelayerRemoved { relayer: relayer });
    }

    #[external(v0)]
    fn pause_bridge(ref self: ContractState) {
        // Only governance can pause
        let caller = get_caller_address();
        assert(caller == self.governance.read(), 'Not governance');

        self.paused.write(true);

        self.emit(BridgePaused {});
    }

    #[external(v0)]
    fn unpause_bridge(ref self: ContractState) {
        // Only governance can unpause
        let caller = get_caller_address();
        assert(caller == self.governance.read(), 'Not governance');

        self.paused.write(false);

        self.emit(BridgeUnpaused {});
    }
}
```

### 8.2 Relayer Implementation

The reference implementation for bridge relayers:

```typescript
// Relayer implementation (TypeScript)
import { StarknetProvider, Contract } from "starknet";
import { ethers } from "ethers";

class VeridisBridgeRelayer {
  // StarkNet provider
  private starknetProvider: StarknetProvider;

  // Destination chain provider
  private destinationProvider: ethers.providers.Provider;

  // Bridge contracts
  private starknetBridge: Contract;
  private destinationBridge: ethers.Contract;

  // Relayer configuration
  private config: RelayerConfig;

  // Relayer state
  private lastProcessedBlock: number;
  private isRunning: boolean;

  constructor(config: RelayerConfig) {
    this.config = config;
    this.starknetProvider = new StarknetProvider(config.starknetRpc);
    this.destinationProvider = new ethers.providers.JsonRpcProvider(
      config.destinationRpc
    );

    // Initialize contracts
    this.starknetBridge = new Contract(
      starknetBridgeAbi,
      config.starknetBridgeAddress,
      this.starknetProvider
    );

    this.destinationBridge = new ethers.Contract(
      config.destinationBridgeAddress,
      destinationBridgeAbi,
      new ethers.Wallet(config.relayerPrivateKey, this.destinationProvider)
    );

    // Initialize state
    this.lastProcessedBlock = config.startBlock || 0;
    this.isRunning = false;
  }

  // Start relayer
  public async start(): Promise<void> {
    if (this.isRunning) return;
    this.isRunning = true;

    console.log(
      `Starting Veridis bridge relayer from block ${this.lastProcessedBlock}`
    );

    try {
      // Main relayer loop
      while (this.isRunning) {
        await this.processNewEvents();
        await new Promise((resolve) =>
          setTimeout(resolve, this.config.pollingInterval)
        );
      }
    } catch (error) {
      console.error("Relayer error:", error);
      this.isRunning = false;
      throw error;
    }
  }

  // Stop relayer
  public stop(): void {
    this.isRunning = false;
    console.log("Stopping Veridis bridge relayer");
  }

  // Process new events
  private async processNewEvents(): Promise<void> {
    // Get latest block number
    const latestBlock = await this.starknetProvider.getBlockNumber();

    if (latestBlock <= this.lastProcessedBlock) {
      return; // No new blocks
    }

    const fromBlock = this.lastProcessedBlock + 1;
    const toBlock = Math.min(
      latestBlock,
      fromBlock + this.config.maxBlocksPerBatch - 1
    );

    console.log(`Processing blocks ${fromBlock} to ${toBlock}`);

    // Get events from StarkNet bridge
    const events = await this.starknetBridge.getPastEvents(
      "AttestationRelayed",
      {
        fromBlock,
        toBlock,
        filters: {
          destination_chain: this.config.destinationChainId,
        },
      }
    );

    // Process each event
    for (const event of events) {
      await this.relayAttestation(event);
    }

    // Update last processed block
    this.lastProcessedBlock = toBlock;

    // Persist state
    this.persistState();
  }

  // Relay a single attestation
  private async relayAttestation(event: any): Promise<void> {
    try {
      const { attestation_type, attester, merkle_root } = event.args;

      console.log(
        `Relaying attestation: type=${attestation_type}, attester=${attester}`
      );

      // Get verification data
      const verificationData = await this.starknetBridge.call(
        "get_verification_data",
        [attestation_type, attester]
      );

      // Prepare state proof
      const stateProof = await this.generateStateProof(
        verificationData.block_number,
        verificationData.state_root
      );

      // Submit to destination chain
      const tx = await this.destinationBridge.relayAttestation(
        attestation_type,
        attester,
        merkle_root,
        verificationData.block_number,
        stateProof,
        { gasLimit: this.config.gasLimit }
      );

      console.log(`Attestation relayed, tx hash: ${tx.hash}`);

      // Wait for confirmation
      await tx.wait(this.config.confirmations);

      console.log(`Attestation relay confirmed`);
    } catch (error) {
      console.error("Error relaying attestation:", error);
      // Implement retry logic or error reporting
    }
  }

  // Generate state proof
  private async generateStateProof(
    blockNumber: number,
    stateRoot: string
  ): Promise<string> {
    // Implementation depends on the specific proof system
    // This is a placeholder for the actual proof generation
    return "0x..."; // Actual proof would be generated here
  }

  // Persist relayer state
  private persistState(): void {
    // Save last processed block to persistent storage
    // Implementation depends on storage mechanism (file, database, etc.)
  }
}

// Start a relayer instance
async function main() {
  const relayer = new VeridisBridgeRelayer({
    starknetRpc: "https://starknet-mainnet.infura.io/v3/...",
    destinationRpc: "https://mainnet.infura.io/v3/...",
    starknetBridgeAddress: "0x...",
    destinationBridgeAddress: "0x...",
    relayerPrivateKey: "0x...",
    destinationChainId: "1", // Ethereum mainnet
    pollingInterval: 15000, // 15 seconds
    maxBlocksPerBatch: 100,
    gasLimit: 500000,
    confirmations: 3,
  });

  await relayer.start();
}
```

### 8.3 Light Client Implementation

The implementation of the StarkNet Light Client on Ethereum:

````solidity
// Ethereum implementation
contract StarkNetLightClient {
    // Chain ID of the StarkNet chain being tracked
    uint256 public immutable STARKNET_CHAIN_ID;

    // Storage for state roots
    mapping(uint256 => bytes32) public stateRoots;

    // Latest verified block number
    uint256 public latestVerifiedBlockNumber;

    // StarkNet program hash for verification
    bytes32 public immutable STARKNET_PROGRAM_HASH;

    // Verification keys
    address public starkVerifier;

    // Challenge period for optimistic verification
    uint256 public immutable CHALLENGE_PERIOD;

    // Governance
    address public governance;

    // Relayer registry
    mapping(address => bool) public authorizedRelayers;

    // Operational state
    bool public paused;

    // Events
    event StateRootUpdated(uint256 indexed blockNumber, bytes32 stateRoot);
    event StateRootProposed(uint256 indexed proposalId, uint256 blockNumber, bytes32 stateRoot);
    event StateRootChallenged(uint256 indexed proposalId, address challenger);
    event RelayerAdded(address indexed relayer);
    event RelayerRemoved(address indexed relayer);
    event ClientPaused();
    event ClientUnpaused();

    // State root proposals for optimistic verification
    struct StateRootProposal {
        uint256 blockNumber;
        bytes32 stateRoot;
        address proposer;
        uint256 proposalTime;
        uint256 challengeEndTime;
        bool challenged;
        bool finalized;
    }

    // Proposals storage
    mapping(uint256 => StateRootProposal) public proposals;
    uint256 public nextProposalId;

    // Constructor
    constructor(
        uint256 starknetChainId,
        bytes32 starknetProgramHash,
        address initialGovernance,
        address initialStarkVerifier,
        uint256 challengePeriod
    ) {
        STARKNET_CHAIN_ID = starknetChainId;
        STARKNET_PROGRAM_HASH = starknetProgramHash;
        governance = initialGovernance;
        starkVerifier = initialStarkVerifier;
        CHALLENGE_PERIOD = challengePeriod;
    }

    // Update state optimistically
    function updateStateOptimistic(
        uint256 blockNumber,
        bytes32 stateRoot,
        bytes calldata signature
    ) external {
        // Ensure not paused
        require(!paused, "Client is paused");

        // Only authorized relayers
        require(authorizedRelayers[msg.sender], "Not authorized");

        // Block number must be greater than latest verified
        require(blockNumber > latestVerifiedBlockNumber, "Old block");

        // Verify the StarkNet sequencer signature
        require(verifySequencerSignature(
            blockNumber,
            stateRoot,
            signature
        ), "Invalid signature");

        // Create proposal
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = StateRootProposal({
            blockNumber: blockNumber,
            stateRoot: stateRoot,
            proposer: msg.sender,
            proposalTime: block.timestamp,
            challengeEndTime: block.timestamp + CHALLENGE_PERIOD,
            challenged: false,
            finalized: false
        });

        emit StateRootProposed(proposalId, blockNumber, stateRoot);
    }

    // Finalize a state root proposal after challenge period
    function finalizeStateRoot(uint256 proposalId) external {
        // Get proposal
        StateRootProposal storage proposal = proposals[proposalId];

        // Check proposal exists
        require(proposal.proposalTime > 0, "Proposal does not exist");

        // Check not already finalized
        require(!proposal.finalized, "Already finalized");

        // Check not challenged
        require(!proposal.challenged, "Proposal was challenged");

        // Check challenge period has passed
        require(block.timestamp >= proposal.challengeEndTime, "Challenge period active");

        // Finalize proposal
        proposal.finalized = true;

        // Update state root
        stateRoots[proposal.blockNumber] = proposal.stateRoot;

        // Update latest verified block number if needed
        if (proposal.blockNumber > latestVerifiedBlockNumber) {
            latestVerifiedBlockNumber = proposal.blockNumber;
        }

        emit StateRootUpdated(proposal.blockNumber, proposal.stateRoot);
    }

    // Challenge a state root proposal
    function challengeStateRoot(
        uint256 proposalId,
        bytes calldata challengeData
    ) external {
        // Get proposal
        StateRootProposal storage proposal = proposals[proposalId];

        // Check proposal exists
        require(proposal.proposalTime > 0, "Proposal does not exist");

        // Check not already finalized
        require(!proposal.finalized, "Already finalized");

        // Check not already challenged
        require(!proposal.challenged, "Already challenged");

        // Check challenge period still active
        require(block.timestamp < proposal.challengeEndTime, "Challenge period ended");

        // Verify the challenge is valid
        require(verifyChallengeData(
            proposal.blockNumber,
            proposal.stateRoot,
            challengeData
        ), "Invalid challenge");

        // Mark as challenged
        proposal.challenged = true;

        emit StateRootChallenged(proposalId, msg.sender);

        // Slashing of proposer could be implemented here
    }

    // Update state with ZK proof
    function updateStateZk(
        uint256 blockNumber,
        bytes32 stateRoot,
        bytes calldata starkProof
    ) external {
        // Ensure not paused
        require(!paused, "Client is paused");

        // Block number must be greater than latest verified
        require(blockNumber > latestVerifiedBlockNumber, "Old block");

        // Verify the STARK proof
        IStarkVerifier verifier = IStarkVerifier(starkVerifier);
        require(verifier.verify(
            STARKNET_PROGRAM_HASH,
            blockNumber,
            stateRoot,
            starkProof
        ), "Invalid STARK proof");

        // Update state root
        stateRoots[blockNumber] = stateRoot;

        // Update latest verified block number
        latestVerifiedBlockNumber = blockNumber;

        emit StateRootUpdated(blockNumber, stateRoot);
    }

    // Verify attestation data is included in the StarkNet state
    function verifyAttestationInclusion(
        uint256 attestationType,
        address attester,
        bytes32 merkleRoot,
        uint256 blockNumber,
        bytes calldata proof
    ) public view returns (bool) {
        // Check block has been verified
        bytes32 stateRoot = stateRoots[blockNumber];
        require(stateRoot != bytes32(0), "State root not available");

        // Verify attestation inclusion in state
        return verifyAttestationAgainstState(
            ```markdown name=Veridis_Cross_Chain_Bridge_Technical_Design.md
            stateRoot,
            attestationType,
            attester,
            merkleRoot,
            proof
        );
    }

    // Internal function to verify attestation against state root
    function verifyAttestationAgainstState(
        bytes32 stateRoot,
        uint256 attestationType,
        address attester,
        bytes32 merkleRoot,
        bytes calldata proof
    ) internal pure returns (bool) {
        // This is a simplified placeholder for the actual verification logic
        // The actual implementation would reconstruct the storage key for the attestation
        // in the Attestation Registry and verify it against the state root

        // Compute the storage key for the attestation
        bytes32 storageKey = computeAttestationStorageKey(
            attestationType,
            attester
        );

        // Verify the storage proof against the state root
        return verifyStorageProof(
            stateRoot,
            storageKey,
            merkleRoot,
            proof
        );
    }

    // Governance functions
    function addRelayer(address relayer) external {
        require(msg.sender == governance, "Not governance");
        authorizedRelayers[relayer] = true;
        emit RelayerAdded(relayer);
    }

    function removeRelayer(address relayer) external {
        require(msg.sender == governance, "Not governance");
        authorizedRelayers[relayer] = false;
        emit RelayerRemoved(relayer);
    }

    function setStarkVerifier(address newVerifier) external {
        require(msg.sender == governance, "Not governance");
        starkVerifier = newVerifier;
    }

    function pause() external {
        require(msg.sender == governance, "Not governance");
        paused = true;
        emit ClientPaused();
    }

    function unpause() external {
        require(msg.sender == governance, "Not governance");
        paused = false;
        emit ClientUnpaused();
    }

    // Helper functions
    function verifySequencerSignature(
        uint256 blockNumber,
        bytes32 stateRoot,
        bytes calldata signature
    ) internal pure returns (bool) {
        // Implementation depends on StarkNet sequencer signature scheme
        // This is a placeholder for the actual signature verification
        return true;
    }

    function verifyChallengeData(
        uint256 blockNumber,
        bytes32 stateRoot,
        bytes calldata challengeData
    ) internal pure returns (bool) {
        // Implementation depends on the challenge mechanism
        // This is a placeholder for the actual challenge verification
        return true;
    }

    function computeAttestationStorageKey(
        uint256 attestationType,
        address attester
    ) internal pure returns (bytes32) {
        // Implementation depends on StarkNet storage layout
        // This is a placeholder for the actual key computation
        return keccak256(abi.encodePacked(attester, attestationType));
    }

    function verifyStorageProof(
        bytes32 stateRoot,
        bytes32 storageKey,
        bytes32 expectedValue,
        bytes calldata proof
    ) internal pure returns (bool) {
        // Implementation depends on StarkNet state tree structure
        // This is a placeholder for the actual proof verification
        return true;
    }
}
````

## 9. Failure Recovery Procedures

### 9.1 Failure Modes

The bridge design includes provisions for the following failure modes:

#### 9.1.1 Relayer Failures

**Failure Mode**: Relayers become unresponsive or malicious

**Recovery Procedures**:

1. **Automatic Failover**:

   - The relayer network includes multiple redundant relayers
   - If primary relayers fail, secondary relayers automatically take over
   - A scoring system tracks relayer performance and reliability

2. **Emergency Relayer Rotation**:

   - Bridge governance can rapidly remove failed relayers
   - New relayers can be added without disrupting bridge operations
   - Temporary increase in required confirmations during rotation

3. **Manual Recovery**:
   - In extreme cases, governance can manually relay critical messages
   - Emergency relayers with elevated permissions can bypass normal restrictions
   - Dedicated monitoring systems trigger alerts for manual intervention

#### 9.1.2 Chain Failures

**Failure Mode**: Source or destination chain experiences downtime or reorgs

**Recovery Procedures**:

1. **Automatic Suspension**:

   - Bridge automatically suspends operations to affected chains
   - Transactions are queued for delayed processing
   - Alternative routes are utilized when available

2. **Chain Reorganization Handling**:

   - Detection of chain reorganizations beyond safe threshold
   - Automatic reversion of affected state roots and messages
   - Reprocessing of messages from canonical chain

3. **Cross-Chain Consensus Fallback**:
   - Multiple confirmation thresholds based on chain conditions
   - Fallback to higher security verification modes during instability
   - External oracle networks for additional verification

#### 9.1.3 Smart Contract Failures

**Failure Mode**: Critical bugs or vulnerabilities in bridge contracts

**Recovery Procedures**:

1. **Emergency Pause**:

   - Governance can immediately pause bridge operations
   - Affected functions can be selectively disabled
   - Circuit breakers trigger automatically on anomalous behavior

2. **Upgrade Procedure**:

   - Time-locked upgrade process for contract fixes
   - Emergency upgrade process for critical vulnerabilities
   - State migration tools for preserving bridge state

3. **Fault Isolation**:
   - Bridge design compartmentalizes risks
   - Chain-specific components can be isolated without affecting others
   - Message queuing system prevents message loss during recovery

### 9.2 Recovery Coordination

The recovery process is coordinated through:

1. **Bridge Governance Council**:

   - Multi-signature control over emergency functions
   - Tiered response based on severity
   - Predefined playbooks for common failure scenarios

2. **Monitoring and Alert System**:

   - 24/7 automated monitoring of bridge components
   - Anomaly detection for early warning
   - Escalation paths based on severity

3. **Communication Channels**:
   - Public status page for bridge operations
   - Secure communication channels for coordinating recovery
   - Regular status updates during incidents

### 9.3 Data Recovery

For critical data recovery, the bridge implements:

1. **State Snapshots**:

   - Regular snapshots of bridge state
   - Distributed storage across multiple secure locations
   - Cryptographic verification of snapshot integrity

2. **Event Log Replay**:

   - All bridge operations are logged as events
   - State can be reconstructed from event history
   - Checkpointing system for efficient partial replay

3. **External State Verification**:
   - Independent verification of bridge state
   - Cross-chain verification of critical data
   - Oracle networks for external state confirmation

## 10. Performance Considerations

### 10.1 Throughput Optimization

The bridge implements several optimizations to maximize throughput:

#### 10.1.1 Batching

```solidity
// Ethereum implementation
function relayAttestationBatch(
    uint256[] calldata attestationTypes,
    address[] calldata attesters,
    bytes32[] calldata merkleRoots,
    uint256 blockNumber,
    bytes calldata proof
) external {
    // Ensure arrays are the same length
    require(
        attestationTypes.length == attesters.length &&
        attestationTypes.length == merkleRoots.length,
        "Array length mismatch"
    );

    // Verify the block state
    require(
        verifyBlockState(blockNumber, proof),
        "Invalid block state proof"
    );

    // Process each attestation in the batch
    for (uint i = 0; i < attestationTypes.length; i++) {
        // Verify and store each attestation
        verifyAndStoreAttestation(
            attestationTypes[i],
            attesters[i],
            merkleRoots[i],
            blockNumber
        );

        emit AttestationRelayed(
            attestationTypes[i],
            attesters[i],
            merkleRoots[i],
            blockNumber
        );
    }
}
```

#### 10.1.2 Compression

For large proofs and messages, data compression is used:

```solidity
// Ethereum implementation
function relayCompressedMessage(
    bytes calldata compressedMessage,
    bytes calldata decompressionProof
) external {
    // Verify decompression proof (e.g., zk-SNARK proving correct decompression)
    require(
        verifyDecompressionProof(compressedMessage, decompressionProof),
        "Invalid decompression proof"
    );

    // Decompress the message
    bytes memory message = decompress(compressedMessage);

    // Process the decompressed message
    processMessage(message);
}
```

#### 10.1.3 Parallelization

The relayer system uses parallel processing:

```typescript
// TypeScript implementation in relayer
async function processBlocksInParallel(
  fromBlock: number,
  toBlock: number
): Promise<void> {
  // Divide the block range into chunks
  const chunkSize = 10;
  const chunks: { start: number; end: number }[] = [];

  for (let start = fromBlock; start <= toBlock; start += chunkSize) {
    const end = Math.min(start + chunkSize - 1, toBlock);
    chunks.push({ start, end });
  }

  // Process chunks in parallel
  await Promise.all(
    chunks.map((chunk) => this.processBlockRange(chunk.start, chunk.end))
  );
}
```

### 10.2 Latency Optimization

To minimize cross-chain verification latency:

#### 10.2.1 Optimistic Verification

For low-value transactions, optimistic verification with shorter challenge periods:

```solidity
// Ethereum implementation
function configureOptimisticVerification(
    uint256 riskLevel,
    uint256 challengePeriod
) external {
    require(msg.sender == governance, "Not governance");

    // Set challenge period based on risk level
    // Lower risk level = shorter challenge period = faster finality
    riskLevelChallengePeriods[riskLevel] = challengePeriod;
}
```

#### 10.2.2 Prioritization

```typescript
// TypeScript implementation in relayer
function prioritizeMessages(messages: BridgeMessage[]): BridgeMessage[] {
  // Sort messages by priority score
  return messages.sort((a, b) => {
    // Calculate priority based on multiple factors
    const aPriority = calculatePriority(a);
    const bPriority = calculatePriority(b);

    // Higher priority first
    return bPriority - aPriority;
  });
}

function calculatePriority(message: BridgeMessage): number {
  let priority = 0;

  // Age factor - older messages get priority
  priority += message.age * AGE_WEIGHT;

  // Value factor - higher value transactions get priority
  priority += message.value * VALUE_WEIGHT;

  // Type factor - certain message types get priority
  if (message.type === MessageType.CONTROL) {
    priority += CONTROL_PRIORITY_BOOST;
  }

  // User-specified priority
  priority += message.userPriority * USER_PRIORITY_WEIGHT;

  return priority;
}
```

#### 10.2.3 Fast Path

Critical messages can take a "fast path" with higher fees but quicker confirmation:

```solidity
// Ethereum implementation
function relayFastPath(
    BridgeMessage calldata message,
    bytes calldata proof,
    bytes32[] calldata signatures
) external payable {
    // Verify the message with stronger guarantees
    require(
        verifyMessageWithSignatures(message, proof, signatures),
        "Invalid message or signatures"
    );

    // Check minimum fee for fast path
    require(
        msg.value >= FAST_PATH_MIN_FEE,
        "Insufficient fee for fast path"
    );

    // Process immediately with no challenge period
    processMessageImmediate(message);

    // Reward relayers who provided signatures
    distributeRewards(message, signatures);
}
```

### 10.3 Gas Optimization

To minimize gas costs on destination chains:

#### 10.3.1 Proof Aggregation

```solidity
// Ethereum implementation
function verifyAggregatedProof(
    bytes32[] calldata merkleRoots,
    bytes calldata aggregatedProof
) external view returns (bool) {
    // Verify multiple attestations with a single aggregated proof
    // This is more gas-efficient than verifying individually
    return zkAggregator.verifyBatch(merkleRoots, aggregatedProof);
}
```

#### 10.3.2 Calldata Optimization

```solidity
// Ethereum implementation
function optimizedAttestationData(
    bytes calldata compactData
) external pure returns (
    uint256 attestationType,
    address attester,
    bytes32 merkleRoot,
    uint256 blockNumber
) {
    // Decode compact representation to save on calldata gas
    // Format: [4 bytes attestationType][20 bytes attester][32 bytes merkleRoot][4 bytes blockNumber]

    assembly {
        // Load first 32 bytes (contains attestationType and part of attester)
        let data1 := calldataload(compactData.offset)

        // Extract attestationType (first 4 bytes)
        attestationType := shr(224, data1)

        // Extract attester (next 20 bytes)
        // Mask the first 4 bytes and shift appropriately
        attester := shr(64, and(data1, 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000))

        // Load next 32 bytes (contains rest of attester, merkleRoot, and part of blockNumber)
        let data2 := calldataload(add(compactData.offset, 32))

        // Extract merkleRoot (bytes 24-56)
        merkleRoot := and(data2, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

        // Load next 32 bytes (contains blockNumber)
        let data3 := calldataload(add(compactData.offset, 64))

        // Extract blockNumber (first 4 bytes)
        blockNumber := shr(224, data3)
    }
}
```

#### 10.3.3 Storage Optimization

```solidity
// Ethereum implementation
function optimizeStorageLayout() internal {
    // Use packed storage slots to reduce gas costs
    // Format: [ 32 bits blockNumber | 160 bits attester | 64 bits flags ]
    // This packs multiple fields into a single storage slot

    // Example of packing multiple fields into a single storage slot
    function packAttestationData(
        uint32 blockNumber,
        address attester,
        bool verified,
        bool revoked,
        uint8 status
    ) internal pure returns (uint256) {
        return uint256(blockNumber) << 224 |
               uint256(uint160(attester)) << 64 |
               (verified ? 1 : 0) << 63 |
               (revoked ? 1 : 0) << 62 |
               uint256(status) << 56;
    }

    // Example of unpacking
    function unpackAttestationData(uint256 packedData) internal pure returns (
        uint32 blockNumber,
        address attester,
        bool verified,
        bool revoked,
        uint8 status
    ) {
        blockNumber = uint32(packedData >> 224);
        attester = address(uint160(packedData >> 64));
        verified = (packedData >> 63) & 1 == 1;
        revoked = (packedData >> 62) & 1 == 1;
        status = uint8((packedData >> 56) & 0x3F);
    }
}
```

## 11. Testing and Verification

### 11.1 Testing Strategy

The bridge undergoes comprehensive testing:

#### 11.1.1 Unit Testing

```typescript
// Unit test example for Ethereum bridge contract
describe("VeridisBridgeEthereum", () => {
  let bridge: VeridisBridgeEthereum;
  let lightClient: StarkNetLightClient;
  let owner: SignerWithAddress;
  let relayer: SignerWithAddress;
  let user: SignerWithAddress;

  beforeEach(async () => {
    // Deploy test contracts
    [owner, relayer, user] = await ethers.getSigners();

    // Deploy light client
    const LightClientFactory = await ethers.getContractFactory(
      "StarkNetLightClient"
    );
    lightClient = await LightClientFactory.deploy(
      STARKNET_CHAIN_ID,
      STARKNET_PROGRAM_HASH,
      owner.address,
      MOCK_STARK_VERIFIER,
      CHALLENGE_PERIOD
    );

    // Deploy bridge
    const BridgeFactory = await ethers.getContractFactory(
      "VeridisBridgeEthereum"
    );
    bridge = await BridgeFactory.deploy(lightClient.address, MOCK_ZK_VERIFIER);

    // Add relayer to light client
    await lightClient.connect(owner).addRelayer(relayer.address);
  });

  it("should verify an attestation with valid proof", async () => {
    // Set up test data
    const attestationType = 1; // KYC_BASIC
    const attester = "0x1234567890123456789012345678901234567890";
    const merkleRoot = ethers.utils.randomBytes(32);
    const blockNumber = 100;

    // Update state root in light client
    const stateRoot = ethers.utils.randomBytes(32);
    await lightClient
      .connect(relayer)
      .updateStateZk(
        blockNumber,
        stateRoot,
        getMockStarkProof(blockNumber, stateRoot)
      );

    // Verify the attestation
    const result = await bridge.verifyAttestation(
      attestationType,
      attester,
      merkleRoot,
      blockNumber,
      getMockAttestationProof(attestationType, attester, merkleRoot)
    );

    // Verify result
    expect(result).to.be.true;

    // Check storage
    const storedAttestation = await bridge.verifiedAttestations(
      attester,
      attestationType
    );
    expect(storedAttestation.merkleRoot).to.equal(
      ethers.utils.hexlify(merkleRoot)
    );
    expect(storedAttestation.blockNumber).to.equal(blockNumber);
  });

  it("should reject attestation with invalid proof", async () => {
    // Set up test data
    const attestationType = 1; // KYC_BASIC
    const attester = "0x1234567890123456789012345678901234567890";
    const merkleRoot = ethers.utils.randomBytes(32);
    const blockNumber = 100;

    // Update state root in light client
    const stateRoot = ethers.utils.randomBytes(32);
    await lightClient
      .connect(relayer)
      .updateStateZk(
        blockNumber,
        stateRoot,
        getMockStarkProof(blockNumber, stateRoot)
      );

    // Attempt to verify with invalid proof
    await expect(
      bridge.verifyAttestation(
        attestationType,
        attester,
        merkleRoot,
        blockNumber,
        getMockInvalidProof() // Invalid proof
      )
    ).to.be.revertedWith("Invalid attestation proof");
  });

  // Additional tests...
});
```

#### 11.1.2 Integration Testing

```typescript
// Integration test example
describe("Cross-Chain Attestation Flow", () => {
  let starknetBridge: StarknetContract;
  let ethereumBridge: Contract;
  let relayer: RelayerService;

  beforeEach(async () => {
    // Set up StarkNet test environment
    const starknetEnv = await setupStarknetTestnet();
    starknetBridge = starknetEnv.bridge;

    // Set up Ethereum test environment
    const ethereumEnv = await setupEthereumTestnet();
    ethereumBridge = ethereumEnv.bridge;

    // Set up relayer
    relayer = new RelayerService({
      starknetProvider: starknetEnv.provider,
      ethereumProvider: ethereumEnv.provider,
      starknetBridge: starknetBridge.address,
      ethereumBridge: ethereumBridge.address,
      privateKey: TEST_PRIVATE_KEY,
    });

    // Start relayer
    await relayer.start();
  });

  afterEach(async () => {
    // Clean up
    await relayer.stop();
  });

  it("should relay attestation from StarkNet to Ethereum", async () => {
    // Issue attestation on StarkNet
    const attestationType = 1; // KYC_BASIC
    const attester = ATTESTER_ADDRESS;
    const merkleRoot = "0x1234..."; // Mock root

    await starknetEnv.attestationRegistry.issueTier1Attestation(
      attestationType,
      attester,
      merkleRoot,
      Math.floor(Date.now() / 1000) + 86400, // 1 day expiry
      "ipfs://schema"
    );

    // Relay to Ethereum
    await starknetBridge.relayAttestation(
      attestationType,
      attester,
      ETHEREUM_CHAIN_ID
    );

    // Wait for relay to complete (with timeout)
    await waitForCondition(async () => {
      const attestation = await ethereumBridge.verifiedAttestations(
        attester,
        attestationType
      );
      return attestation.merkleRoot === merkleRoot;
    }, 30000);

    // Verify attestation was relayed
    const attestation = await ethereumBridge.verifiedAttestations(
      attester,
      attestationType
    );
    expect(attestation.merkleRoot).to.equal(merkleRoot);
  });

  it("should verify credential ZK proof cross-chain", async () => {
    // First relay the attestation
    // ...

    // Generate ZK proof for credential
    const proof = await generateCredentialProof(
      userCredential,
      attestation,
      userSecret
    );

    // Verify on Ethereum
    const result = await ethereumBridge.verifyCredentialZk(
      proof.zkProof,
      proof.publicInputs
    );

    expect(result).to.be.true;

    // Check nullifier registration if applicable
    if (proof.publicInputs.hasNullifier) {
      const isUsed = await ethereumBridge.nullifiers(
        proof.publicInputs.nullifier
      );
      expect(isUsed).to.be.true;
    }
  });

  // Additional tests...
});
```

#### 11.1.3 Formal Verification

The bridge contracts undergo formal verification using:

1. **Safety Properties**:

   - Verified attestations correspond to attestations on StarkNet
   - Nullifiers cannot be reused
   - State roots are correctly validated

2. **Liveness Properties**:
   - Messages are eventually delivered if relayers are functioning
   - Challenge mechanism works as expected
   - Recovery procedures restore normal operation

### 11.2 Audit Strategy

The bridge undergoes a multi-phase audit process:

1. **Internal Audit**:

   - Code review by core team
   - Static analysis tools
   - Dynamic fuzzing and testing

2. **External Audits**:

   - Multiple independent security firms
   - Specialized ZK experts
   - Cross-chain bridge specialists

3. **Bug Bounty Program**:
   - Tiered rewards based on severity
   - Focus on critical bridge components
   - Incentives for complex attack vectors

### 11.3 Monitoring and Alerts

The bridge includes comprehensive monitoring:

```typescript
// Monitoring service example
class BridgeMonitor {
  private starknetProvider: StarknetProvider;
  private destinationProviders: Map<string, Provider>;
  private alertSystem: AlertSystem;
  private metricsCollector: MetricsCollector;

  constructor(config: MonitorConfig) {
    this.starknetProvider = new StarknetProvider(config.starknetRpc);

    // Initialize providers for each destination chain
    this.destinationProviders = new Map();
    for (const [chainId, rpcUrl] of Object.entries(config.destinationRpcs)) {
      this.destinationProviders.set(
        chainId,
        createProviderForChain(chainId, rpcUrl)
      );
    }

    this.alertSystem = new AlertSystem(config.alertConfig);
    this.metricsCollector = new MetricsCollector(config.metricsConfig);
  }

  public async start(): Promise<void> {
    // Start monitoring tasks
    this.monitorStarkNetBridge();
    this.monitorDestinationBridges();
    this.monitorRelayers();
    this.monitorMessageLatency();
  }

  private async monitorStarkNetBridge(): Promise<void> {
    // Monitor StarkNet bridge events
    const bridge = new Contract(
      starknetBridgeAbi,
      STARKNET_BRIDGE_ADDRESS,
      this.starknetProvider
    );

    // Subscribe to events
    bridge.on("AttestationRelayed", (event) => {
      // Track attestation relay requests
      this.metricsCollector.trackAttestationRelay(
        event.attestation_type,
        event.attester,
        event.destination_chain
      );

      // Start tracking latency for this relay
      this.startLatencyTracking(
        event.attestation_type,
        event.attester,
        event.destination_chain,
        event.block_timestamp
      );
    });

    // Additional monitoring...
  }

  private async monitorMessageLatency(): Promise<void> {
    // Check for delayed messages
    setInterval(async () => {
      const pendingMessages = this.getPendingMessages();

      for (const message of pendingMessages) {
        const latency = Date.now() - message.timestamp;

        // Report latency metric
        this.metricsCollector.recordMessageLatency(
          message.type,
          message.destinationChain,
          latency
        );

        // Alert on excessive latency
        if (latency > LATENCY_THRESHOLD) {
          this.alertSystem.sendAlert({
            severity: "warning",
            title: "Excessive message latency",
            message: `Message ${message.id} has been pending for ${latency}ms`,
            metadata: {
              messageType: message.type,
              destinationChain: message.destinationChain,
              attestationType: message.attestationType,
              attester: message.attester,
            },
          });
        }
      }
    }, 60000); // Check every minute
  }

  // Additional monitoring methods...
}
```

## 12. Appendices

### 12.1 StarkNet State Representation

The StarkNet state is represented in the bridge as follows:

```
StarkNet State Structure
├── Global State Root
│   └── Storage Commitment
│       ├── Contract Class Commitment
│       └── Contract Storage Commitment
│           └── Attestation Registry Storage
│               ├── Tier1Attestations
│               │   └── (attester, attestationType) -> AttestationData
│               └── Tier2Attestations
│                   └── (attester, subject, attestationType) -> AttestationData
└── Block Information
    ├── Block Number
    ├── Block Hash
    ├── Timestamp
    └── Sequencer Address
```

### 12.2 Merkle Proof Format

The standard format for Merkle proofs in the bridge:

```typescript
interface MerkleProof {
  // The leaf being proven
  leaf: string;

  // Path from leaf to root
  path: Array<{
    // Sibling hash
    sibling: string;

    // Direction (left/right)
    isLeft: boolean;
  }>;
}
```

### 12.3 Cross-Chain Message Format

The standard format for cross-chain messages:

```typescript
interface CrossChainMessage {
  // Message header
  header: {
    // Message type identifier
    messageType: number;

    // Source chain identifier
    sourceChain: string;

    // Destination chain identifier
    destinationChain: string;

    // Unique nonce
    nonce: string;

    // Timestamp
    timestamp: number;

    // Version
    version: number;
  };

  // Message body (type-specific)
  body: unknown;

  // Signatures from relayers (if applicable)
  signatures?: string[];
}
```

### 12.4 Supported Chain Configurations

Chain-specific configurations for the bridge:

| Chain      | Chain ID    | Light Client Type | Verification Method  | Confirmation Blocks | Notes                 |
| ---------- | ----------- | ----------------- | -------------------- | ------------------- | --------------------- |
| StarkNet   | starknet    | N/A (source)      | N/A                  | 3                   | Source chain          |
| Ethereum   | 1           | STARK Verifier    | ZK + Optimistic      | 12                  | Primary destination   |
| Polygon    | 137         | STARK Verifier    | ZK + Optimistic      | 128                 | EVM compatible        |
| Arbitrum   | 42161       | STARK Verifier    | ZK + Optimistic      | 1                   | L2 optimizations      |
| Optimism   | 10          | STARK Verifier    | ZK + Optimistic      | 1                   | L2 optimizations      |
| Cosmos Hub | cosmoshub-4 | IBC Light Client  | IBC Protocol         | 2                   | IBC integration       |
| Osmosis    | osmosis-1   | IBC Light Client  | IBC Protocol         | 2                   | Cosmos ecosystem      |
| Solana     | solana      | Custom Client     | Ed25519 Verification | 32                  | Custom implementation |
| Polkadot   | polkadot    | XCMP Client       | XCMP Protocol        | 2                   | Parachain integration |

### 12.5 Transaction Fee Model

The fee model for the bridge:

1. **Relay Fee Structure**:

   - Base fee: 0.005 ETH per attestation relay
   - Premium fee: Additional 0.01 ETH for fast-path relays
   - Batch discount: 30% discount for batch relays

2. **Fee Distribution**:

   - Relayers: 70% of fees
   - Protocol treasury: 20% of fees
   - Insurance fund: 10% of fees

3. **Fee Adjustment Mechanism**:
   - Dynamic fee based on network congestion
   - Governance-controlled fee parameters
   - Chain-specific fee multipliers

---

## Document Metadata

**Document ID:** VERIDIS-SPEC-BRIDGE-2025-001  
**Version:** 1.0  
**Date:** 2025-05-27  
**Authors:** Cass402 and the Veridis Engineering Team  
**Last Edit:** 2025-05-27 05:00:38 UTC by Cass402

**Classification:** Internal Technical Documentation  
**Distribution:** Veridis Engineering, Auditors, Technical Partners

**Document End**
