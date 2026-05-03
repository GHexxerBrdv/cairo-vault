use sncast_std::{DeclareResultTrait, FeeSettingsTrait, declare, deploy, get_nonce};
use starknet::contract_address_const;

#[executable]
fn main() {
    let max_fee = 999999999999999;
    let fee_settings = FeeSettingsTrait::max_fee(max_fee);
    let salt = 0x1;

    // --- 1. Deploy MockERC20 ---
    println!("Declaring MockERC20...");
    let mock_declare_nonce = get_nonce('latest');
    let mock_declare_result = declare("MockERC20", fee_settings, Option::Some(mock_declare_nonce))
        .expect('MockERC20 declare failed');

    println!("Deploying MockERC20...");
    let mut mock_constructor_args = array![];
    let name: ByteArray = "Mock Token";
    let symbol: ByteArray = "MTK";
    let initial_supply: u256 = 1000000000000000000000000; // 1M tokens
    let recipient = contract_address_const::<
        0x5f77805612e4b5c8cec7c17cfeb44d3667865b5647a768943d3c607d444bb05,
    >();

    name.serialize(ref mock_constructor_args);
    symbol.serialize(ref mock_constructor_args);
    initial_supply.serialize(ref mock_constructor_args);
    recipient.serialize(ref mock_constructor_args);

    let mock_deploy_nonce = get_nonce('latest');
    let mock_deploy_result = deploy(
        *mock_declare_result.class_hash(),
        mock_constructor_args,
        Option::Some(salt),
        true,
        fee_settings,
        Option::Some(mock_deploy_nonce),
    )
        .expect('MockERC20 deploy failed');

    let asset_address = mock_deploy_result.contract_address;
    println!("MockERC20 deployed at: {:?}", asset_address);

    // --- 2. Deploy Vault ---
    println!("Declaring Vault...");
    let vault_declare_nonce = get_nonce('latest');
    let vault_declare_result = declare("Vault", fee_settings, Option::Some(vault_declare_nonce))
        .expect('Vault declare failed');

    println!("Deploying Vault...");
    let vault_constructor_args = array![asset_address.into()];
    let vault_deploy_nonce = get_nonce('latest');
    let vault_deploy_result = deploy(
        *vault_declare_result.class_hash(),
        vault_constructor_args,
        Option::Some(salt),
        true,
        fee_settings,
        Option::Some(vault_deploy_nonce),
    )
        .expect('Vault deploy failed');

    println!("Vault deployed at: {:?}", vault_deploy_result.contract_address);
}
