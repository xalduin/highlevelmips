require_relative 'expression.rb'

CONDITION_OPS = ['==', '!=', '<', '<=', '>', '>=']
EXPRESSION_OPS = ['+', '-']
TERM_OPS = ['*', '-']

def parse_condition(text)
    result = []

    result<< parse_expression(text)

    text.lstrip!
    op = text[0..1]
    unless CONDITION_OPS.include? op
        raise "Unknown conditional operator '#{op}'"
    end
    text.slice!(0..1)
    result<< OP_TABLE[op]

    result<< parse_expression(text)

    return result
end


# expresssion = [-] term [{+, -} term]*
def parse_expression(text)
    result = []

    result<< parse_term(text)

    text.strip!
    until text.empty?
        op = text[0]

        # Reached the end of known parsing, return
        unless EXPRESSION_OPS.include?(op)
            if result.size == 1
                return result[0]
            end
            return result
        end

        text.slice!(0)
        result<< OP_TABLE[op]
        result<< parse_expression(text)
        text.strip!
    end

    if result.size == 1
        return result[0]
    end
    return result
end

def parse_term(text)
    result = []

    result<< parse_factor(text)

    text.lstrip!
    until text.empty?
        op = text[0]

        unless TERM_OPS.include?(op)
            if result.size == 1
                return result[0]
            end
            return result
        end
        text.slice!(0)

        result<< OP_TABLE[op]
        result<< parse_expression(text)
        text.lstrip!
    end

    if result.size == 1
        return result[0]
    end
    return result
end

# Numbers, includes hex, binary, octal
# 0xabcdef for hex
# 0b10 for binary
# 01234567 for octal
# 124567890 for decimal
NUM_REGEXP = /^
    (
        (:?\-?0[xX][a-fA-F\d]+)
        |
        (:?\-?0[bB][01]+)
        |
        (:?\-?0[0-7]+)
        |
        (:?\-?\d+)
    )/x
IDENT_REGEXP = /^([a-zA-Z]\w*)/

# Factors are:
#   numbers
#   identifiers (just an identifier = variable)
#   an expression inside parenthesis
def parse_factor(text)
    text.lstrip!

    char = text[0]
    if char == '('
        text.slice!(0)
        result = parse_expression(text)
        char = text.slice!(0)

        unless char == ')'
            raise "Expected ')' but read '#{char}'"
        end

        return result

    elsif char.match(IDENT_REGEXP)
        ident = text.slice!(IDENT_REGEXP)
        return ident
    else
        match = text.slice!(NUM_REGEXP)
        if match.empty?
            puts "Text: '#{text}', match = '#{match}'"
            raise "Expected number"
        end
        num = Integer(match)
        return num
    end
end

        
