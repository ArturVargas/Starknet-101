%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn
from starkware.starknet.common.messages import send_message_to_l1

const MESSAGE_WITHDRAW = 0;

// 0x8359E4B0152ed5A731162D3c7B0D8D56edB165A0
@storage_var
func L1_CONTRACT_ADDRESS() -> (contract_address: felt) {
}

// A mapping from a user (L1 Ethereum address) to their balance.
@storage_var
func balance(l1_user: felt) -> (amount: felt) {
}

@view
func get_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(user: felt) -> (
    balance: felt
) {
    let (res) = balance.read(l1_user=user);
    return (balance=res);
}

// set the contract address
@external
func set_l1_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    l1_address: felt
) {
    L1_CONTRACT_ADDRESS.write(l1_address);
    return ();
}

// Function to print some money to play with
@external
func increase_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user: felt, amount: felt
) {
    let (res) = balance.read(l1_user=user);
    balance.write(user, res + amount);
    return ();
}

// Sending a message to L1
@external
func withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user: felt, amount: felt
) {
    // Make sure 'amount' is positive.
    assert_nn(amount);

    let (res) = balance.read(l1_user=user);
    tempvar new_balance = res - amount;

    // Make sure the new balance will be positive.
    assert_nn(new_balance);

    // Update the new balance.
    balance.write(user, new_balance);

    // Send the withdrawal message.
    let (message_payload: felt*) = alloc();
    assert message_payload[0] = MESSAGE_WITHDRAW;
    assert message_payload[1] = user;
    assert message_payload[2] = amount;
    let (contract_address) = L1_CONTRACT_ADDRESS.read();
    send_message_to_l1(to_address=contract_address, payload_size=3, payload=message_payload);

    return ();
}

// Receiving messages from L1
@l1_handler
func deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_address: felt, user: felt, amount: felt
) {
    // Make sure the message was sent by the intended L1 contract.
    let (contract_address) = L1_CONTRACT_ADDRESS.read();
    assert from_address = contract_address;

    // Read the current balance.
    let (res) = balance.read(l1_user=user);

    // Compute and update the new balance.
    tempvar new_balance = res + amount;
    balance.write(user, new_balance);

    return ();
}

// https://goerli.etherscan.io/address/0x8359E4B0152ed5A731162D3c7B0D8D56edB165A0#writeContract
