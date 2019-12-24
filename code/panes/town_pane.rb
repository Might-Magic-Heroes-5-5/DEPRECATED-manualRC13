def town_pane first=@primary_pane, second=@secondary_pane
	set_main "CLASSES", FACTIONS, "factions", "factions"
	@pane_t1 = reading("panes/town_pane/name1.txt").split("\n")
	pane_t2 = reading("panes/town_pane/name2.txt").split("\n")
	pane_t2.map!{|x| x=x[0..-2]}
	t_dir = "panes/town_pane/changes"
	lg_cur = nil; # currently selected language

	first.clear do
		@events["primary"] = true
		subtitle @pane_t1[0], align: "center"
		@existing_tr_pane = flow(left: 55, top: 60, width: 130, height: 70) { check_translations }
		
		flow left: 190, top: 60, width: 130, height: 70 do
			gui_resolution = [ "1200x800", "1200x750" ]
			para @pane_t1[2], left: 5, top: 5, size: 12
			list_box :items => gui_resolution, choose: gui_resolution[@@res], left: 40, top: 30, width: 80, height: 19 do |n|
				if n.text != gui_resolution[@@res] then
					@@res = gui_resolution.index(n.text)
					@@APP_DB.execute( "update settings set value='#{@@res}' where name = 'app_size';" )
					alert(@pane_t1[3])
				end
			end
		end	
		
		flow left: 55, top: 140, width: 270, height: 240 do
			@translation_list = "settings/translation_list.txt"
			button(@pane_t1[4], left: 43, top: 5, width: 160, height: 30) { show_store }
			@translation_slot = flow left: 5, top: 45, width: 250, height: 190
		end
	end

	second.clear do
		flow left: 50, top: 60, width: 730, height: 700 do	
			image 'pics/themes/town.png', width: 1.0, height: 1.0
			subtitle pane_t2[0], top: 30, align: "center"
			left, top, jump, move = 60, 130, 72, 50
			stack left: 50, top: 95, width: 0.85, height: 0.64 do
				pane_t2[1..6].each_with_index { |p, i| subtitle p, align:  "left", stroke: white, top: -12 + jump*i, size: 22 }
			end
			set( (image "pics/changes/buildings.png", left: left, top: top, width: @icon_size2), header: pane_t2[7], text: reading("#{t_dir}/buildings.txt"), event: "secondary" ) { system "start http://www.moddb.com/mods/might-magic-heroes-55/news/mmh55-release-notes-rc10-beta-3" }
			set (image "pics/changes/heroes.png", left: left + move, top: top, width: @icon_size2), header: pane_t2[8], text: reading("#{t_dir}/heroes.txt"), event: "secondary"
			set (image "pics/changes/townportal.png", left: left + move*2, top: top, width: @icon_size2), header: pane_t2[25], text: reading("#{t_dir}/townportal.txt"), event: "secondary"
			set( (image "pics/changes/governor.png", left: left + move*3, top: top, width: @icon_size2), header: pane_t2[27], text: reading("#{t_dir}/governor.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=41977" }
			set( (image "pics/changes/dragonblood.png", left: left + move*4, top: top, width: @icon_size2), header: pane_t2[30], text: reading("#{t_dir}/dragonblood.txt"), event: "secondary" ) { system "start http://www.moddb.com/mods/might-magic-heroes-55/news/might-magic-heroes-55-lore-update" }
			set (image "pics/misc/attack.png", left: left, top: top + jump, width: @icon_size2), header: pane_t2[9], text: reading("#{t_dir}/attack.txt"), event: "secondary"
			set (image "pics/misc/knowledge.png", left: left + move, top: top + jump, width: @icon_size2), header: pane_t2[10], text: reading("#{t_dir}/knowledge.txt"), event: "secondary"
			set( (image "pics/changes/spell_system.png", left: left + move*2, top: top + jump, width: @icon_size2), header: pane_t2[14], text: reading("#{t_dir}/spell_system.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=41320" }
			set (image "pics/changes/8skills.png", left: left + move*3, top: top + jump, width: @icon_size2), header: pane_t2[24], text: reading("#{t_dir}/8skills.txt"), event: "secondary"
			set (image "pics/changes/levels.png", left: left + move*4, top: top + jump, width: @icon_size2), header: pane_t2[28], text: reading("#{t_dir}/levels.txt"), event: "secondary"
			set (image "pics/changes/movement.png", left: left + move*5, top: top + jump, width: @icon_size2), header: pane_t2[16], text: reading("#{t_dir}/movement.txt"), event: "secondary"
			set( (image "pics/changes/arrangement.png", left: left, top: top + jump*2, width: @icon_size2), header: pane_t2[11], text: reading("#{t_dir}/arrangement.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=41320" }
			set (image "pics/changes/necromancy.png", left: left + move, top: top + jump*2, width: @icon_size2), header: pane_t2[12], text: reading("#{t_dir}/necromancy.txt"), event: "secondary"
			set (image "pics/changes/gating.png", left: left + move*2, top: top + jump*2, width: @icon_size2), header: pane_t2[13], text: reading("#{t_dir}/gating.txt"), event: "secondary"
			set (image "pics/changes/occultism.png", left: left + move*3, top: top + jump*2, width: @icon_size2), header: pane_t2[15], text: reading("#{t_dir}/occultism.txt"), event: "secondary"
			set (image "pics/changes/bloodrage.png", left: left + move*4, top: top + jump*2, width: @icon_size2), header: pane_t2[33], text: reading("#{t_dir}/bloodrage.txt"), event: "secondary"
			set (image "pics/changes/training.png", left: left + move*5, top: top + jump*2, width: @icon_size2), header: pane_t2[34], text: reading("#{t_dir}/training.txt"), event: "secondary"
			set (image "pics/changes/bloodrage_gui.png", left: left, top: top + jump*3, width: @icon_size2), header: pane_t2[20], text: reading("#{t_dir}/bloodrage_gui.txt"), event: "secondary"
			set( (image "pics/changes/manual.png", left: left + move, top: top + jump*3, width: @icon_size2), header: pane_t2[21], text: reading("#{t_dir}/manual.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=43030" }
			set (image "pics/changes/textures.png", left: left + move*2, top: top + jump*3, width: @icon_size2), header: pane_t2[22], text: reading("#{t_dir}/textures.txt"), event: "secondary"
			set (image "pics/changes/atb.png", left: left + move*3, top: top + jump*3, width: @icon_size2), header: pane_t2[23], text: reading("#{t_dir}/atb.txt"), event: "secondary"				
			set( (image "pics/changes/pest.png", left: left, top: top + jump*4, width: @icon_size2), header: pane_t2[26], text: reading("#{t_dir}/pest.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=39792" }
			set (image "pics/changes/ai.png", left: left + move, top: top + jump*4, width: @icon_size2), header: pane_t2[29], text: reading("#{t_dir}/ai.txt"), event: "secondary"
			set( (image "pics/changes/duel_mode.png", left: left + move*2, top: top + jump*4, width: @icon_size2), header: pane_t2[31], text: reading("#{t_dir}/duel_mode.txt"), event: "secondary" ) { system "start https://www.moddb.com/mods/might-magic-heroes-55/news/mmh55-new-creature-duel-mode-rc10beta" }
			set( (image "pics/changes/generator.png", left: left + move*3, top: top + jump*4, width: @icon_size2), header: pane_t2[17], text: reading("#{t_dir}/generator.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=41341" }
			set (image "pics/changes/sites.png", left: left + move*4, top: top + jump*4, width: @icon_size2), header: pane_t2[18], text: reading("#{t_dir}/sites.txt"), event: "secondary"
			set( (image "pics/changes/artifacts.png", left: left + move*5, top: top + jump*4, width: @icon_size2), header: pane_t2[19], text: reading("#{t_dir}/artifacts.txt"), event: "secondary" ) { system "start http://heroescommunity.com/viewthread.php3?TID=41528" }
			#set (image "pics/changes/gryphnchain.png", left: left, top: top + jump*5, width: @icon_size2), header: pane_t2[32], text: reading("#{t_dir}/gryphnchain.txt"), event: "secondary"
			set (image "pics/changes/boots.png", left: left, top: top + jump*5, width: @icon_size2), header: pane_t2[32], text: reading("#{t_dir}/boots.txt"), event: "secondary"
		end
	end
end

