class Instruction
    attr_reader :type, :data

    def initialize(type, data)
        @type = type
        @data = data
    end
end
