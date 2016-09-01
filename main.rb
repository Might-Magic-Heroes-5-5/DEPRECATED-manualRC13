class Tooltip < Shoes::Widget
	
		def initialize ()
			motion { |x, y| @move_left = x; @move_top = y }
			start { @menu = stack height: 0 do end.hide }
		end
		
		def resize ( length, length2=0, h_length=0 )
			wide, high = length*8, 1
			while (wide*high/length < 9*17 or wide/high > 6) do
				(wide/high).between?(0,7) ? nil : ( wide-=wide/2 )
				high+=18
				wide < 260 ? wide = 260 : nil
			end
			(h_length+3)*10>wide ? wide = ( (h_length+3)*10 ) : nil
			h_length > 0 ? high+=60 : nil
			high+=8*20*length2/wide
			return wide, high
		end
		
		def present ( options={} )
		text, text2, header, offset, wide, high = options[:text], options[:text2], options[:header], options[:offset], options[:wide], options[:high]
			flow margin_left: offset, width: wide, height: high do
				header == "" ? nil : ( para ("#{header}"), size: 17, stroke: white, font: "Bell MT", align: "center", justify: false )
				para ("#{text}"), size: 9, stroke: white, font: "Courier New", align: "center", justify: true
				text2 == "" ? nil : ( para ("#{text2}"), size: 9, stroke: rgb(50,50,50), font: "Courier New", align: "center", justify: true )
			end
		end
		
		def open ( options={} )
			offset, high, wide, text, text2, header, back1, back2 = 10, options[:height], options[:width], options[:text] || "ERROR: Missing mandatory options \"width:\", \"height:\" or \"text:\"\nAvailable options:\ntext: the text presented in the tooltip window\nwidth: the width of the tooltip\nheight: the height of the tooltip\nfont: the font of the text\nstroke: the stroke of the text\nsize: the size of the text\nborder: the colour of the border of the tooltip\nbackground: the colour of the tooltip box\nExample:   slot.hover { @sign.open text: \"tooltip comming through\", width: 200, height: 100, border: rgb(0,20,5,0.5), background: rgb(0,244,99,0.5) , font: \"Vivaldi\" , size: 10, stroke: white }", options[:text2] || "", options[:header] || "", options[:border] || rgb(120,42,5,0.5), options[:background] || rgb(180,150,110,0.7) 
			( wide.nil? || high.nil? ) ? (wide, high = resize text.length, text2.length, header.length ) : nil
			@menu.style width: offset + wide, height: offset + high
			menu_left, menu_top = @move_left, @move_top;
			@move_left + @menu.width >= app.width + offset ? menu_left = @move_left - @menu.width : nil
			@move_top + @menu.height >= app.height + offset ? menu_top = @move_top - 2*@menu.height/3 : nil
			@menu.move(menu_left, menu_top)
			@menu.clear do
				background back1, curve: 15
				background back2, curve: 15, width: @menu.width-4, height: @menu.height - 4, left: 2, top: 2
				present text: text, text2: text2, header: header, offset: offset/2, wide: wide, high: high
			end
			start { @menu.show }
		end
		
		def close
			@menu.hide
		end
	end

Shoes.app(title: "Open Skillwheel v:0.70, database: HoMM 5.5 RC8b", width: 1000, height: 730, resizable: false ) do
background 'pics/themes/background.png'
	
	font "vivaldi.ttf" unless Shoes::FONTS.include? "Vivaldi"
	font "belmt.ttf" unless Shoes::FONTS.include? "Bell MT"
	style Shoes::Subtitle, font: "Vivaldi" 
	style Shoes::Tagline, font: "Bell MT", size: 16, align: "center"

	@table_stats = []
	@box = Array.new(12) { Array.new(12) }
	@offense, @defense, @stat_mana_multiplier = 1, 1, 1

	def set	(img, options={} )
		img.hover { @hovers.open  text: options[:text], header: options[:header] , text2: options[:text2], width: options[:width], height: options[:height] }		
		img.leave { @hovers.close }
	end
	
	def set_primary_image img, text, i
		set img, text: text
		img.click do
			@hovers.close
			button, left, top = self.mouse
			@ch_primary[i]+=1
			set_primary
		end
	end
	
	def read_skills text, int = 0
		skills = []
		File.read(text).each_line { |line| skills << line.chop }
		int == 1 ? skills.each_with_index { |n, i|	skills[i] = n.to_i } : nil
		return skills
	end
	
	def check_plus_dependency  x, y
		@ch_skills[x] == "11111111121" ? ( @ch_skills[x] = "00000000020";  ) : nil
		case y
			when 0 then @ch_skills[x][0..2] = "100";
			when 1 then @ch_skills[x][0..2] = "110";
			when 2 then @ch_skills[x][0..2] = "111"; 
			when 6,7,8 then @ch_skills[x][y] = "1"; 
							@ch_skills[x][y-3] = "1"
			when 10 then @ch_skills[x][y] = "1"; 
						 @ch_skills[x][y-3] = "1"; 
						 @ch_skills[x][y-6] = "1"
			else @ch_skills[x][y] = "1"
		end
		p = count_perks x
		if p>2 then
			for i in 3..10
				@ch_skills[x][i] == "0" ? @ch_skills[x][i] = "2" : nil
			end
		end
		@ch_skills[x] = visible_perks @ch_skills[x]
		for i in 1..p
			@ch_skills[x][i-1] = "1"
		end
	end
	
	def check_minus_dependency x, y
		p = count_perks x
		case y
			when 0 then @ch_skills[x] = "00000000020";
			when 1 then p>1 ? ( return 0 ) : ( @ch_skills[x][0..2] = "100" )
			when 2 then p>2 ? ( return 0 ) : ( @ch_skills[x][0..2] = "110" )
			when 4 then @ch_skills[x][y+6] = "0";
						@ch_skills[x][y+3] = "0";
						@ch_skills[x][y] = "0";
			when 3,7,5 then @ch_skills[x][y] = "0";
							@ch_skills[x][y+3] = "0"
			else @ch_skills[x][y] = "0"
		end
		for i in 3..10
			@ch_skills[x][i] == "2" ? @ch_skills[x][i] = "0" : nil
		end
		@ch_skills[x][9] = "2"
		@ch_skills[x] = visible_perks @ch_skills[x]
	end
	
	def count_perks x, p = 0
		for i in 3..10
			@ch_skills[x][i] == "1" ? p+=1 : nil
		end	
		return p
	end
	
	def visible_perks skillcheck
		case skillcheck[3..10]
			when "10000020","00100020" then skillcheck[10] = "2"
			when "00100120","00100122" then skillcheck[3..10] = "00122122"
			when "01001020","01001022" then skillcheck[3..10] = "01021220"
			when "10010020","10010022" then skillcheck[3..10] = "10012222"
			when "10100020","10100022" then skillcheck[3..10] = "10102022"
			when "11000020","11000022" then skillcheck[3..10] = "11000222"
			when "01100020","01100022" then skillcheck[3..10] = "01120022"
		end
		return skillcheck
	end
	
	def set_factions img, factions
		set img, text: factions, width: 100, height: 25
		img.click do
			classes = read_skills "text/factions/#{factions}.txt"
			space = ( @class_board.width - 40*classes.length )/( classes.length + 1 )
			@class_board.clear do
				for i in 0..classes.length-1 do
					@class_board.append { set_classes (image "pics/classes/active/#{classes[i]}.png", left: space + i*( 40 + space ) ,width: 40), classes[i] }
				end
			end
		end
	end
	
	def set_classes img, classes
		set img, text: classes, width: 130, height: 25
		img.click do
			@ch_class = classes
			hero = 0
			set_hero hero
			set_skillwheel
		end
	end
	
	def set_hero hero
		@wheel_turn = 0
		ch_heroes = read_skills "text/classes/#{@ch_class}/heroes.txt"
		@ch_skills = read_skills "text/heroes/#{ch_heroes[hero]}/skills.txt"
		@ch_primary = read_skills "text/classes/#{@ch_class}/primary.txt", 1 
		File.file?("text/heroes/#{ch_heroes[hero]}/Additional.txt") == true ? desc = File.read("text/heroes/#{ch_heroes[hero]}/Additional.txt") : desc = nil
		@box_hero.clear { image "pics/heroes/#{ch_heroes[hero]}.png", width: 60 }
		set @box_hero, text: ( File.read("text/heroes/#{ch_heroes[hero]}/spec.txt") ), header: ( File.read("text/heroes/#{ch_heroes[hero]}/name.txt") ), text2: desc
		@left_button.click { hero = set_button hero, ch_heroes.length, "down" }.show
		@right_button.click { hero = set_button hero, ch_heroes.length }.show
		set_level 1
	end

	def set_level ch_level
		@box_level.clear { subtitle "#{ch_level}", size: 20, font: "Vivaldi"  }	
		set_primary
		@box_level.click do          		 ############# Hero leveling up and gaining of primary stats based on chance
			@hovers.close
			if  ch_level<50 then
				ch_level+=1
				i = rand(1..100)
				case i
					when 1..@ch_primary[4] then @ch_primary[0]+=1
					when (@ch_primary[4] + 1)..(@ch_primary[4] + @ch_primary[5]) then @ch_primary[1]+=1
					when (@ch_primary[4] + @ch_primary[5] + 1)..(@ch_primary[4] + @ch_primary[5] + @ch_primary[6]) then @ch_primary[2]+=1
					when (@ch_primary[4] + @ch_primary[5] + @ch_primary[6] + 1)..100 then @ch_primary[3]+=1
				end
			end
			@box_level.clear  { subtitle "#{ch_level}", size: 20, font: "Vivaldi"  }
			set_primary
		end
	end
	
	def set_primary
		@ch_primary.each_with_index do |p,i|
			case i
				when 0..3 then  @table_stats[i].replace p
					else @table_stats[i].replace "#{p}%"
			end
		end
		@stat_damage.replace "#{((3.33*@ch_primary[0])*@offense).round(2)}%"
		@stat_defense.replace "#{((3.33*@ch_primary[1])*@defense).round(2)}%"
		@stat_mana.replace "#{@stat_mana_multiplier*@ch_primary[3]}"
	end

	def set_skillwheel
		ch_secondary = read_skills "text/classes/#{@ch_class}/secondary.txt"
		if ch_secondary.length>12 then	####setting left/right arrows if there are more than 12 skills
			case @wheel_turn
				when 0 then @wheel_left.hide; @wheel_right.show
				when 1..ch_secondary.length-13 then @wheel_left.show; @wheel_right.show
				else @wheel_left.show; @wheel_right.hide
			end
		else
			@wheel_left.hide
			@wheel_right.hide
		end
		ch_secondary.each_with_index do |skill, x|   #####rotates each of the 12 skillwheel sections
			x - @wheel_turn>11 ? break : nil	 
			set_box @box[x-@wheel_turn], x, skill, "no"
			
		end
	end
	
	def set_box box, x, skill, points="yes"  						#####populate the current skillwheel part with perks and skills
		perks = read_skills "text/skilltree/#{skill}.txt"
		@ch_skills[x].each_char.with_index do |perk_value, y|
			box[y].clear do
				unless perks[y] == "" || perk_value == "2"
					case perk_value
						when "0" then 
							background rgb(120,120,120,0.7), hidden: true;
							image "pics/skills/grey/#{perks[y]}.png", width: 35, height: 35
							case perks[y]
								when "Basic Offense" then @offense = 1; set_primary
								when "Basic Defense" then @defense = 1; set_primary
								when "Basic Enlightenment" then @enlightenment = 5; set_primary
								when "Intelligence" then @stat_mana_multiplier = 10; set_primary
							end
						when "1" then 
							background rgb(120,120,120,0.7), hidden: true;
							image do
								image "pics/skills/active/#{perks[y]}.png", width: 35 , height: 35
								shadow radius: 1, fill: rgb(0, 0, 0, 0.5)
							end
							case perks[y]
								when "Expert Offense" then @offense = 1.2; set_primary
								when "Advanced Offense" then @offense = 1.15; set_primary
								when "Basic Offense" then @offense = 1.1; set_primary
								when "Basic Defense" then @defense = 1.1; set_primary
								when "Advanced Defense" then @defense = 1.175; set_primary
								when "Expert Defense" then @defense = 1.25; set_primary
								when "Intelligence" then @stat_mana_multiplier = 14; set_primary
								when "Basic Enlightenment" then @enlightenment = 5; set_primary
								when "Basic Enlightenment" then @enlightenment = 4; set_primary
								when "Basic Enlightenment" then @enlightenment = 3; set_primary
								when "Preparation" then @preparation=2; set_primary
							end
					end
					File.file?("text/skills/#{perks[y]}/Additional.txt") == true ? text2 = File.read("text/skills/#{perks[y]}/Additional.txt") : text2 = nil
					contents[1].hover do
						box[y].contents[0].show;
						@hovers.open text: ( File.read("text/skills/#{perks[y]}/Description.txt") ), header: ( File.read("text/skills/#{perks[y]}/name.txt") ), text2: text2
					end	
					contents[1].leave do
						box[y].contents[0].hide;
						@hovers.close
					end
					contents[1].click do
						(perk_value == "0" or @ch_skills[x] == "11111111121") ? ( check_plus_dependency x, y ) : ( check_minus_dependency x, y )
						@hovers.close
						set_box box, x, skill
					end
				end
			end
		end
	end

	def set_button hero, count, direction = "up"
		direction == "up" ? hero+=1 : hero-=1 ##direction points if one is going up or down the list
		( hero > -1 && hero < count ) ? ( set_hero hero; set_skillwheel; return hero; ) : ( hero < 0 ? ( return 0 )  : ( return count-1 ) )
	end

	FACTIONS = read_skills "text/factions/factions.txt"
	@hovers = tooltip()
##################################################################################################################### MAIN STARTS HERE
	stack width: 280 do		#################################################### LEFT  - LISTBOX OF HEROES, PRIMARY STATS
		image "pics/themes/factions_pane.png", left: 5, top: 30, width: 295, height: 170
		image "pics/themes/manuscript.png", left: 20, top: 200, width: 263
		image "pics/themes/menu.png", left: 70, top: 580, width: 170
		
		for i in 0..7 do
			top = i/4*51;	left = i*51 - 4*top
			flow( left: 51 + left, top: 66 + top, width: 50, height: 50 ) { set_factions (image "pics/factions/#{FACTIONS[i]}.png", width: 50), FACTIONS[i] }
		end
		subtitle "Faction Classes", left: 43, top: 205, font: "Vivaldi"
		@class_board = flow left: 39, top: 252, width: 220, height: 45 ############# CLASSES WINDOW
		flow width: 220, left: 58, top: 315 do	 ############# PRIMARY STATS TABLE
			table_image = [ "attack", "defense", "spellpower", "knowledge" ]
			for i in 0..11 do
				flow height: 45, width: 45 do
					border("rgb(105, 105, 105)", strokewidth: 1)
					case i
						when 0..3 then	set_primary_image ( image "pics/pskills/#{table_image[i]}.png", left: 1, top: 1 ), ( File.read("text/pskills/#{table_image[i]}.txt") ), i
						else @table_stats[i-4] = para "", align: "center", margin_top: 0.32
					end
				end
			end
		end
		
		flow do
			@stat_damage = para "", left: 65, top: 455, size: 11
			@stat_defense = para "", left: 142, top: 455, size: 11
			@stat_mana = para "", left: 218, top: 455, size: 11
			subtitle "Hero level", left: 110, top: 495, size: 16
			set ( @box_level = ( flow left: 209, top: 47, width: 40, height: 35) ), text: "Left click to level up!", width: 200, height: 30
			set ( image "pics/stats/damage.png", left: 50, top: 10, width: 15 ), text: "3.33%*Attack*(1+offense_skill) damage boost"
			set ( image "pics/stats/defense.png", left: 127, top: 10, width: 15 ), text: "3.33%*Defense*(1+defense_skill) health boost"
			set ( image "pics/stats/mana.png", left: 203, top: 10, width: 15 ), text: "Hero Mana pool"
		end
	end

	stack width: 715, height: 715 do	#################################################### IGHT - SKILLWHEEL TABLE
		image "pics/themes/wheel.png", width: 710, top: 5
		c_width, c_height, step, start_rad = 674, 688, Math::PI/6, 0  ########### using math formula to define the circpostion of the boxes
		for q in 0..11
			angle = -1.46 + (Math::PI/21)*(q%3)
			if q>1 then
				((q+1)%3) == 1 ? start_rad+=50 : nil
			end
			radius = 330-start_rad
			for w in 0..11
				x, y = (c_width/2 + radius * Math.cos(angle)).round(0), (c_height/2 + radius * Math.sin(angle)).round(0)
				angle += step
				@box[w][q] = flow left: x, top: y, width: 36, height: 36
			end
		end

		@wheel_left = image "pics/buttons/wheel_arrow.png", left: 315, top: 240 do end.hide.rotate 180
		@wheel_right = image "pics/buttons/wheel_arrow.png", left: 365, top: 240 do end.hide
		@box_hero = flow left: 322, top: 327, width: 60, height: 60
		@left_button = image "pics/buttons/normal.png", left: 295, top: 327 do end.hide.rotate 180
		@right_button = image "pics/buttons/normal.png", left: 385, top: 327 do end.hide
		@wheel_left.click { @wheel_left.style[:hidden] == true ? nil : @wheel_turn-=1; set_skillwheel }
		@wheel_right.click { @wheel_right.style[:hidden] == true ? nil : @wheel_turn+=1; set_skillwheel }
	end
	
	stack top: 665, left: 940, width: 50, height: 50 do
		back = background rgb(255,248,220,0.5), hidden: true
		image "pics/themes/about.png"
		contents[1].hover { back.toggle }
		contents[1].leave { back.toggle }
		contents[1].click do
			window(title: "Äbout", width: 450, height: 150, resizable: false ) do
				para "Open Skillwheel version 0.70 by dredknight (Jordan Kostov)\n\nDesign advisor: Marina Kostova\nTechnical advisor: Simeon Manolov", justify: true
				button("www.heroescommunity.com", left: 110, top: 100) { system("start http://heroescommunity.com/viewthread.php3?TID=42212") }
			end
		end
	end
end
