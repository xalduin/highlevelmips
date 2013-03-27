load 'instructions.rb'


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

def get_variable_id(name, local_table)
    

def generate_branch(expression, branch_label, local_table)
    # Constant expressions require no condition checking
    if expression == true
        return [ generate_j(branch_label) ]
    elsif expression == false
        return []
    end

    left = expression[:left]
    right = expression[:right]
    operation = expression[:op]



end

def generate_exitwhen(func_name, instruction, global_table, local_table)
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
    end
end
