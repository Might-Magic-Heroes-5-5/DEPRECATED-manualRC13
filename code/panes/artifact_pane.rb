def artifact_pane first=@primary_pane, second=@secondary_pane
	filters = DB.execute( "select filter from artifact_filter;" )
	set_main "ARTIFACT", filters , "buttons", "panes/artifact_pane/buttons"
	first.clear
	second.clear do
		flow left: 80, top: 108, width: 650, height: 600, scroll: true do
			image 'pics/themes/pane3.png', width: 1.0, height: 1.0
			subtitle reading("panes/artifact_pane/name.txt"), top: 0, align: "center", stroke: white
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
		protection_coef.each { |p| @protection << p_max*p[0] }
		first.clear do
			subtitle pane_t1[0], align: "center"
			@micro_pane = stack left: 45, top: 60, width: 280, height: 280;
			(@k_box = click_box).create(left: 255, top: 263, val: 1, max: 100, min: 1, jump: 10, text: pane_t1[2])
			@k_box.update
		end

		@artifact_list.clear do
			image 'pics/themes/micro_pane.png', left: 120, top: 15
			image 'pics/themes/micro_inventory.png', left: 120, top: 260
			subtitle pane_t1[3], left: 158, top: 5, size: 22, stroke: white
			subtitle pane_t1[4], left: 310, top: 5, size: 22, stroke: white
			subtitle "x1         x2         x3", left: 268, top: 155, size: 22, stroke: white
			subtitle pane_t1[5], top: 180, size: 22, stroke: white, align: "center"
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
				set_effect i, pane_t1[10]
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
					shell_text = "#{prefix} #{name} #{suffix} (#{@k_box.show})"
					@inventory.each { |v| v.contents[0].nil? ? ( create_micro v, shell_text, @state.dup, pane_t1[10]; break ) : nil }
				end
			end
			subtitle pane_t1[8], left: 250, top: 270, size: 22, stroke: white
			button("#{pane_t1[9]}", left: 198, top: 490, width: 200 ) { @inventory.map!(&:clear) }
		end
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
	
def create_micro box, name, effects, txt_cost
	txt, price = [], []
	effects.each_with_index do |e, i|
		e == 0 ? next : nil
		id = @micro_eff[e][0]
		values = DB.execute( "select effect from micro_artifact_effect WHERE id='#{id}';" )[0][0]
		cost = DB.execute( "select gold, Wood, ore, mercury, crystal, sulfur, gem from micro_artifact_effect WHERE id='#{id}';" )
		price << cost[0..-1][0].map! { |x| x*(i+1) }
		if id == 'MAE_MAGIC_PROTECTION' then
			txt << (reading("micro_artifacts/#{id}/effect.txt").sub! '<value>', (@protection[@k_box.show > 59 ? 59 : @k_box.show-1 ].floor.to_s))
		else
			txt << (reading("micro_artifacts/#{id}/effect.txt").sub! '<value>', ((1 + values*@k_box.show).floor.to_s))
		end
	end
	price = Hash[ RESOURCE.zip price.transpose.map { |x| x.reduce(:+) } ]
	box.append do
		set (image "pics/micro_artifacts/#{@sh_id}#{@shell_lvl}.png", width: 60), text: name, event: "secondary" do
			@micro_pane.clear do
				para name, size: 14, align: "center"
				txt.each { |t| para t, margin_left: 20, margin_right: 20 }
				subtitle txt_cost, top: 200, size: 20, align: "center"
				flow(left: 38, top: 245, width: 300, height: 50 ) { set_resources price }
			end
		end
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
			when 'MAE_HASTE' then value = (values*@k_box.show).floor.to_s
			when 'MAE_MAGIC_PROTECTION' then value = @protection[@k_box.show > 59 ? 59 : @k_box.show-1 ].floor.to_s
			else value = (1+values*@k_box.show).floor.to_s
			end
			txt = reading("micro_artifacts/#{id}/effect.txt").sub! '<value>', value
			@micro_pane.clear do
				para "#{name}", size: 14, align: "center"
				para txt, margin_left: 20
				subtitle txt_cost, size: 20, top: 200, align: "center"
				stack(left: 38, top: 245, width: 300, height: 50) { set_resources price }
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