#[starknet::contract]
mod Vault {
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    use crate::math::{
        convert_to_assets_down,
        convert_to_assets_up,
        convert_to_shares_down,
        convert_to_shares_up,
    };

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,

        Deposit: DepositEvent,
        Withdraw: WithdrawEvent,
    }

    #[derive(Drop, starknet::Event)]
    struct DepositEvent {
        sender: ContractAddress,
        receiver: ContractAddress,
        assets: u256,
        shares: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawEvent {
        sender: ContractAddress,
        receiver: ContractAddress,
        assets: u256,
        shares: u256,
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        asset: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, asset: ContractAddress) {
        self.asset.write(asset);

        self.erc20.initializer('Vault share', 'VSHARE');
    }

    fn asset_dispature(self: @ContractState) -> IERC20Dispatcher {
        IERC20Dispatcher { contract_address: self.asset.read() }
    }

    fn total_assets(self: @ContractState) -> u256 {
        let token = self.asset_dispature();
        token.balance_of(get_contract_address())
    }


    #[view]
    fn asset(self: @ContractState) -> ContractAddress {
        self.asset.read()
    }

    fn totalAssets(self: @ContractState) -> u256 {
        self.total_assets()
    }

    #[external(v0)]
    fn deposit(ref self: ContractState, assets: u256, receiver: ContractAddress) -> u256 {
        assert(assets > 0, 'Zero Assets');

        let caller = get_caller_address();
        let total_assets = self.total_assets();
        let supply = self.erc20.total_supply();

        let shares = convert_to_shares_down(assets, total_assets, supply);
        assert(shares > 0, 'Zero Shares');

        let token = self.asset_dispature();

        token.transfer_from(caller, get_contract_address(), assets);
        self.erc20.mint(receiver, shares);

        self.emit(Event::Deposit(DepositEvent {
            sender: caller,
            receiver,
            assets,
            shares,
        }));
        shares
    }

    #[external(v0)]
    fn mint(ref self: ContractState, shares: u256, receiver: ContractAddress) -> u256 {
        assert(shares > 0, 'Zero Shares');

        let caller = get_caller_address();
        let total_assets = self.total_assets();
        let supply = self.erc20.total_supply();

        let assets = convert_to_assets_up(shares, total_assets, supply);
        assert(assets > 0, 'Zero Assets');

        let token = self.asset_dispature();
        token.transfer_from(caller, get_contract_address(), assets);
        self.erc20.mint(receiver, shares);
        self.emit(Event::Deposit(DepositEvent {
            sender: caller,
            receiver,
            assets,
            shares,
        }));
        
        assets
    }

    #[external(v0)]
    fn withdraw(ref self: ContractState, assets: u256, receiver: ContractAddress) -> u256 {
        assert(assets > 0, 'Zero Assets');
        let caller = get_caller_address();
        let total_assets = self.total_assets();
        let supply = self.erc20.total_supply();

        let shares = convert_to_shares_up(assets, total_assets, supply);
        assert(shares > 0, 'Zero Shares');

        self.erc20.burn(caller, shares);

        let token = self.asset_dispature();
        token.transfer(receiver, assets);

        self.emit(Event::Withdraw(WithdrawEvent {
            sender: caller,
            receiver,
            assets,
            shares,
        }));
        
        shares
    }

    #[external(v0)]
    fn redeem(ref self: ContractState, shares: u256, receiver: ContractAddress) -> u256 {
        assert(shares > 0, 'Zero Shares');

        let caller = get_caller_address();
        let total_assets = self.total_assets();
        let supply = self.erc20.total_supply();

        let assets = convert_to_assets_down(shares, total_assets, supply);
        assert(assets > 0, 'Zero Assets');

        self.erc20.burn(caller, shares);

        let token = self.asset_dispature();
        token.transfer(receiver, assets);

        self.emit(Event::Withdraw(WithdrawEvent {
            sender: caller,
            receiver,
            assets,
            shares,
        }));
        
        assets
    }

    #[view]
    fn preview_deposit(self: @ContractState, assets: u256) -> u256 {
        let total_assets = self.total_assets();
        let supply = self.erc20.total_supply();
        convert_to_shares_down(assets, total_assets, supply)
    }

    #[view]
    fn preview_mint(self: @ContractState, shares: u256) -> u256 {
        let total_assets = self.total_assets();
        let supply = self.erc20.total_supply();
        convert_to_assets_up(shares, total_assets, supply)
    }

    #[view]
    fn preview_withdraw(self: @ContractState, assets: u256) -> u256 {
        let total_assets = self.total_assets();
        let supply = self.erc20.total_supply();
        convert_to_shares_up(assets, total_assets, supply)
    }

    #[view]
    fn preview_redeem(self: @ContractState, shares: u256) -> u256 {
        let total_assets = self.total_assets();
        let supply = self.erc20.total_supply();
        convert_to_assets_down(shares, total_assets, supply)
    }

    #[view]
    fn max_deposit(self: @ContractState) -> u256 {
        u256::MAX
    }

    #[view]
    fn max_mint(self: @ContractState) -> u256 {
        u256::MAX
    }

    #[view]
    fn max_redeem(self: @ContractState, owner: ContractAddress) -> u256 {
        self.erc20.balance_of(owner)
    }

    #[view]
    fn max_withdraw(self: @ContractState, owner: ContractAddress) -> u256 {
        let shares = self.erc20.balance_of(owner);

        let total_assets = self.total_assets();
        let supply = self.erc20.total_supply();

        convert_to_assets_down(shares, total_assets, supply)
    }
}
