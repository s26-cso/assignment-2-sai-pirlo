.text
.globl main
.extern printf
.extern atoi
.extern putchar

.data
fmt: .string "%d "           # Format for integers with a space 
fmt_last: .string "%d"       # Format for the last integer with no space 

.bss
.balign 16                   # Align memory for 64-bit performance 
arr: .space 800000           # Space for 100,000 IQs (8 bytes each) 
res: .space 800000           # Space for 100,000 results (8 bytes each) 
stack: .space 800000         # Space for the index stack (8 bytes each) 

.text

main:
    addi sp, sp, -48         # Create stack frame 
    sd ra, 40(sp)            # Save return address 
    sd s0, 32(sp)            # Save s0 (argc) 
    sd s1, 24(sp)            # Save s1 (argv pointer) 
    sd s2, 16(sp)            # Save s2 (loop counter) 
    sd s3, 8(sp)             # Save s3 (student count n) 

    mv s0, a0                # Move argc into s0 
    mv s1, a1                # Move argv into s1 

    li s2, 1                 # Start at index 1 to skip program name 
    li s3, 0                 # Initialize student count to zero 

reading:
    bge s2, s0, read_completed # If counter >= argc, stop reading 
    slli t0, s2, 3           # Calculate offset for argv[i] 
    add t1, s1, t0           # Get address of current argument string 
    ld a0, 0(t1)             # Load string pointer into a0 
    call atoi                # Convert IQ string to integer 
    slli t2, s3, 3           # Calculate offset for arr[n] 
    la t3, arr               # Load base address of IQ array 
    add t4, t3, t2           # Get address of current array slot 
    sd a0, 0(t4)             # Store integer IQ in array 
    addi s3, s3, 1           # Increment student count 
    addi s2, s2, 1           # Increment loop counter 
    j reading                # Repeat for next argument 

read_completed:
    beqz s3, end_no_newline  # If count is zero, exit without printing 
    addi t0, s3, -1          # t0 = n - 1 (process from right to left) 
    li t1, -1                # Initialize stack top index as empty (-1) 

whynot:
    blt t0, zero, print      # If loop index < 0, all students processed 

while:
    blt t1, zero, find_nge   # If stack is empty, exit while loop 
    la t2, stack             # Load stack base address 
    slli t3, t1, 3           # Get offset for stack top 
    add t4, t2, t3           # Get address of stack top 
    ld t5, 0(t4)             # Load index stored at stack top 
    la t2, arr               # Load IQ array base address 
    slli t3, t5, 3           # Get offset for IQ at that index 
    add t4, t2, t3           # Get address of IQ at stack top index 
    ld t5, 0(t4)             # Load the IQ of the student on the stack 
    la t2, arr               # Load IQ array base address 
    slli t3, t0, 3           # Get offset for current student IQ 
    add t4, t2, t3           # Get address for current student IQ 
    ld t6, 0(t4)             # Load current student IQ 
    blt t6, t5, find_nge     # If current IQ < stack IQ, NGE found 
    addi t1, t1, -1          # Else, pop stack (not greater) 
    j while                  # Repeat while loop 

find_nge:
    la t2, res               # Load result array base address 
    slli t3, t0, 3           # Get offset for current result slot 
    add t4, t2, t3           # Get address for res[i] 
    blt t1, zero, set_neg    # If stack empty, no greater element found 
    la t2, stack             # Load stack base address 
    slli t3, t1, 3           # Get offset for stack top 
    add t5, t2, t3           # Get address for stack top 
    ld t6, 0(t5)             # Load the index of the NGE 
    sd t6, 0(t4)             # Store index in the result array 
    j push_stack             # Go to push step 

set_neg:
    li t5, -1                # Set result to -1 
    sd t5, 0(t4)             # Store -1 in result array 

push_stack:
    addi t1, t1, 1           # Increment stack top index (push) 
    la t2, stack             # Load stack base address 
    slli t3, t1, 3           # Get offset for new stack top 
    add t4, t2, t3           # Get address for new stack top 
    sd t0, 0(t4)             # Store current index on the stack 
    addi t0, t0, -1          # Move to the student on the left 
    j whynot                 # Repeat for next student 

print:
    li s2, 0                 # Initialize printing loop index 
    addi s0, s3, -1          # Calculate index of the last element 

printing:
    bge s2, s3, end          # If index >= n, stop printing 
    la t0, res               # Load result array base address 
    slli t1, s2, 3           # Get offset for current result 
    add t2, t0, t1           # Get address of current result 
    ld a1, 0(t2)             # Load the result index for printing 
    beq s2, s0, last_val     # If this is the last element, skip space 
    la a0, fmt               # Load "%d " format 
    call printf              # Print integer with space 
    j iter_inc               # Next iteration 

last_val:
    la a0, fmt_last          # Load "%d" format 
    call printf              # Print final integer 

iter_inc:
    addi s2, s2, 1           # Increment loop counter 
    j printing               # Repeat printing 

end:
    li a0, 10                # Load ASCII newline '\n' 
    call putchar             # Print the newline 

end_no_newline:
    li a0, 0                 # Set return code to 0 
    ld ra, 40(sp)            # Restore return address 
    ld s0, 32(sp)            # Restore s0 
    ld s1, 24(sp)            # Restore s1 
    ld s2, 16(sp)            # Restore s2 
    ld s3, 8(sp)             # Restore s3 
    addi sp, sp, 48          # Release stack space 
    ret                      # Exit program
