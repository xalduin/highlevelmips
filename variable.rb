require_relative 'expression.rb'

LOCAL_COUNT = 8

def lookup_var(name, local_table)
    unless local_table
        return nil
    end

    unless local_table[:var] && local_table[:var_type]
        return nil
    end

    index = local_table[:var][name]
    type  = local_table[:var_type][name]

    if index == nil || type == nil
        return nil
    end

    return index, type
end

# Local table usage:
# [:var_index] contains next unused index (int)
# [:var][name] contains index (0-7) for variable (int)
# [:var_type][name] contains type for variable (string)

def process_var(line, match, global_table, local_table)
    name = match[1]
    type = match[2]

    if match[3] or match[4]
        raise :var_error
    end

    unless global_table
        puts "Whoops? No global table"
        return nil
    end

    unless local_table
        puts "Cannot declare global variables"
        return nil
    end

    unless valid_type?(type)
        puts "Invalid type '" + type + "'"
        return nil
    end

    if local_table[:var] == nil
        local_table[:var] = {}
    end
    if local_table[:var_type] == nil
        local_table[:var_type] = {}
    end

    if local_table[:var].has_key?(name)
        puts "Redeclared local variable " + name
        return nil
    end

    index = local_table[:var_index]

    if index >= LOCAL_COUNT
        puts "Local variable count exceeded"
        return nil
    end

    local_table[:var][name] = index
    local_table[:var_type][name] = type
    local_table[:var_index] = index + 1

    return true
end

# Global table usage:
# [:const_value][name] = value of const (string)
# [:const_type][name] = type of const (string)

def process_const_decl(line, match, global_table, local_table)
    name = match[1]
    type = match[2]
    value = match[3]

    unless global_table
        puts "Whoops? No global table"
        return nil
    end

    unless valid_type?(type)
        puts "Invalid type: '" + type + "'"
        return nil
    end

    if global_table[:const_value] == nil
        global_table[:const_value] = {}
    end
    if global_table[:const_type] == nil
        global_table[:const_type] = {}
    end

    if global_table[:const_value].has_key?(name)
        puts "Redeclared constant " + name
        return nil
    end

    global_table[:const_value][name] = value
    global_table[:const_type][name] = type

    return true
end

# Adds an instruction for setting the value of a variable
# Checks to ensure that the variable was previously defined and that it has
# a proper expression
def process_set(line, match, global_table, local_table)

    unless global_table and local_table
        puts "Must have value for global and local tables"
        return nil
    end

    name = match[1]
    value = match[2]

    unless local_table[:var].has_key?(name)
        puts "Undeclared variable '#{name}'"
        return nil
    end

    value = process_noncondition_expression(value, local_table)

    if value == nil
        return nil
    end

    instruction = {:type  => :assign,
                   :ident => name,
                   :value => value
    }

    if value.is_a? Integer
        instruction[:value_type] = :const
    else
        instruction[:value_type] = :expression
    end

    instruction_list = local_table[:instructions]
    instruction_list<< instruction

    return true
end
