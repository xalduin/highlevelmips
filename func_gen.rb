require_relative 'instructions.rb'
require_relative 'instruction_gen.rb'

# Int -> [String]
# size: number of bytes to allocate, should be a minimum of 8
#
# Stack Format:
# Return address
# Saved registers
# Saved frame pointer
def generate_stack_allocate(size)
    result = []

    if size < 8
        puts "Need at least 8 bytes for stack"
        return nil
    end

    # Allocate space on stack
    result<< generate_addi(R_STACK_POINTER, R_STACK_POINTER, -size)

    # Store the frame pointer on the top of the stack
    result<< generate_sw(R_FRAME_POINTER, R_STACK_POINTER, 0)

    # Set frame pointer to location of return address
    result<< generate_addi(R_FRAME_POINTER,
                           R_STACK_POINTER,
                           size - REGISTER_SIZE)

    # Store return address
    result<< generate_sw(R_RETURN_ADDRESS, R_FRAME_POINTER, 0)

    # Store existing local (S) registers
    index = 0
    size -= 8
    while index * 4 < size
        result<<generate_sw(RS_LOCAL + index.to_s,
                            R_FRAME_POINTER,
                            -(index + 1) * REGISTER_SIZE)

        index += 1
    end

    return result
end

# Generates code to restore return address, frame pointer, and stack pointer
# Frame:
# [ Return address ]
#  ------------------- <- Frame pointer
# [ Saved registers]
# [ Saved frame pointer]
#  ---------------------- <- Stack pointer
def generate_stack_deallocate(size)
    result = []

    index = 0
    while index * (REGISTER_SIZE) < size - (REGISTER_SIZE * 2)
        result<<generate_lw(RS_LOCAL + index.to_s,
                            R_FRAME_POINTER,
                            -(index + 1) * REGISTER_SIZE)

        index += 1
    end
    # Restore return address and frame pointer
    result<< generate_lw(R_RETURN_ADDRESS, R_FRAME_POINTER, 0)
    result<< generate_lw(R_FRAME_POINTER, R_STACK_POINTER, 0)

    # Restore stack pointer
    result<< generate_addi(R_STACK_POINTER, R_STACK_POINTER, size)

    return result
end

# String * {} -> [String]
# name: name of the function to generate
# global_table: table of information from parsed program
#
# result: An array of assembly instructions
def generate_func(name, global_table)
    global_table[:current_func] = name
    local_table = global_table[:func][name]
    instructions = local_table[:instructions]

    # Calculate stack size needed, variables + return address + frame pointer
    var_count = local_table[:var_index]
    stack_size = (var_count + 2) * REGISTER_SIZE 

    # Generate function definition and stack allocation
    result = []
    result<< generate_label("func_" + name)
    result += generate_stack_allocate(stack_size)

    # Generate each instruction
    instructions.each do |instruction|
        result += generate_instruction(instruction, global_table, local_table)
    end

    result<< generate_label("func_" + name + "_done")
    result += generate_stack_deallocate(stack_size)

    result<< generate_jr(R_RETURN_ADDRESS)

    return result
end

def generate_program(global_table)
    result = []
    global_table[:func].each_key do |func_name|
        result += generate_func(func_name, global_table)
    end

    return result
end
