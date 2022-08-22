import vault.aleo;

// The 'liquidate.aleo' program. Loosely following
// https://github.com/liquity/dev/blob/main/packages/contracts/contracts/TroveManager.sol
program liquidate.aleo;

/*
assumptions

mapping values can be read
a program-owned liquidity pool exists that is used as the pool for liquidating and absorbing debt

is there a concept of closing a mapping out??

necessary constants
MIN_COLLATERALIZATION_RATIO
MINIMUM_DEPOSIT
LIQUIDATION_SECURITY_DEPOSIT
LIQUIDATION_POOL

necessary values
USD_AG_PRICE price of aleo-gates in USD
BORROW_FEE percentage of borrowing amount of USZK to pay
GAS_FEE
fees???
*/

// functionality for liquidations following the liquidations in normal mode for liquidity here:
// https://github.com/liquity/dev#liquidation-logic
function liquidate_normal:
    input r0 as address.public; // address to be liquidated

    // can't liquidate a vault that has no borrows
    IF vault_borrows[r0] !EXISTS:
        THROW ERROR;

    // normal liquidation cannot occur if there's not enough USZK stored in the liquidation pool
    IF LIQUIDATION_POOL.amount < vault_borrows[r0]:
        THROW ERROR;

    mul vault_deposits[r0] USD_AG_PRICE into r1; // price of deposit in USD
    div r1 vault_borrows[r0] into r2; // collateralization ratio of the vault

    // vaults with greater collateralization ratio should not be liquidated
    IF r2 > MIN_COLLATERALIZATION_RATIO:
        THROW ERROR;

    sub vault_deposits[r0] GAS_FEE into r3; // GAS_FEE is used to cover gas costs

    BURN vault_borrows[r0] FROM LIQUIDATION_POOL; // burn enough staked USZK from the pool to cover the borrower's debt

    SEND r3 TO LIQUIDATION_POOL; // send the collateral to the pool -- this is the reward earned by the pool for liquation

    decrement vault_borrows[r0] by vault_borrows[r0]; // debt has been paid -- the borrower's USZK is theirs free and clear now
    decrement vault_deposits[r0] by vault_deposits[r0]; // no more collateral.


// when there's no staking pool to liquidate vaults, the debt and collateral is spread across all other vaults
function liquidate_empty_staking_pool:
    input r0 as address.public; // address to be liquidated

    // can't liquidate a vault that has no borrows
    IF vault_borrows[r0] !EXISTS:
        THROW ERROR;

    mul vault_deposits[r0] USD_AG_PRICE into r1; // price of deposit in USD
    div r1 vault_borrows[r0] into r2; // collateralization ratio of the vault

    // vaults with greater collateralization ratio should not be liquidated
    IF r2 > MIN_COLLATERALIZATION_RATIO:
        THROW ERROR;
    
    sub vault_deposits[r0] GAS_FEE into r3; // GAS_FEE is used to cover gas costs

    div r3 TOTAL_VAULTS into r4; // amount of collateral to spread per vault
    div vault_borrows[r0] TOTAL_VAULTS into r5; // amount of debt to spread per vault

    // this next part may need to be split into more instructions, given the limit on processing on-chain
    FOR address in vault_deposits:
        increment vault_deposits[address] by r4;
        increment vault_borrows[address] by r5;

    decrement vault_deposits[r0] by vault_deposits[r0]; // no more collateral.
    decrement vault_borrows[r0] by vault_borrows[r0]; // debt has been paid -- the borrower's USZK is theirs free and clear now


function liquidate_normal_partial_pool:
    input r0 as address.public; // address to be liquidated

    // can't liquidate a vault that has no borrows
    IF vault_borrows[r0] !EXISTS:
        THROW ERROR;

    mul vault_deposits[r0] USD_AG_PRICE into r1; // price of deposit in USD
    div r1 vault_borrows[r0] into r2; // collateralization ratio of the vault

    // vaults with greater collateralization ratio should not be liquidated
    IF r2 > MIN_COLLATERALIZATION_RATIO:
        THROW ERROR;
    
    sub vault_deposits[r0] GAS_FEE into r3; // GAS_FEE is used to cover gas costs

    BURN LIQUIDATION_POOL.TOTAL FROM LIQUIDATION_POOL; // burn as much staked USZK from the pool as possible
    div LIQUIDATION_POOL.TOTAL USD_AG_PRICE into r4; // how much that burned USZK is worth of the collateral
    SEND r4 to LIQUIDATION_POOL;
    decrement vault_deposits[r0] by r4; // collateral has been partially reclaimed
    decrement vault_borrows[r0] by vault_borrows[r0]; // debt has been partially repaid

    div vault_deposits[r0] TOTAL_VAULTS into r5; // amount of collateral to spread among remaining vaults
    div vault_borrows[r0] TOTAL_VAULTS into r6; // amount of debt to spread among remaining vaults

    // this next part may need to be split into more instructions, given the limit on processing on-chain
    FOR address in vault_deposits:
        increment vault_deposits[address] by r5;
        increment vault_borrows[address] by r6;

    decrement vault_deposits[r0] by vault_deposits[r0]; // no more collateral.
    decrement vault_borrows[r0] by vault_borrows[r0]; // debt has been paid -- the borrower's USZK is theirs free and clear now


