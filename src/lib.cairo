use starknet::ContractAddress;
mod math;

#[starknet::interface]
pub trait IVault<TContractState> {
    fn asset(self: @TContractState) -> ContractAddress;
    fn total_assets(self: @TContractState) -> u256;
    fn deposit(ref self: TContractState, assets: u256, receiver: ContractAddress) -> u256;
    fn withdraw(
        ref self: TContractState, assets: u256, receiver: ContractAddress, owner: ContractAddress,
    ) -> u256;
    fn mint(ref self: TContractState, shares: u256, receiver: ContractAddress) -> u256;
    fn redeem(
        ref self: TContractState, shares: u256, receiver: ContractAddress, owner: ContractAddress,
    ) -> u256;
    fn preview_deposit(self: @TContractState, assets: u256) -> u256;
    fn preview_mint(self: @TContractState, shares: u256) -> u256;
    fn preview_withdraw(self: @TContractState, assets: u256) -> u256;
    fn preview_redeem(self: @TContractState, shares: u256) -> u256;
}

#[starknet::contract]
pub mod Vault {
    use openzeppelin::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::storage::*;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use crate::math::{
        convert_to_assets_down, convert_to_assets_up, convert_to_shares_down, convert_to_shares_up,
    };

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl ERC20HooksImpl = ERC20HooksEmptyImpl<ContractState>;


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        Deposit: Deposit,
        Withdraw: Withdraw,
    }

    #[derive(Drop, starknet::Event)]
    struct Deposit {
        pub sender: ContractAddress,
        pub receiver: ContractAddress,
        pub assets: u256,
        pub shares: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdraw {
        pub sender: ContractAddress,
        pub receiver: ContractAddress,
        pub owner: ContractAddress,
        pub assets: u256,
        pub shares: u256,
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pub erc20: ERC20Component::Storage,
        pub underlying_asset: ContractAddress,
    }

    impl ERC20ImmutableConfig of ERC20Component::ImmutableConfig {
        const DECIMALS: u8 = 18;
    }

    #[constructor]
    fn constructor(ref self: ContractState, asset: ContractAddress) {
        self.underlying_asset.write(asset);
        self.erc20.initializer("GB Share", "GShare");
    }

    #[abi(embed_v0)]
    impl VaultImpl of super::IVault<ContractState> {
        fn asset(self: @ContractState) -> ContractAddress {
            self.underlying_asset.read()
        }

        fn total_assets(self: @ContractState) -> u256 {
            let token = self.get_asset_dispatcher();
            token.balance_of(get_contract_address())
        }

        fn deposit(ref self: ContractState, assets: u256, receiver: ContractAddress) -> u256 {
            assert(assets > 0, 'Zero Assets');

            let caller = get_caller_address();
            let total_assets = self.total_assets();
            let supply = self.erc20.total_supply();

            let shares = convert_to_shares_down(assets, total_assets, supply);
            assert(shares > 0, 'Zero Shares');

            let token = self.get_asset_dispatcher();
            assert(token.transfer_from(caller, get_contract_address(), assets), 'Transfer failed');
            self.erc20.mint(receiver, shares);

            self.emit(Deposit { sender: caller, receiver, assets, shares });
            shares
        }

        fn mint(ref self: ContractState, shares: u256, receiver: ContractAddress) -> u256 {
            assert(shares > 0, 'Zero Shares');

            let caller = get_caller_address();
            let total_assets = self.total_assets();
            let supply = self.erc20.total_supply();

            let assets = convert_to_assets_up(shares, total_assets, supply);
            assert(assets > 0, 'Zero Assets');
            let token = self.get_asset_dispatcher();
            assert(token.transfer_from(caller, get_contract_address(), assets), 'Transfer failed');
            self.erc20.mint(receiver, shares);
            self.emit(Deposit { sender: caller, receiver, assets, shares });
            assets
        }

        fn withdraw(
            ref self: ContractState,
            assets: u256,
            receiver: ContractAddress,
            owner: ContractAddress,
        ) -> u256 {
            assert(assets > 0, 'Zero Assets');
            let caller = get_caller_address();
            let total_assets = self.total_assets();
            let supply = self.erc20.total_supply();

            let shares = convert_to_shares_up(assets, total_assets, supply);
            assert(shares > 0, 'Zero Shares');

            if (caller != owner) {
                self.erc20._spend_allowance(owner, caller, shares);
            }

            self.erc20.burn(owner, shares);

            let token = self.get_asset_dispatcher();
            assert(token.transfer(receiver, assets), 'Transfer failed');

            self.emit(Withdraw { sender: caller, receiver, owner, assets, shares });
            shares
        }

        fn redeem(
            ref self: ContractState,
            shares: u256,
            receiver: ContractAddress,
            owner: ContractAddress,
        ) -> u256 {
            assert(shares > 0, 'Zero Shares');

            let caller = get_caller_address();
            let total_assets = self.total_assets();
            let supply = self.erc20.total_supply();

            let assets = convert_to_assets_down(shares, total_assets, supply);
            assert(assets > 0, 'Zero Assets');

            if (caller != owner) {
                self.erc20._spend_allowance(owner, caller, shares);
            }

            self.erc20.burn(owner, shares);

            let token = self.get_asset_dispatcher();
            assert(token.transfer(receiver, assets), 'Transfer failed');

            self.emit(Withdraw { sender: caller, receiver, owner, assets, shares });
            assets
        }

        fn preview_deposit(self: @ContractState, assets: u256) -> u256 {
            convert_to_shares_down(assets, self.total_assets(), self.erc20.total_supply())
        }

        fn preview_mint(self: @ContractState, shares: u256) -> u256 {
            convert_to_assets_up(shares, self.total_assets(), self.erc20.total_supply())
        }

        fn preview_withdraw(self: @ContractState, assets: u256) -> u256 {
            convert_to_shares_up(assets, self.total_assets(), self.erc20.total_supply())
        }

        fn preview_redeem(self: @ContractState, shares: u256) -> u256 {
            convert_to_assets_down(shares, self.total_assets(), self.erc20.total_supply())
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_asset_dispatcher(self: @ContractState) -> IERC20Dispatcher {
            IERC20Dispatcher { contract_address: self.underlying_asset.read() }
        }
    }
}
