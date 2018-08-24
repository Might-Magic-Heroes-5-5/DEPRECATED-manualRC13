require 'code/tooltip'
require 'code/readskills'
require 'sqlite3'
require 'yaml'
require 'zip'


@@APP_DB = SQLite3::Database.new "settings/app_settings.db"
@@lg=@@APP_DB.execute( "select value from settings where name='language';" )[0][0]   		#get language
@@res=@@APP_DB.execute( "select value from settings where name='app_size';" )[0][0].to_i	#get app size

@@a_width = [ 1200, 1200 ]
@@a_height = [ 800, 750 ] 

class Array
  def same_values?
    self.uniq.length == 1
  end
end

def set (img, options={} )
	img.hover { @events[options[:event]] == true ? (@hovers.show text: options[:text], header: options[:header], size: 9, text2: options[:text2], width: options[:width], height: options[:height]; img.scale 1.25, 1.25) : nil }
	img.leave { @events[options[:event]] == true ? (@hovers.hide; img.scale 0.8, 0.8) : nil }
	img.click { |press| @events[options[:event]] == true ? (@hovers.hide; yield(press) if block_given?) : nil } 
end

def trim num
  i, f = num.to_i, num.to_f
  i == f ? i : f
end

def set_button hero, count, direction = "up"
	direction == "up" ? hero+=1 : hero-=1 			##direction points if one is going up or down the list
	( hero > -1 && hero < count ) ? ( set_hero hero; set_wheel; ) : nil
end

def reading f_name; begin return @texts.read(f_name) rescue nil end; end

Shoes.app(title: "Might & Magic: Heroes 5.5 Reference Manual, database: RC10b4", width: @@a_width[@@res], height: @@a_height[@@res], resizable: false ) do
	
	###### defining data vars #####

	DB = SQLite3::Database.new "settings/skillwheel.db"
	FACTIONS = DB.execute( "select name from factions where name!='TOWN_NO_TYPE';" )  #get faction list
	MASTERIES = { MASTERY_BASIC: 1, MASTERY_ADVANCED: 2, MASTERY_EXPERT: 3 }
	RESOURCE = [ "Gold", "Wood", "Ore", "Mercury", "Crystal", "Sulfur", "Gem"]
	OFFENSE_BONUS = [ 1, 1.1, 1.15, 1.2 ]
	DEFENSE_BONUS = [ 1, 1.1, 1.15, 1.2 ]
	@texts = Zip::File.open("text/#{@@lg}.pak") 		#load texts
	#@texts = Zip::File.open("text/en.pak") 		#load texts
	@offense, @defense, @mana_multiplier = 1, 1, 10     #skill multipliers - Offense, Defense, Intelligence
	@wheel_turn = 0
	
	###### defining system vars #####
	font "settings/fonts/1-vivaldi.ttf" unless Shoes::FONTS.include? "1 Vivaldi"
	font "settings/fonts/belmt.ttf" unless Shoes::FONTS.include? "Bell MT"
	style Shoes::Subtitle, font: "1 Vivaldi"
	style Shoes::Tagline, font: "Bookman Old Style", size: 16, align: "center"
		
	@events = { "menu" => true, "primary" => true, "secondary" => true }        ## Arrange GUI drawing slots into groups for the purpose of mass hiding
	
	GUI_SETTINGS = [															## defines hero skill wheel circle drawing vars for different GUI resolutions
	[60, 40, 40,  0,   0,   0,   0,  0, 0,  0 ],
	[60, 40, 36, 15, -30, -50, -22, -2, 40, 0 ]
	]
	@icon_size, @icon_size2, @icon_size3, @M_SL_L, @M_SL_T, @M_WH, @M_BR, @M_SR, @M_WH_L, @M_WH_R = GUI_SETTINGS[@@res]
	
	@hovers = tooltip(reading("properties/font_type.txt").split("\r\n"), 		## set default text fonts (should be monospaced)
		reading("properties/font_size.txt").split("\r\n").map(&:to_i),			## set default font size
		reading("properties/calc_text_size.txt").split("\r\n").map(&:to_i),		## define width and height size per char for (text and text2) popup size calculation (monospaced font is advisable)
		reading("properties/calc_header_size.txt").split("\r\n").map(&:to_i))   ## define width and height size per char for (header) popup size calculation 
		
	def set_resources price, x=0		
		price.each do |key, value|
			if value != 0 then
				image "pics/resources/#{key}.png", left: 8+70*(x%3), top: 0 + 22*(x/3)
				para value, left: 34+70*(x%3), top: 0 + 22*(x/3)
				x+=1
			end
		end
	end 

	def set_main page, object, dir_img, dir_txt
		@main_slot.contents.each_with_index do |slot, i|
			slot.clear do
				object[i].nil? ? nil : ( set_slot page, object[i][0], 
											( image "pics/#{dir_img}/#{object[i][0]}.png", width: @icon_size ),
											text: (reading "#{dir_txt}/#{object[i][0]}/name.txt"), event: "menu" )
			end
		end
	end

	def set_slot page, item, img, options={}
		set img, text: options[:text], header: options[:header] || nil, text2: options[:text2] || nil, event: options[:event] do |press|
			case page
			when "CLASSES" then set_classes item;
			when "PRIMARY" then case press
								when 1 then @ch_primary[item]+=1;
								when 2 then @ch_primary[item]=0;
								when 3 then @ch_primary[item]+=10;
								end 
								set_primary
			when "CREATURE" then creature_pane_2_book item
			when "SPELL" then spell_pane_pages item
			when "HERO" then @ch_class = item;
							 @wheel_turn = 0
							 set_hero 0
							 set_wheel
			when "ARTIFACT" then @artifact_list.clear; artifact_slot item; 
			end
		end
	end

	def set_classes item
		classes = DB.execute( "select id from classes where faction = '#{item}' order by sequence ASC;" )
		space = ( @class_board.width - @icon_size2*classes.length )/( classes.length + 1 )
		@class_board.clear do
			classes.length.times do |i|
				@class_board.append do
					flow(top: 5, left: space + i*( @icon_size2 + space ), width: @icon_size2) do
						set_slot "HERO", classes[i][0],
						( image "pics/classes/active/#{classes[i][0]}.png", width: @icon_size2),
						text: (reading "classes/#{classes[i][0]}/name.txt"),
						event: "primary"
					end
				end
			end
		end
	end

	def set_hero current, load0=nil, load1=nil, load2=nil, load3=nil, load4=nil, load5=nil
		class_heroes = DB.execute( "select id, atk, def, spp, knw from heroes where classes='#{@ch_class}' order by sequence ASC;" )
		hero = load0 || class_heroes[current][0]
		@hero_level = load5 || 1
		@hero_primary = DB.execute( "select atk, def, spp, knw from heroes where id = '#{hero}';" )[0]
		@skill_chance = DB.execute( "select atk_c, def_c, spp_c, knw_c from classes where id = '#{@ch_class}';")[0]
		@ch_primary = load1 || (@hero_primary + @skill_chance)
		@hero_secondary = load2 || DB.execute( "select skills from heroes where id = '#{hero}';" )[0][0].split(',')
		@hero_mastery = load3 || DB.execute( "select masteries from heroes where id = '#{hero}';" )[0][0].split(',')
		@hero_perks = load4 || DB.execute( "select perks from heroes where id = '#{hero}';" )[0][0].split(',')
		hero_spells = DB.execute( "select spells from heroes where id = '#{hero}';")[0][0].split(',')
		@hero_spell_pane.clear do
			hero_spells.each_with_index do |s, i|
				set (image "pics/spells/#{s}.png", left: 5 + 45*(i%2), top: 3, width: @icon_size2),
					header: (reading "spells/#{s}/name.txt"),
					text: (reading "spells/#{s}/desc.txt"),
					text2: (reading "spells/#{s}/additional.txt"),
					event: "primary"
			end
		end
		@save.clear do
			s_txt = reading("panes/hero_pane/save.txt").split("\n")
			button s_txt[0], left: 0, top: 0, width: 81, height: 25 do
				options = ['hero', 'ch_class', 'ch_primary', 'hero_secondary', 'hero_mastery', 'hero_perks', 'hero_level' ]
				user_data = [ hero, @ch_class, @ch_primary, @hero_secondary, @hero_mastery, @hero_perks, @hero_level ]
				data = Hash[options.map {|x| [x, ""]}]
				user_data.each_with_index { |n, i| data[options[i]] = n; }
				fl = file_exists s_txt[1], s_txt[2]
				fl.nil? ? nil : ( File.open("save/#{fl}", "w") { |f| f.write(data.to_yaml) } )
			end
		end
		@box_hero.clear { image "pics/heroes/#{hero}.png", width: 80 }
		set @box_hero, text: (reading "heroes/#{hero}/spec.txt"),
			header: (reading "heroes/#{hero}/name.txt"),
			text2: (reading "heroes/#{hero}/additional.txt"),
			event: "secondary"
		@left_button.click { set_button current, class_heroes.length, "down" }.show
		@right_button.click { set_button current, class_heroes.length }.show
		set_level
	end

	def file_exists ask1, ask2
		s_file = ask(ask1)
		if File.file?("save/#{s_file}") then
			confirm(ask2) ? nil : (return nil)
		end
		return s_file
	end

	def set_level
		@box_level.clear { subtitle "#{@hero_level}", size: 20 }
		set_primary
		@box_level.click do |press| ############# Hero leveling up and gaining of primary stats based on chance
			@hovers.hide
			case press
			when 1 then @hero_level<100 ? leveling : nil
			when 2 then @hero_level = 1; @ch_primary = @hero_primary + @skill_chance;
			when 3 then @hero_level<91 ? 10.times do leveling end : nil
			end
			set_level
		end
	end
	
	def leveling
		@hero_level+=1
		i = rand(1..100)
		case i
		when 1..@ch_primary[4] then @ch_primary[0]+=1
		when (@ch_primary[4] + 1)..(@ch_primary[4] + @ch_primary[5]) then @ch_primary[1]+=1
		when (@ch_primary[4] + @ch_primary[5] + 1)..(@ch_primary[4] + @ch_primary[5] + @ch_primary[6]) then @ch_primary[2]+=1
		when (@ch_primary[4] + @ch_primary[5] + @ch_primary[6] + 1)..100 then @ch_primary[3]+=1
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
		@ch_secondary = DB.execute( "select skill from #{@ch_class} where type='SKILLTYPE_SKILL' order by sequence ASC;" )
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
			set_wheel_tree skill[0], yy
		end
	end

	def set_wheel_tree skill, yy, source='skill'   	###Populates a tree on the wheel
		status = @hero_secondary.index(skill)
		mastery = status.nil? ? 0 : MASTERIES[:"#{@hero_mastery[status]}"]
		perks = DB.execute( "select name from skills where tree='#{skill}' and type='SKILLTYPE_STANDART_PERK' order by sequence ASC;" )
		branch, branch_count = [], [ 0, 0, 0 ] 		###skill branch; number of active perks
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
		box.clear
		box.append do
			if x < mastery then
				image do
					image "pics/skills/active/#{skill}#{x+1}.png", width: @icon_size3, height: @icon_size3, left: 3, top: 3
					shadow radius: 1, fill: rgb(0, 0, 0, 0.6)
				end
				case skill
				when "HERO_SKILL_OFFENCE" then @offense = OFFENSE_BONUS[x+1]; set_primary
				when "HERO_SKILL_DEFENCE" then @defense = DEFENSE_BONUS[x+1]; set_primary
				end
			else
				image "pics/skills/grey/#{skill}#{x+1}.png", width: @icon_size3, height: @icon_size3, left: 3, top: 3
				if x==0 then
					case skill
					when "HERO_SKILL_OFFENCE" then @offense = OFFENSE_BONUS[0]; set_primary
					when "HERO_SKILL_DEFENCE" then @defense = DEFENSE_BONUS[0]; set_primary
					end
				end
			end

			set(contents[0], text: (reading "skills/#{skill}/desc#{x+1}.txt"),
				header: (reading "skills/#{skill}/name#{x+1}.txt"),
				text2: (reading "skills/#{skill}/additional#{x+1}.txt"),
				event: "secondary") do
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
		new_size = @icon_size3 - 4*(x + 1)
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
			set(contents[0], text: reading("skills/#{perk}/desc.txt"),
				header: reading("skills/#{perk}/name.txt"),
				text2: reading("skills/#{perk}/additional.txt"),
				event: "secondary") do
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

	def hero_pane first=@primary_pane, second=@secondary_pane
		@ch_primary = [0, 0, 0, 0 ]
		@box = Array.new(12) { Array.new(12) }
		set_main "CLASSES", FACTIONS, "factions", "factions"
		pane_t1 = (reading "panes/hero_pane/name.txt").split("\n")
		pane_t1.map! { |x| x=x[0..-2] }
		first.clear do
			primary_t1 = flow do
				@events["primary"] = true
				table_image = [ "attack", "defense", "spellpower", "knowledge" ]
				subtitle pane_t1[0], top: 15, align: "center"
				@class_board = flow left: 39, top: 60, width: 280, height: @icon_size + 10 ############# CLASSES LAYOUT
				flow width: 200, left: 90, top: 120 do	 ############# PRIMARY STATS TABLE
					12.times { |i| flow(height: 47, width: 47) { border("rgb(105, 105, 105)", strokewidth: 1) } }
					4.times { |i| contents[i].append { set_slot "PRIMARY", i, ( image "pics/misc/#{table_image[i]}.png", left: 1, top: 1, width: 45),  text: pane_t1[1], event: "primary" }	}
					@hero_st = flow left: 0, top: 48, width: 180, height: 45
					@hero_ch = flow left: 0, top: 93, width: 180, height: 45
				end
				flow do
					@stat_damage = para "", left: 100, top: 270, size: 12
					@stat_defense = para "", left: 187, top: 270, size: 12
					@stat_mana = para "", left: 273, top: 270, size: 12
					set ( @box_level = ( flow left: 262, top: 115, width: 40, height: 35) ), text: pane_t1[2], event: "primary"
					set ( image "pics/misc/s_damage.png", left: 80, top: 11, width: @icon_size/3 ), text: pane_t1[3], width: 500, height: 40, event: "primary"
					set ( image "pics/misc/s_defense.png", left: 167, top: 11, width: @icon_size/3 ), text: pane_t1[4], width: 500, height: 40, event: "primary"
					set ( image "pics/misc/s_mana.png", left: 253, top: 11, width: @icon_size/3 ), text: pane_t1[5], width: 250, height: 40, event: "primary"
					subtitle pane_t1[6], left: 70, top: 300, size: 18
					@hero_spell_pane = flow left: 80, top: 70, height: 44, width: 170;
					button pane_t1[7], left: 120, top: 145, height: 20, width: 120 do
						primary_t1.hide
						first.append do
							primary_t2 = flow width: 1.0, height: 0.9 do
								subtitle pane_t1[8], align: "center", top: 10
								q = stack left: 80, top: 57, width: 252, height: 330, scroll: true;
								save_list q, pane_t1[10], pane_t1[11]
								start { q.scroll_top = 1 } ## this line fixes Framework bug
								button(pane_t1[9], left: 140, top: 405, height: 20, width: 80 ) { primary_t2.remove; primary_t1.show }
							end
						end
					end
				end
			end
		end
		
		def save_list stk, del, sure
			stk.append do
				Dir.glob("save/**/*").reject{ |rj| File.directory?(rj) }.each_with_index do |s, i|
					flow do
						check { load_hero s } 
						para "#{i+1}. #{s.split('/')[1]}"
						button del, left: 160, top: 2, width: 60, height: 22 do
							if confirm(sure) then
								rm(s)
								stk.clear;
								save_list stk, del
							end
						end
					end
				end
			end
		end

		second.clear do
			image 'pics/themes/wheel.png', left: 5+@M_WH_L, top: 2+@M_WH_R, width: 785+@M_WH; c_width, c_height, step, start_rad, begin_rad, start_rad_up = 796+@M_WH, 800+@M_WH, Math::PI/6, 0, 362+@M_BR, 58+@M_SR
			@wheel_left = image "pics/buttons/wheel_arrow.png", left: 370, top: 280 do end.hide.rotate 180
			@wheel_right = image "pics/buttons/wheel_arrow.png", left: 425, top: 280 do end.hide
			@box_hero = flow left: 355+@M_SL_L, top: 355+@M_SL_T, width: 80, height: 80
			@save = flow left: 355+@M_SL_L, top: 440+@M_SL_T, width: 82, height: 30
			@left_button = image "pics/buttons/normal.png", left: 325+@M_SL_L, top: 357+@M_SL_T, width: 25, height: 80 do end.hide.rotate 180
			@right_button = image "pics/buttons/normal.png", left: 440+@M_SL_L, top: 357+@M_SL_T, width: 25, height: 80 do end.hide
			for q in 0..11
				angle = -1.46 + (Math::PI/21)*(q%3)
				q>1 ? ( ( ( q+1 )%3 ) == 1 ? start_rad += start_rad_up : nil ) : nil
				radius = begin_rad - start_rad
				for w in 0..11
					x, y = (@M_WH_L + c_width/2 + radius * Math.cos(angle)).round(0), (c_height/2 + radius * Math.sin(angle)).round(0)
					angle += step
					@box[w][q] = flow left: x - (@icon_size3 + 6)/2, top: y - (@icon_size3 + 6)/2, width: @icon_size3 + 6, height: @icon_size3 + 6
				end
			end
			@wheel_left.click { @wheel_left.style[:hidden] == true ? nil : @wheel_turn-=1; set_wheel }
			@wheel_right.click { @wheel_right.style[:hidden] == true ? nil : @wheel_turn+=1; set_wheel }
		end
	end

	def load_hero hero
		opts = YAML.load_file(hero)
		@ch_class = opts['ch_class']
		hero_pane
		set_hero 0, opts['hero'], opts['ch_primary'], opts['hero_secondary'], opts['hero_mastery'], opts['hero_perks'], opts['hero_level']
		set_wheel
	end

	def creature_pane first=@primary_pane, second=@secondary_pane
		set_main "CREATURE", FACTIONS, "factions", "factions"
		pane_t1 = (reading "panes/creature_pane/name.txt").split("\n")
		first.clear do
			@events["primary"] = true
			subtitle pane_t1[0], top: 15, align: "center"
			@creature_name = subtitle "", left: 5, top: 55, size: 20, align: "center"
			flow left: 70, top: 50, width: 250, height: 300 do
				left, top = 10
				image 'pics/themes/creature_spells.png', left: 65, top: 25, width: 240, height: 260
				@creature_stats = flow left: left + 20, top: 40, width: 240, height: 340, event: "primary"
				set ( image "pics/misc/s_attack.png", left: left, top: 45, width: 18 ), text: pane_t1[1], event: "primary"
				set ( image "pics/misc/s_defense.png", left: left, top: 68, width: 18 ), text: pane_t1[2], event: "primary"
				set ( image "pics/misc/s_damage.png", left: left, top: 91, width: 18 ), text: pane_t1[3], event: "primary"
				set ( image "pics/misc/s_initiative.png", left: left, top: 114, width: 18 ), text: pane_t1[4], event: "primary"
				set ( image "pics/misc/s_speed.png", left: left, top: 137, width: 18 ), text: pane_t1[5], event: "primary"
				set ( image "pics/misc/s_hitpoints.png", left: left, top: 160, width: 18 ), text: pane_t1[6], event: "primary"
				set ( image "pics/misc/s_mana.png", left: left, top: 183, width: 18 ), text: pane_t1[7], event: "primary"
				set ( image "pics/misc/s_shots.png", left: left, top: 206, width: 18 ), text: pane_t1[8], event: "primary"
				set ( image "pics/skills/active/hero_skill_recruitment.png", left: left, top: 229, width: 21 ), text: pane_t1[9], event: "primary"
			end
			subtitle pane_t1[10], top: 305, size: 22, align: "center"
			@cost_slot = flow left: 70, top: 340, width: 150, height: 30;
			subtitle pane_t1[11], left: 134, top: 370, size: 22
		end

		second.clear do
			flow left: 30, top: 70, width: 438, height: 660 do
				image 'pics/themes/pane2.png', width: 1.0, height: 1.0
				subtitle pane_t1[12], top: 10, stroke: white, align: "center", size: 30
				@pane2 = flow left: 0, top: 35, width: 1.0, height: 0.9, scroll: true, scroll_top: 100
			end
			flow left: 500, top: 45, width: 350, height: 690 do
				image 'pics/themes/creature_back.png', width: 433
				flow( left: 40, top: 40, width: 310, height: 40 ) { @faction_name = subtitle "", top: 5, size: 22, align: "center" }
				x, y = 63, 22;
				for q in 0..20
					x+=60
					(q + 1)%3 == 1 ? (  x=123; y+=80 ) : nil
					@box[q] = flow left: x, top: y, width: 52, height: 52
				end
			end
		end
		creature_pane_2_book
	end

	def creature_pane_2_book faction='TOWN_NO_TYPE'
		creatures = DB.execute( "select * from creatures where faction = '#{faction}' order by sequence ASC;" )
		@faction_name.replace reading "factions/#{faction}/name.txt"
		@box.map!(&:clear)
		creatures.each_with_index do |x, y|
			@box[y].append do
				set image("pics/creatures/#{x[0]}.png", left: 1, width: 50), text: reading("creatures/#{x[0]}/name.txt"), event: "secondary" do
					@creature_name.replace reading "creatures/#{x[0]}/name.txt"
					creature_abilities = x[16].split(",")
					creature_spells = x[10].split(",")
					creature_price = Hash[RESOURCE.zip x[17..-1]]
					#creature_spell_mastery = read_skills dir_xdb, 0, "<Mastery>", "</Mastery>"
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
						subtitle x[13], left: 164, top: 280
						i=0
						creature_spells.each do |spell|
							if spell.include?("ABILITY") then
								next
							else
								set (image "pics/spells/#{spell}.png", left: 155 - 40*(i%2), top: 170 - 40*(i/2), width: 37),
									header: (reading "spells/#{spell}/name.txt"),
									text: (reading "spells/#{spell}/desc.txt"),
									text2: (reading "spells/#{spell}/additional.txt"),
									event: "primary"
							end
							i+=1
						end
						@cost_slot.clear { set_resources creature_price }
					end
					@pane2.clear do
						creature_abilities.each_with_index do |a, d|
							para strong("#{(reading "abilities/#{a}/name.txt")}"), stroke: white, size: 14, align: "center", margin_left: 20, margin_right: 20, margin_top: 35
							para (reading "abilities/#{a}/desc.txt"), stroke: white, size: 12, justify: true, align: "center", margin_left: 20, margin_right: 20
						end
					end
				end
			end
		end
	end

	def spell_pane first=@primary_pane, second=@secondary_pane
		@spell_mastery, @spell_power = 0, 1
		schools = DB.execute( "select id from guilds" )
		set_main "SPELL", schools, "guilds", "guilds"
		pane_t1 = (reading "panes/spell_pane/name.txt").split("\n")
		first.clear do
			@events["primary"] = true
			subtitle pane_t1[0], top: 15, align: "center"
			subtitle pane_t1[1], top: 58, size: 18, align: "center"
			@bar = progress left: 81, top: 90, width: 200, height: 3
			5.times { |i| para i+1, left: 110+i*40, top: 95 }
			flow(left: 55, top: 120, width: 260, height: 160) { @spell_text = para "", align: "left", justify: true, size: 12 }
			pane_t1[2..5].each_with_index do |mastery, i|
				radio( left: 85+i*60, top: 310 ).click { @spell_mastery = i; spell_pane_effect };  
				flow(left: 35+i*60, top: 292 + 36*(i%2), width: 120, height: 25 ) { para mastery, size: 12, align: "center" }
			end
			set ( image "pics/misc/s_mana.png", left: 125, top: 371, width: @icon_size/3 ), text: pane_t1[7], width: 250, height: 40, event: "primary"
			@mana_f = flow left: 150, top: 369, width: 80, height: 70;
			set ( @box_level = flow(left: 255, top: 371, width: 50, height: 45 ) ), text: pane_t1[9], event: "primary"
		end
		set_power

		second.clear do
			flow left: 95, top: 130, width: 640, height: 540 do
				image 'pics/themes/spellbook.jpg', width: 1.0, height: 1.0
				16.times { |q| @box[q] = flow left: 60 + 125*(q%2) + 305*(q/8), top: 40 + 125*(q/2) - 500*(q/8), width: 90 }
			end
		end
	end

	def spell_pane_pages school
		spells = DB.execute( "select * from spells where guild = '#{school}' order by tier ASC;" )
		@box.map!(&:clear)
		spells.each_with_index do |spell, i|
			@box[i].clear do
				set( image("pics/spells/#{spell[0]}.png", width: 90, event: "secondary" ),
				header: (reading "spells/#{spell[0]}/name.txt"),
				text: (reading "spells/#{spell[0]}/desc.txt"),
				text2: (reading "spells/#{spell[0]}/additional.txt"),
				event: "secondary" ) { spell_pane_effect @spell_current=spell }
			end
		end
	end

	def spell_pane_effect spell=@spell_current
		unless spell.nil? then
			desc_vars = []
			spell_effect = spell[1].split(",").map(&:to_f)
			spell_increase = spell[2].split(",").map(&:to_f)
			pred = (@spell_mastery == 3) ? "pred_expert" : "pred"
			text_sp_effect = (reading "spells/#{spell[0]}/#{pred}.txt") || (reading "spells/#{spell[0]}/pred.txt") || (reading "spells/universal_prediction.txt")
			text_sp_effect.scan(Regexp.union(/<.*?>/,/<.*?>/)).each { |match| desc_vars << match }
			case spell[0]
			when "SPELL_BLADE_BARRIER" then
				special = DB.execute( "select * from spells_specials where id = '#{spell[0]}';" )
				spell_effect = special[0][1].split(',').map(&:to_i) + spell_effect[4..-1]
				spell_increase = special[0][2].split(',').map(&:to_i) + spell_increase[4..-1]
			when "SPELL_EARTHQUAKE" then
				spell_effect = spell_effect[4..-1] + spell_effect[0..3]
				spell_increase = Array.new(8, 0)
			when "SPELL_ARCANE_CRYSTAL" then
				special = DB.execute( "select * from spells_specials where id = '#{spell[0]}';" )
				spell_effect = [special[0][1], special[0][1], special[0][1], special[0][1]] + spell_effect
				spell_increase = [special[0][2], special[0][2], special[0][2], special[0][2]] + spell_increase
			when "SPELL_DEEP_FREEZE" then
				special = DB.execute( "select * from spells_specials where id = '#{spell[0]}';" )
				spell_effect.insert(4, special[0][1].split(',').map(&:to_i)).flatten!
				spell_increase.insert(4, special[0][2].split(',').map(&:to_i)).flatten!
			when "SPELL_SUMMON_HIVE" then
				special = DB.execute( "select * from spells_specials where id = '#{spell[0]}';" )
				spell_effect = special[0][1].split(',').map(&:to_f)
				spell_increase = special[0][2].split(',').map(&:to_f)
				spell_effect = spell_effect[4..7] + spell_effect[0..3]
				spell_increase = spell_increase[4..7] + spell_increase[0..3]
			end
			
			if spell[0].include?("_RUNE_") then
				text_sp_effect.clear;
				r_values = spell[-1].split(",")
				@mana_f.clear do
					off = 0
					r_values.each_with_index do |r, i|
						if r != '0' then
							image "pics/resources/#{RESOURCE[i]}.png", left: 40*(off%2), top: 22*(off/2);
							para r, left: 22 + 40*(off%2), top: 22*(off/2)
							off+=1
						end
					end
				end
			else
				@mana_f.clear { para spell[3] }
			end			
			
			case spell[0]
			when "SPELL_DIVINE_VENGEANCE" then
				b = spell_effect[@spell_mastery]
				s = spell_increase[@spell_mastery]
				text_sp_effect.sub! desc_vars[1], "#{trim b.round(2)}"
				text_sp_effect.sub! desc_vars[0], "#{trim s.round(2)}"
			when "SPELL_LAND_MINE" then
				desc_vars.each_with_index do |var, i|
					b = spell_effect[@spell_mastery+4*(1-i)]
					s = spell_increase[@spell_mastery+4*(1-i)]
					text_sp_effect.sub! var, "#{trim (b+s*@spell_power).round(2)}"
				end
			when "SPELL_CURSE" then
				desc_vars.each_with_index do |var, i|
					b = spell_effect[@spell_mastery+4*i]
					s = spell_increase[@spell_mastery+4*i]
					cast = (b+s*@spell_power).round(2)
					if i == 0 then
						cast < 0 ? cast = 0 : nil
					end
					text_sp_effect.sub! var, "#{trim cast}"
				end
			when "SPELL_ANIMATE_DEAD", "SPELL_RESURRECT" then
				desc_vars.each_with_index do |var, i|
					b = spell_effect[@spell_mastery+4*i]
					s = spell_increase[@spell_mastery+4*i]
					cast = (b+s*@spell_power).round(2)
					if i == 1 then
						cast < 0 ? cast = 0 : nil
					end
					text_sp_effect.sub! var, "#{trim cast}"
				end
			when "SPELL_DEFLECT_ARROWS", "SPELL_CELESTIAL_SHIELD", "SPELL_BLESS", "SPELL_FORGETFULNESS" then
				desc_vars.each_with_index do |var, i|
					b = spell_effect[@spell_mastery+4*i]
					s = spell_increase[@spell_mastery+4*i]
					cast = (b+s*@spell_power).round(2)
					if i == 0 then
						cast > 100 ? cast = 100 : nil
					end
					text_sp_effect.sub! var, "#{trim cast}"
				end
			else
				desc_vars.each_with_index do |var, i|
					b = spell_effect[@spell_mastery+4*i]
					s = spell_increase[@spell_mastery+4*i]
					text_sp_effect.sub! var, "#{trim (b+s*@spell_power).round(2)}"
				end
			end
			@spell_text.replace "#{text_sp_effect}"
			@bar.fraction = (spell[4].to_f/5).round(2)
		end
	end

	def set_power  ############# Adjusting spell efects
		@box_level.clear { subtitle "#{@spell_power}",left: 10, top: 3, size: 20 }
		@box_level.click do |press|
			@hovers.hide
			case press
			when 1 then @spell_power<100 ? @spell_power+=1 : nil
			when 2 then @spell_power = 1
			when 3 then @spell_power<91 ? @spell_power+=10 : nil
			end
			set_power
			spell_pane_effect
		end
	end

	def town_pane first=@primary_pane, second=@secondary_pane
		set_main "CLASSES", FACTIONS, "factions", "factions"
		pane_t1 = reading("panes/town_pane/name1.txt").split("\n")
		pane_t2 = reading("panes/town_pane/name2.txt").split("\n")
		pane_t2.map!{|x| x=x[0..-2]}
		t_dir = "panes/town_pane/changes"
		lg_cur = nil; # currently selected language

		first.clear do
			@events["primary"] = true
			@lg_list = []
			subtitle pane_t1[0], top: 15, align: "center"
			flow left: 55, top: 60, width: 200, height: 300 do
				para pane_t1[1], left: 5, top: 5, size: 12
				Dir.glob("text/**/*.pak").reject{ |rj| File.directory?(rj) }.each_with_index do |p, i|
					lg_name = p.split('/')[1].split('.')[0]
					@lg_list << lg_name
					@@lg == lg_name ? ( lg_cur = i ) : nil
				end
				list_box :items => @lg_list.map{|x| x}, choose: @lg_list[lg_cur] , left: 10, top: 30, width: 100 do |n|
					@@lg = n.text
					if @@lg != @lg_list[lg_cur] then
						@texts = Zip::File.open("text/#{@@lg}.pak")
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
				para pane_t1[2], left: 5, top: 60, size: 12
				gui_resolution = [ "1200x800", "1200x750" ]
				list_box :items => gui_resolution, choose: gui_resolution[@@res], left: 10, top: 85, width: 100 do |n|
					if n.text != gui_resolution[@@res] then
						@@res = gui_resolution.index(n.text)
						@@APP_DB.execute( "update settings set value='#{@@res}' where name = 'app_size';" )
						alert(pane_t1[3])
					end
				end
			end
		end

		second.clear do
			flow left: 50, top: 60, width: 730, height: 700 do	
				image 'pics/themes/town.png', width: 1.0, height: 1.0
				subtitle pane_t2[0], top: 47, align: "center"
				left, top, jump, move = 60, 130, 72, 50
				stack left: 50, top: 95, width: 0.85, height: 0.64 do
					pane_t2[1..6].each_with_index { |p, i| tagline p, align:  "left", stroke: white, top: 0 + jump*i }
				end
				set( (image "pics/changes/buildings.png", left: left, top: top, width: @icon_size2), header: pane_t2[7], text: reading("#{t_dir}/buildings.txt"), event: "secondary" ) { system "start http://www.moddb.com/mods/might-magic-heroes-55/news/mmh55-release-notes-rc10-beta-3" }
				set (image "pics/changes/heroes.png", left: left + move, top: top, width: @icon_size2), header: pane_t2[8], text: reading("#{t_dir}/heroes.txt"), event: "secondary"
				set (image "pics/misc/attack.png", left: left, top: top + jump, width: @icon_size2), header: pane_t2[9], text: reading("#{t_dir}/attack.txt"), event: "secondary"
				set (image "pics/misc/knowledge.png", left: left + move, top: top + jump, width: @icon_size2), header: pane_t2[10], text: reading("#{t_dir}/knowledge.txt"), event: "secondary"
				set( (image "pics/changes/arrangement.png", left: left + move*2, top: top + jump, width: @icon_size2), header: pane_t2[11], text: reading("#{t_dir}/arrangement.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=41320" }
				set (image "pics/changes/necromancy.png", left: left + move*3, top: top + jump, width: @icon_size2), header: pane_t2[12], text: reading("#{t_dir}/necromancy.txt"), event: "secondary"
				set (image "pics/changes/gating.png", left: left + move*4, top: top + jump, width: @icon_size2), header: pane_t2[13], text: reading("#{t_dir}/gating.txt"), event: "secondary"
				set( (image "pics/changes/spell_system.png", left: left + move*5, top: top + jump, width: @icon_size2), header: pane_t2[14], text: reading("#{t_dir}/spell_system.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=41320" }
				set (image "pics/changes/occultism.png", left: left + move*6, top: top + jump, width: @icon_size2), header: pane_t2[15], text: reading("#{t_dir}/occultism.txt"), event: "secondary"
				set (image "pics/changes/movement.png", left: left, top: top + jump*2, width: @icon_size2), header: pane_t2[16], text: reading("#{t_dir}/movement.txt"), event: "secondary"
				set( (image "pics/changes/generator.png", left: left + move, top: top + jump*2, width: @icon_size2), header: pane_t2[17], text: reading("#{t_dir}/generator.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=41341" }
				set (image "pics/changes/sites.png", left: left + move*2, top: top + jump*2, width: @icon_size2), header: pane_t2[18], text: reading("#{t_dir}/sites.txt"), event: "secondary"
				set( (image "pics/changes/artifacts.png", left: left + move*3, top: top + jump*2, width: @icon_size2), header: pane_t2[19], text: reading("#{t_dir}/artifacts.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=41528" }
				set (image "pics/changes/bloodrage.png", left: left, top: top + jump*3, width: @icon_size2), header: pane_t2[20], text: reading("#{t_dir}/bloodrage.txt"), event: "secondary"
				set( (image "pics/changes/manual.png", left: left + move, top: top + jump*3, width: @icon_size2), header: pane_t2[21], text: reading("#{t_dir}/manual.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=43030" }
				set (image "pics/changes/textures.png", left: left + move*2, top: top + jump*3, width: @icon_size2), header: pane_t2[22], text: reading("#{t_dir}/textures.txt"), event: "secondary"
				set (image "pics/changes/atb.png", left: left + move*3, top: top + jump*3, width: @icon_size2), header: pane_t2[23], text: reading("#{t_dir}/atb.txt"), event: "secondary"
				set (image "pics/changes/8skills.png", left: left, top: top + jump*4, width: @icon_size2), header: pane_t2[24], text: reading("#{t_dir}/8skills.txt"), event: "secondary"
				set (image "pics/changes/townportal.png", left: left + move, top: top + jump*4, width: @icon_size2), header: pane_t2[25], text: reading("#{t_dir}/townportal.txt"), event: "secondary"
				set( (image "pics/changes/pest.png", left: left + move*2, top: top + jump*4, width: @icon_size2), header: pane_t2[26], text: reading("#{t_dir}/pest.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=39792" }
				set( (image "pics/changes/governor.png", left: left + move*3, top: top + jump*4, width: @icon_size2), header: pane_t2[27], text: reading("#{t_dir}/governor.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=41977" }
				set (image "pics/changes/levels.png", left: left + move*4, top: top + jump*4, width: @icon_size2), header: pane_t2[28], text: reading("#{t_dir}/levels.txt"), event: "secondary"
				set (image "pics/changes/ai.png", left: left + move*5, top: top + jump*4, width: @icon_size2), header: pane_t2[29], text: reading("#{t_dir}/ai.txt"), event: "secondary"
				set( (image "pics/changes/dragonblood.png", left: left + move*6, top: top + jump*4, width: @icon_size2), header: pane_t2[30], text: reading("#{t_dir}/dragonblood.txt"), event: "secondary" ) { system "start http://www.moddb.com/mods/might-magic-heroes-55/news/might-magic-heroes-55-lore-update" }
				set( (image "pics/changes/duel_mode.png", left: left + move*7, top: top + jump*4, width: @icon_size2), header: pane_t2[31], text: reading("#{t_dir}/duel_mode.txt"), event: "secondary" ) { system "start https://www.moddb.com/mods/might-magic-heroes-55/news/mmh55-new-creature-duel-mode-rc10beta" }
				set (image "pics/changes/gryphnchain.png", left: left, top: top + jump*5, width: @icon_size2), header: pane_t2[32], text: reading("#{t_dir}/gryphnchain.txt"), event: "secondary"
				set (image "pics/changes/boots.png", left: left + move, top: top + jump*5, width: @icon_size2), header: pane_t2[33], text: reading("#{t_dir}/boots.txt"), event: "secondary"
			end
		end
	end

	def artifact_pane first=@primary_pane, second=@secondary_pane
		filters = DB.execute( "select filter from artifact_filter;" )
		set_main "ARTIFACT", filters , "buttons", "panes/artifact_pane/buttons"
		first.clear
		second.clear do
			flow left: 80, top: 108, width: 650, height: 600, scroll: true do
				image 'pics/themes/pane3.png', width: 1.0, height: 1.0
				subtitle reading("panes/artifact_pane/name.txt"), top: 15, align: "center", stroke: white
				@artifact_list = flow left: 0.05 , top: 0.1, width: 0.95, height: 0.9
			end
		end
	end

	def artifact_slot sort, first = @primary_pane
		if sort != 'micro_artifact' then
			first.clear do
				slots = (DB.execute( "select name from artifact_filter where filter = '#{sort}';" ))[0][0].split(",")
				slots.each_with_index { |slot, i| set_artifacts sort, slot, i }
			end
		else
			pane_t1 = reading("panes/artifact_pane/buttons/micro_artifact/pane1.txt").split("\n")
			protection_coef = DB.execute( "select id from micro_protection;" )
			p_max = DB.execute( "select effect from micro_artifact_effect where id='MAE_MAGIC_PROTECTION';" )[0][0]
			@protection = []
			@knowledge = 1
			protection_coef.each { |p| @protection << p_max*p[0] }
			first.clear do
				subtitle pane_t1[0], top: 15, align: "center"
				@micro_pane = stack left: 45, top: 60, width: 280, height: 280;
				set ( @box_level = ( flow left: 255, top: 371, width: 50, height: 45 ) ),text: pane_t1[2], event: "primary"
				set_knowledge
			end

			@artifact_list.clear do
				image 'pics/themes/micro_pane.png', left: 120, top: 15
				image 'pics/themes/micro_inventory.png', left: 120, top: 260
				subtitle pane_t1[3], left: 152, top: 20, size: 18, stroke: white
				subtitle pane_t1[4], left: 310, top: 20, size: 18, stroke: white
				subtitle "x1      x2       x3", left: 263, top: 175, size: 18, stroke: white
				subtitle pane_t1[5], top: 200, size: 18, stroke: white, align: "center"
				@shells = (DB.execute( "select id from micro_artifact_shell;" ))
				@micro_eff = (DB.execute( "select id from micro_artifact_effect;" ))
				@state, @micro_slot, @up, @down, @inventory = [0,0,0], [], [], [], []
				@shell_slot = flow(left: 151, top: 80, width: 65, height: 65)
				@shell_up = image("pics/buttons/horizontal.png", left: 152, top: 53, width: 60, height: 25)
				@shell_down = (image("pics/buttons/horizontal.png", left: 152, top: 150, width: 60, height: 25).rotate 180)
				@shell_ch, @shell_lvl = 0, 1
				set_shell
				l = 249
				3.times do |i|
					@micro_slot << flow(left: l+66*i, top: 81, width: 65, height: 65)
					@up << image("pics/buttons/horizontal.png", left: l+1+67*i, top: 53, width: 60, height: 25).hide
					@down << (image("pics/buttons/horizontal.png", left: l+1+67*i, top: 150, width: 60, height: 25).hide.rotate 180)
					set_effect i, pane_t1[9]
				end
				@up[0].show
				@down[0].show
				10.times { |i| @inventory << flow(left: 131+67*(i%5), top: 338 + 68*(i/5), width: 65, height: 65) }
				button "#{pane_t1[6]}", left: 490, top: 100, width: 100 do
					if @shell_ch == 0 || ( @state.same_values? && @state[0] = 0) then
						alert(pane_t1[7])
					else
						a, b, temp, shell_text = 0, 0, [], ""
						@state.each_with_index { |s, i|	(s == 0) ? next : (temp << s) }
						a, b = temp[0..1].sort
						val = "#{a}#{b}".to_i
						sub = (
						case val
						when 12..19 then 2
						when 23..29 then 5
						when 34..39 then 9
						when 45..49 then 14
						when 56..59 then 20
						when 67..69 then 27
						when 78..79 then 35
						when 89 then 44
						end )
						name = reading("micro_artifacts/#{@sh_id}/name.txt")
						case temp.count
						 when 0,1 then suffix = reading("micro_artifacts/#{@micro_eff[@state[0]][0]}/suffix.txt")
						 when 2 then  mod = val - sub
									  prefix = reading("micro_artifacts/MA_PREFIXES/f_#{mod}.txt")
						 when 3 then  mod = val - sub
									  prefix = reading("micro_artifacts/MA_PREFIXES/f_#{mod}.txt")
									  suffix = reading("micro_artifacts/#{@micro_eff[@state[2]][0]}/suffix.txt")
						end
						shell_text = "#{prefix} #{name} #{suffix} (#{@knowledge})"
						@inventory.each { |v| v.contents[0].nil? ? ( create_micro v, shell_text, @state.dup, pane_t1[10]; break ) : nil }
					end
				end
				subtitle pane_t1[8], left: 250, top: 285, size: 18, stroke: white
				button("#{pane_t1[9]}", left: 198, top: 490, width: 200 ) { @inventory.map!(&:clear) }
			end
		end
	end

	def create_micro box, name, effects, txt_cost
		txt, price = [], []
		effects.each_with_index do |e, i|
			e == 0 ? next : nil
			id = @micro_eff[e][0]
			values = DB.execute( "select effect from micro_artifact_effect WHERE id='#{id}';" )[0][0]
			cost = DB.execute( "select gold, Wood, ore, mercury, crystal, sulfur, gem from micro_artifact_effect WHERE id='#{id}';" )
			price << cost[0..-1][0].map! { |x| x*(i+1) }
			if id == 'MAE_MAGIC_PROTECTION' then
				txt << (reading("micro_artifacts/#{id}/effect.txt").sub! '<value>', (@protection[@knowledge > 59 ? 59 : @knowledge-1 ].floor.to_s))
			else
				txt << (reading("micro_artifacts/#{id}/effect.txt").sub! '<value>', ((1 + values*@knowledge).floor.to_s))
			end
		end
		price = Hash[ RESOURCE.zip price.transpose.map { |x| x.reduce(:+) } ]
		box.append do
			set (image "pics/micro_artifacts/#{@sh_id}#{@shell_lvl}.png", width: 60), text: name, event: "secondary" do
				@micro_pane.clear do
					subtitle name, size: 18, align: "center"
					txt.each { |t| para t, margin_left: 20, margin_right: 20 }
					subtitle txt_cost, top: 210, size: 18, align: "center"
					flow(left: 38, top: 245, width: 300, height: 50 ) { set_resources price }
				end
			end
		end
	end
	
	def set_knowledge
		@box_level.clear { subtitle "#{@knowledge}", left: 10, top: 3, size: 20 }
		@box_level.click do |press| ############# Adjusting spell efects
			@hovers.hide
			case press
			when 1 then @knowledge<100 ? @knowledge+=1 : nil
			when 2 then @knowledge = 1
			when 3 then @knowledge<91 ? @knowledge+=10 : nil
			end
			set_knowledge
			spell_pane_effect
		end
	end
		
	def set_shell
		@shell_lvl = 3
		@sh_id = @shells[@shell_ch][0]
		@state.map{|x| @shell_lvl-= (x==0 ? 1 : 0) }
		@shell_lvl+=1 if @shell_lvl == 0
		@shell_slot.clear do
			if @shell_ch!=0 then
				set (image "pics/micro_artifacts/#{@sh_id}#{@shell_lvl}.png", width: 60),
				text: reading("micro_artifacts/#{@sh_id}/desc.txt"), 
				header: reading("micro_artifacts/#{@sh_id}/name.txt"), 
				event: "secondary"
			end
		end
		@shell_up.click { @shell_ch < 4 ? ( @shell_ch+=1;set_shell) : nil }
		@shell_down.click { @shell_ch > 0 ? ( @shell_ch-=1;set_shell) : nil }
	end

	def set_effect i, txt_cost
		@micro_slot[i].clear do
			value = 0
			@state[i]==0 ? next : nil
			id = @micro_eff[@state[i]][0]
			img = image "pics/micro_artifacts/#{id}.png", width: 60
			name = reading("micro_artifacts/#{id}/name.txt")
			desc = reading("micro_artifacts/#{id}/desc.txt")
			values = DB.execute( "select effect from micro_artifact_effect WHERE id='#{id}';" )[0][0]
			cost = DB.execute( "select gold, Wood, ore, mercury, crystal, sulfur, gem from micro_artifact_effect WHERE id='#{id}';" )
			price = Hash[RESOURCE.zip cost[0..-1][0]]
			set img, text: desc, header: name, event: "secondary" do
			case id
			when 'MAE_HASTE' then value = (values*@knowledge).floor.to_s
			when 'MAE_MAGIC_PROTECTION' then value = @protection[@knowledge > 59 ? 59 : @knowledge-1 ].floor.to_s
			else value = (1+values*@knowledge).floor.to_s
			end
			txt = reading("micro_artifacts/#{id}/effect.txt").sub! '<value>', value
				@micro_pane.clear do
					subtitle "#{name}", size: 18, align: "center"
					para txt, margin_left: 20
					subtitle txt_cost, size: 18, top: 200, align: "center"
					stack(width: 280, top: 240, height: 30, margin_left: 20) { set_resources price }
				end
			end
		end
		set_shell
		@up[i].click do
			(@state[i-1]!=0 || i==0) ? nil : next
				@state[i] = (go_up @state[i], @state[i+1], @micro_eff.length)
				set_effect i, txt_cost
				show_hide_buttons i
		end
		@down[i].click do
			(@state[i-1]!=0 || i==0) ? nil : next
			@state[i] = (go_down @state[i], @state[i+1], @micro_eff.length)
			set_effect i, txt_cost
			show_hide_buttons i
		end
	end

	def show_hide_buttons i
		if i<@state.count-1 then
			if @state[i]!=0 then
				[@up[i+1], @down[i+1]].map!(&:show)
			else
				[@up[i+1], @down[i+1]].map!(&:hide)
			end
		end
	end
	
	def go_up value, next_value, max
		max.times do |k|
			(value+k+1==max) ? ( (next_value.nil? || next_value==0) ? (return 0) : value=1-(k+1) ) : nil
			@state.include?(value+k+1) ? nil : (return value+k+1)
		end
	end
	
	def go_down value, next_value, max
		max.times do |k|
			value-(k+1)<=0 ? ( ((next_value.nil? || next_value==0) && value!=0) ? (return 0) : value=max+k ) : nil
			@state.include?(value-(k+1)) ? nil : (return value-(k+1))
		end
	end

	def set_artifacts sort, a, i
		button reading("panes/artifact_pane/buttons/#{sort}/#{a}.txt"), left: 68+120*(i%2), top: 70+35*(i/2), width: 100 do
			@artifact_list.clear do
				case sort
				when "by_slot" then DB.execute( "select id, cost from artifacts where slot = '#{a}';" ).each { |art, cost| add_artifact art, cost}
				when "by_price" then DB.execute( "select id, cost from artifacts where cost BETWEEN #{a.to_i - 9999} AND #{a.to_i};" ).each { |art, cost| add_artifact art, cost}
				when "by_rarity" then DB.execute( "select id, cost from artifacts where type = '#{a}';" ).each { |art, cost| add_artifact art, cost}
				when "by_modifier" then DB.execute( "select id, cost from artifacts where #{a} > 0;" ).each { |art, cost| add_artifact art, cost}
				when "by_set" then DB.execute( "select id, cost from artifacts where art_set = '#{a}';" ).each { |art, cost| add_artifact art, cost}
				end
			end
		end
	end

	def add_artifact artifact, cost
		list=@artifact_list.contents.count
		@artifact_list.append do
			set ( image "pics/artifacts/#{artifact}.png", left: 5 + 75*(list%8), top: 5 + (list/8)*70, width: @icon_size),
			text: reading("artifacts/#{artifact}/desc.txt"),
			header: reading("artifacts/#{artifact}/name.txt") + "(#{cost})",
			text2: reading("artifacts/#{artifact}/additional.txt"),
			event: "secondary"
		end
	end

	def main_menu
		@backgr = image 'pics/themes/background.jpg', left: 0, top: 0, width: app.width, height: app.height
		menu = reading("panes/main_menu.txt").split("\n")
		@app = flow height: app.height do
			stack left: 0, top: 0, width: 0.291 do
				image 'pics/themes/factions_pane.png', left: 8, top: 68, width: 349, height: 201
				image 'pics/themes/manuscript.png', left: 20, top: 270, width: 330

				@main_slot = flow left: 61, top: 110 do
					8.times { |i| flow left: (@icon_size+1)*(i%4), top: (@icon_size+1)*(i/4), width: @icon_size, height: @icon_size }
				end
				@primary_pane = stack left: 0, top: 280, width: 1.0, height: 500   # LEFT  - heroes stats and sheets
			end
			set( ( image "pics/buttons/town_index.png", left: 32, top: 25, width: 45, height: 45 ), text: menu[0], event: "menu" ) { town_pane }
			set( ( image "pics/buttons/hero_index.png", left: 92, top: 25, width: 45, height: 45 ), text: menu[1], event: "menu" ) { hero_pane }
			set( ( image "pics/buttons/creature_index.png", left: 152, top: 25, width: 45, height: 45 ), text: menu[2], event: "menu" ) { creature_pane }
			set( ( image "pics/buttons/spell_index.png", left: 212, top: 25, width: 45, height: 45 ), text: menu[3], event: "menu" ) { spell_pane }
			set( ( image "pics/buttons/artifact_index.png", left: 272, top: 25, width: 45, height: 45 ), text: menu[4], event: "menu" ) { artifact_pane }

			@secondary_pane = stack left: 0.292, top: 0, width: 0.66, height: 0.99 # RIGHT - SKILLWHEEL TABLE
			stack left: @@a_width[@@res] - 60, top: @@a_height[@@res] - 60, width: 60, height: 60 do
				image "pics/themes/about.png"
				set contents[0], text: "Credits", event: "secondary" do
					@credits.nil? ? nil : @credits.close
					@credits=window(title: "About", width: 450, height: 200, resizable: false) do
						para File.read("text/credits.txt"), justify: true
						button( "www.heroescommunity.com", left: 110, top: 150 ) { system("start http://heroescommunity.com/viewthread.php3?TID=42212") }
					end
				end
			end
		end
	end

######################## MAIN STARTS HERE #########

	main_menu  # define General app slots
	hero_pane  # launch hero module

end