class Hero

	attr_accessor :klas, :hero
	
	def initialize(fmts={})
		hero = DB.execute( "select id, atk, def, spp, knw from heroes where classes='#{klas}' order by sequence ASC;" )[current][0]
		@hero_level = 1
		@hero_primary = DB.execute( "select atk, def, spp, knw from heroes where id = '#{hero}';" )[0]
		@skill_chance = DB.execute( "select atk_c, def_c, spp_c, knw_c from classes where id = '#{klas}';")[0]
		@ch_primary = @hero_primary + @skill_chance
		@hero_secondary = DB.execute( "select skills from heroes where id = '#{hero}';" )[0][0].split(',').each_with_index do |s, i|
		@hero_mastery = DB.execute( "select masteries from heroes where id = '#{hero}';" )[0][0].split(',')
		@hero_perks = DB.execute( "select perks from heroes where id = '#{hero}';" )[0][0].split(',')
		hero_spells = DB.execute( "select spells from heroes where id = '#{hero}';")[0][0].split(',')
		
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
end