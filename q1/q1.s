.text
.globl make_node
.globl insert
.globl get
.globl getAtMost

make_node:
    addi sp, sp, -16     # Allocate 16 bytes on the stack
    sd ra, 8(sp)         # Save the return address to the stack
    sd s0, 0(sp)         # Save register s0 to the stack

    mv s0, a0            # Move input value from a0 to s0 for safekeeping
    li a0, 24            # Load 24 into a0 (size of struct Node in bytes)
    call malloc          # Call malloc to allocate memory for the new node

    sw s0, 0(a0)         # Store the value into the first 4 bytes of the node
    sd zero, 8(a0)       # Set the left pointer (offset 8) to NULL
    sd zero, 16(a0)      # Set the right pointer (offset 16) to NULL

    ld ra, 8(sp)         # Restore the return address from the stack
    ld s0, 0(sp)         # Restore register s0 from the stack
    addi sp, sp, 16      # Deallocate 16 bytes from the stack
    ret                  # Return to the caller

insert:
    addi sp, sp, -32     # Allocate 32 bytes on the stack
    sd ra, 24(sp)        # Save the return address to the stack
    sd s0, 16(sp)        # Save register s0 (root) to the stack
    sd s1, 8(sp)         # Save register s1 (val) to the stack

    mv s0, a0            # Store the current root pointer in s0
    mv s1, a1            # Store the value to insert in s1

    bnez s0, insert_compare # If root is not NULL, jump to comparison logic

    mv a0, s1            # If root is NULL, prepare value for new node
    call make_node       # Create the new leaf node
    j insert_end         # Jump to function exit

insert_compare:
    lw t0, 0(s0)         # Load the value of the current node into t0
    beq s1, t0, insert_dup  # If value matches current node, it's a duplicate
    blt s1, t0, insert_left # If value is less than current node, go left

    ld a0, 16(s0)        # Load the right child pointer into a0
    mv a1, s1            # Move target value into a1 for recursive call
    call insert          # Recursively call insert on the right child
    sd a0, 16(s0)        # Update the current node's right pointer with result
    j insert_dup         # Jump to return logic

insert_left:
    ld a0, 8(s0)         # Load the left child pointer into a0
    mv a1, s1            # Move target value into a1 for recursive call
    call insert          # Recursively call insert on the left child
    sd a0, 8(s0)         # Update the current node's left pointer with result

insert_dup:
    mv a0, s0            # Move the original root pointer into a0 for return

insert_end:
    ld ra, 24(sp)        # Restore the return address from the stack
    ld s0, 16(sp)        # Restore register s0 from the stack
    ld s1, 8(sp)         # Restore register s1 from the stack
    addi sp, sp, 32      # Deallocate 32 bytes from the stack
    ret                  # Return to the caller

get:
get_loop:
    beqz a0, get_end     # If current node is NULL, value not found; exit
    lw t0, 0(a0)         # Load current node's value into t0

    beq a1, t0, get_end  # If values match, node found; exit loop
    blt a1, t0, get_left # If target is less than current value, go left

    ld a0, 16(a0)        # Move current node pointer to the right child
    j get_loop           # Repeat loop

get_left:
    ld a0, 8(a0)         # Move current node pointer to the left child
    j get_loop           # Repeat loop

get_end:
    ret                  # Return (a0 is either the node pointer or NULL)

getAtMost:
    li a2, -1            # Initialize best candidate (a2) to -1

gam_loop:
    beqz a1, getAtMost_end # If current node is NULL, no more nodes; exit loop

    lw t0, 0(a1)         # Load current node's value into t0

    beq t0, a0, getAtMost_equal # If exact match, it's the perfect "at most"
    bgt t0, a0, getAtMost_left  # If current value is too big, must go left

    mv a2, t0            # Current value is smaller than target; update candidate
    ld a1, 16(a1)        # Move to right child to look for a larger valid value
    j gam_loop           # Repeat loop

getAtMost_left:
    ld a1, 8(a1)         # Move current node pointer to the left child
    j gam_loop           # Repeat loop

getAtMost_equal:
    mv a0, t0            # Move the matching value into a0 for return
    ret                  # Return immediately

getAtMost_end:
    mv a0, a2            # Move the best candidate found (-1 or value) into a0
    ret                  # Return to the caller
