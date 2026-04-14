.text
.globl main
.extern printf
.extern atoi
.extern putchar

.data
fmt: .string "%d "       # Format string for printing indices

.bss
.balign 8                # Align to 8-byte boundary for 64-bit loads/stores
arr: .space 8000         # Space for 1000 IQ values (8 bytes each)
res: .space 8000         # Space for 1000 result indices
stack: .space 8000       # Space for the stack (storing indices)

.text

main:
    addi sp, sp, -48     # Allocate 48 bytes on stack (16-byte aligned)
    sd ra, 40(sp)        # Save return address
    sd s0, 32(sp)        # Save s0 (argc)
    sd s1, 24(sp)        # Save s1 (argv pointer)
    sd s2, 16(sp)        # Save s2 (argument counter i)
    sd s3, 8(sp)         # Save s3 (array size n)
    mv s0, a0            # Store argc in s0
    mv s1, a1            # Store argv pointer in s1
    li s2, 1             # Start index at 1 (skip program name in argv[0])
    li s3, 0             # Initialize array element count to 0

reading:
    bge s2, s0, read_completed # If i >= argc, finished reading arguments
    slli t0, s2, 3       # Multiply index i by 8 (pointer size)
    add t1, s1, t0       # Calculate address of argv[i]
    ld a0, 0(t1)         # Load pointer to the string argument
    call atoi            # Convert string IQ to integer
    slli t2, s3, 3       # Multiply element count by 8
    la t3, arr           # Load base address of arr
    add t4, t3, t2       # Calculate address of arr[s3]
    sd a0, 0(t4)         # Store the integer IQ into the array
    addi s3, s3, 1       # Increment element count
    addi s2, s2, 1       # Increment argument counter
    j reading            # Repeat for next argument

read_completed:
    addi t0, s3, -1      # t0 = n - 1 (start from rightmost element)
    li t1, -1            # t1 = -1 (initialize stack top index as empty)

whynot:
    blt t0, zero, print  # If current index < 0, processing is done; go to print

while:
    blt t1, zero, find_nge # If stack is empty, exit while loop
    la t2, stack         # Load stack base address
    slli t3, t1, 3       # Multiply stack top index by 8
    add t4, t2, t3       # Get address of stack[t1]
    ld t5, 0(t4)         # t5 = index stored at stack top
    la t2, arr           # Load arr base address
    slli t3, t5, 3       # Multiply stack-top index by 8
    add t4, t2, t3       # Get address of arr[stack.top()]
    ld t5, 0(t4)         # t5 = IQ value at stack top index
    la t2, arr           # Load arr base address
    slli t3, t0, 3       # Multiply current index i by 8
    add t4, t2, t3       # Get address of arr[i]
    ld t6, 0(t4)         # t6 = current IQ value (arr[i])
    blt t6, t5, find_nge # If current IQ < stack IQ, we found NGE; exit while
    addi t1, t1, -1      # Else, pop from stack (decrement stack top index)
    j while              # Repeat while loop

find_nge:
    la t2, res           # Load res base address
    slli t3, t0, 3       # Calculate offset for res[i]
    add t4, t2, t3       # t4 = address of res[i]
    blt t1, zero, set_neg # If stack empty, no greater element found
    la t2, stack         # Load stack base address
    slli t3, t1, 3       # Get offset for stack top
    add t5, t2, t3       # t5 = address of stack[top]
    ld t6, 0(t5)         # t6 = index stored at stack top
    sd t6, 0(t4)         # Store this index in res[i]
    j push_stack         # Proceed to push current index

set_neg:
    li t5, -1            # Load -1 into t5
    sd t5, 0(t4)         # Store -1 in res[i]

push_stack:
    addi t1, t1, 1       # Increment stack top index
    la t2, stack         # Load stack base address
    slli t3, t1, 3       # Get offset for new stack top
    add t4, t2, t3       # t4 = address of stack[new_top]
    sd t0, 0(t4)         # Push current index i onto the stack
    addi t0, t0, -1      # Move to the next element on the left (i--)
    j whynot             # Repeat main logic loop

print:
    li s2, 0             # Initialize print counter s2 to 0

printing:
    bge s2, s3, end      # If s2 >= n, finished printing
    la t0, res           # Load res base address
    slli t1, s2, 3       # Calculate offset for res[s2]
    add t2, t0, t1       # t2 = address of res[s2]
    ld a1, 0(t2)         # Load the result index into a1 for printf
    la a0, fmt           # Load the format string "%d " into a0
    call printf          # Print the index
    addi s2, s2, 1       # Increment print counter
    j printing           # Repeat for next element

end:
    li a0, 10            # Load ASCII for newline ('\n')
    call putchar         # Print the newline
    li a0, 0             # Set return value to 0
    ld ra, 40(sp)        # Restore return address
    ld s0, 32(sp)        # Restore s0
    ld s1, 24(sp)        # Restore s1
    ld s2, 16(sp)        # Restore s2
    ld s3, 8(sp)         # Restore s3
    addi sp, sp, 48      # Deallocate stack frame
    ret                  # Return to caller
