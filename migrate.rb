require 'sqlite3'
require 'code/readskills'
#FileUtils.rm "skillwheel1.db"
Shoes.app do
	db = SQLite3::Database.new "skillwheel.db"
#=begin
	############ create table with faction list and native spells
	db.execute <<-SQL
	  create table factions (
		name string
	  );
	SQL

	(read_skills "design/factions.txt").each do |n|
	  db.execute "insert into factions values ( ? )", n
	end

	############ create table with classes list, primary stats and secondary skills
	 db.execute <<-SQL
	  create table classes (
		name string,
		atk int,
		def int,
		spp int,
		knw int,
		atk_c int,
		def_c int,
		spp_c int,
		knw_c int,
		skills string,
		faction string
	  );
	SQL

	Dir.glob("design/factions/**/*").reject{ |rj| File.directory?(rj) }.each do |fn|
		file_name = fn.split("/")[-1].split('.')[0]
		(read_skills fn).each do |n| 
			primary = read_skills "design/classes/#{n}/primary.txt"
			secondary = read_skills "design/classes/#{n}/secondary.txt"
			db.execute "insert into classes values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", n, primary, secondary.join(","), file_name
		end
	end

	############ create table skilltree table
	db.execute <<-SQL
	  create table skills (
		name string,
		tree string
	  );
	  SQL
	Dir.glob("design/skilltree/**/*").reject{ |rj| File.directory?(rj) }.each_with_index do |fn, i|
		file_name = fn.split("/")[-1].split('.')[0]
		(read_skills fn).each { |n| db.execute "insert into skills values ( ?, ?)", n, file_name }
	end
	
	### create creature table 
	db.execute <<-SQL
	create table creature_stats (
	  name string,
	  ability string,
	  spell string,
	  attack int,
	  defense int,
	  min_damage int,
	  max_damage int,
	  Initiative int,
	  speed int,
	  health int,
	  mana int,
	  shots int,
	  weekly_growth int,
	  tier int,
	  faction string
	  )
	  SQL

	Dir.glob("design/creatures/factions/**/*").reject{ |rj| File.directory?(rj) }.each do |f|
		faction = f.split("/")[-1].split('.')[0]
		(read_skills f).each do |creature_name| 
	#Dir.glob("design/creatures/creatures/**/*").reject{ |rj| File.directory?(rj) }.each do |fn|
			#creature_name = fn.split("/")[-1].split('.')[0]
			fn = "design/creatures/creatures/#{creature_name}.xdb"
			#debug(read_skills fn)
			@creature_abilities = read_skills fn, 0, "<Item>ABILITY_", "</Item>"
			(read_skills fn, 0, "<Range>", "</Range>").include?('0') ? nil : @creature_abilities.unshift("SHOOTER")
			(read_skills fn, 0, "<CombatSize>", "</CombatSize>").include?('2') ? @creature_abilities.unshift("LARGE_CREATURE") : nil
			@creature_spells  = read_skills fn, 0, "<Spell>SPELL_", "</Spell>"
			@creature_spells.each { |spell| spell.include?("ABILITY") ? @creature_spells - [spell] : nil }
			attack = read_skills fn, 0, "<AttackSkill>", "</AttackSkill>" 
			defense = read_skills fn, 0, "<DefenceSkill>", "</DefenceSkill>" 
			min_damage = (read_skills fn, 0, "<MinDamage>", "</MinDamage>")[0]
			max_damage = (read_skills fn, 0, "<MaxDamage>", "</MaxDamage>")[0]
			initiative = read_skills fn, 0, "<Initiative>", "</Initiative>" 
			speed = read_skills fn, 0, "<Speed>", "</Speed>"
			health = read_skills fn, 0, "<Health>", "</Health>"
			mana = read_skills fn, 0, "<SpellPoints>", "</SpellPoints>"
			shots = read_skills fn, 0, "<Shots>", "</Shots>"
			weeklygrowth = read_skills fn, 0, "<WeeklyGrowth>", "</WeeklyGrowth>"
			tier = read_skills fn, 0, "<CreatureTier>", "</CreatureTier>"
			db.execute "insert into creature_stats values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", creature_name, @creature_abilities.join(','),@creature_spells.join(','),
			attack,defense,min_damage,max_damage,initiative,speed,health,mana,shots,weeklygrowth,tier, faction
		end
	end
	############ create table with all spell schools
	db.execute <<-SQL
	  create table spell_schools (
		name string
	  );
	  SQL
	  
	 [["dark"], ["light"], ["destruction"], ["summoning"], ["adventure"], ["runic"], ["warcry"]].each do |sch|
		db.execute "insert into spell_schools values ( ? )", sch[0]
	 end
	############ create table with all spells
	
	db.execute <<-SQL
	  create table spells (
		name string,
		spell_effect string,
		spell_increase string,
		spell_level int,
		mana int,
		resource_cost string,
		school string
	  );
	  SQL

	Dir.glob("design/spells/schools/**/*").reject{ |rj| File.directory?(rj) }.each do |f|
		school = f.split("/")[-1].split('.')[0]
		(read_skills f).each do |spell|
			xdb = "design/spells/spells/#{spell}.xdb"
			if spell.include? "rune" then
				resource_cost = ""
				[ "Wood", "Ore", "Mercury", "Crystal", "Sulfur", "Gem" ].each_with_index do |resource, i|
					cost = ( read_skills "design/spells/spells/#{spell}.xdb", 1, "<#{resource}>", "</#{resource}>" )
					cost[0] > 0 ?  resource_cost << "#{cost[0]} #{resource} " : nil
				end
			else
				resource_cost = ""
			end
			spell_effect = read_skills "design/spells/spells/#{spell}.xdb", 2, "<Base>", "</Base>"
			spell_increase = read_skills "design/spells/spells/#{spell}.xdb", 2, "<PerPower>", "</PerPower>"
			spell_level = (read_skills "design/spells/spells/#{spell}.xdb", 0, "<Level>", "</Level>")[0]
			mana = (read_skills "design/spells/spells/#{spell}.xdb", 0, "<TrainedCost>", "</TrainedCost>")[0]
			db.execute "insert into spells values (?, ?, ?, ?, ?, ?, ?)", spell, spell_effect.join(','),spell_increase.join(','), spell_level, mana, resource_cost, school
		end
	end
	
	
	############ create table with all artifacts
	db.execute <<-SQL
	  create table artifacts (
		name string,
		slot string,
		CostOfGold int,
		type string,
		Attack int,
		Defence int,
		SpellPower int,
		Knowledge int,
		Morale int,
		Luck int,
		art_set string
	  );
	  SQL
	  
	Dir.glob("design/artifacts/artifacts/**/*").reject{ |rj| File.directory?(rj) }.each do |f|
		artifact_name = f.split("/")[-1].split('.')[0]
		slot = (read_skills "design/artifacts/artifacts/#{artifact_name}.xdb", 0, "Slot>", "</Slot>")[0]
		CostOfGold = (read_skills "design/artifacts/artifacts/#{artifact_name}.xdb", 0, "CostOfGold>", "</CostOfGold>")[0]
		Attack = (read_skills "design/artifacts/artifacts/#{artifact_name}.xdb", 0, "Attack>", "</Attack>")[0]
		Defence = (read_skills "design/artifacts/artifacts/#{artifact_name}.xdb", 0, "Defence>", "</Defence>")[0]
		SpellPower = (read_skills "design/artifacts/artifacts/#{artifact_name}.xdb", 0, "SpellPower>", "</SpellPower>")[0]
		Knowledge = (read_skills "design/artifacts/artifacts/#{artifact_name}.xdb", 0, "Knowledge>", "</Knowledge>")[0]
		Morale = (read_skills "design/artifacts/artifacts/#{artifact_name}.xdb", 0, "Morale>", "</Morale>")[0]
		Luck = (read_skills "design/artifacts/artifacts/#{artifact_name}.xdb", 0, "Luck>", "</Luck>")[0]
		type = (read_skills "design/artifacts/artifacts/#{artifact_name}.xdb", 0, "<Type>", "</Type>")[0]
		Dir.glob("design/artifacts/sets/**/*").reject{ |rj| File.directory?(rj) }.each_with_index do |s, i|
			set_name = s.split("/")[-1].split('.')[0]
			if (read_skills s).include?(artifact_name) == true then
				@set = set_name; 
				break;
			else
				@set = "none";
			end
		end
		db.execute "insert into artifacts values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", artifact_name, slot, CostOfGold, type, Attack, Defence, SpellPower, Knowledge, Morale, Luck, @set
	end

	############ create table with all artifact filters
	db.execute <<-SQL
	  create table artifact_filter (
		name string,
		filter string
	  );
	  SQL
	
	Dir.glob("design/artifacts/filters/**/*").reject{ |rj| File.directory?(rj) }.each do |fl|
		filter_name = fl.split("/")[-1].split('.')[0]
		filter = (read_skills fl)
		#debug(filter)
		db.execute "insert into artifact_filter values ( ?, ?)", filter.join(","), filter_name
	end

	############ create table with all heroes and their stats
	
	db.execute <<-SQL
	  create table heroes (
		name string,
		secondary string,
		sort_order int,
		classes string
	  );
	  SQL
#=end
	Dir.glob("design/classes/**/*/heroes.txt").reject{ |rj| File.directory?(rj) }.each do |fl|
		@classes = fl.split("/")[-2]
		(read_skills "design/classes/#{@classes}/heroes.txt").each_with_index do |hero, i|
			#hero == 'unknown' ? next : nil
			s_stats = read_skills "text/en/heroes/#{hero}/skills.txt"
			db.execute "insert into heroes values ( ?, ?, ?, ?)", hero, s_stats.join(','), i, @classes
		end
	end
	#@classes, hero, i = '', 'unknown', 0
	#s_stats = read_skills "text/en/heroes/#{hero}/skills.txt"
	#db.execute "insert into heroes values ( ?, ?, ?, ?)", hero, s_stats.join(','), i, @classes
	


		#(read_skills fn).each do |n| 
		#	db.execute "insert into classes values (?, ?, ?)", count, file_name, n;
		#	count+=1
	#	debug(fn)
	#end
	
	para "SUCCESS"
	db.execute( "select * from heroes" ) do |row|
	  debug(p row)
	end

end
