def compile(infile, outfile)
	compile_code = RubyVM::InstructionSequence.compile_file infile
	File.binwrite(outfile ,Marshal.dump(compile_code.to_binary))
end

def execute(bytefile)
	byte_code = Marshal.load(File.binread(bytefile))
	instructions = RubyVM::InstructionSequence.load_from_binary byte_code
	instructions.eval
end


