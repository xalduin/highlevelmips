require_relative 'instructions.rb'

def generate_branch(expression, dest_label, var_list)
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
        if OP_COMMUTATIVE_TABLE[operation] == false
            operation = OP_OPPOSITE_TABLE[operation]
        end

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
    else
        right_reg = right_value.register
    end

    left_reg = left_value.register

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

def generate_expression(dest, expression, var_list)

    # If the expression is a constant, a load immediate will be fine
    if expression.is_a? Integer
        return [generate_li(dest, expression)]

    elsif expression == true
        return [generate_li(dest, 1)]

    elsif expression == false
        return [generate_li(dest, 0)]
    end

    # Create a stack of temp registers that can be popped if necessary
    temp_register_stack = Array(0..(TEMP_REGISTER_COUNT - 1))
    result = []

    left = expression[:left]
    left_type = left[0]
    left_value = left[1]
    right = expression[:right]
    right_type = right[0]
    right_value = right[1]
    operation = expression[:op]

    left_reg = nil
    right_reg = nil

    # Immediate values must either be the 2nd argument or be stored in
    # a register
    if left_type == :const
        commutative = OP_COMMUTATIVE_TABLE[operation]

        # Commutative operations allow for the left/right side to be
        # swapped without problem
        if commutative
            left_type, right_type = right_type, left_type
            left_value, right_value = right_value, left_value

        # Otherwise, the constant should be loaded into a register
        else
            temp_index = temp_register_stack.pop
            left_reg = RS_TEMP + temp_index.to_s

            result<< generate_li(left_reg, left_value)
        end
    end

    # Left side refers to a variable
    unless left_reg
        left_reg = left_value.register
    end

    # Right side is a variable
    if right_type == :ident
        right_reg = right_value.register
    end

    case operation
    when :add
        if right_type == :const
            result<< generate_addi(dest, left_reg, right_value)
        else
            result<< generate_add(dest, left_reg, right_reg)
        end

    when :mul
        if right_type == :const
            result<< generate_mul(dest, left_reg, right_value)
        else
            result<< generate_mul(dest, left_reg, right_reg)
        end

    when :sub
        if right_type == :const
            result<< generate_addi(dest, left_reg, "-" + right_value)
        else
            result<< generate_sub(dest, left_reg, right_reg)
        end

    when :div
        if right_type == :const
            result<< generate_div(dest, left_reg, right_value)
        else
            result<< generate_div(dest, left_reg, right_reg)
        end

    else
        puts "Unrecognized operation '#{operation}'"
        return nil
    end

    return result
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

def if_name(func_name, index)
    return "func_#{func_name}_if#{index}"
end

def generate_if(func_name, instruction, local_table)
    index      = instruction[:index]
    expression = instruction[:value]

    has_else = local_table[:if_has_else][index]
    dest_label = if_name(func_name, index)

    if has_else
        dest_label += "_else"
    else
        dest_label += "_end"
    end

    return generate_branch_negation(expression, dest_label, local_table)
end

# Else statement is in the format:
# jump to endif
# else statement label
def generate_else(func_name, instruction)
    index = instruction[:index]
    result = []

    result<< generate_j( if_name(func_name, index) + "_end" )
    result<< generate_label( if_name(func_name, index) + "_else" )
    return result
end

def generate_endif(func_name, instruction)
    index = instruction[:index]

    label_name = if_name(func_name, index) + "_end"
    return [ generate_label(label_name) ]
end

def generate_exitwhen(func_name, instruction, local_table)
    index = instruction[:index]
    dest_label = loop_name(func_name, index) + '_end'

    expression = instruction[:value]
    return generate_branch(expression, dest_label, local_table)
end

def generate_func_call(func_name, instruction, local_table)
    func_ident = instruction[:ident]
    func_args = instruction[:args]

    result = []

    arg_num = 0
    func_args.each do |arg|
        arg_type = arg[:type]
        arg_value = arg[:value]
        arg_register = RS_ARG + arg_num.to_s

        if arg_type == :const
            result<< generate_li(arg_register, arg_value)
        else
            result<< generate_move(arg_register, arg_value)
        end

        arg_num += 1
    end

    result<< generate_jal("func_" + func_ident)
    return result
end

def generate_assign(func_name, instruction, local_table)
    ident = instruction[:ident]
    value_type = instruction[:value_type]
    value = instruction[:value]

    var_register = get_variable_register(ident, local_table)

    if value_type == :const
        return [generate_li(var_register, value)]
    end

    # Value type is an expression
    return generate_expression(var_register, value, local_table)
end


def generate_instruction(instruction, global_table, local_table)
    type = instruction[:type]
    func_name = global_table[:current_func]

    case type
    when :if
        return generate_if(func_name, instruction, local_table)
    when :else
        return generate_else(func_name, instruction)
    when :endif
        return generate_endif(func_name, instruction)

    when :loop
        return generate_loop(func_name, instruction)
    when :endloop
        return generate_endloop(func_name, instruction)
    when :exitwhen
        return generate_exitwhen(func_name, instruction, local_table)

    when :func_call
        return generate_func_call(func_name, instruction, local_table)
    when :assign
        return generate_assign(func_name, instruction, local_table)
    else
        puts "Unrecognized instruction type '#{type}'"
        return []
    end
end
