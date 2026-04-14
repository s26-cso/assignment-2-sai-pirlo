.text
.globl main
.extern fopen
.extern fseek
.extern ftell
.extern fgetc
.extern fclose
.extern printf

.data
fname: .string "input.txt"
mode:  .string "r"
yes:   .string "Yes\n"
no:    .string "No\n"

.text

main:
    addi sp, sp, -48     # Allocate stack frame
    sd ra, 40(sp)        # Save return address
    sd s0, 32(sp)        # s0 = file pointer
    sd s1, 24(sp)        # s1 = start index
    sd s2, 16(sp)        # s2 = end index
    sd s3, 8(sp)         # s3 = start character
    sd s4, 0(sp)         # s4 = end character
    la a0, fname         # Load filename
    la a1, mode          # Load mode "r"
    call fopen           # Open the file
    mv s0, a0            # Store file pointer in s0
    beqz s0, print_no    # If file pointer is NULL, fail

    # Find file size
    mv a0, s0
    li a1, 0
    li a2, 2             # SEEK_END
    call fseek           # Move pointer to the end of file

    mv a0, s0
    call ftell           # Get current position (size)
    mv s2, a0            # Store size in s2
    addi s2, s2, -1      # Set s2 to the index of the last byte

check:
    bltz s2, print_yes   # If file is empty, it's a palindrome
    mv a0, s0
    mv a1, s2
    li a2, 0             # SEEK_SET
    call fseek           # Move to index s2
    mv a0, s0
    call fgetc           # Read character at end
    li t0, 10            # Newline character (ASCII 10)
    beq a0, t0, skip     # If it's a newline, skip it
    j start              # Otherwise, start palindrome comparison

skip:
    addi s2, s2, -1      # Move end index back
    j check              # Check again

start:
    li s1, 0             # Set start index s1 = 0

loop:
    bge s1, s2, print_yes # If pointers meet or cross, it's a palindrome

    # Get character at start index
    mv a0, s0
    mv a1, s1
    li a2, 0
    call fseek
    mv a0, s0
    call fgetc
    mv s3, a0            # Save start character

    # Get character at end index
    mv a0, s0
    mv a1, s2
    li a2, 0
    call fseek
    mv a0, s0
    call fgetc
    mv s4, a0            # Save end character
    bne s3, s4, print_no # If characters don't match, not a palindrome
    addi s1, s1, 1       # Increment start index
    addi s2, s2, -1      # Decrement end index
    j loop

print_yes:
    la a0, yes
    call printf
    j end

print_no:
    la a0, no
    call printf

end:
    mv a0, s0
    call fclose          # Close the file
    li a0, 0             # Return 0
    ld ra, 40(sp)        # Restore registers
    ld s0, 32(sp)
    ld s1, 24(sp)
    ld s2, 16(sp)
    ld s3, 8(sp)
    ld s4, 0(sp)
    addi sp, sp, 48      # Deallocate stack
    ret
