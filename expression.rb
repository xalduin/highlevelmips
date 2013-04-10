OP_EQUAL = '=='
OP_NOT_EQUAL = '!='
OP_LESS = '<'
OP_LESS_EQUAL = '<='
OP_GREATER = '>'
OP_GREATER_EQUAL = '>='

OP_ADD = '+'
OP_SUB = '-'
OP_MUL = '*'
OP_DIV = '/'

OP_TABLE = {
    OP_EQUAL          => :equal,
    OP_NOT_EQUAL      => :not_equal,
    OP_LESS           => :less,
    OP_LESS_EQUAL     => :less_equal,
    OP_GREATER        => :greater,
    OP_GREATER_EQUAL  => :greater_equal,
    OP_ADD            => :add,
    OP_SUB            => :sub,
    OP_MUL            => :mul,
    OP_DIV            => :div
}

OP_OPPOSITE_TABLE = {
    :equal            => :not_equal,
    :not_equal        => :equal,
    :less             => :greater_equal,
    :less_equal       => :greater,
    :greater          => :less_equal,
    :greater_equal    => :less
}

OP_COMMUTATIVE_TABLE = {
    :add => true,
    :sub => false,
    :mul => true,
    :div => false,

    :equal         => true,
    :not_equal     => true,
    :less          => false,
    :less_equal    => false,
    :greater       => false,
    :greater_equal => false
}
