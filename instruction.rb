class Instruction
    attr_reader :type, :data

    def initialize(type, data)
        @type = type
        @data = data
    end
end

class InstructionHandler
    attr :type

    def type()
        return @type
    end

    def run(data)
        raise NoMethodError
    end
end

class InstructionList
    attr :instr_list

    def initialize()
        @instr_list = []
    end

    def add(instruction)
        unless instruction.is_a? Instruction
            raise "Internal: Invalid argument '#{instruction}'"
        end

        instr_list<< instruction
    end
end
