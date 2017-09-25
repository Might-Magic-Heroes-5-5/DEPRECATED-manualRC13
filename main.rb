require 'code/tooltip'
require 'code/readskills'
require 'sqlite3'

def set	(img, options={} )
	img.hover { @hovers.show text: options[:text], header: options[:header] , size: 9,  text2: options[:text2], width: options[:width], height: options[:height]; img.scale 1.25, 1.25 }
	img.leave { @hovers.hide; img.scale 0.8, 0.8 }
end

def trim num
  i, f = num.to_i, num.to_f
  i == f ? i : f
end

def set_button hero, count, direction = "up"
	direction == "up" ? hero+=1 : hero-=1 ##direction points if one is going up or down the list
	( hero > -1 && hero < count ) ? ( set_hero hero; set_skillwheel; ) : nil 
end

Shoes.app(title: "Might & Magic: Heroes 5.5 Reference Manual, database: RC9c", width: 1200, height: 800, resizable: false ) do

	font "fonts/vivaldi.ttf" unless Shoes::FONTS.include? "Vivaldi"
	font "fonts/belmt.ttf" unless Shoes::FONTS.include? "Bell MT"
	style Shoes::Subtitle, font: "Vivaldi"
	style Shoes::Tagline, font: "Bell MT", size: 16, align: "center"
	@hovers = tooltip()
	@table_stats = []
	@offense, @defense, @mana_multiplier = 1, 1, 1
	DB = SQLite3::Database.new "skillwheel.db"
	
	def set_main page, object, dir_img, dir_txt
		@main_slot.each_with_index do |slot, i|
			slot.clear do
				object[i].nil? ? nil : ( set_slot page, object[i][0], ( image "pics/#{dir_img}/#{object[i][0]}.png", width: @icon_size ), text: File.read("text/#{@LG}/#{dir_txt}/#{object[i][0]}/name.txt") )
			end
		end
	end
	
	def set_slot page, item, img, options={}
		set img, text: options[:text], header: options[:header] || nil, text2: options[:text2] || nil #, width: 100, height: 25
		img.click do
			@hovers.hide
			case page
			when "TOWN" then town_pane_2 item
			when "HERO" then set_classes item
			when "HERO_PRIMARY" then @ch_primary[item]+=1; set_primary
			when "CREATURE" then creature_pane_2_book item
			when "SPELL" then spell_pane_pages item
			when "CLASSES" then @ch_class = item; set_hero 0; set_skillwheel
			when "LINK" then system("start #{item}")
			when "ARTIFACT" then artifact_slot item
			end
		end
	end
		
	def set_classes item
		classes = DB.execute( "select name from classes where faction = '#{item}';" )
		space = ( @class_board.width - @icon_size2*classes.length )/( classes.length + 1 )
		@class_board.clear do
			for i in 0..classes.length-1 do
				@class_board.append do
					flow(top: 5, left: space + i*( @icon_size2 + space ), width: @icon_size2) { set_slot "CLASSES", classes[i][0], ( image "pics/classes/active/#{classes[i][0]}.png", width: @icon_size2), text: classes[i][0] }
				end
			end
		end
	end

	def set_hero hero
		@wheel_turn = 0
		ch_heroes = DB.execute( "select name, secondary from heroes where classes = '#{@ch_class}';" )#[0][0].split(',')
		@ch_primary = DB.execute( "select atk, def, spp, knw, atk_c, def_c, spp_c, knw_c from classes where name = '#{@ch_class}';" )[0]
		@ch_skills = ch_heroes[hero][1].split(",")
		@save.clear do
			button "Save", left: 0, top: 0, width: 81, height: 25 do
				options = ['hero', 'ch_class', 'ch_primary', 'ch_skills' ]
				data = Hash[options.map {|x| [x, ""]}]
				[ hero, @ch_class, @ch_primary, @ch_skills ].each_with_index { |n, i| data[options[i]] = n; }
				File.open(ask_save_file, "w") { |f| f.write(data.to_yaml) }
			end
		end
		@box_hero.clear { image "pics/heroes/#{ch_heroes[hero][0]}.png", width: 80 }
		set @box_hero, text: ( (read_skills "text/#{@LG}/heroes/#{ch_heroes[hero][0]}/spec.txt").join("\n") ), header: ( (read_skills "text/#{@LG}/heroes/#{ch_heroes[hero][0]}/name.txt")[0] ), text2: ((read_skills "text/#{@LG}/heroes/#{ch_heroes[hero][0]}/additional.txt")[0])
		@left_button.click { set_button hero, ch_heroes.length, "down" }.show
		@right_button.click { set_button hero, ch_heroes.length }.show
		set_level
	end

	def set_level ch_level=1
		@box_level.clear { subtitle "#{ch_level}", size: 20, font: "Vivaldi" }	
		set_primary
		@box_level.click do |press| ############# Hero leveling up and gaining of primary stats based on chance
			@hovers.hide
			if press == 1 && ch_level<100 then
				ch_level+=1
				i = rand(1..100)
				case i
				when 1..@ch_primary[4] then @ch_primary[0]+=1
				when (@ch_primary[4] + 1)..(@ch_primary[4] + @ch_primary[5]) then @ch_primary[1]+=1
				when (@ch_primary[4] + @ch_primary[5] + 1)..(@ch_primary[4] + @ch_primary[5] + @ch_primary[6]) then @ch_primary[2]+=1
				when (@ch_primary[4] + @ch_primary[5] + @ch_primary[6] + 1)..100 then @ch_primary[3]+=1
				end
			else
				ch_level = 1;
				@ch_primary = DB.execute( "select atk, def, spp, knw, atk_c, def_c, spp_c, knw_c from classes where name = '#{@ch_class}';" )[0]
			end
			set_level ch_level
		end
	end

	def set_primary
		@hero_st.clear { @ch_primary[0..3].each_with_index { |p, i | para p, margin_top: 0.32, left: 11 + i*47, size: 13 } }
		@hero_ch.clear { @ch_primary[4..7].each_with_index { |p, i | para "#{p}%", margin_top: 0.32, left: 3 + i*47, size: 13 } }
		@stat_damage.replace "#{((3.33*@ch_primary[0])*@offense).round(2)}%"
		@stat_defense.replace "#{((3.33*@ch_primary[1])*@defense).round(2)}%"
		@stat_mana.replace "#{@mana_multiplier*@ch_primary[3]}"
	end

	def set_skillwheel
		ch_secondary = DB.execute( "select skills from classes where name = '#{@ch_class}';" )[0][0].split(',')
		if ch_secondary.length>12 then	####setting left/right arrows if there are more than 12 skills
			case @wheel_turn
			when 0 then @wheel_left.hide; @wheel_right.show
			when 1..ch_secondary.length-13 then @wheel_left.show; @wheel_right.show
			else @wheel_left.show; @wheel_right.hide
			end
		else
			@wheel_left.hide; @wheel_right.hide
		end
		ch_secondary.each_with_index do |skill, x| #####rotates each of the 12 skill sections
			x - @wheel_turn>11 ? break : nil	 
			set_box @box[x-@wheel_turn], x, skill
		end
	end

	def set_box box, x, skill #####populate the current box with perk or skill
		perks = DB.execute( "select name from skills where tree = '#{skill}';" )
		box.map!(&:clear)
		@ch_skills[x].each_char.with_index do |perk_value, y|	
			box[y].append do
				unless perks[y][0] == "" || perk_value == "2"
					new_size = y/3 == 3? @icon_size2 - 10 : @icon_size2 - 5*(y/3)
					case perk_value
					when "0" then 
						image "pics/skills/grey/#{perks[y][0]}.png", width: new_size, height: new_size, left: 3, top: 3
						case perks[y][0]
						when "basic offense" then @offense = 1; set_primary
						when "basic defense" then @defense = 1; set_primary
						when "intelligence" then @mana_multiplier = 10; set_primary
						end
					when "1" then 
						image do
							image "pics/skills/active/#{perks[y][0]}.png", width: new_size, height: new_size, left: 3, top: 3
							shadow radius: 1, fill: rgb(0, 0, 0, 0.5)
						end
						case perks[y][0]
						when "expert offense" then @offense = 1.2; set_primary
						when "advanced offense" then @offense = 1.15; set_primary
						when "basic offense" then @offense = 1.1; set_primary
						when "basic defense" then @defense = 1.1; set_primary
						when "advanced defense" then @defense = 1.15; set_primary
						when "expert defense" then @defense = 1.2; set_primary
						when "intelligence" then @mana_multiplier = 14; set_primary
						end
					end
					set contents[0], text: ( (read_skills "text/#{@LG}/skills/#{perks[y][0]}/description.txt")[0] ), header: ( (read_skills "text/#{@LG}/skills/#{perks[y][0]}/name.txt")[0] ), text2: (read_skills "text/#{@LG}/skills/#{perks[y][0]}/additional.txt").join("\n")
					contents[0].click do
						@hovers.hide
						( perk_value == "0" or @ch_skills[x] == "11111111121" ) ? ( check_plus_dependency x, y ) : ( check_minus_dependency x, y )
						set_box box, x, skill
					end
				end
			end	
		end
	end

	def check_plus_dependency x, y
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

	def count_perks x, p = 0
		for i in 3..10
			@ch_skills[x][i] == "1" ? p+=1 : nil
		end	
		return p
	end

	def hero_pane first=@primary_text, second=@secondary_pane
		@ch_primary = [0, 0, 0, 0 ]
		@box = Array.new(12) { Array.new(12) }
		set_main "HERO", FACTIONS, "factions", "factions"
		pane_text = read_skills "text/#{@LG}/panes/hero_pane/name.txt"
		first.clear do
			subtitle pane_text[0], left: 75, top: 285
			@class_board = flow left: 39, top: 332, width: 280, height: @icon_size + 10 ############# CLASSES LAYOUT
			flow width: 200, left: 90, top: 400 do	 ############# PRIMARY STATS TABLE
				table_image = [ "attack", "defense", "spellpower", "knowledge" ]
				for i in 0..11 do
					flow height: 47, width: 47 do
						border("rgb(105, 105, 105)", strokewidth: 1)
						case i
						when 0..3 then
						set_slot "HERO_PRIMARY", i, ( image "pics/misc/#{table_image[i]}.png", left: 1, top: 1, width: 45),  text: pane_text[1]
						end
					end
				end
				@hero_st = flow left: 0, top: 48, width: 180, height: 45;
				@hero_ch = flow left: 0, top: 93, width: 180, height: 45;
			end
			flow do
				@stat_damage = para "", left: 100, top: 550, size: 12
				@stat_defense = para "", left: 187, top: 550, size: 12
				@stat_mana = para "", left: 273, top: 550, size: 12
				subtitle pane_text[2], left: 120, top: 647, size: 20
				set ( @box_level = ( flow left: 263, top: 108, width: 40, height: 35) ), text: pane_text[3], width: 200, height: 30
				set ( image "pics/misc/s_damage.png", left: 80, top: 11, width: @icon_size/3 ), text: pane_text[4]
				set ( image "pics/misc/s_defense.png", left: 167, top: 11, width: @icon_size/3 ), text: pane_text[5]
				set ( image "pics/misc/s_mana.png", left: 253, top: 11, width: @icon_size/3 ), text: pane_text[6]
				button "Load hero preset", left: 102, top: 60, height: 25
			end
		end

		second.clear do
			image 'pics/themes/wheel.png', width: 785, top: 1, left: 6
			/fill rgb(135, 206, 250, 0.3)
			oval left: 400, top: 400, width: 780, height: 780, center: true;
			#fill rgb(220, 255, 70, 0.5)..rgb(50, 50, 50, 0.5)
			fill rgb(170, 205, 50, 0.3)
			oval left: 400, top: 400, width: 662, height: 662, center: true;
			fill rgb(218, 165, 32, 0.3)
			oval left: 396, top: 396, width: 546, height: 546, center: true;
			fill rgb(248, 84, 34, 0.3)
			oval left: 394, top: 397, width: 435, height: 435, center: true;
			nofill
			oval left: 394, top: 397, width: 280, height: 280, center: true	
			  ########### using math formula to define the circular postion of the skill nestss
			#oval left: 400, top: 400, width: 70, height: 70, center: true;	
				line 398, 18, 398, 174
				line 584, 68, 507, 203
				line 726, 205, 588, 284
				line 780, 400, 617, 400
				line 727, 593, 590, 507
				line 590, 733, 505, 590
				line 398, 780, 398, 619
				line 202, 728, 281, 589
				line 70, 590, 200, 506
				line 20, 400, 172, 400
				line 70, 205, 204, 282
				line 208, 68, 285, 203/
			c_width, c_height, step, start_rad = 749, 750, Math::PI/6, 0
			for q in 0..11
				angle = -1.46 + (Math::PI/21)*(q%3)
				q>1 ? ( ( ( q+1 )%3 ) == 1 ? start_rad += 60 : nil ) : nil
				radius = 362 - start_rad
				for w in 0..11
					x, y = (c_width/2 + radius * Math.cos(angle)).round(0), (c_height/2 + radius * Math.sin(angle)).round(0)
					angle += step
					@box[w][q] = flow left: x, top: y, width: @icon_size2 + 6, height: @icon_size2 + 6
				end
			end	
			@wheel_left = image "pics/buttons/wheel_arrow.png", left: 350, top: 280 do end.hide.rotate 180
			@wheel_right = image "pics/buttons/wheel_arrow.png", left: 420, top: 280 do end.hide
			@box_hero = flow left: 355, top: 355, width: 80, height: 80
			@save = flow left: 355, top: 440, width: 82, height: 30;
			@left_button = image "pics/buttons/normal.png", left: 325, top: 357, width: 25, height: 80 do end.hide.rotate 180
			@right_button = image "pics/buttons/normal.png", left: 440, top: 357, width: 25, height: 80 do end.hide
			@wheel_left.click { @wheel_left.style[:hidden] == true ? nil : @wheel_turn-=1; set_skillwheel }
			@wheel_right.click { @wheel_right.style[:hidden] == true ? nil : @wheel_turn+=1; set_skillwheel }
		end
	end

	def creature_pane first=@primary_text, second=@secondary_pane
		set_main "CREATURE", FACTIONS, "factions", "factions"
		pane_text = read_skills "text/#{@LG}/panes/creature_pane/name.txt"

		first.clear do
			subtitle pane_text[0], top: 285, font: "Vivaldi", align: "center"
			@creature_name = para "", left: 5, top: 335, size: 20, align: "center", font: "Vivaldi"
			flow left: 70, top: 330, width: 250, height: 300 do
				left = 10
				image 'pics/themes/creature_spells.png', left: 74, top: 55, width: 240, height: 280
				@creature_stats = flow left: left + 20, top: 40, width: 240, height: 340;
				set ( image "pics/misc/s_attack.png", left: left, top: 45, width: 18 ), text: pane_text[1]
				set ( image "pics/misc/s_defense.png", left: left, top: 68, width: 18 ), text: pane_text[2]
				set ( image "pics/misc/s_damage.png", left: left, top: 91, width: 18 ), text: pane_text[3]
				set ( image "pics/misc/s_initiative.png", left: left, top: 114, width: 18 ), text: pane_text[4]
				set ( image "pics/misc/s_speed.png", left: left, top: 137, width: 18 ), text: pane_text[5]
				set ( image "pics/misc/s_hitpoints.png", left: left, top: 160, width: 18 ), text: pane_text[6]
				set ( image "pics/misc/s_mana.png", left: left, top: 183, width: 18 ), text: pane_text[7]
				set ( image "pics/misc/s_shots.png", left: left, top: 206, width: 18 ), text: pane_text[8]
				set ( image "pics/skills/active/recruitment.png", left: left, top: 229, width: 21 ), text: pane_text[9]
			end
			subtitle pane_text[10], left: 134, top: 645, size: 22
		end

		second.clear do
			flow left: 30, top: 70, width: 438, height: 660 do
				image 'pics/themes/pane2.png', width: 1.0, height: 1.0
				subtitle pane_text[11], top: 5, stroke: white, align: "center", size: 30
				@pane2 = flow left: 0, top: 35, width: 1.0, height: 0.9, scroll: true, scroll_top: 100
			end
			flow left: 500, top: 45, width: 350, height: 690 do
				image 'pics/themes/creature_back.png', width: 433
				flow( left: 40, top: 40, width: 310, height: 40 ) { @faction_name = para "", font: "Vivaldi", size: 22, align: "center" }
				x, y = 63, 1;
				for q in 0..20
					y+=80
					(q + 1)%7 == 1 ? ( x+=60; y=102 ) : nil
					@box[q] = flow left: x, top: y, width: 52, height: 52;
				end
			end
		end
		creature_pane_2_book
	end

	def creature_pane_2_book faction='neutral'
		@creatures = DB.execute( "select * from creature_stats where faction = '#{faction}';" )
		@faction_name.replace File.read("text/#{@LG}/factions/#{faction}/name.txt")
		@box.map!(&:clear)
		@creatures.each_with_index do |x, y|
			@box[y].append do
				set ( image "pics/creatures/#{x[0]}.png", left: 1, width: 50 ), text: "#{x[0]}"
				contents[0].click do
					@creature_name.replace x[0]
					@creature_abilities = x[1].split(",")
					@creature_spells = x[2].split(",")
					#@creature_spell_mastery = read_skills dir_xdb, 0, "<Mastery>", "</Mastery>"
					@creature_stats.clear do
						para x[3], left: 10, top: 3, size: 13
						para x[4], left: 10, top: 24, size: 13
						para "#{x[5]} - #{x[6]}", left: 10, top: 46, size: 13
						para x[7], left: 10, top: 70, size: 13
						para x[8], left: 10, top: 93, size: 13
						para x[9], left: 10, top: 115, size: 13
						para x[10], left: 10, top: 139, size: 13
						para x[11], left: 10, top: 162, size: 13
						para x[12], left: 10, top: 187, size: 13
						subtitle x[13], left: 164, top: 273
						i=0
						@creature_spells.each do |spell|
							spell.include?("ABILITY") ? next : (set (image "pics/spells/#{spell.downcase}.png", left: 164 - 43*(i%2), top: 205 - 43*(i/2), width: 40), header: (read_skills "text/#{@LG}/spells/#{spell.downcase}/name.txt")[0], text: ( read_skills "text/#{@LG}/spells/#{spell.downcase}/long_description.txt" ).join("\n"))
							i+=1
						end					
					end
					@pane2.clear do
						@creature_abilities.each_with_index do |a, d|
							para strong("#{File.read("text/#{@LG}/creature_abilities/#{a}/name.txt")}"), stroke: white, size: 14, align: "center", margin_left: 20, margin_right: 20, margin_top: 35
							para "#{File.read("text/#{@LG}/creature_abilities/#{a}/description.txt")}", stroke: white, size: 12, justify: true, align: "center", margin_left: 20, margin_right: 20
						end
					end
				end
			end
		end
	end
	
	def spell_pane first=@primary_text, second=@secondary_pane
		@spell_mastery = 0
		schools = DB.execute("select name from spell_schools")
		set_main "SPELL", schools, "guilds", "guilds"
		pane_text = read_skills "text/#{@LG}/panes/spell_pane/name.txt"
		first.clear do
			subtitle pane_text[0], top: 285, font: "Vivaldi", align: "center"
			subtitle pane_text[1], left: 120, top: 330, size: 18;
			@spell_lvl = subtitle "", left: 215, top: 331, size: 18;
			flow(left: 55, top: 370, width: 260, height: 150) { @spell_text = para "", align: "left", justify: true, size: 12 }
			pane_text[2..5].each_with_index { |mastery, i| radio( left: 185, top: 525+i*20 ).click { @spell_mastery = i; spell_pane_effect };  para mastery, left: 215, top: 528+i*20, size: 12 }
			subtitle pane_text[6], left: 45, top: 518, size: 18
			subtitle pane_text[7], left: 80, top: 610, size: 18
			@spell_mana = subtitle "", left: 177, top: 611, size: 18;
			subtitle pane_text[8], left: 120, top: 645, size: 22
			set ( @box_level = ( flow left: 257, top: 645, width: 50, height: 45 ) ), text: "Click to increase!", width: 200, height: 30
		end
		set_spellpower 1

		second.clear do
			flow left: 95, top: 130, width: 640, height: 540 do
				image 'pics/themes/spellbook.jpg', width: 1.0, height: 1.0
				for q in 0..15 do
					@box[q] = flow left: 60 + 125*(q%2) + 305*(q/8), top: 40 + 125*(q/2) - 500*(q/8), width: 90; 
				end
			end
		end
	end
	
	def spell_pane_pages school
		spells = DB.execute( "select * from spells where school = '#{school}';" )
		@box.map!(&:clear)
		spells.each_with_index do |spell, i|
			@box[i].clear do
				set ( image "pics/spells/#{spell[0]}.png", width: 90 ), header: (read_skills "text/#{@LG}/spells/#{spell[0]}/name.txt")[0], text: ( read_skills "text/#{@LG}/spells/#{spell[0]}/long_description.txt" ).join("\n"), text2: ( read_skills "text/#{@LG}/spells/#{spell[0]}/additional.txt").join("\n")			
				contents[0].click {	spell_pane_effect @spell_current = spell }
			end
		end
	end
	
	def spell_pane_effect spell=@spell_current
		unless spell.nil? then
			desc_vars = []
			if spell[0].include? "rune" then
				text_sp_effect = "Casting cost is " + spell[5]
			else
				spell_effect = spell[1].split(",").map(&:to_f)
				spell_increase = spell[2].split(",").map(&:to_f)
				File.file?("text/#{@LG}/spells/#{spell[0]}/SpellBookPrediction.txt") == true ? ( text_sp_effect = File.read("text/#{@LG}/spells/#{spell[0]}/spellbookprediction.txt") ) : ( text_sp_effect = File.read("text/#{@LG}/spells/universal prediction/spellbookprediction.txt") )
				text_sp_effect.scan(Regexp.union(/<.*?>%/,/<.*?>/)).each { |match| desc_vars << match }
				desc_vars.each_with_index do |var, i|
					if var["%"] then
						spell_effect[0+i*4] < 2 ? ( text_sp_effect.sub! var, "#{trim ((spell_effect[@spell_mastery+4*i]+spell_increase[@spell_mastery+4*i]*@spell_power)*100).round(2)}%" ) : ( text_sp_effect.sub! var, "#{trim (spell_effect[@spell_mastery+4*i]+spell_increase[@spell_mastery+4*i]*@spell_power).round(2)}%" )
					else
						text_sp_effect.sub! var, "#{trim (spell_effect[@spell_mastery+4*i]+spell_increase[@spell_mastery+4*i]*@spell_power).round(2)}"
					end
				end
			end
			@spell_text.replace "#{text_sp_effect}"
			@spell_lvl.replace spell[3]
			@spell_mana.replace spell[4]
		end
	end
	
	def set_spellpower power
		@spell_power = power
		@box_level.clear { subtitle "#{@spell_power}",left: 10, top: 3, size: 20, font: "Vivaldi" }	
		@box_level.click do |press| ############# Adjusting spell efects
			@hovers.hide
			case press
			when 1 then @spell_power<100 ? @spell_power+=1 : nil
			when 2 then @spell_power = 1;
			when 3 then @spell_power>1 ? @spell_power-=1 : nil
			end
			set_spellpower @spell_power
			spell_pane_effect
		end
	end
	
	def town_pane first=@primary_text, second=@secondary_pane
		set_main "HERO", FACTIONS, "factions", "factions"
		pane_text = read_skills "text/#{@LG}/panes/town_pane/name1.txt"
		pane_text2 = read_skills "text/#{@LG}/panes/town_pane/name2.txt"
		dir_text = "text/#{@LG}/panes/town_pane/changes"
		
		first.clear do
			subtitle pane_text[0], top: 285, align: "center"
			para pane_text[1], left: 60, top: 340, size: 12
			#lang_setings = read_skills "design/settings/language.txt"
			#box_text = ["English", "Polskie" ]
			#chosen = lang_setings.index(@LG)
			#list_box :items => box_text, left: 170, top: 340, width: 100 do |n|
				#case n.text
				#when box_text[0] then @LG = lang_setings[0]
				#when box_text[1] then @LG = lang_setings[1]
				#end
				#@app.clear
				#main_menu
				#town_pane
			#end
		end
		
		second.clear do
			flow left: 50, top: 60, width: 730, height: 700 do
				image 'pics/themes/town.png', width: 1.0, height: 1.0
				subtitle pane_text2[0], top: 42, align: "center"
				stack left: 50, top: 110, width: 0.5, height: 0.64 do
					subtitle pane_text2[1], align: "left", stroke: white
					subtitle pane_text2[2], align: "left", stroke: white
					subtitle pane_text2[3], align: "left", stroke: white
					subtitle pane_text2[4], align: "left", stroke: white, left: 5
					subtitle pane_text2[5], align: "left", stroke: white
					subtitle pane_text2[6], align: "left", stroke: white
				end
				left, top, jump, move = 160, 118, 58, 50
				set_slot "LINK", "http://heroescommunity.com/viewthread.php3?TID=28539", (image "pics/changes/buildings.png", left: left, top: top, width: @icon_size2), header: pane_text2[7], text: File.read("#{dir_text}/buildings.txt")
				set (image "pics/changes/heroes.png", left: left + move, top: top, width: @icon_size2), header: pane_text2[8], text: File.read("#{dir_text}/heroes.txt")
				set (image "pics/misc/attack.png", left: left, top: top + jump, width: @icon_size2), header: pane_text2[9], text: File.read("#{dir_text}/attack.txt")
				set (image "pics/misc/knowledge.png", left: left + move, top: top + jump, width: @icon_size2), header: pane_text2[10], text: File.read("#{dir_text}/knowledge.txt")
				set_slot "LINK", "http://heroescommunity.com/viewthread.php3?TID=41320", (image "pics/changes/arrangement.png", left: left + move*2, top: top + jump, width: @icon_size2), header: pane_text2[11], text: File.read("#{dir_text}/arrangement.txt")
				set (image "pics/changes/necromancy.png", left: left + move*3, top: top + jump, width: @icon_size2), header: pane_text2[12], text: File.read("#{dir_text}/necromancy.txt")
				set (image "pics/changes/gating.png", left: left + move*4, top: top + jump, width: @icon_size2), header: pane_text2[13], text: File.read("#{dir_text}/gating.txt")
				set_slot "LINK", "http://heroescommunity.com/viewthread.php3?TID=41320", (image "pics/changes/spell_system.png", left: left, top: top + jump*2, width: @icon_size2), header: pane_text2[14], text: File.read("#{dir_text}/spell_system.txt")
				set (image "pics/changes/occultism.png", left: left + move, top: top + jump*2, width: @icon_size2), header: pane_text2[15], text: File.read("#{dir_text}/occultism.txt")
				set (image "pics/changes/movement.png", left: left + move*2, top: top + jump*3, width: @icon_size2), header: pane_text2[16], text: File.read("#{dir_text}/movement.txt")
				set_slot "LINK", "http://heroescommunity.com/viewthread.php3?TID=41341", (image "pics/changes/generator.png", left: left + move*3, top: top + jump*3, width: @icon_size2), header: pane_text2[17], text: File.read("#{dir_text}/generator.txt")
				set (image "pics/changes/sites.png", left: left + move*4, top: top + jump*3, width: @icon_size2), header: pane_text2[18], text: File.read("#{dir_text}/sites.txt")
				set_slot "LINK", "http://heroescommunity.com/viewthread.php3?TID=41528", (image "pics/changes/artifacts.png", left: left + move*5, top: top + jump*3, width: @icon_size2), header: pane_text2[19], text: File.read("#{dir_text}/artifacts.txt")
				set (image "pics/changes/bloodrage.png", left: left + move, top: top + jump*4, width: @icon_size2), header: pane_text2[20], text: File.read("#{dir_text}/bloodrage.txt")
				set_slot "LINK", "http://heroescommunity.com/viewthread.php3?TID=43030", (image "pics/changes/manual.png", left: left + move*2, top: top + jump*4, width: @icon_size2), header: pane_text2[21], text: File.read("#{dir_text}/manual.txt")
				set (image "pics/changes/textures.png", left: left + move*3, top: top + jump*4, width: @icon_size2), header: pane_text2[22], text: File.read("#{dir_text}/textures.txt")
				set (image "pics/changes/atb.png", left: left + move*4, top: top + jump*4, width: @icon_size2), header: pane_text2[23], text: File.read("#{dir_text}/atb.txt")
				set (image "pics/changes/8skills.png", left: left + move, top: top + jump*5, width: @icon_size2), header: pane_text2[24], text: File.read("#{dir_text}/8skills.txt")
				set (image "pics/changes/townportal.png", left: left + move*2, top: top + jump*5, width: @icon_size2), header: pane_text2[25], text: File.read("#{dir_text}/townportal.txt")
				set_slot "LINK", "http://heroescommunity.com/viewthread.php3?TID=39792", (image "pics/changes/pest.png", left: left + move*3, top: top + jump*5, width: @icon_size2), header: pane_text2[26], text: File.read("#{dir_text}/pest.txt")
				set_slot "LINK", "http://heroescommunity.com/viewthread.php3?TID=41977", (image "pics/changes/governor.png", left: left + move*4, top: top + jump*5, width: @icon_size2), header: pane_text2[27], text: File.read("#{dir_text}/governor.txt")
				set (image "pics/changes/levels.png", left: left + move*5, top: top + jump*5, width: @icon_size2), header: pane_text2[28], text: File.read("#{dir_text}/levels.txt")
				set (image "pics/changes/ai.png", left: left + move*6, top: top + jump*5, width: @icon_size2), header: pane_text2[29], text: File.read("#{dir_text}/ai.txt")
				@pane_magic = flow left: 0.56, top: 80, width: 0.38, height: 0.64
			end
		end
	end

	def artifact_pane first=@primary_text, second=@secondary_pane
		filters = DB.execute( "select filter from artifact_filter;" )
		set_main "ARTIFACT", filters , "buttons", "panes/artifact_pane/buttons" 
		first.clear { @sort_pane = flow }
		second.clear do
			flow left: 80, top: 108, width: 650, height: 600, scroll: true do
				image 'pics/themes/pane3.png', width: 1.0, height: 1.0
				subtitle File.read("text/#{@LG}/panes/artifact_pane/name.txt"), top: 10, align: "center",  stroke: white
				@artifact_list = flow left: 0.05 , top: 0.1, width: 0.95, height: 0.9;
			end
		end
	end
	
	def artifact_slot sort
		slots = (DB.execute( "select name from artifact_filter where filter = '#{sort}';" ))[0][0].split(",")
		@sort_pane.clear { slots.each_with_index {|slot, i| set_artifacts sort, slots, i } }
	end
	
	def set_artifacts sort, slots, i
		button File.read("text/#{@LG}/panes/artifact_pane/buttons/#{sort}/#{slots[i]}.txt"), left: 68+120*(i%2), top: 350+35*(i/2), width: 100 do
			@artifact_list.clear do
				case sort
				when "by_slot" then DB.execute( "select * from artifacts where slot = '#{slots[i]}';" ).each { |art| add_artifact art[0]}
				when "by_price" then DB.execute( "select * from artifacts where CostOfGold BETWEEN #{slots[i].to_i - 9999} AND #{slots[i].to_i};" ).each { |art| add_artifact art[0]}
				when "by_rarity" then DB.execute( "select * from artifacts where type = '#{slots[i]}';" ).each { |art| add_artifact art[0]}
				when "by_modifier" then DB.execute( "select * from artifacts where #{slots[i]} > 0;" ).each { |art| add_artifact art[0]}
				when "by_set" then DB.execute( "select * from artifacts where art_set = '#{slots[i]}';" ).each { |art| add_artifact art[0]}
				end
			end
		end
	end
	
	def add_artifact artifact
		list=@artifact_list.contents.count
		@artifact_list.append{ set_slot "ARTIFACT_SLOT", artifact, ( image "pics/artifacts/#{artifact}.png", left: 5 + 75*(list%8), top: 5 + (list/8)*70, width: @icon_size), text: (read_skills "text/#{@LG}/artifacts/#{artifact}/description.txt")[0], header: (read_skills "text/#{@LG}/artifacts/#{artifact}/name.txt")[0], text2: ((read_skills "text/#{@LG}/artifacts/#{artifact}/additional.txt")[0]) }				
	end
	
	def main_menu
		image 'pics/themes/background.jpg', left: 0, top: 0, width: app.width, height: app.height
		@app = flow do
			menu = read_skills "text/#{@LG}/panes/main_menu.txt"
			@main_slot = []
			
			stack width: 350 do
				image 'pics/themes/factions_pane.png', left: 7, top: 68, width: 350, height: 202
				image 'pics/themes/manuscript.png', left: 20, top: 270, width: 330
				for i in 0..7 do
					top = i/4*(@icon_size + 1); left = i*(@icon_size +1) - 4*top; 
					@main_slot[i]=flow( left: @icon_size + 1 + left, top: 110 + top, width: @icon_size, height: @icon_size )
				end
				@primary_text = stack width: 1.0; #################################### LEFT  - heroes stats and sheets
			end
			set ( ( image "pics/buttons/town_index.png", left: 32, top: 25, width: 45, height: 45 ).click { town_pane } ), text: menu[0]
			set ( ( image "pics/buttons/hero_index.png", left: 92, top: 25, width: 45, height: 45 ).click { hero_pane } ), text: menu[1]
			set ( ( image "pics/buttons/creature_index.png", left: 152, top: 25, width: 45, height: 45 ).click { creature_pane } ), text: menu[2]
			set ( ( image "pics/buttons/spell_index.png", left: 212, top: 25, width: 45, height: 45 ).click { spell_pane } ), text: menu[3]
			set ( ( image "pics/buttons/artifact_index.png", left: 272, top: 25, width: 45, height: 45 ).click { artifact_pane } ), text: menu[4]
			
			@secondary_pane = stack width: 800, height: 800;	###################### RIGHT - SKILLWHEEL TABLE
			stack left: app.width - 60, top: app.height - 60, width: 60, height: 60 do
				image "pics/themes/about.png"
				set contents[0], text: "Credits"
				contents[0].click do
					@a.nil? ? nil : @a.close
					@a=window(title: "About", width: 450, height: 200, resizable: false) do
					para File.read("text/#{owner.instance_variable_get(:@LG)}/panes/credits_pane/name.txt"), justify: true
						button( "www.heroescommunity.com", left: 110, top: 150 ) { system("start http://heroescommunity.com/viewthread.php3?TID=42212") }
					end
				end
			end
		end
	end
	
##################################################################################################################### MAIN STARTS HERE

	FACTIONS = DB.execute( "select name from factions;" )  #get faction list
	@LG = "en" # Define deafult app language english
	@icon_size = 60
	@icon_size2 = 40
	main_menu  # define General app slots
	hero_pane  # Launch one of the app functions
end
