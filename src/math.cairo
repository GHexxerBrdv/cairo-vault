const VIRTUAL_ASSETS: u256 = 1;
const VIRTUAL_SHARES: u256 = 1;

fn floor_div(a: u256, b: u256) -> u256 {
    a / b
}

fn ceil_div(a: u256, b: u256) -> u256 {
    (a + b - 1) / b
}

pub fn convert_to_shares_down(assets: u256, total_assets: u256, total_supply: u256) -> u256 {
    floor_div(assets * (total_supply + VIRTUAL_SHARES), total_assets + VIRTUAL_ASSETS)
}

pub fn convert_to_assets_down(shares: u256, total_assets: u256, total_supply: u256) -> u256 {
    floor_div(shares * (total_assets + VIRTUAL_ASSETS), total_supply + VIRTUAL_SHARES)
}

pub fn convert_to_shares_up(assets: u256, total_assets: u256, total_supply: u256) -> u256 {
    ceil_div(assets * (total_supply + VIRTUAL_SHARES), total_assets + VIRTUAL_ASSETS)
}

pub fn convert_to_assets_up(shares: u256, total_assets: u256, total_supply: u256) -> u256 {
    ceil_div(shares * (total_assets + VIRTUAL_ASSETS), total_supply + VIRTUAL_SHARES)
}
