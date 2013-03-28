REGISTER_SIZE = 4
INDENT_SIZE = 4

# Registers
R_RETURN_ADDRESS = '$ra'
R_STACK_POINTER  = '$sp'
R_FRAME_POINTER  = '$fp'
R_ZERO           = '$zero'

# Register suffixes, (s registers, t registers, etc)
LOCAL_REGISTER_COUNT = 8
TEMP_REGISTER_COUNT = 10
RS_LOCAL = '$s'
RS_TEMP  = '$t' 

##############
# Instructions
##############

# Add, add immediate
I_ADD  = 'add'
I_ADDI = 'addi'

I_SUB  = 'sub'

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

I_BEQ  = "beq"
I_BNE  = "bne"

I_BLEZ = 'blez'
I_BGTZ = 'bgtz'

# Load immediate
I_LI   = 'li'

# Set less than
I_SLT  = 'slt'

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

def generate_sub(dest, left, right)
    return instruction_string(I_SUB, "#{dest}, #{left}, #{right}")
end

def generate_sw(value, address, offset)
    #TODO: Assert value is a register, address is register, offset is 16bit
    
    return instruction_string(I_SW, "#{value}, #{offset}(#{address})")
end

def generate_lw(dest, address, offset)
    #TODO: Assert dest is register, address is register, offset 16bit

    return instruction_string(I_LW, "#{dest}, #{offset}(#{address})")
end

##################################
# Jump instructions

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

###################################
# Branch instructions

def generate_beq(left, right, dest)
    #TODO: Assert left and right registers, dest is 16 bit

    return instruction_string(I_BEQ, "#{left}, #{right}, #{dest}")
end

def generate_bne(left, right, dest)
    return instruction_string(I_BNE, "#{left}, #{right}, #{dest}")
end

# branch <= 0
def generate_blez(value, dest)
    return instruction_string(I_BLEZ, "#{value}, #{dest}")
end

# branch > 0
def generate_bgtz(value, dest)
    return instruction_string(I_BGTZ, "#{value}, #{dest}")
end

##################################
# Misc

def generate_li(dest, immediate)
    return instruction_string(I_LI, "#{dest}, #{immediate}")
end

# Set less than
def generate_slt(dest, left, right)
    return insruction_string(I_SLT, "#{dest}, #{left}, #{right}")
end
