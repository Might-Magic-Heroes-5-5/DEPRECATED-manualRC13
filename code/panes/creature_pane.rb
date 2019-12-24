def creature_pane first=@primary_pane, second=@secondary_pane
	set_main "CREATURE", FACTIONS, "factions", "factions"
	pane_t1 = (reading "panes/creature_pane/name.txt").split("\n")
	first.clear do
		@events["primary"] = true
		subtitle pane_t1[0], align: "center"
		@creature_name = subtitle "", top: 40, size: 24, align: "center"
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
		subtitle pane_t1[10], top: 295, size: 22, align: "center"
		@cost_slot = flow left: 70, top: 340, width: 150, height: 30;
		subtitle pane_t1[11], left: 134, top: 360, size: 22
	end

	second.clear do
		flow left: 30, top: 70, width: 438, height: 660 do
			image 'pics/themes/pane2.png', width: 1.0, height: 1.0
			subtitle pane_t1[12], top: 0, stroke: white, align: "center", size: 30
			@pane2 = flow left: 0, top: 35, width: 1.0, height: 0.9, scroll: true, scroll_top: 100
		end
		flow left: 500, top: 45, width: 350, height: 690 do
			image 'pics/themes/creature_back.png', width: 433
			flow( left: 40, top: 40, width: 310, height: 40 ) { @faction_name = subtitle "", top: -10, size: 24, align: "center" }
			x, y = 63, 22;
			for q in 0..20
				x+=60
				(q + 1)%3 == 1 ? (  x=123; y+=80 ) : nil
				@box[q] = flow left: x, top: y, width: 52, height: 52
			end
		end
	end
	creature_pane_update
end

def creature_pane_update faction='TOWN_NO_TYPE'
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
					[ x[1], x[2], "#{x[4]} - #{x[5]}", x[7], x[6], x[9], x[12], x[3], x[15] ].each_with_index do |e, n|
						para e, left: 10, top: 2+n*23, size: 13
					end
					subtitle x[13], left: 168, top: 258, size: 28
					i=0
					creature_spells.each do |spell|
						unless spell.include?("ABILITY") then
							set (image "pics/spells/#{spell}.png", left: 155 - 40*(i%2), top: 170 - 40*(i/2), width: 37),
								header: (reading "spells/#{spell}/name.txt"),
								text: (reading "spells/#{spell}/desc.txt"),
								text2: (reading "spells/#{spell}/additional.txt"),
								event: "primary"
							i+=1
						end
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