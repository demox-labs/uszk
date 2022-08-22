// The 'price_feed.aleo' program.
program price_feed.aleo;

interface oracle_token {
    oracle as address; // The address of the oracle
    token as address; // The address of the token program
}

mapping pair_prices:
    // The combo of oracle and token
    key oracle_token as field.public;

    // The price of the token.
    value price as u64.public;

function initialize:
    input r0 as address.public; // oracle address
    input r1 as address.public; // the symbol of the price
    input r2 as u64.public; // the current price

    cast r0 r1 into r3 as oracle_symbol;
    hash.ped64 r3 into r4;

    finalize r4 r2;


finalize initialize:
    input r0 as field.public;
    input r1 as u64.public;

    increment pair_prices[r0] by r1;


function update:
    input r0 as address.public; // oracle address
    input r1 as address.public; // the symbol of the price
    input r2 as u64.public; // the current price

    cast r0 r1 into r3 as oracle_symbol;
    hash.ped64 r3 into r4;

    finalize r4 r2 pair_prices[r4];


finalize update:
    input r0 as field.public;
    input r1 as u64.public;
    input r2 as u64.public;

    increment pair_prices[r0] by r1;
    decrement pair_prices[r0] by r2;


function get_price:
    input r0 as address.public; // token address
    input r1 as address.public; // oracle address #1, must not be null
    input r2 as address.public; // oracle address #2, could be nullable
    input r3 as address.public; // oracle address #3, could be nullable

    cast r1 r0 into r4 as oracle_symbol;
    hash.ped64 r4 into r5;

    cast r2 r0 into r6 as oracle_symbol;
    hash.ped64 r6 into r7;

    cast r3 r0 into r8 as oracle_symbol;
    hash.ped64 r8 into r9;

    assert.neg pair_prices[r5] 0u64; // halt if no price is set (assuming defaults to 0)
    gt pair_prices[r7] 0u64 into r10;
    gt pair_prices[r9] 0u64 into r11;

    cast r10 into r12 as u64; // Assumes a True casted boolean -> 1u64 & False -> 0u64
    cast r11 into r13 as u64; // Assumes a True casted boolean -> 1u64 & False -> 0u64

    // Calculate number of non-null oracles
    sum 1u64 r12 into r14;
    sum r13 r14 into r15;

    sum pair_prices[r5] pair_prices[r7] into r16;
    sum r16 pair_prices[r9] into r17;

    div r17 r15 into r18;

    output r18 as u64.public;