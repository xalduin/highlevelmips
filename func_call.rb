require_relative 'statement.rb'
require_relative 'expression.rb'
require_relative 'variable.rb'

FUNC_CALL_REGEXP = /\w+/

TYPE_WORD = :word
TYPE_HALF = :half
TYPE_BYTE = :byte
TYPE_CONST = :const
TYPE_WORD_ARRAY = :word_array
TYPE_HALF_ARRAY = :half_array
TYPE_BYTE_ARRAY = :byte_array

IMPLICIT_CAST_TABLE = {
    TYPE_CONST => [:byte, :half, :word],
    TYPE_BYTE  => [:half, :word],
    TYPE_HALF  => [:word]
}

def valid_type_match(arg_type, param_type)
    if arg_type == param_type
        return true
    end

    cast_list = IMPLICIT_CAST_TABLE[arg_type.to_sym]
    if cast_list == nil
        return false
    end

    return cast_list.include?(param_type)
end


# String * [Empty] * [Hash] * Hash -> True/nil
# Returns true on success, nil on failure
#
# Hash format:
# :type => :const or :var
#
# :value => 
#   if :const, then the constant value
#   if :var, then the variable index
#
# Result is stored in result_list
def process_func_call_args(call_args, result_list, func_params, local_table)
    if call_args == nil || call_args.empty?
        return true
    end

    unless result_list.empty?
        puts "InternalError: result_list must be empty"
        return nil
    end

    index = 0
    arg_matches = call_args.scan(FUNC_CALL_REGEXP)


    arg_matches.each do |arg_match|
        arg = arg_match

        # Lookup info on the function parameter's type
        func_param = func_params[index]
        if func_param == nil
            puts "Too many arguments supplied to function call"
            return nil
        end
        param_type = func_param[:type].to_sym

        entry = {}
        match = arg.match(CONST_REGEXP)
        if match
            entry[:value] = arg
            entry[:type]  = :const

            unless valid_type_match(:const, param_type)
                puts "Cannont convert constant '#{arg}' to '#{param_type}'"
                return nil
            end

        else
            var = lookup_var(arg, local_table)
            if var == nil
                puts "Unknown variable '#{arg}'"
                return nil
            end

            var_name = var[0]
            var_type = var[1].to_sym

            unless valid_type_match(var_type, param_type)
                puts "Cannot convert '#{arg}:#{var_type}' to #{param_type}"
                return nil
            end

            entry[:type] = :var
            entry[:value] = var_name
        end

        result_list<< entry
        index += 1
    end

    if index < func_params.size
        puts "Expected #{func_params.size} arguments, only #{index} supplied"
        return nil
    end

    return true 
end

# String * MatchData * Hash * Hash -> True/nil
# True on success, nil on failure
#
# Instruction added (format):
# :type => :func_call
# :ident => function being called
# :args => list of arguments
def process_func_call(line, match, global_table, local_table)
    unless global_table[:current_func]
        puts "Function calls must be made inside functions"
        return nil
    end

    if global_table[:func] == nil
        puts "InternalError: No global table entry for functions"
        return nil
    end

    func_name = match[1]
    call_args = match[2]

    unless global_table[:func].has_key?(func_name)
        puts "Trying to call undeclared function #{func_name}"
        return nil
    end

    arg_list = []
    func_args = global_table[:func_args][func_name]

    unless process_func_call_args(call_args, arg_list, func_args, local_table)
        return nil
    end

    # Create the instruction and add it to the list
    instruction = {:type  => :func_call,
                   :ident => func_name,
                   :args  => arg_list
    }
    instruction_list = local_table[:instructions]
    instruction_list<< instruction

    return true
end
