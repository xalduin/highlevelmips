require_relative 'statement.rb'
require_relative 'variable.rb'
require_relative 'expression.rb'

def process_var(match, var_list)
    ident = match[1]
    type = match[2]
    is_array = (match[3] != nil)

    if var_list.has_ident?(ident)
        raise "Redeclared variable '#{ident}'"
        return false
    end

    if is_array
        type = type + "_array"
    end

    var = Variable.new(ident, type)
    var_list.add(var)

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
