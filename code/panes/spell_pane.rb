def spell_pane 
	@spell_mastery, sp, @hero_lvl, @guild_lvl, @dblood_lvl = 0, 1, 1, 1, 1
	schools = DB.execute( "select id from guilds" )
	set_main "SPELL", schools, "guilds", "guilds"
	@primary_pane.clear
	@secondary_pane.clear do
		flow left: 95, top: 130, width: 640, height: 540 do
			image 'pics/themes/spellbook.jpg', width: 1.0, height: 1.0
			16.times { |q| @box[q] = flow left: 60 + 125*(q%2) + 305*(q/8), top: 40 + 125*(q/2) - 500*(q/8), width: 90 }
		end
	end
end

def spell_pane_pages school
	spells = DB.execute( "select * from spells where guild = '#{school}' order by tier ASC;" )
	@box.map!(&:clear)
	if school == "MAGIC_SCHOOL_SPECIAL" then
		summon_pane_set
		spells.each_with_index do |spell, i|
			@box[i].clear do
				set( image("pics/spells/#{spell[0]}.png", width: 80, event: "secondary" ),
				header: (reading "spells/#{spell[0]}/name.txt"),
				text: (reading "spells/#{spell[0]}/desc.txt"),
				text2: (reading "spells/#{spell[0]}/additional.txt"),
				event: "secondary" ) { summon_pane_update spell }
			end
		end
	else
		spell_pane_magic
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
end

def spell_pane_effect spell=@spell_current
	unless spell.nil? then
		desc_vars, sp = [], @l_box.show 
		spell_effect = spell[1].split(",").map(&:to_f)
		spell_increase = spell[2].split(",").map(&:to_f)
		pred = (@spell_mastery == 3) ? "pred_expert" : "pred"
		text_sp_effect = (reading "spells/#{spell[0]}/#{pred}.txt") || (reading "spells/#{spell[0]}/pred.txt") || (reading "spells/universal_prediction.txt")
		text_sp_effect.scan(Regexp.union(/<.*?>%/,/<.*?>/)).each { |match| desc_vars << match }
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
			@mana_f.clear do
				mass_mana = MASS_SPELLS.include?(spell[0]) ? 4*spell[3] : (EMPOWERED_SPELLS.include?(spell[0]) ? 2*spell[3] : 0)			
				para (mass_mana != 0 ? "#{spell[3]}/#{mass_mana}" : "#{spell[3]}")
			end
		end			
		case spell[0]
		when "SPELL_DIVINE_VENGEANCE" then
			b = spell_effect[@spell_mastery]
			s = spell_increase[@spell_mastery]
			text_sp_effect.sub! desc_vars[1], "#{trim b.round(2)}"
			text_sp_effect.sub! desc_vars[0], "#{trim s.round(2)}"
		when "SPELL_LAND_MINE" then
			desc_txt = [ "Mines", "Damage" ]
			desc_vars.each_with_index do |var, i|
				b = spell_effect[@spell_mastery+4*(1-i)]
				s = spell_increase[@spell_mastery+4*(1-i)]
				text_sp_effect.sub! var, "#{trim (b+s*sp).round(2)} /#{b.round(1)}+#{s.round(1)}*SP/"
			end
			
		when "SPELL_CURSE" then
			desc_vars.each_with_index do |var, i|
				b = spell_effect[@spell_mastery+4*i]
				s = spell_increase[@spell_mastery+4*i]
				cast = (b+s*sp).round(2)
				if i == 0 then
					cast < 0 ? cast = 0 : nil
				end
				text_sp_effect.sub! var, "#{trim cast}#{["%", ""][i]} /#{b.round(0)}+#{s.round(0)}*SP/"
			end
		when "SPELL_ANIMATE_DEAD", "SPELL_RESURRECT" then
			desc_vars.each_with_index do |var, i|
				b = spell_effect[@spell_mastery+4*i]
				s = spell_increase[@spell_mastery+4*i]
				cast = (b+s*sp).round(2)
				(cast = 0 if cast < 0) if i == 1
				text_sp_effect.sub! var, "#{trim cast}#{["", "%"][i]} /#{b.round(0)}+#{s.round(1)}*SP/"
			end
		when "SPELL_DEFLECT_ARROWS", "SPELL_CELESTIAL_SHIELD", "SPELL_BLESS", "SPELL_FORGETFULNESS" then
			desc_vars.each_with_index do |var, i|
				b = spell_effect[@spell_mastery+4*i]
				s = spell_increase[@spell_mastery+4*i]
				cast = (b+s*sp).round(2)
				(cast = 100 if cast > 100) if i == 0
				text_sp_effect.sub! var, "#{trim cast}#{["%", " "][i]} /#{b.round(1)}+#{s}*SP/"
			end
		when "SPELL_DIMENSION_DOOR", "SPELL_TOWN_PORTAL", "SPELL_SUMMON_BOAT", "SPELL_SUMMON_CREATURES" then text_sp_effect = "";
		when "SPELL_HASTE", "SPELL_SLOW", "SPELL_VAMPIRISM", "SPELL_REGENERATION", "SPELL_HYPNOTIZE", "SPELL_BERSERK" then
			desc_vars.each_with_index do |var, i|
				b = spell_effect[@spell_mastery+4*i]
				s = spell_increase[@spell_mastery+4*i]
				dmg = (b+s*sp).round(2)
				text_sp_effect.sub! var, "#{trim (b+s*sp).round(2)}#{["%", ""][i]} /#{b.round(1)}+#{s.round(2)}*SP/"
			end
		else
			if spell[5] == "MAGIC_SCHOOL_DESTRUCTIVE" and spell[0] != "SPELL_DEEP_FREEZE" or spell[0] == "SPELL_MAGIC_FIST" then
				b = spell_effect[@spell_mastery]
				s = spell_increase[@spell_mastery]
				dmg = (b+s*sp).round(2)
				text_sp_effect = (text_sp_effect + reading("spells/empowered_prediction.txt"))
				text_sp_effect.sub! desc_vars[0], "#{trim dmg} /#{b.round(0)}+#{s.round(0)}*SP/"
				text_sp_effect.sub! "<value=damage2>", "#{trim dmg*1.5}"
			else
				desc_vars.each_with_index do |var, i|
					b = spell_effect[@spell_mastery+4*i]
					s = spell_increase[@spell_mastery+4*i]
					dmg = (b+s*sp).round(2)
					if [ "SPELL_EARTHQUAKE", "SPELL_CONJURE_PHOENIX"].include?(spell[0]) then
						text_sp_effect.sub! var, "#{trim (b+s*sp).round(2)}"
					else
						text_sp_effect.sub! var, "#{trim (b+s*sp).round(2)} /#{b.round(1)}+#{s.round(2)}*SP/"
					end
				end
			end
		end
		@spell_text.replace "#{text_sp_effect}"
		@bar.fraction = (spell[4].to_f/5).round(2)
	end
end

def summon_pane_update summon
	@sh_box.update{ summon_text(summon) }
	@sg_box.update{ summon_text(summon) } 
	@sd_box.update{ summon_text(summon) }
end

def summon_text(summon=nil)
	unless summon.nil? then
		desc_vars = []
		name = (reading "spells/#{summon[0]}/name.txt")
		desc_text = (reading "spells/summon_formula.txt")
		desc_text.scan(Regexp.union(/<.*?>/,/<.*?>/)).each { |match| desc_vars << match }
		#debug("sh_box = #{@sh_box.show}; sd_box = #{@sd_box.show}; sg_box = #{@sg_box.show}")
		limit = @sh_box.show*@sd_box.show > 600 ?  600 : @sh_box.show*@sd_box.show
		units = (Math.sqrt(limit)*(1 + @sg_box.show)/summon[1]).round
		[ units, @sh_box.show, @sd_box.show, @sg_box.show, summon[1] ].each_with_index do |t,i|
			desc_text.sub! desc_vars[i], "#{t}"
		end
		@spell_header.replace "#{name}"
		@spell_text.replace "#{desc_text}"
	end
end

def summon_pane_set summon=@spell_current	
	pane_t1 = (reading "panes/spell_pane/summon.txt").split("\n")
	@primary_pane.clear do
		@events["primary"] = true
		subtitle pane_t1[0], align: "center"
		flow left: 50, top: 60, width: 255, height: 270 do
			@spell_header = para "", top: 5, align: "center", justify: true, size: 14
			@spell_text = para "", left: 5, top: 45, align: "left", justify: true, size: 12 
		end
		(@sh_box = click_box).create(left: 125, top: 263, val: 1, max: 100, min: 1, jump: 10, text: pane_t1[1])
		(@sg_box = click_box).create(left: 185, top: 263, val: 1, max: 5, min: 1, jump: 1, text: pane_t1[2])
		(@sd_box = click_box).create(left: 255, top: 263, val: 1, max: 100, min: 1, jump: 10, text: pane_t1[3])
		set ( image "pics/changes/dragonblood.png", left: 130, top: 335, width: 30), text: pane_t1[4], event: "primary"
		set ( image "pics/guilds/mageguild.png", left: 196, top: 335, width: 30), text: pane_t1[5], event: "primary"
	end		
end

def spell_pane_magic
	pane_t1 = (reading "panes/spell_pane/name.txt").split("\n")
	@primary_pane.clear do
		@events["primary"] = true
		subtitle pane_t1[0], align: "center"
		subtitle pane_t1[1], top: 43, size: 22, align: "center"
		@bar = progress left: 81, top: 90, width: 200, height: 3
		5.times { |i| para i+1, left: 110+i*40, top: 95 }
		flow(left: 55, top: 120, width: 260, height: 160) { @spell_text = para "", left: 0, top: 0, align: "left", size: 12 }
		pane_t1[2..5].each_with_index do |mastery, i|
			radio(:mastery, left: 85+i*60, top: 310).click { @spell_mastery = i; spell_pane_effect };  
			flow(left: 35+i*60, top: 292 + 36*(i%2), width: 120, height: 25 ) { para mastery, size: 12, align: "center" }
		end
		set ( image "pics/misc/s_mana.png", left: 125, top: 371, width: @icon_size/3 ), text: pane_t1[7], width: 250, height: 40, event: "primary"
		@mana_f = flow left: 150, top: 369, width: 80, height: 70;
		(@l_box = click_box).create(left: 255, top: 263, val: 1, max: 100, min: 1, jump: 10, text: pane_t1[9])
		@l_box.update { spell_pane_effect }
	end
end