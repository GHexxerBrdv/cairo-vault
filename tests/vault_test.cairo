use erc4626::interface::{IVaultDispatcher, IVaultDispatcherTrait};
use openzeppelin::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::*;
use starknet::{ContractAddress, contract_address_const};

fn deploy_vault(asset: ContractAddress) -> ContractAddress {
    let contract = declare("Vault").unwrap().contract_class();
    let mut contract_args = array![asset.into()];
    let (contract_address, _) = contract.deploy(@contract_args).unwrap();
    contract_address
}

fn deploy_mock_erc20(initial_supply: u256, recipient: ContractAddress) -> ContractAddress {
    let contract = declare("MockERC20").unwrap().contract_class();
    let mut contract_args = array![];
    let name: ByteArray = "MockToken";
    let symbol: ByteArray = "MTK";
    name.serialize(ref contract_args);
    symbol.serialize(ref contract_args);
    initial_supply.serialize(ref contract_args);
    recipient.serialize(ref contract_args);
    let (contract_address, _) = contract.deploy(@contract_args).unwrap();
    contract_address
}

#[test]
fn test_deposit() {
    let owner = contract_address_const::<0x123>();
    let asset_address = deploy_mock_erc20(1000, owner);
    let vault_address = deploy_vault(asset_address);

    let asset = IERC20Dispatcher { contract_address: asset_address };
    let vault = IVaultDispatcher { contract_address: vault_address };
    let vault_token = IERC20Dispatcher { contract_address: vault_address };

    // Prank as owner to approve
    start_cheat_caller_address(asset_address, owner);
    asset.approve(vault_address, 500);
    stop_cheat_caller_address(asset_address);

    // Prank as owner to deposit
    start_cheat_caller_address(vault_address, owner);
    vault.deposit(500, owner);
    stop_cheat_caller_address(vault_address);

    assert(asset.balance_of(vault_address) == 500, 'Vault should have 500 assets');
    assert(vault.total_assets() == 500, 'Total assets should be 500');

    // Check shares (1:1 for first deposit with virtual assets/shares in math)
    // convert_to_shares_down(500, 0, 0) = floor_div(500 * (0 + 1), 0 + 1) = 500
    let shares = vault_token.balance_of(owner);
    assert(shares == 500, 'Owner should have 500 shares');
}

#[test]
fn test_withdraw() {
    let owner = contract_address_const::<0x123>();
    let asset_address = deploy_mock_erc20(1000, owner);
    let vault_address = deploy_vault(asset_address);

    let asset = IERC20Dispatcher { contract_address: asset_address };
    let vault = IVaultDispatcher { contract_address: vault_address };
    let vault_token = IERC20Dispatcher { contract_address: vault_address };

    // Prank as owner to approve
    start_cheat_caller_address(asset_address, owner);
    asset.approve(vault_address, 500);
    stop_cheat_caller_address(asset_address);

    // Prank as owner to deposit
    start_cheat_caller_address(vault_address, owner);
    vault.deposit(500, owner);
    stop_cheat_caller_address(vault_address);

    assert(asset.balance_of(vault_address) == 500, 'Vault should have 500 assets');
    assert(vault.total_assets() == 500, 'Total assets should be 500');

    // Check shares (1:1 for first deposit with virtual assets/shares in math)
    // convert_to_shares_down(500, 0, 0) = floor_div(500 * (0 + 1), 0 + 1) = 500
    let shares = vault_token.balance_of(owner);
    assert(shares == 500, 'Owner should have 500 shares');

    start_cheat_caller_address(vault_address, owner);
    vault.withdraw(500, owner, owner);
    stop_cheat_caller_address(vault_address);

    assert(asset.balance_of(vault_address) == 0, 'Vault should have 0 assets');
    assert(vault.total_assets() == 0, 'Total assets should be 0');
    let shares = vault_token.balance_of(owner);
    assert(shares == 0, 'Owner should have 0 shares');
}
