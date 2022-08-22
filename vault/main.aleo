// The 'vault.aleo' program. Missing a ton of checks. Loosely following
// https://github.com/liquity/dev/blob/main/packages/contracts/contracts/BorrowerOperations.sol
program vault.aleo;

/*
assumptions
mapping values can be read

necessary constants
MIN_COLLATERALIZATION_RATIO
MINIMUM_DEPOSIT
LIQUIDATION_SECURITY_DEPOSIT
LIQUIDATION_POOL

necessary values
USD_AG_PRICE price of aleo-gates in USD
BORROW_FEE percentage of borrowing amount of USZK to pay
fees???
*/

mapping vault_deposits:
    key owner as address.public;
    value aleo_deposited as u64.public;

mapping vault_borrows:
    key owner as address.public;
    value uszk_borrowed as u64.public;

function initialize_vault:
    input r0 as u64.public; // aleo-gates to deposit
    input r1 as u64.public; // requested USZK

    IF r0 < MINIMUM_DEPOSIT:
        THROW ERROR;

    IF vault_deposits[self.caller] EXISTS && vault_deposits[self.caller] > 0:
        THROW ERROR;
    
    sub r0 LIQUIDATION_SECURITY_DEPOSIT into r2; // how much of
    // the deposit is left after setting aside security deposit

    div r1 100u64 into r3; // divide by 100, then multiply by BORROW_FEE
    mul r3 BORROW_FEE into r4; // r4 should be the amount that the borrower must pay

    add r4 r1 into r5; // total amount needed to borrow

    mul r0 USD_AG_PRICE into r6; // price of deposit in USD

    div r6 r5 into r7; // expected collateralization ratio

    IF r7 >= MIN_COLLATERALIZATION_RATIO:
        THROW ERROR;
    
    SEND LIQUIDATION_SECURITY_DEPOSIT TO LIQUIDATION_POOL;
    SEND r4 TO PROTOCOL;
    SEND r1 TO self.caller;

    // should save the collaterization ratio and the vault address somewhere for the purpose of redemptions

    finalize self.caller r2 r5;

finalize initialize_vault:
    input r0 as address.public; // address of vault creator
    input r1 as u64.public; // aleo-gates to deposit after security deposit removed
    input r2 as u64.public; // amount of USZK borrowed

    increment vault_deposits[r0] by r1;
    increment vault_borrows[r0] by r2;

function close_vault:
    IF vault_deposits[self.caller] !EXISTS:
        THROW ERROR;

    IF vault_borrows[self.caller] > 0:
        THROW ERROR;
    
    SEND LIQUIDATION_SECURITY_DEPOSIT TO self.caller;
    SEND vault_deposits[self.caller] TO self.caller;

    // collateralization ratio should be updated, vault should be removed from redeemable vaults list

    finalize close_vault self.caller vault_deposits[self.caller];

finalize close_vault:
    input r0 as address.public;
    input r1 as u64.public;

    decrement vault_deposits[r0] by r1;

function add_collateral_vault:
    input r0 as u64.public; // aleo-gates to deposit

    IF vault_deposits[self.caller] !EXISTS:
        THROW ERROR;

    add vault_deposits[self.caller] r0 into r1; // new sum of deposit for the vault

    // should save new collateralization ratio

    finalize r0 self.caller;

finalize add_collateral_vault:
    input r0 as u64.public; // amount of aleo-gates to increase collateral by
    input r1 as address.public; // address of vault owner to increase

    increment vault_deposits[r1] by r0;

function remove_collateral_vault:
    input r0 as u64.public; // aleo-gates to withdraw

    sub vault_deposits[self.caller] r0 into r1; // amount that would be left after the withdraw_vault
    mul r1 USD_AG_PRICE into r2; // value of what's left in the vault

    div r2 vault_borrows[self.caller] into r3; // new collateralization ratio


    IF r3 < MIN_COLLATERALIZATION_RATIO:
        THROW ERROR;
    
    // should save new collateralization ratio    

    finalize r0 self.caller;

finalize remove_collateral_vault:
    input r0 as u64.public; // aleo-gates to withdraw
    input r1 as address.public;

    decrement vault_deposits[r1] by r0;

function borrow:
    input r0 as u64.public; // amount of uszk to borrow

    div r0 100u64 into r1; // divide by 100, then multiply by BORROW_FEE
    mul r1 BORROW_FEE into r2; // r2 should be the amount that the borrower must pay
    add r2 r0 into r3; // total extra amount to borrow

    add vault_borrows[self.caller] r3 into r4; // new amount of borrow

    mul vault_deposits USD_AG_PRICE into r5; // value of what's in the vault
    div r5 r4 into r6; // new collateralization ratio

    IF r6 < MIN_COLLATERALIZATION_RATIO:
        THROW ERROR;

    SEND r0 TO self.caller;

    finalize r3 self.caller;

finalize borrow:
    input r0 as u64.public; // new amount of uszk to borrow
    input r1 as address.public;

    increment vault_borrows[r1] by r0;

function repay_borrow:
    input r0 as u64.public; // amount of uszk to repay_borrow

    // should adjust the collateralization ratio and save

    finalize r0 self.caller;

finalize repay_borrow:
    input r0 as u64.public;
    input r1 as address.public;

    decrement vault_borrows[r1] by r0;