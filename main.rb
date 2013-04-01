require_relative 'statement.rb'
require_relative 'variable.rb'
require_relative 'func.rb'
require_relative 'loop.rb'
require_relative 'if.rb'
require_relative 'func_call.rb'

require_relative 'func_gen.rb'

def valid_type?(type)
    return VAR_TYPES.include?(type)
end

def process_line(line, table)
    # Remove leading whitespace, comments and extra spaces
    line.strip!
    line.gsub!(/#.*/, '')
    line.gsub!(/  /, ' ')
    line.gsub!(/ *, */, ',')

    local_table = nil
    func_name = table[:current_func]
    if func_name
        local_table = table[:func][func_name]
    end

    match = line.match(S_VAR_DECL)
    if match
        return process_var(line, match, table, local_table)
    end

    match = line.match(S_CONST_DECL)
    if match
        return process_const_decl(line, match, table, local_table)
    end

    match = line.match(B_FUNC_DECL)
    if match
        return process_func_decl(line, match, table)
    end

    match = line.match(B_ENDFUNC)
    if match
        return process_endfunc(line, match, table)
    end

    match = line.match(B_IF_DECL)
    if match
        return process_if(line, match, table, local_table)
    end

    match = line.match(B_ELSE_DECL)
    if match
        return process_else(line, match, table, local_table)
    end

    match = line.match(B_ENDIF)
    if match
        return process_endif(line, match, table, local_table)
    end

    match = line.match(B_LOOP_DECL)
    if match
        return process_loop(line, match, table, local_table)
    end

    match = line.match(B_EXITWHEN)
    if match
        return process_exitwhen(line, match, table, local_table)
    end

    match = line.match(B_ENDLOOP)
    if match
        return process_endloop(line, match, table, local_table)
    end

    match = line.match(S_FUNC_CALL)
    if match
        return process_func_call(line, match, table, local_table)
    end

    match = line.match(S_SET_VAR)
    if match
        return process_set(line, match, table, local_table)
    end

    if line.match(/^\s*$/)
        return true
    end

    puts "Unrecognized expression"
    return nil
end
    
def create_table()
    text = File.open("input.hlm").read
    text.gsub!(/\r\n?/, "\n")

    table = {}

    line_number = 1
    text.each_line do |line|
        result = process_line(line, table)
        
        if result == nil
            puts "Line #{line_number}: #{line}\n"
            puts "Failed to parse file"
            break
        end

        line_number += 1
    end

    return table
end

def create_program(table, output_file)
    result = []
    File.open(output_file, "w") do |file|
        result = generate_program(table)
        result.each do |line|
            file << line + "\n"
        end
    end

    return result
end

#run_program
#puts "Finished"
