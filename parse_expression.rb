CONDITION_OPS = ['==', '!=', '<', '<=', '>', '>=']
EXPRESSION_OPS = ['+', '-']

def parse_condition(text)
    result = []

    result<< parse_expression(text)

    op = text[0..1]
    unless CONDITION_OPS.include? op
        raise "Unknown conditional operator '#{op}'"
    end
    text.slice!(0..1)
    result<< op

    result<< parse_expression(text)

    return result
end


# expresssion = [-] term [{+, -} term]*
def parse_expresssion(text)
    negate = (text[0] == '-')
    result = []

    if negate
        text.slice!(0)
        result<< :negate
    end

    result<< parse_term(text)

    until text.empty?
        op = text[0]

        # Reached the end of known parsing, return
        unless EXPRESSION_OPS.include?(op)
            return result
        end

        text.slice!(0)
        result<< parse_term(text)
    end

    return result
end

IDENT_REGEXP = /(\w+)/
NUM_REGEXP = /(\d+)/
def parse_term(text)
    result = []


    return result
end
