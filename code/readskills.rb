def read_skills text, int = 0, first = nil, second = nil
	skills = []
	if File.file?(text) == true 
		File.read(text).each_line do |line|
			if first.nil? or second.nil? then
				skills << line
			elsif (line[/#{first}(.*?)#{second}/m, 1]).nil? == false then
				skills << (line)[/#{first}(.*?)#{second}/m, 1];
			end
		end
		case int
		when 1 then skills.each_with_index { |n, i|	skills[i] = n.to_i } 
		when 2 then skills.each_with_index { |n, i|	skills[i] = n.to_f }
		end
	end
	return skills
end