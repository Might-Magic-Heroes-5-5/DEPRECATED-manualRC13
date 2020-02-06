def check_translations
	@language_list, select_lg, i = [], 0, 0
	@existing_translations = Array.new(0) { Array.new(2) }
	installed_translations = (filter_files "text", "credits.txt")
	para @pane_t1[1], left: 5, top: 5, size: 12
	installed_translations.each do |t|
		begin
			tr = Zip::File.open("text/#{t}")
			language = tr.read("properties/version.txt").split(',').push(t)
			@existing_translations.push(language)
			#@language_list << language
			select_lg = i if @@lg == t
			i+=1
		rescue
			debug( "#{t} is broken" )
		end
	end

	list_box :items => @existing_translations.map{|x| "#{x[0]}_#{x[1]}"}, choose: "#{@existing_translations[select_lg][0]}_#{@existing_translations[select_lg][1]}" , left: 40, top: 30, width: 90, height: 19 do |n|
		@existing_translations.each_with_index { |l| @@lg = l[3] if "#{l[0]}_#{l[1]}" == n.text  }
		if @@lg != @existing_translations[select_lg][3] then
			@texts = Zip::File.open("text/#{@@lg}")
			@@APP_DB.execute( "update settings set value='#{@@lg}' where name = 'language';" )
			@hovers.change(reading("properties/font_type.txt").split("\r\n"),
				reading("properties/font_size.txt").split("\r\n").map(&:to_i), 
				reading("properties/calc_text_size.txt").split("\r\n").map(&:to_i),
				reading("properties/calc_header_size.txt").split("\r\n").map(&:to_i)) 
			@app.remove
			main_menu
			town_pane
		end
	end

end

def show_store
	store_packs, i = [], 0
	response = get_url @@SERVER_URL
	response.code == "200" ? ( File.open(@translation_list, "w") { |f| f.write response.body } ) : ( messages 3 )
	@translation_slot.clear do
		if File.file?(@translation_list) then
			File.readlines(@translation_list).each do |pack|
				next if pack.start_with?("#")
				package = pack.split(',')
				if package[2] == @@TXT_VER then
					store_packs[i] = flow left: 5, top: 5 + i*40, width: 240, height: 38 do
						para "#{package[0]} v#{package[1]}", left: 2, top: 2, size: 12, align: "left"
						temp, temp2 = [], 0
						@existing_translations.each_with_index { |p, i| temp << i if p[0] == package[0] }
						temp.each { |t| temp2 = @existing_translations[t][1].to_i if @existing_translations[t][1].to_i > temp2 }
						temp2 >= package[1].to_i ? (name = "Installed"; status = "disabled") : (name = "Download"; status = nil)
						dl_button contents[0].parent, "#{name}", package[3], "#{package[0]}", "#{package[1]}", status
					end
					i+=1
				end
			end
		end
	end
end

def dl_button slot, text, url, name, ver, state = nil
	q = button(text, left: 130, top: 0, width: 100, height: 25, state: state) do		
		response = get_url url
		if response.code == "200" then
			test = File.open("text/#{name}#{ver}.pak", "wb") { |file| file.write(response.body) }
			slot.contents[1].remove
			slot.append { dl_button slot, "Done!", nil, nil, nil, "disabled" }
			@existing_tr_pane.clear.append { check_translations }
		else
			messages 3
		end
	end
end
	
def messages m, text=nil		        ####All alerts that pop in the application
	alert(case m
		when 0 then "Wait until download completes"
		when 1 then "Installation complete"
		when 2 then "Core modules and creature packs removed successfully!"
		when 3 then "No connection to server"
		when 99 then text 
	  end, title: nil)
end