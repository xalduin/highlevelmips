load 'instructions.rb'

def generate_branch(expression, dest_label, local_table)
    # Constant expressions require no condition checking
    if expression == true
        return [ generate_j(dest_label) ]
    elsif expression == false
        return []
    end

    temp_register_stack = Array(0..(TEMP_REGISTER_COUNT - 1))
    result = []

    left = expression[:left]
    left_type = left[0]
    left_value = left[1]
    right = expression[:right]
    right_type = right[0]
    right_value = right[1]
    operation = expression[:op]

    # Immediate values must be the 2nd argument, so perform a negation and
    # argument order swap
    if left_type == :const
        operation = OP_OPPOSITE_TABLE[operation]

        left_type, right_type = right_type, left_type
        left_value, right_value = right_value, left_value
    end

    right_reg = nil
    right_index = nil

    # If the right side value is a constant, move it into a register
    if right_type == :const
        right_index = temp_register_stack.pop
        right_reg = RS_TEMP + right_index.to_s

        # Generate the load immediate instruction
        result<< generate_li(right_reg, right_value)
    end

    left_reg = get_variable_register(left_value, local_table)

    # The set less than instruction is used for < and >=
    if operation == :less || operation == :greater_equal
        temp_index = temp_register_stack.pop
        temp_reg   = RS_TEMP + temp_index

        result<< generate_slt(temp_reg, left_reg, right_reg)

    # Subtraction is used for <= and > operations
    elsif operation == :less_equal || operation == :greater
        temp_index = temp_register_stack.pop
        temp_reg   = RS_TEMP + temp_index

        result<< generate_sub(temp_reg, left_reg, right_reg)
    end

    case operation
    when :equal
        result<< generate_beq(left_reg, right_reg, dest_label)
    when :not_equal
        result<< generate_bne(left_reg, right_reg, dest_label)
    
    when :less
        result<< generate_bne(temp_reg, R_ZERO, dest_label)
    when :greater_equal
        result<< generate_beq(temp_reg, R_ZERO, dest_label)

    when :less_equal
        result<< generate_blez(temp_reg, dest_label)
    when :greater
        result<< generate_bgtz(temp_reg, dest_label)
    end

    return result
end

def generate_branch_negation(expression, dest, local_table)
    left = expression[:left]
    right = expression[:right]
    operation = expression[:op]

    operation = OP_OPPOSITE_TABLE[operation]
    new_expression = {
        :left => right,
        :right => left,
        :op => operation
    }

    return generate_branch(new_expression, dest, local_table)
end

def loop_name(func_name, index)
    return "func_#{func_name}_loop#{index}"
end

def generate_loop(func_name, instruction)
    index = instruction[:index]
    return [ generate_label(loop_name(func_name, index)) ]
end

def generate_endloop(func_name, instruction)
    index = instruction[:index]
    loop_label = loop_name(func_name, index)

    result = []
    result<< generate_j(loop_label)
    result<< generate_label(loop_label + '_end')

    return result
end

def get_variable_register(name, local_table)
    return RS_LOCAL + local_table[:var][name].to_s
end

def generate_exitwhen(func_name, instruction, local_table)
    index = instruction[:index]
    dest_label = loop_name(func_name, index) + '_end'

    expression = instruction[:value]
    return generate_branch(expression, dest_label, local_table)
end


def generate_instruction(instruction, global_table, local_table)
    type = instruction[:type]
    func_name = global_table[:current_func]

    case type
    when :loop
        return generate_loop(func_name, instruction)
    when :endloop
        return generate_endloop(func_name, instruction)
    when :exitwhen
        return generate_exitwhen(func_name, instruction, local_table)
    end
end
