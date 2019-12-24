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
			subtitle pane_t1[0], align: "center"	### Classes header
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
				set ( @box_level = ( flow left: 255, top: 115, width: 50, height: 35) ), text: pane_t1[2], event: "primary"
				set ( image "pics/misc/s_damage.png", left: 80, top: 11, width: @icon_size/3 ), text: pane_t1[3], width: 500, height: 40, event: "primary"
				set ( image "pics/misc/s_defense.png", left: 167, top: 11, width: @icon_size/3 ), text: pane_t1[4], width: 500, height: 40, event: "primary"
				set ( image "pics/misc/s_mana.png", left: 253, top: 11, width: @icon_size/3 ), text: pane_t1[5], width: 250, height: 40, event: "primary"
				subtitle pane_t1[6], left: 70, top: 290, size: 22 ### Mana text
				@hero_spell_pane = flow left: 80, top: 70, height: 44, width: 170;
				button pane_t1[7], left: 120, top: 145, height: 20, width: 120 do
					primary_t1.hide
					first.append do
						primary_t2 = flow width: 1.0, height: 0.9 do
							subtitle pane_t1[8], align: "center"
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

	second.clear do
		image 'pics/themes/wheel.png', left: 5+@M_WH_L, top: 2+@M_WH_R, width: 785+@M_WH; c_width, c_height, step, start_rad, begin_rad, start_rad_up = 796+@M_WH, 800+@M_WH, Math::PI/6, 0, 362+@M_BR, 58+@M_SR
		@wheel_left = image "pics/buttons/wheel_arrow.png", left: 355 + @ARR_L, top: 290 + @ARR_T do end.hide.rotate 180
		@wheel_right = image "pics/buttons/wheel_arrow.png", left: 410 + @ARR_L, top: 290 + @ARR_T do end.hide
		@box_hero = flow left: 355+@M_SL_L, top: 355+@M_SL_T, width: 80, height: 80
		@save = flow left: 351+@M_SL_L, top: 440+@M_SL_T, width: 82, height: 30
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
		button s_txt[0], left: 0, top: 0, width: 90, height: 28 do
			options = ['hero', 'ch_class', 'ch_primary', 'hero_secondary', 'hero_mastery', 'hero_perks', 'hero_level' ]
			user_data = [ hero, @ch_class, @ch_primary, @hero_secondary, @hero_mastery, @hero_perks, @hero_level ]
			data = Hash[options.map {|x| [x, ""]}]
			user_data.each_with_index { |n, i| data[options[i]] = n; }
			fl = file_exists s_txt[1], s_txt[2]
			( File.open("save/#{fl}", "w") { |f| f.write(data.to_yaml) } ) unless (fl == "" or fl == nil)
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

def set_level
	@box_level.clear { subtitle "#{@hero_level}", top: -27, align: "center", size: 28 }
	set_primary
	@box_level.click do |press| ############# Hero leveling up and gaining of primary stats based on chance
		@hovers.hide
		case press
		when 1 then leveling if @hero_level<100
		when 2 then @hero_level = 1; @ch_primary = @hero_primary + @skill_chance;
		when 3 then 10.times do leveling end if @hero_level<91
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
		break if ( yy = y - @wheel_turn ) > 11
		set_wheel_tree skill[0], yy
	end
end

def set_wheel_tree skill, yy, source='skill'   	###Populates a tree on the wheel
	status = @hero_secondary.index(skill)
	mastery = status.nil? ? 0 : MASTERIES[:"#{@hero_mastery[status]}"]
	perks = DB.execute( "select name from skills where tree='#{skill}' and type='SKILLTYPE_STANDART_PERK' order by sequence ASC;" )
	p_count, branch, branch_count,  = 0, [], [ 0, 0, 0 ] 		###skill branch; number of active perks
	perks.each_with_index do |b, i|
		branch << (get_branch b[0])
		branch[i].each { |p| (p_count+=1; branch_count[i]+=1) if @hero_perks.include?(p) }
	end

	if source == 'skill' then
		if mastery == 0 then
			@hero_perks-=(branch[0] + branch[1] + branch[2] )
			p_count, branch_count = 0, [ 0, 0, 0 ]
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
	return branch if next_skill.nil? 
	get_branch next_skill[0], branch
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
						save_list stk, del, sure
					end
				end
			end
		end
	end
end
	
def file_exists ask1, ask2
	s_file = ask(ask1)
	File.file?("save/#{s_file}") ? ( confirm(ask2) ? nil : (return "") ) : nil
	return s_file
end
	
def load_hero hero
	opts = YAML.load_file(hero)
	@ch_class = opts['ch_class']
	hero_pane
	set_hero 0, opts['hero'], opts['ch_primary'], opts['hero_secondary'], opts['hero_mastery'], opts['hero_perks'], opts['hero_level']
	set_wheel
end