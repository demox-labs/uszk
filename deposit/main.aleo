// The 'deposit.aleo' program.
program deposit.aleo;

mapping:
    key owner as address.public;
    value aleo_deposited as u64.public;

function hello:
    input r0 as u32.public;
    input r1 as u32.private;
    add r0 r1 into r2;
    output r2 as u32.private;
