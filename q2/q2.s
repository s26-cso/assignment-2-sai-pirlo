.text
.globl main
.extern printf
.extern atoi
.extern putchar

.data
fmt: .string "%d "           # Format for integers with a space
fmt_last: .string "%d"       # Format for the final integer (no space)

.bss
.balign 16                   # Ensure 16-byte alignment for the data section
arr: .space 80000            # Space for 10,000 IQs (8 bytes each)
res: .space 80000            # Space for 10,000 result indices
stack: .space 80000          # Space for 10,000 stack indices

.text

main:
    addi sp, sp, -48         # Allocate 48 bytes on the stack
    sd ra, 40(sp)            # Save return address to stack
    sd s0, 32(sp)            # Save s0 (argc) to stack
    sd s1, 24(sp)            # Save s1 (argv pointer) to stack
    sd s2, 16(sp)            # Save s2 (loop counter/index) to stack
    sd s3, 8(sp)             # Save s3 (total element count n) to stack

    mv s0, a0                # Copy argc into s0
    mv s1, a1                # Copy argv pointer into s1

    li s2, 1                 # Set s2 = 1 to skip the program name in argv[0]
    li s3, 0                 # Initialize student count n = 0

reading:
    bge s2, s0, read_completed # If loop index >= argc, we are done reading
    slli t0, s2, 3           # Calculate offset for argv[s2] (index * 8)
    add t1, s1, t0           # Get address of the string pointer in argv
    ld a0, 0(t1)             # Load the string pointer into a0
    call atoi                # Convert the string to an integer
    slli t2, s3, 3           # Calculate offset for arr[s3]
    la t3, arr               # Load base address of our IQ array
    add t4, t3, t2           # Get address of current array slot
    sd a0, 0(t4)             # Store the IQ value into the array
    addi s3, s3, 1           # Increment total student count n
    addi s2, s2, 1           # Increment argument loop index
    j reading                # Jump back to read the next student

read_completed:
    addi t0, s3, -1          # t0 = n - 1 (start index for NGE logic)
    li t1, -1                # t1 = stack top index (initialize to -1 for empty)

whynot:
    blt t0, zero, print      # If current index < 0, all students processed

while:
    blt t1, zero, find_nge   # If stack is empty, exit the while loop
    la t2, stack             # Load base address of the stack
    slli t3, t1, 3           # Get offset of the stack top element
    add t4, t2, t3           # Get address of stack[top]
    ld t5, 0(t4)             # Load the index stored at the stack top
    la t2, arr               # Load base address of IQ array
    slli t3, t5, 3           # Get offset of the IQ at the stack top's index
    add t4, t2, t3           # Get address of arr[stack.top()]
    ld t5, 0(t4)             # t5 = IQ of the student on the stack top
    la t2, arr               # Load base address of IQ array
    slli t3, t0, 3           # Get offset of the current student's IQ
    add t4, t2, t3           # Get address of arr[current_index]
    ld t6, 0(t4)             # t6 = IQ of the current student
    blt t6, t5, find_nge     # If current IQ < stack IQ, stack top is the NGE
    addi t1, t1, -1          # Else, pop stack (top index decrement)
    j while                  # Repeat loop

find_nge:
    la t2, res               # Load base address of result array
    slli t3, t0, 3           # Calculate offset for res[current_index]
    add t4, t2, t3           # Get address of res[current_index]
    blt t1, zero, set_neg    # If stack is empty, no greater element found
    la t2, stack             # Load base address of the stack
    slli t3, t1, 3           # Get offset of the stack top
    add t5, t2, t3           # Get address of stack[top]
    ld t6, 0(t5)             # Load the index stored on the stack top
    sd t6, 0(t4)             # Store that index as the NGE result
    j push_stack             # Go to push current index onto stack

set_neg:
    li t5, -1                # Load -1 for "no greater element"
    sd t5, 0(t4)             # Store -1 into the result array

push_stack:
    addi t1, t1, 1           # Increment stack top index (push)
    la t2, stack             # Load base address of stack
    slli t3, t1, 3           # Get offset for the new stack top
    add t4, t2, t3           # Get address for new stack top
    sd t0, 0(t4)             # Store current index t0 on the stack
    addi t0, t0, -1          # Decrement loop index (move to the left)
    j whynot                 # Repeat for the next student student

print:
    li s2, 0                 # Initialize printing counter s2 = 0
    addi s0, s3, -1          # Calculate s0 = n - 1 (the index of the last element)

printing:
    bge s2, s3, end          # If printing counter >= n, we are done
    la t0, res               # Load base address of result array
    slli t1, s2, 3           # Get offset for result at current counter
    add t2, t0, t1           # Get address of res[s2]
    ld a1, 0(t2)             # Load the result index/value into a1 for printf
    beq s2, s0, last_val     # If current index is the last element, jump
    la a0, fmt               # Load format string "%d " (with space)
    call printf              # Print the integer and the space
    j iter_inc               # Skip to increment counter

last_val:
    la a0, fmt_last          # Load format string "%d" (no space)
    call printf              # Print the final integer

iter_inc:
    addi s2, s2, 1           # Increment the printing counter
    j printing               # Repeat for the next result

end:
    li a0, 10                # Load ASCII value for newline '\n'
    call putchar             # Print the newline character
    li a0, 0                 # Set main's return value to 0
    ld ra, 40(sp)            # Restore return address from stack
    ld s0, 32(sp)            # Restore s0 from stack
    ld s1, 24(sp)            # Restore s1 from stack
    ld s2, 16(sp)            # Restore s2 from stack
    ld s3, 8(sp)             # Restore s3 from stack
    addi sp, sp, 48          # Deallocate the stack frame
    ret                      # Return to the OS
