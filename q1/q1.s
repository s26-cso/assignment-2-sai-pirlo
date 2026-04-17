.text
.globl make_node
.globl insert
.globl get
.globl getAtMost

make_node:
    addi sp, sp, -16     # Allocate 16 bytes on the stack
    sd ra, 8(sp)         # Save return address
    sd s0, 0(sp)         # Save s0 to stack
    mv s0, a0            # Save input value in s0
    li a0, 24            # Size: 4 (int) + 4 (pad) + 8 (ptr) + 8 (ptr)
    call malloc          # Allocate memory for the node
    sw s0, 0(a0)         # Set node->val
    sd zero, 8(a0)       # Set node->left = NULL
    sd zero, 16(a0)      # Set node->right = NULL
    ld ra, 8(sp)         # Restore return address
    ld s0, 0(sp)         # Restore s0
    addi sp, sp, 16      # Deallocate stack
    ret

insert:
    addi sp, sp, -32     # Allocate 32 bytes on the stack
    sd ra, 24(sp)        # Save return address
    sd s0, 16(sp)        # Save s0 (root)
    sd s1, 8(sp)         # Save s1 (val)
    mv s0, a0            # s0 = root
    mv s1, a1            # s1 = val
    bnez s0, insert_compare # If root is not NULL, go to comparison
    mv a0, s1            # If root is NULL, create new node
    call make_node
    j insert_end

insert_compare:
    lw t0, 0(s0)         # t0 = current->val
    beq s1, t0, insert_done # If val exists, return root
    blt s1, t0, insert_left # If val < current->val, go left
    ld a0, 16(s0)        # Load current->right
    mv a1, s1
    call insert          # Recurse right
    sd a0, 16(s0)        # Update current->right
    j insert_done

insert_left:
    ld a0, 8(s0)         # Load current->left
    mv a1, s1
    call insert          # Recurse left
    sd a0, 8(s0)         # Update current->left

insert_done:
    mv a0, s0            # Return the original root

insert_end:
    ld ra, 24(sp)
    ld s0, 16(sp)
    ld s1, 8(sp)
    addi sp, sp, 32
    ret

get:
get_loop:
    beqz a0, get_end     # If root is NULL, exit
    lw t0, 0(a0)         # t0 = current->val
    beq a1, t0, get_end  # If val matches, exit loop
    blt a1, t0, get_left # If val < current->val, go left
    ld a0, 16(a0)        # Move to right child
    j get_loop

get_left:
    ld a0, 8(a0)         # Move to left child
    j get_loop

get_end:
    ret                  # a0 is the node pointer or NULL

getAtMost:
    li a2, -1            # Initialize candidate to -1

gam_loop:
    beqz a1, gam_end     # If current node is NULL, exit loop
    lw t0, 0(a1)         # t0 = current->val (root is in a1)
    beq t0, a0, gam_exact # Exact match found
    bgt t0, a0, gam_left  # If node val > target, go left
    mv a2, t0            # current val < target: update candidate
    ld a1, 16(a1)        # Try to find a larger value on the right
    j gam_loop

gam_left:
    ld a1, 8(a1)         # Move to left child
    j gam_loop

gam_exact:
    mv a0, t0            # Return the exact match
    ret

gam_end:
    mv a0, a2            # Return the best candidate found
    ret
