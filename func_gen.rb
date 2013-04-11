require_relative 'instructions.rb'
require_relative 'function.rb'

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
    result<< generate_sw(R_RETURN_ADDRESS, 0, R_FRAME_POINTER)

    # Store existing local (S) registers
    index = 0
    size -= 8
    while index * 4 < size
        result<<generate_sw(RS_LOCAL + index.to_s,
                            -(index + 1) * REGISTER_SIZE,
                            R_FRAME_POINTER)

        index += 1
    end

    return result
end

def generate_store_parmeters(arg_list)
    result = [] 

    arg_list.each_index do |index|
        target_reg = RS_LOCAL + index.to_s
        source_reg = RS_ARG + index.to_s

        result<< generate_move(target_reg, source_reg)
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
                            -(index + 1) * REGISTER_SIZE,
                            R_FRAME_POINTER)

        index += 1
    end
    # Restore return address and frame pointer
    result<< generate_lw(R_RETURN_ADDRESS, 0, R_FRAME_POINTER)
    result<< generate_lw(R_FRAME_POINTER, 0, R_STACK_POINTER)

    # Restore stack pointer
    result<< generate_addi(R_STACK_POINTER, R_STACK_POINTER, size)

    return result
end

def setup_variables(var_list)
    vars = var_list.variables.values

    vars.each_with_index do |var, index|
        var.register = RS_LOCAL + index.to_s
    end
end

# String * {} -> [String]
# name: name of the function to generate
# global_table: table of information from parsed program
#
# result: An array of assembly instructions
def generate_func(func)
    unless func.is_a? Function
        raise "Internal: generate_func: func must be a Function"
    end

    func_name = func.ident.to_s
    instructions = func.instr_list

    # Calculate stack size needed, variables + return address + frame pointer
    var_count = func.var_list.size
    stack_size = (var_count + 2) * REGISTER_SIZE 

    # Generate function definition and stack allocation
    result = []
    result<< generate_label("func_" + func_name)
    result += generate_stack_allocate(stack_size)

    # Store arguments (a registers) in local (s registers)
    result += generate_store_parmeters(func.arg_list)

    setup_variables(func.var_list)

    # Generate each instruction
    instructions.each do |instruction|
        result += instruction.render
    end

    result<< generate_label("func_" + func_name + "_done")
    result += generate_stack_deallocate(stack_size)

    result<< generate_jr(R_RETURN_ADDRESS)

    return result
end

def generate_program(func_list)
    result = []
    func_list.each do |func|
        result += generate_func(func)
    end
    return result
end
