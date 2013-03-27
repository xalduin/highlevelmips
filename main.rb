require 'statement.rb'
require 'variable.rb'

LOCAL_COUNT = 8

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
        process_var(line, match, table)
    end

    match = line.match(S_CONST_DECL)
    if match
        process_const_decl(line, match, table)
    end

    match = line.match(B_FUNC_DECL)
    if match
        process_func(line, match, table)
    end

    match = line.match(B_IF_DECL)
    if match
        return process_if(line, match, table, local_table)
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

end
    

text = File.open("input.hlm").read
text.gsub!(/\r\n?/, "\n")

table = {}

line_number = 1
text.each_line do |line|
    process_line(line, table)
    line_number += 1
end
