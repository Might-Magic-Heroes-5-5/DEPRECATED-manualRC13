require 'code/tooltip'
require 'code/readskills'
require 'sqlite3'
require 'yaml'

def set	(img, options={}, &block )
	img.hover { @hovers.show text: options[:text], header: options[:header] , size: 9,  text2: options[:text2], width: options[:width], height: options[:height]; img.scale 1.25, 1.25 }
	img.leave { @hovers.hide; img.scale 0.8, 0.8 }
	img.click { @hovers.hide; block.call if block_given? } 
end

def trim num
  i, f = num.to_i, num.to_f
  i == f ? i : f
end

def set_button hero, count, direction = "up"
	direction == "up" ? hero+=1 : hero-=1 ##direction points if one is going up or down the list
	( hero > -1 && hero < count ) ? ( set_hero hero; set_wheel; ) : nil 
end

def reading f_name; File.exists?(f_name) ? ( return File.read(f_name) ) : nil; end

Shoes.app(title: "Might & Magic: Heroes 5.5 Reference Manual, database: RC9c", width: 1200, height: 800, resizable: true ) do

	###### defining system vars #####
	
	font "settings/fonts/vivaldi.ttf" unless Shoes::FONTS.include? "Vivaldi"
	font "settings/fonts/belmt.ttf" unless Shoes::FONTS.include? "Bell MT"
	style Shoes::Subtitle, font: "Vivaldi"
	style Shoes::Tagline, font: "Bell MT", size: 16, align: "center"
	@hovers = tooltip()
	@icon_size, @icon_size2 = 60, 40
	
	###### defining data vars #####
	
	DB = SQLite3::Database.new "settings/skillwheel.db"
	FACTIONS = DB.execute( "select name from factions where name!='TOWN_NO_TYPE';" )  #get faction list
	MASTERIES = { MASTERY_BASIC: 1, MASTERY_ADVANCED: 2, MASTERY_EXPERT: 3 }
	OFFENSE_BONUS = [ 1, 1.1, 1.15, 1.2 ]
	DEFENSE_BONUS = [ 1, 1.1, 1.15, 1.2 ]
	@LG = "en" 											#deafult app language
	@offense, @defense, @mana_multiplier = 1, 1, 10     #skill multipliers - Offense, Defense, Intelligence
	
	def set_main page, object, dir_img, dir_txt
		@main_slot.each_with_index do |slot, i|
			slot.clear do
				object[i].nil? ? nil : ( set_slot page, object[i][0], ( image "pics/#{dir_img}/#{object[i][0]}.png", width: @icon_size ), text: File.read("text/#{@LG}/#{dir_txt}/#{object[i][0]}/name.txt") )
			end
		end
	end

	def set_slot page, item, img, options={}
		set img, text: options[:text], header: options[:header] || nil, text2: options[:text2] || nil do
			case page
			when "CLASSES" then set_classes item;
			when "PRIMARY" then @ch_primary[item]+=1; set_primary
			when "CREATURE" then creature_pane_2_book item
			when "SPELL" then spell_pane_pages item
			when "HERO" then
				@ch_class = item; 
				
				set_hero 0; 
				set_wheel
			when "ARTIFACT" then artifact_slot item
			end
		end
	end
		
	def set_classes item
		classes = DB.execute( "select id from classes where faction = '#{item}';" )
		space = ( @class_board.width - @icon_size2*classes.length )/( classes.length + 1 )
		@class_board.clear do
			for i in 0..classes.length-1 do
				@class_board.append do
					flow(top: 5, left: space + i*( @icon_size2 + space ), width: @icon_size2) do
						set_slot "HERO", classes[i][0], ( image "pics/classes/active/#{classes[i][0]}.png", width: @icon_size2), text: (reading "text/#{@LG}/classes/#{classes[i][0]}/name.txt") 
					end
				end
			end
		end
	end

	def set_hero current, load1=nil, load2=nil
		@wheel_turn = 0
		class_heroes = DB.execute( "select id, atk, def, spp, knw from heroes where classes='#{@ch_class}' order by id ASC;" )
		hero = class_heroes[current][0]
		hero_primary = DB.execute( "select atk, def, spp, knw from heroes where id = '#{hero}';" )[0]
		skill_chance = DB.execute( "select atk_c, def_c, spp_c, knw_c from classes where id = '#{@ch_class}';")[0]
		@ch_primary = load1 || (hero_primary + skill_chance)
		@hero_secondary = DB.execute( "select skills from heroes where id = '#{hero}';" )[0][0].split(',')
		@hero_mastery = DB.execute( "select masteries from heroes where id = '#{hero}';" )[0][0].split(',')
		@hero_perks = DB.execute( "select perks from heroes where id = '#{hero}';" )[0][0].split(',')
		#@save.clear do
		#	button "Save", left: 0, top: 0, width: 81, height: 25 do
		#		options = ['hero', 'ch_class', 'ch_primary', 'ch_skills' ]
		#		data = Hash[options.map {|x| [x, ""]}]
		#		[ hero, @ch_class, @ch_primary, @hero_secondary ].each_with_index { |n, i| data[options[i]] = n; }
		#		File.open(ask_save_file, "w") { |f| f.write(data.to_yaml) }
		#	end
		#end
		@box_hero.clear { image "pics/heroes/#{hero}.png", width: 80 }
		set @box_hero, text: (reading "text/#{@LG}/heroes/#{hero}/spec.txt"),
			header: (reading "text/#{@LG}/heroes/#{hero}/name.txt"),
			text2: (reading "text/#{@LG}/heroes/#{hero}/additional.txt")
		@left_button.click { set_button current, class_heroes.length, "down" }.show
		@right_button.click { set_button current, class_heroes.length }.show
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
		@stat_damage.replace "#{((2.5*@ch_primary[0])*@offense).round(2)}%"
		@stat_defense.replace "#{((2.5*@ch_primary[1])*@defense).round(2)}%"
		@stat_mana.replace "#{@mana_multiplier*@ch_primary[3]}"
	end

	def set_wheel ##assigns skill trees to wheel and rotates if needed
		@ch_secondary = DB.execute( "select skill from #{@ch_class} where type='SKILLTYPE_SKILL';" )
		if @ch_secondary.length>12 then	####setting left/right arrows if there are more than 12 skills
			case @wheel_turn
			when 0 then @wheel_left.hide; @wheel_right.show
			when 1..@ch_secondary.length-13 then @wheel_left.show; @wheel_right.show
			else @wheel_left.show; @wheel_right.hide
			end
		else
			@wheel_left.hide; @wheel_right.hide
		end
		@ch_secondary.each_with_index do |skill, y| 
			( yy = y - @wheel_turn ) > 11 ? break : nil
			set_wheel_tree skill[0], yy; 
		end
	end
	
	def set_wheel_tree skill, yy, source='skill'   	###Populates a tree on the wheel
		status = @hero_secondary.index(skill)
		mastery = status.nil? ? 0 : MASTERIES[:"#{@hero_mastery[status]}"]
		perks = DB.execute( "select name from skills where tree='#{skill}' and type='SKILLTYPE_STANDART_PERK';" )
		branch, branch_count = [], [ 0, 0, 0 ] 		###branch perks; number of active perks for each branch
		p_count = 0
		perks.each_with_index do |b, i|
			branch << (get_branch b[0])
			branch[i].each do |p|
				@hero_perks.include?(p) ? ( p_count+=1; branch_count[i]+=1 ) : nil
			end
		end
		
		if source == 'skill' then
			if mastery == 0 then
				@hero_perks-=(branch[0] + branch[1] + branch[2] )
				branch_count = [ 0, 0, 0 ]
				p_count = 0
			end
		else
			if p_count > mastery then
				if mastery == 0 then
					@hero_secondary << skill
					@hero_mastery << MASTERIES.key(p_count)
				else
					@hero_mastery[status] = MASTERIES.key(p_count)
				end
				mastery = p_count
			end
		end
		set_skills skill, yy, mastery, p_count
		set_perks skill, yy, branch, p_count, branch_count
	end
	
	def set_skills skill, y, mastery, p_count
		3.times { |x| set_skill_box @box[y][x], skill, x, mastery, y, p_count }
	end	
	
	def set_skill_box box, skill, x, mastery, y, p_count
		box.clear;
		box.append do
			if x < mastery then
				image do
					image "pics/skills/active/#{skill}#{x+1}.png", width: @icon_size2, height: @icon_size2, left: 3, top: 3
					shadow radius: 1, fill: rgb(0, 0, 0, 0.6)
				end
				case skill
				when "HERO_SKILL_OFFENCE" then @offense = OFFENSE_BONUS[x+1]; set_primary
				when "HERO_SKILL_DEFENCE" then @defense = DEFENSE_BONUS[x+1]; set_primary
				end
			else
				image "pics/skills/grey/#{skill}#{x+1}.png", width: @icon_size2, height: @icon_size2, left: 3, top: 3
				if x==0 then
					case skill
					when "HERO_SKILL_OFFENCE" then @offense = OFFENSE_BONUS[0]; set_primary
					when "HERO_SKILL_DEFENCE" then @defense = DEFENSE_BONUS[0]; set_primary
					end
				end
			end

			set(contents[0], text: (reading "text/#{@LG}/skills/#{skill}/desc#{x+1}.txt"),
				header: (reading "text/#{@LG}/skills/#{skill}/name#{x+1}.txt"),
				text2: (reading "text/#{@LG}/skills/#{skill}/additional#{x+1}.txt")) do
				place = @hero_secondary.index(skill)
				if x >= mastery then
					if place.nil? then
						@hero_secondary << skill
						@hero_mastery << MASTERIES.key(x+1)
					else
						@hero_mastery[place] = MASTERIES.key(x+1)
					end
				else
					if x == 0 then
						@hero_mastery.delete_at(place)
						@hero_secondary.delete_at(place)
					else
						x >= p_count ? @hero_mastery[place] = MASTERIES.key(x) : nil
					end
				end
				set_wheel_tree skill, y
			end
		end
	end
	
	def set_perks skill, y, branch, p_count, branch_count							
		@box[y][3..-1].map!(&:clear)
		branch.each_with_index do |b,z|
			b.each_with_index { |p,x| set_perks_box @box[y][3 + z + x*3], p, x, y, z, skill, p_count, branch_count[z] }
		end
	end
	
	def get_branch perk, branch = []
		branch << perk
		next_skill = (DB.execute "select skill from #{@ch_class} where chance='#{perk}'")[0]
		next_skill.nil? ? ( return branch ) : ( get_branch next_skill.join(','), branch )
	end
	
	def set_perks_box box, perk, x, y, z, skill, p_count, branch_count
		mastery = @hero_perks.include?(perk) ? x : 99
		( x < mastery and 2-x < p_count - branch_count ) ? return : nil
		new_size = @icon_size2 - 4*(x + 1)
		box.append do
			if x < mastery then
				case perk
				when "HERO_SKILL_INTELLIGENCE" then @mana_multiplier = 10; set_primary
				when "HERO_SKILL_BARBARIAN_INTELLIGENCE" then @mana_multiplier = 10; set_primary
				end
				image "pics/skills/grey/#{perk}.png", width: new_size, height: new_size, left: 3, top: 3
			else
				case perk
				when "HERO_SKILL_INTELLIGENCE" then @mana_multiplier = 14; set_primary
				when "HERO_SKILL_BARBARIAN_INTELLIGENCE" then @mana_multiplier = 14; set_primary
				end
				image do
					image "pics/skills/active/#{perk}.png", width: new_size, height: new_size, left: 3, top: 3
					shadow radius: 1, fill: rgb(0, 0, 0, 0.6)
				end
			end
			set(contents[0], text: (reading "text/#{@LG}/skills/#{perk}/desc.txt"),
				header: (reading "text/#{@LG}/skills/#{perk}/name.txt"),
				text2: (reading "text/#{@LG}/skills/#{perk}/additional.txt")) do
				mastery == 99 ?	( perk_add perk ) : ( perk_del perk )
				set_wheel_tree skill, y, 'perk'
			end
		end
	end
	
	def perk_add perk
		@hero_perks.push(perk)
		prev = (DB.execute "select chance from #{@ch_class} where skill='#{perk}'")[0]
		prev.nil? ? return : ( perk_add prev[0] ) 
	end

	def perk_del perk
		@hero_perks.delete(perk)
		prev = (DB.execute "select skill from #{@ch_class} where chance='#{perk}'")[0]
		prev.nil? ? return : ( perk_del prev[0] )
		
	end
	
	def hero_pane first=@primary_text, second=@secondary_pane
		@ch_primary = [0, 0, 0, 0 ]
		@box = Array.new(12) { Array.new(12) }
		set_main "CLASSES", FACTIONS, "factions", "factions"
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
						set_slot "PRIMARY", i, ( image "pics/misc/#{table_image[i]}.png", left: 1, top: 1, width: 45),  text: pane_text[1]
						end
					end
				end
				@hero_st = flow left: 0, top: 48, width: 180, height: 45
				@hero_ch = flow left: 0, top: 93, width: 180, height: 45;
			end
			flow do
				@stat_damage = para "", left: 100, top: 550, size: 12
				@stat_defense = para "", left: 187, top: 550, size: 12
				@stat_mana = para "", left: 273, top: 550, size: 12
				subtitle pane_text[2], left: 120, top: 647, size: 20
				set ( @box_level = ( flow left: 263, top: 108, width: 40, height: 35) ), text: pane_text[3]
				set ( image "pics/misc/s_damage.png", left: 80, top: 11, width: @icon_size/3 ), text: pane_text[4], width: 500, height: 40
				set ( image "pics/misc/s_defense.png", left: 167, top: 11, width: @icon_size/3 ), text: pane_text[5], width: 500, height: 40
				set ( image "pics/misc/s_mana.png", left: 253, top: 11, width: @icon_size/3 ), text: pane_text[6], width: 250, height: 40
				button "Load hero preset", left: 102, top: 60, height: 25 do 
					opts = YAML.load_file(ask_open_file)
					@ch_class = opts['ch_class']
					set_hero opts['hero'], opts['ch_primary'], opts['ch_skills']
					set_wheel
				end
			end
		end

		second.clear do
			case @shoe
			when 1 then image 'pics/themes/wheel.png', left: 5, top: 2, width: 785; c_width, c_height, step, start_rad, begin_rad, start_rad_up = 796, 800, Math::PI/6, 0, 362, 58
			when 2 then	image 'pics/themes/wheel.png', left: 5, top: 35, width: 918; c_width, c_height, step, start_rad, begin_rad, start_rad_up = 880, 950, Math::PI/6, 0, 425, 68
			end
			@wheel_left = image "pics/buttons/wheel_arrow.png", left: 350, top: 280 do end.hide.rotate 180
			@wheel_right = image "pics/buttons/wheel_arrow.png", left: 420, top: 280 do end.hide
			@box_hero = flow left: 355, top: 355, width: 80, height: 80
			@save = flow left: 355, top: 440, width: 82, height: 30;
			@left_button = image "pics/buttons/normal.png", left: 325, top: 357, width: 25, height: 80 do end.hide.rotate 180
			@right_button = image "pics/buttons/normal.png", left: 440, top: 357, width: 25, height: 80 do end.hide
			
			for q in 0..11
				angle = -1.46 + (Math::PI/21)*(q%3)
				q>1 ? ( ( ( q+1 )%3 ) == 1 ? start_rad += start_rad_up : nil ) : nil
				radius = begin_rad - start_rad
				for w in 0..11
					x, y = (c_width/2 + radius * Math.cos(angle)).round(0), (c_height/2 + radius * Math.sin(angle)).round(0)
					angle += step
					@box[w][q] = flow left: x - (@icon_size2 + 6)/2, top: y - (@icon_size2 + 6)/2, width: @icon_size2 + 6, height: @icon_size2 + 6
				end
			end	
			@wheel_left.click { @wheel_left.style[:hidden] == true ? nil : @wheel_turn-=1; set_wheel }
			@wheel_right.click { @wheel_right.style[:hidden] == true ? nil : @wheel_turn+=1; set_wheel }
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
				set ( image "pics/skills/active/hero_skill_recruitment.png", left: left, top: 229, width: 21 ), text: pane_text[9]
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
				x, y = 63, 22;
				for q in 0..20
					x+=60
					(q + 1)%3 == 1 ? (  x=123; y+=80 ) : nil
					@box[q] = flow left: x, top: y, width: 52, height: 52;
				end
			end
		end
		creature_pane_2_book
	end

	def creature_pane_2_book faction='TOWN_NO_TYPE'
		@creatures = DB.execute( "select * from creatures where faction = '#{faction}' order by tier ASC;" )
		@faction_name.replace File.read("text/#{@LG}/factions/#{faction}/name.txt")
		@box.map!(&:clear)
		@creatures.each_with_index do |x, y|
			@box[y].append do
				set ( image "pics/creatures/#{x[0]}.png", left: 1, width: 50 ), text: "#{x[0]}" do
					@creature_name.replace File.read("text/#{@LG}/creatures/#{x[0]}/name.txt")
					@creature_abilities = x[16].split(",")
					@creature_spells = x[10].split(",")
					#@creature_spell_mastery = read_skills dir_xdb, 0, "<Mastery>", "</Mastery>"
					@creature_stats.clear do
						para x[1], left: 10, top: 3, size: 13
						para x[2], left: 10, top: 24, size: 13
						para "#{x[4]} - #{x[5]}", left: 10, top: 46, size: 13
						para x[7], left: 10, top: 70, size: 13
						para x[6], left: 10, top: 93, size: 13
						para x[9], left: 10, top: 115, size: 13
						para x[12], left: 10, top: 139, size: 13
						para x[3], left: 10, top: 162, size: 13
						para x[15], left: 10, top: 187, size: 13
						subtitle x[13], left: 164, top: 273
						i=0
						@creature_spells.each do |spell|
							if spell.include?("ABILITY") then
								next
							else
								set (image "pics/spells/#{spell}.png", left: 164 - 43*(i%2), top: 205 - 43*(i/2), width: 40),
									header: (reading "text/#{@LG}/spells/#{spell}/name.txt"),
									text: (reading "text/#{@LG}/spells/#{spell}/desc.txt"),
									text2: (reading "text/#{@LG}/spells/#{spell}/additional.txt")
							end
							i+=1
						end					
					end
					@pane2.clear do
						@creature_abilities.each_with_index do |a, d|
							para strong("#{(reading "text/#{@LG}/abilities/#{a}/name.txt")}"), stroke: white, size: 14, align: "center", margin_left: 20, margin_right: 20, margin_top: 35
							para (reading "text/#{@LG}/abilities/#{a}/desc.txt"), stroke: white, size: 12, justify: true, align: "center", margin_left: 20, margin_right: 20
						end
					end
				end
			end
		end
	end
	
	def spell_pane first=@primary_text, second=@secondary_pane
		@spell_mastery = 0
		schools = DB.execute("select id from guilds")
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
		spells = DB.execute( "select * from spells where guild = '#{school}' order by tier ASC;" )
		@box.map!(&:clear)
		spells.each_with_index do |spell, i|
			@box[i].clear do
				set( ( image "pics/spells/#{spell[0]}.png", width: 90 ),
				header: (reading "text/#{@LG}/spells/#{spell[0]}/name.txt"),
				text: (reading "text/#{@LG}/spells/#{spell[0]}/desc.txt"),
				text2: (reading "text/#{@LG}/spells/#{spell[0]}/additional.txt")) { spell_pane_effect @spell_current=spell }
			end
		end
	end

	def spell_pane_effect spell=@spell_current
		debug(spell)
		unless spell.nil? then
			desc_vars = []
			spell_effect = spell[1].split(",").map(&:to_f)
			spell_increase = spell[2].split(",").map(&:to_f)
			text_sp_effect = File.read("text/#{@LG}/spells/#{File.file?("text/#{@LG}/spells/#{spell[0]}/pred.txt") ? "#{spell[0]}/pred.txt" : "universal_prediction.txt" }")
			text_sp_effect.scan(Regexp.union(/<.*?>/,/<.*?>/)).each { |match| desc_vars << match }
			desc_vars.each_with_index do |var, i|
				if var["%"] then
					spell_effect[0+i*4] < 2 ? ( text_sp_effect.sub! var, "#{trim ((spell_effect[@spell_mastery+4*i]+spell_increase[@spell_mastery+4*i]*@spell_power)*100).round(2)}%" ) : ( text_sp_effect.sub! var, "#{trim (spell_effect[@spell_mastery+4*i]+spell_increase[@spell_mastery+4*i]*@spell_power).round(2)}%" )
				else
					text_sp_effect.sub! var, "#{trim (spell_effect[@spell_mastery+4*i]+spell_increase[@spell_mastery+4*i]*@spell_power).round(2)}"
				end
			end
			@spell_text.replace "#{text_sp_effect}"
			@spell_mana.replace spell[3]
			@spell_lvl.replace spell[4]
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
		set_main "CLASSES", FACTIONS, "factions", "factions"
		pane_text = read_skills "text/#{@LG}/panes/town_pane/name1.txt"
		pane_text2 = read_skills "text/#{@LG}/panes/town_pane/name2.txt"
		dir_text = "text/#{@LG}/panes/town_pane/changes"

		first.clear do
			@lg_list = []
			subtitle pane_text[0], top: 285, align: "center"
			para pane_text[1], left: 60, top: 340, size: 12
			Dir.entries('text').reject{ |rj| rj == '.' or rj == '..' }.each do |n|
				@lg_list << [(reading "text/#{n}/language_name.txt"), n]
			end
			#chosen = lang_setings.index(@LG)
			list_box :items => @lg_list.map{|x| x[0]}, left: 170, top: 340, width: 100 do |n|
				@lg_list.each { |l| l[0].include?(n.text) ? ( @LG = l[1]; break ) : nil }
				@app.clear
				main_menu
				town_pane
			end
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
				set( (image "pics/changes/buildings.png", left: left, top: top, width: @icon_size2), header: pane_text2[7], text: File.read("#{dir_text}/buildings.txt") ) { system "start http://heroescommunity.com/viewthread.php3?TID=28539" }
				set (image "pics/changes/heroes.png", left: left + move, top: top, width: @icon_size2), header: pane_text2[8], text: File.read("#{dir_text}/heroes.txt")
				set (image "pics/misc/attack.png", left: left, top: top + jump, width: @icon_size2), header: pane_text2[9], text: File.read("#{dir_text}/attack.txt")
				set (image "pics/misc/knowledge.png", left: left + move, top: top + jump, width: @icon_size2), header: pane_text2[10], text: File.read("#{dir_text}/knowledge.txt")
				set( (image "pics/changes/arrangement.png", left: left + move*2, top: top + jump, width: @icon_size2), header: pane_text2[11], text: File.read("#{dir_text}/arrangement.txt") ) { system "start http://heroescommunity.com/viewthread.php3?TID=41320" }
				set (image "pics/changes/necromancy.png", left: left + move*3, top: top + jump, width: @icon_size2), header: pane_text2[12], text: File.read("#{dir_text}/necromancy.txt")
				set (image "pics/changes/gating.png", left: left + move*4, top: top + jump, width: @icon_size2), header: pane_text2[13], text: File.read("#{dir_text}/gating.txt")
				set( (image "pics/changes/spell_system.png", left: left, top: top + jump*2, width: @icon_size2), header: pane_text2[14], text: File.read("#{dir_text}/spell_system.txt") ) { system "start http://heroescommunity.com/viewthread.php3?TID=41320" }
				set (image "pics/changes/occultism.png", left: left + move, top: top + jump*2, width: @icon_size2), header: pane_text2[15], text: File.read("#{dir_text}/occultism.txt")
				set (image "pics/changes/movement.png", left: left + move*2, top: top + jump*3, width: @icon_size2), header: pane_text2[16], text: File.read("#{dir_text}/movement.txt")
				set( (image "pics/changes/generator.png", left: left + move*3, top: top + jump*3, width: @icon_size2), header: pane_text2[17], text: File.read("#{dir_text}/generator.txt") ) { system "start http://heroescommunity.com/viewthread.php3?TID=41341" }
				set (image "pics/changes/sites.png", left: left + move*4, top: top + jump*3, width: @icon_size2), header: pane_text2[18], text: File.read("#{dir_text}/sites.txt")
				set( (image "pics/changes/artifacts.png", left: left + move*5, top: top + jump*3, width: @icon_size2), header: pane_text2[19], text: File.read("#{dir_text}/artifacts.txt") ) { system "start http://heroescommunity.com/viewthread.php3?TID=41528" }
				set (image "pics/changes/bloodrage.png", left: left + move, top: top + jump*4, width: @icon_size2), header: pane_text2[20], text: File.read("#{dir_text}/bloodrage.txt")
				set( (image "pics/changes/manual.png", left: left + move*2, top: top + jump*4, width: @icon_size2), header: pane_text2[21], text: File.read("#{dir_text}/manual.txt") ) { system "start http://heroescommunity.com/viewthread.php3?TID=43030" }
				set (image "pics/changes/textures.png", left: left + move*3, top: top + jump*4, width: @icon_size2), header: pane_text2[22], text: File.read("#{dir_text}/textures.txt")
				set (image "pics/changes/atb.png", left: left + move*4, top: top + jump*4, width: @icon_size2), header: pane_text2[23], text: File.read("#{dir_text}/atb.txt")
				set (image "pics/changes/8skills.png", left: left + move, top: top + jump*5, width: @icon_size2), header: pane_text2[24], text: File.read("#{dir_text}/8skills.txt")
				set (image "pics/changes/townportal.png", left: left + move*2, top: top + jump*5, width: @icon_size2), header: pane_text2[25], text: File.read("#{dir_text}/townportal.txt")
				set( (image "pics/changes/pest.png", left: left + move*3, top: top + jump*5, width: @icon_size2), header: pane_text2[26], text: File.read("#{dir_text}/pest.txt") ) { system "start http://heroescommunity.com/viewthread.php3?TID=39792" }
				set( (image "pics/changes/governor.png", left: left + move*4, top: top + jump*5, width: @icon_size2), header: pane_text2[27], text: File.read("#{dir_text}/governor.txt") ) { system "start http://heroescommunity.com/viewthread.php3?TID=41977" }
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
				when "by_price" then DB.execute( "select * from artifacts where cost BETWEEN #{slots[i].to_i - 9999} AND #{slots[i].to_i};" ).each { |art| add_artifact art[0]}
				when "by_rarity" then DB.execute( "select * from artifacts where type = '#{slots[i]}';" ).each { |art| add_artifact art[0]}
				when "by_modifier" then DB.execute( "select * from artifacts where #{slots[i]} > 0;" ).each { |art| add_artifact art[0]}
				when "by_set" then DB.execute( "select * from artifacts where art_set = '#{slots[i]}';" ).each { |art| add_artifact art[0]}
				end
			end
		end
	end
	
	def add_artifact artifact
		list=@artifact_list.contents.count
		@artifact_list.append{ set_slot "ARTIFACT_SLOT", artifact, ( image "pics/artifacts/#{artifact}.png", left: 5 + 75*(list%8), top: 5 + (list/8)*70, width: @icon_size), text: (reading "text/#{@LG}/artifacts/#{artifact}/desc.txt"), header: (reading "text/#{@LG}/artifacts/#{artifact}/name.txt"), text2: (reading "text/#{@LG}/artifacts/#{artifact}/additional.txt") }				
	end
	
	def main_menu
		@backgr = image 'pics/themes/background.jpg', left: 0, top: 0, width: app.width, height: app.height
		@app = flow height: app.height do
			menu = read_skills "text/#{@LG}/panes/main_menu.txt"
			@main_slot = []
			
			stack left: 0, top: 0,width: 0.291 do
				image 'pics/themes/factions_pane.png', left: 8, top: 68, width: 349, height: 201
				image 'pics/themes/manuscript.png', left: 20, top: 270, width: 330
				for i in 0..7 do
					top = i/4*(@icon_size + 1); left = i*(@icon_size +1) - 4*top; 
					@main_slot[i]=flow( left: @icon_size + 1 + left, top: 110 + top, width: @icon_size, height: @icon_size )
				end
				@primary_text = stack width: 1.0; #################################### LEFT  - heroes stats and sheets
			end
			set( ( image "pics/buttons/town_index.png", left: 32, top: 25, width: 45, height: 45 ), text: menu[0] ) { town_pane }
			set( ( image "pics/buttons/hero_index.png", left: 92, top: 25, width: 45, height: 45 ), text: menu[1] ) { hero_pane }
			set( ( image "pics/buttons/creature_index.png", left: 152, top: 25, width: 45, height: 45 ), text: menu[2] ) { creature_pane }
			set( ( image "pics/buttons/spell_index.png", left: 212, top: 25, width: 45, height: 45 ), text: menu[3] ) { spell_pane }
			set( ( image "pics/buttons/artifact_index.png", left: 272, top: 25, width: 45, height: 45 ), text: menu[4] ) { artifact_pane }
			
			@secondary_pane = stack left: 0.292, top: 0, width: 0.66, height: 0.99;	###################### RIGHT - SKILLWHEEL TABLE
			stack left: app.width - 60, top: app.height - 60, width: 60, height: 60 do
				image "pics/themes/about.png"
				set contents[0], text: "Credits" do
					@a.nil? ? nil : @a.close
					@a=window(title: "About", width: 450, height: 200, resizable: false) do
						para File.read("text/#{owner.instance_variable_get(:@LG)}/panes/credits_pane/name.txt"), justify: true
						button( "www.heroescommunity.com", left: 110, top: 150 ) { system("start http://heroescommunity.com/view	.php3?TID=42212") }
					end
				end
			end
			
			@shoe = 1
			button "resize", left: 320, top: 10 do
				#self.resizable: true
				self.opacity = 50
				if @shoe == 1 then
					app.resize 1400, 1000
					@backgr.style(width: app.width, height: app.height)
					@app.style(width: app.width, height: app.height)
					@shoe = 2
				else
					app.resize 1200, 800
					@backgr.style(width: app.width, height: app.height)
					@app.style(width: app.width, height: app.height)
					@shoe = 1
				end
				#self.resizable false
			end
		end
	end

######################## MAIN STARTS HERE #########

	main_menu  # define General app slots
	hero_pane  # launch hero module
end