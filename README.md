# ERC4626 Vault on Starknet

A robust implementation of the **ERC4626 Tokenized Vault Standard** in Cairo for the Starknet ecosystem. This project leverages the OpenZeppelin Cairo contracts and Starknet Foundry for a secure and well-tested vault architecture.

## Features

- **Standard Compliance**: Fully implements the ERC4626 interface (Deposit, Mint, Withdraw, Redeem, and Previews).
- **Security**: Utilizes virtual assets and shares to mitigate inflation attacks (common in initial vault deposits).
- **OpenZeppelin Integration**: Built on top of OpenZeppelin's `ERC20Component` for reliable token logic.
- **Precision Math**: Custom math library for rounding assets and shares consistently (rounding down for shares, rounding up for assets).

## Project Structure

```text
├── src/
│   ├── lib.cairo        # Main contract (Vault) implementation
│   ├── interface.cairo  # IVault interface definition
│   └── math.cairo       # ERC4626 rounding and conversion logic
├── tests/
│   ├── vault_test.cairo # Integration tests using snforge
│   └── mock_erc20.cairo # Mock token for testing
└── Scarb.toml           # Project dependencies and configuration
```

## Getting Started

### Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) (Cairo package manager)
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/) (`snforge` for testing)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd erc4626
   ```

2. Build the project:
   ```bash
   scarb build
   ```

### Testing

Run the integration tests using Starknet Foundry:
```bash
scarb test
```

# Deploy address

Vault :- 0x7caa5c1c5556279ddf8a95a678b683b57df5a766ce120128b44c107c47effae (Starkent sepolia)

## Usage

### Deployment

To deploy the vault, you need to provide the address of the underlying ERC20 asset:

```bash
sncast deploy --contract-name Vault --constructor-calldata <ASSET_ADDRESS>
```

### Integration

The vault exposes the `IVault` interface. You can interact with it using a dispatcher:

```rust
use erc4626::interface::{IVaultDispatcher, IVaultDispatcherTrait};

let vault = IVaultDispatcher { contract_address: vault_address };
vault.deposit(assets_amount, receiver_address);
```

## Security

This implementation includes:
- **Rounding Logic**: Ensures that the vault always rounds in favor of the vault's integrity (e.g., rounding up on assets required for a specific number of shares).
- **Virtual Assets/Shares**: Prevents the "first depositor" attack by adding a virtual offset to the total supply and assets during calculations.

## License

MIT
