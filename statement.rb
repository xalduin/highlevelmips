#Matching for variable declaration
# 1. identifier
# 2. type
# 3. [] if the type is an array (optional)

S_VAR_DECL   = /^var \s+ ([a-zA-Z]\w*) \s* : \s* ([a-z]+) (\[ \])? $/x

# Matching for const declaration
# 1. identifier
# 2. type
# 3. expression value

S_CONST_DECL = /^const \s+ ([a-zA-Z]\w*)+ \s* : \s* (\w+) \s* = \s* (.+)/x 

# Matching for set variable to value
# 1. identifier
# 2. expression value of right hand side
S_SET_VAR   = /([a-zA-Z]\w*) \s* = \s* (.+)/x

# Matching for set variable array to value
# 1. identifier
# 2. array index
# 3. expression value of right hand side
S_SET_ARRAY = /([a-zA-Z]\w*) \s* \[ \s* (\d+) \s* \] \s* = \s* (.+)/x

# Matching for return statement
# 1. Return value expression
S_RETURN = /^return \s+ (.*)$/x

# Matching for function call
# 1. Variable to store result
# 2. identifier
# 3. all arguments as a single string (spaces included)
S_FUNC_CALL = /^(?:([a-zA-Z]\w*) \s* = \s*)?
    ([a-zA-Z]\w*)
    \s*
    \( \s* 
          ((\w+)? \s*(\,\s*(\w+))*)
    \s* 
    \)
    $/x

# Matching for function declaration
# 1. function identifier
# 2. List of all arguments (including :, type name, and spaces) (optional)
# 3-8. Can be ignored
# 9. Return type (optional)

B_FUNC_DECL = /func\s+
    ([a-zA-Z]\w*)
    \s* \( \s*
    (
        ([a-zA-Z]\w*)\s*:\s*([a-zA-Z]+)
        (\s*\,\s*([a-zA-Z]\w*)\s*:\s*([a-zA-Z]+))*
    )?
    \s* \)
    (\s*->\s*
     ([a-zA-Z]+)
    )?/x

B_ENDFUNC = /^endfunc$/

# Matching for if statement
# 1. Expression to be evaluated for if
B_IF_DECL = /^if \s+ (\S.+) \s* $/x

B_ELSE_DECL = /^else$/
B_ENDIF = /^endif$/

B_LOOP_DECL = /^\s*loop\s*$/
B_ENDLOOP = /^\s*endloop\s*$/

# Matchinf for exitwhen statement
# 1. Expression to be evaluated
B_EXITWHEN= /exitwhen \s+ (\S.+)/x

VAR_REGEXP   = /^([a-zA-Z]\w*)$/
