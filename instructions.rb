REGISTER_SIZE = 4
INDENT_SIZE = 4

# Registers
R_RETURN_ADDRESS = '$ra'
R_STACK_POINTER  = '$sp'
R_FRAME_POINTER  = '$fp'

# Register suffixes, (s registers, t registers, etc)
RS_LOCAL = '$s'
RS_TEMP  = '$t' 

##############
# Instructions
##############

# Add, add immediate
I_ADD  = 'add'
I_ADDI = 'addi'

# Store word, half, byte
I_SW   = 'sw'
I_SH   = 'sh'
I_SB   = 'sb'

# Store word, half, byte
I_LW   = 'lw'
I_LH   = 'lh'
I_LB   = 'lb'

# Jump, jump register
I_J    = 'j'
I_JR   = 'jr'

# Returns a string with proper indentation
def instruction_string(inst, params)
    return "#{inst} #{params}"
end

def generate_label(name)
    #TODO: Check for already used label name?
    
    return "#{name}:"
end

def generate_addi(dest, source, value)
    #TODO: Assert value is 16-bit value

    return instruction_string(I_ADDI, "#{dest}, #{source}, #{value}")
end

def generate_sw(value, address, offset)
    #TODO: Assert value is a register, address is register, offset is 16bit
    
    return instruction_string(I_SW, "#{value}, #{offset}(#{address})")
end

def generate_lw(dest, address, offset)
    #TODO: Assert dest is register, address is register, offset 16bit

    return instruction_string(I_LW, "#{dest}, #{offset}(#{address})")
end

def generate_j(dest)
    return instruction_string(I_J, "#{dest}")
end

# Assumes that jr will be using R_RETURN_ADDRESS
def generate_jr()
    return instruction_string(I_JR, "#{R_RETURN_ADDRESS}")
end

def generate_jr(register)
    return instruction_string(I_JR, "#{register}")
end
