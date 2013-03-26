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

    match = line.match(S_VAR_DECL)
    if match
        process_var(line, match)
    end

    match = line.match(S_CONST_DECL)
    if match
        process_const_decl(line, match)
    end

    match = line.match(B_FUNC_DECL)
    if match
        process_func(line, match)
    end

    match = line.match(B_IF_DECL)
    if match
        process_if(line, match)
    end

    match = line.match(B_LOOP_DECL)
    if match
        process_loop(line, match)
    end

end
    

text = File.open("input.hlm").read
text.gsub!(/\r\n?/, "\n")

table = {}

text.each_line do |line|
    process_line(line, table)
end
