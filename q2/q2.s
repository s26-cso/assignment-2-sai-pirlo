.text
.globl main
.extern printf
.extern atoi
.extern putchar

.data
fmt: .string "%d "          # Format for elements with a trailing space
fmt_last: .string "%d"      # Format for the final element (no trailing space)

.bss
.balign 8                   # Align memory to 8-byte boundary for 64-bit access
arr: .space 8000            # Array to store input IQ values (up to 1000)
res: .space 8000            # Array to store resulting indices
stack: .space 8000          # Memory used as a stack to find next greater element

.text

main:
    addi sp, sp, -48        # Allocate 48 bytes of stack space
    sd ra, 40(sp)           # Save the return address to the stack
    sd s0, 32(sp)           # Save s0 (argc) to the stack
    sd s1, 24(sp)           # Save s1 (argv pointer) to the stack
    sd s2, 16(sp)           # Save s2 (loop counter) to the stack
    sd s3, 8(sp)            # Save s3 (array size) to the stack

    mv s0, a0               # Move argc into s0
    mv s1, a1               # Move argv pointer into s1

    li s2, 1                # Initialize i = 1 (to skip program name in argv[0])
    li s3, 0                # Initialize array size count = 0

reading:
    bge s2, s0, read_completed # If i >= argc, exit the reading loop
    slli t0, s2, 3          # Multiply index by 8 to get byte offset
    add t1, s1, t0          # Get the address of argv[i]
    ld a0, 0(t1)            # Load the string pointer from argv[i]
    call atoi               # Convert string to integer (IQ value)
    slli t2, s3, 3          # Multiply count by 8 for array offset
    la t3, arr              # Load the base address of the IQ array
    add t4, t3, t2          # Calculate the address for the current element
    sd a0, 0(t4)            # Store the converted integer into arr[s3]
    addi s3, s3, 1          # Increment the array size counter
    addi s2, s2, 1          # Increment the argument counter
    j reading               # Jump back to read the next argument

read_completed:
    addi t0, s3, -1         # Set t0 to n - 1 (start index from the right)
    li t1, -1               # Initialize stack top index as -1 (empty)

whynot:
    blt t0, zero, print     # If index < 0, all elements processed; go to print

while:
    blt t1, zero, find_nge  # If stack is empty, skip to finding NGE
    la t2, stack            # Load stack base address
    slli t3, t1, 3          # Multiply stack top index by 8
    add t4, t2, t3          # Calculate address of stack[top]
    ld t5, 0(t4)            # Load the index stored at the stack top
    la t2, arr              # Load arr base address
    slli t3, t5, 3          # Multiply index from stack by 8
    add t4, t2, t3          # Get address of arr[stack_top_index]
    ld t5, 0(t4)            # Load the IQ value at that index
    la t2, arr              # Load arr base address again
    slli t3, t0, 3          # Multiply current index i by 8
    add t4, t2, t3          # Get address of current IQ value arr[i]
    ld t6, 0(t4)            # Load the current IQ value
    blt t6, t5, find_nge    # If current IQ < stack IQ, we found the NGE
    addi t1, t1, -1         # Else, pop from stack by decrementing top index
    j while                 # Repeat until stack is empty or NGE is found

find_nge:
    la t2, res              # Load base address of results array
    slli t3, t0, 3          # Calculate offset for current index
    add t4, t2, t3          # Get address of res[i]
    blt t1, zero, set_neg   # If stack is empty, no greater element exists
    la t2, stack            # Load stack base address
    slli t3, t1, 3          # Calculate offset for stack top
    add t5, t2, t3          # Get address of stack[top]
    ld t6, 0(t5)            # Load the index of the NGE from the stack
    sd t6, 0(t4)            # Store that index in the result array
    j push_stack            # Jump to push the current index to the stack

set_neg:
    li t5, -1               # Load -1 to represent "no greater element"
    sd t5, 0(t4)            # Store -1 in the result array

push_stack:
    addi t1, t1, 1          # Increment stack top index (push operation)
    la t2, stack            # Load stack base address
    slli t3, t1, 3          # Calculate offset for new stack top
    add t4, t2, t3          # Get address for new stack top
    sd t0, 0(t4)            # Store current index t0 onto the stack
    addi t0, t0, -1         # Decrement current index (move to the left)
    j whynot                # Repeat processing for the next element

print:
    li s2, 0                # Initialize output counter i = 0
    addi s0, s3, -1         # Calculate the index of the last element (n - 1)

printing:
    bge s2, s3, end         # If i >= n, exit the printing loop
    la t0, res              # Load base address of results array
    slli t1, s2, 3          # Calculate offset for res[i]
    add t2, t0, t1          # Get address of res[i]
    ld a1, 0(t2)            # Load the result value into a1 for printf
    beq s2, s0, last_val    # If this is the last element, use a different format
    la a0, fmt              # Load "%d " format string
    call printf             # Print value followed by space
    j iter_inc              # Jump to increment loop counter

last_val:
    la a0, fmt_last         # Load "%d" format string (no space)
    call printf             # Print the final value

iter_inc:
    addi s2, s2, 1          # Increment the loop counter i
    j printing              # Repeat for the next element

end:
    li a0, 10               # Load ASCII value for newline ('\n')
    call putchar            # Print the newline character
    li a0, 0                # Set main return value to 0
    ld ra, 40(sp)           # Restore the return address from the stack
    ld s0, 32(sp)           # Restore s0 from the stack
    ld s1, 24(sp)           # Restore s1 from the stack
    ld s2, 16(sp)           # Restore s2 from the stack
    ld s3, 8(sp)            # Restore s3 from the stack
    addi sp, sp, 48         # Deallocate the stack frame
    ret                     # Return to the operating system
