Shoes.app(title: "Open Skillwheel v:0.70, database: HoMM 5.5 RC8", width: 1000, height: 730, resizable: false ) do
background 'pics/background.png'

if Shoes::FONTS.include? "Vivaldi"
	style Shoes::Subtitle, font: "Vivaldi"
end
if Shoes::FONTS.include? "Bell MT"
	style Shoes::Tagline, font: "Bell MT", size: 16, align: "center"
else
	style Shoes::Tagline, size: 16, align: "center"
end  
	@table_stats=[]
	@box=Array.new(12) { Array.new(12) }	
	
	def set_primary_image image, file
		image.hover do
			text=File.read("text/pskills/#{file}.txt")
			open_popup 200, 70, "", text
		end
		image.leave do
			close_popup
		end			
	end
	
	def read_skills text, int=0
		skills=[]
		File.read(text).each_line do |line|
			skills << line.chop
		end
		if int==1 then
			skills.each_with_index do |n, i|
				skills[i]=n.to_i
			end
		end				
		return skills
	end
	
	def check_plus_dependency  x, y
		z=0; p=0
		case y
			when 0 then @ch_skills[x][0..2]="100"; z=1
			when 1 then @ch_skills[x][0..2]="110"; z=2
			when 2 then @ch_skills[x][0..2]="111"; z=3
			when 6,7,8 then @ch_skills[x][y]= "1"; 
							@ch_skills[x][y-3]="1"
			when 10 then @ch_skills[x][y]= "1"; 
						 @ch_skills[x][y-3]="1"; 
						 @ch_skills[x][y-6]="1"
			else @ch_skills[x][y]="1"
		end
		for i in 3..10
			if @ch_skills[x][i] == "1" then p+=1 end
		end
		@ch_skills[x]=visible_perks @ch_skills[x]
		if p>2 then
			for i in 3..10 
				if @ch_skills[x][i]=="0" then
					@ch_skills[x][i]="2"
				end
			end
		end
		if p>z then
			for i in 1..p 
				@ch_skills[x][i-1]="1"
			end
		end
	end
	
	def check_minus_dependency x, y
		p=0
		for i in 3..10
			if @ch_skills[x][i] == "1" then p+=1 end
		end
		case y
			when 0 then @ch_skills[x]="00000000020";
			when 1 then unless p>1 then 
							@ch_skills[x][0..2]="100"
				        else
							return 0;  
						end
			when 2 then unless p>2 then 
							@ch_skills[x][0..2]="110";
						else 
							return 0; 
						end
			when 4 then @ch_skills[x][y+6]="0";
						@ch_skills[x][y+3]="0";
						@ch_skills[x][y]="0";
			when 3,7,5 then @ch_skills[x][y]="0";
							@ch_skills[x][y+3]="0"
			else @ch_skills[x][y]="0"
		end
		for i in 3..10 
			if @ch_skills[x][i]=="2" then
				@ch_skills[x][i]="0"
			end
		end
		@ch_skills[x][9]="2"
		@ch_skills[x]=visible_perks @ch_skills[x]
	end
	
	def visible_perks skillcheck
		case skillcheck[3..10]
			when "10000020","00100020" then skillcheck[10]="2"
			when "00100120","00100122" then skillcheck[3..10]="00122122" 
			when "01001020","01001022" then skillcheck[3..10]="01021220" 
			when "10010020","10010022" then skillcheck[3..10]="10012222" 
			when "10100020","10100022" then skillcheck[3..10]="10102022"
			when "11000020","11000022" then skillcheck[3..10]="11000222" 
			when "01100020","01100022" then skillcheck[3..10]="01120022" 
		end
		return skillcheck
	end
			
	def open_popup wide, high, header="", text=""
		offset=10
		@menu.style width: wide, height: high
		menu_left=@move_left; menu_top=@move_top;
		if @move_left+@menu.width >= app.width+offset then menu_left=@move_left-@menu.width end
		if @move_top+@menu.height >= app.height+offset then menu_top=@move_top-@menu.height end			
		@menu.move(menu_left, menu_top)
		@menu.clear do 
			background rgb(248,248,255,0.8), curve: 15
			background rgb(80,100,120,0.8), curve: 15, width: @menu.width-4, height: @menu.height-4, left: 2, top: 2
			if header!="" then tagline strong("#{header}"), stroke: white end
			if text!="" then para "#{text}", justify: true, align: "center", stroke: white, size: 10, width: @menu.width-2*offset, left: offset end
		end
		timer(0.1) { @menu.show }		
	end
	
	def close_popup
		@menu.hide
	end
	
	def set_primary
		@ch_primary.each_with_index do |p,i|
			case i
				when 0..3 then @table_stats[i].replace p.to_i
				else @table_stats[i].replace "#{p.to_i}%"
			end
		end	
		@level_text.replace @ch_level
		@stat_damage.replace "#{((3.33*@ch_primary[0])*@offense).round(2)}%"
		@stat_defense.replace "#{((3.33*@ch_primary[1])*@defense).round(2)}%"
		@stat_mana.replace "#{@stat_mana_multiplier*@ch_primary[3]}"
	end
	
	def set_skillwheel
		ch_secondary=read_skills "text/classes/#{@ch_class}/secondary.txt"
		@offense=1
		@defense=1
		@stat_mana_multiplier=10
		if ch_secondary.length>12 then	####setting left/right arrows if there are more than 12 skills
			case @wheel_turn
				when 0 then @wheel_left.hide; @wheel_right.show
				when 1..ch_secondary.length-13 then @wheel_left.show; @wheel_right.show
				else @wheel_left.show;@wheel_right.hide
			end
		else
			@wheel_left.hide
			@wheel_right.hide
		end	
		ch_secondary.each_with_index do |s, x|   #####rotates each of the 12 skillwheel sections
			if x-@wheel_turn>11 then break end	 #exits when all 12 sections are full buth there are more skills
			perks=[]
			perks=read_skills "text/skilltree/#{s}.txt"
			perks.each_with_index do |skill_name, y|	#####populate the current skillwheel part with perks and skills 
				@box[x-@wheel_turn][y].clear do					
					if skill_name != "" and @ch_skills[x][y]!="2" then
						background rgb(120,120,120,0.7), hidden: true;				
						if @ch_skills[x][y] == "1" then
							image do
								image "pics/skills/active/#{skill_name}.png", width: 35 , height: 35
								shadow radius: 1, fill: rgb(0, 0, 0, 0.5)
							end
							case skill_name
								when "Intelligence" then @stat_mana_multiplier=15
								when "Basic Offense" then @offense=1.1
								when "Advanced Offense" then @offense=1.15
								when "Expert Offense" then @offense=1.2
								when "Basic Defense" then @defense=1.1
								when "Advanced Defense" then @defense=1.2
								when "Expert Defense" then @defense=1.3
							end
							#debug ("#{@ch_skills} it is #{ch_secondary.find_index("Enlightenment")} or #{ch_secondary.find_index("Learning")} or secondary is #{ch_secondary}")
						else
							image "pics/skills/grey/#{skill_name}.png", width: 35, height: 35
						end
						contents[1].hover do
							@box[x-@wheel_turn][y].contents[0].show;
							header=File.read("text/skills/#{skill_name}/name.txt")
							text=File.read("text/skills/#{skill_name}/Description.txt")
							open_popup 320, 60+(5*text.length)/11, header, text
						end	
						contents[1].leave do
							@box[x-@wheel_turn][y].contents[0].hide; 
							close_popup								
						end
						contents[1].click do
							if @hero==0 and @ch_skills[x]=="11111111121" then @ch_skills[x]="00000000020" end
							unless @ch_skills[x][y]=="1" then
								check_plus_dependency x, y
							else
								check_minus_dependency x, y
							end			
							@menu.hide
							set_skillwheel
						end
					end
				end
			end
		end
		set_primary	####set primary table stats according to skillwheel changes
	end
	
	def set_button current, string, direction="up"
		if direction=="up" then current+=1 else current-=1 end ##direction points if one is going up or down the list
		if current>-1 && current<string then
			@box_hero.clear { image "pics/heroes/#{@ch_heroes[current]}.png", width: 60 }
			@ch_skills=read_skills "text/heroes/#{@ch_heroes[current]}/skills.txt"
			set_skillwheel
			return current
		elsif current<0
			return 0
		else 
			return string-1
		end
	end

	motion { |x, y| @move_left=x; @move_top=y } ## capture mouse pointer
	CLASSES=read_skills "text/classes/classes.txt"
###################################################### MAIN STARTS HERE ############################################################################################################
	stack width: 280 do								#################################################### LEFT  - LISTBOX OF HEROES, PRIMARY STATS ############
		image "pics/V.png", width: 263, top: 144, left: 8
		list_box :items => CLASSES, :width => 120, :margin => 8, :choose => CLASSES[0] do |n|
			@menu.hide
			@ch_class="#{n.text}"
			@hero=0
			@wheel_turn=0
			@ch_level=1
			@ch_heroes=read_skills "text/classes/#{@ch_class}/heroes.txt"
			@ch_primary=read_skills "text/classes/#{@ch_class}/primary.txt", 1
			@ch_skills=read_skills "text/heroes/#{@ch_heroes[@hero]}/skills.txt"	
			set_skillwheel 
			@box_hero.clear do image "pics/heroes/#{@ch_heroes[@hero]}.png", width: 60 end
		end
		flow width: 245, margin_left: 45, margin_top: 130 do								 ############# PRIMARY STATS TABLE #############	
			table_image=[ "attack", "defense", "spellpower", "knowledge" ]
			for i in 0..11																									
				flow height: 45, width: 45 do
					border("rgb(105, 105, 105)", strokewidth: 1)
					case i 
						when 0..3 then	image "pics/pskills/#{table_image[i]}.png", left: 1, top: 1
										set_primary_image contents[1], table_image[i]
						else @table_stats[i-4] = para "0" , align: "center", margin_top: 0.32
					end			
				end
			end
		end
		flow do
			image "pics/stats/damage.png", left: 60, top: 15, width: 15
			@stat_damage=para "", left: 82, top: 318, size: 14, font: "Utsaah"
			image "pics/stats/defense.png", left: 140, top: 15, width: 15		
			@stat_defense=para "", left: 160, top: 318, size: 14, font:"Utsaah"
			image "pics/stats/mana.png", left: 60, top: 40, width: 15		
			@stat_mana=para "", left: 82, top: 344, size: 14, font: "Utsaah"
			subtitle  "Hero level", left: 90, top: 420, size: 16
			flow width: 40, height: 35, left: 196, top: 133 do
				@level_text=subtitle "#{@ch_level}", size: 20
			end
			contents[0].hover do
				open_popup 240, 50, "","3.33%*Attack*(1+offense_skill) damage boost"
			end
			contents[0].leave do
				close_popup
			end
			contents[2].hover do
				open_popup 240, 50, "","3.33%*Defense*(1+defense_skill) health boost"
			end
			contents[2].leave do
				close_popup
			end
			contents[4].hover do
				open_popup 240, 30, "","Max mana points"
			end
			contents[4].leave do
				close_popup
			end
			contents[7].hover do
				open_popup 200, 50, "","Left click to level up!\nRight click to start fresh."
			end
			contents[7].leave do
				close_popup
			end
			contents[7].click do |button|             ##########Hero leveling up and gaining of primary stats based on chance
				close_popup
				if button == 1 && @ch_level<50 then
					@ch_level+=1	
					i=rand(0..100)+1
					case i
						when 1..@ch_primary[4] then @ch_primary[0]+=1
						when @ch_primary[4]+1..@ch_primary[4]+@ch_primary[5] then @ch_primary[1]+=1
						when @ch_primary[4]+@ch_primary[5]+1..@ch_primary[4]+@ch_primary[5]+@ch_primary[6] then @ch_primary[2]+=1
						when @ch_primary[4]+@ch_primary[5]+@ch_primary[6]+1..100 then @ch_primary[3]+=1
					end
				else
					@ch_level=1
					@ch_primary=read_skills "text/classes/#{@ch_class}/primary.txt", 1
				end
				set_primary
			end
		end
	end
	
	stack width: 715,height: 715 do			############################################# RIGHT - SKILLWHEEL TABLE #################################################################	
		image "pics/wheel.png", width: 710, top: 5
		C_width=674									##using math formula to define the circpostion of the boxes
		C_height=688
		step=Math::PI/6
		start_rad=0	
		for q in 0..11
			angle=-1.46 + (Math::PI/21)*(q%3)
			if q>1 then
				if ((q+1)%3)==1 then 
					start_rad+=50 
				end 
			end	
			radius=330-start_rad
			for w in 0..11
				x = (C_width/2 + radius * Math.cos(angle)).round(0)
				y = (C_height/2 + radius * Math.sin(angle)).round(0)
				angle += step
				@box[w][q] = flow left: x, top: y, width: 36, height: 36 do
				end
			end
		end
		
		@wheel_left=image "pics/buttons/wheel_arrow.png", left: 315, top: 240 do end
		@wheel_left.click do 
			@wheel_turn-=1; set_skillwheel
		end.rotate 180
		@wheel_right=image "pics/buttons/wheel_arrow.png", left: 365, top: 240 do end
		@wheel_right.click do
			@wheel_turn+=1; set_skillwheel
		end
		@box_hero=flow left: 322, top: 327, width: 60, height: 60 do
			border(black, strokewidth: 2)
		end
		@box_hero.hover do
			text=File.read("text/heroes/#{@ch_heroes[@hero]}/spec.txt")
			name=File.read("text/heroes/#{@ch_heroes[@hero]}/name.txt")
			open_popup 300, 90+text.length/2, name, text
		end
		@box_hero.leave { close_popup }		
		left_button = image "pics/buttons/normal.png", left: 295, top: 327
		left_button.rotate 180
		left_button.click do
			@wheel_turn=0
			@hero=set_button @hero, @ch_heroes.length, "down"
		end
		right_button = image "pics/buttons/normal.png", left: 385, top: 327 
		right_button.click do
			@wheel_turn=0
			@hero=set_button @hero, @ch_heroes.length
		end
	end
	
	stack top: 665, left: 940, width: 40, height: 50 do
		back=background rgb(255,248,220,0.5), hidden: true;
		about=image "pics/about.png"
		about.hover { back.toggle }
		about.leave { back.toggle }
		about.click do 
			window(title: "Äbout", width: 450, height: 150, resizable: false ) do
				para "Open Skillwheel version 0.70 by dredknight (Jordan Kostov)\n\nDesign advisor: Marina Kostova\nTechnical advisor: Simeon Manolov", justify: true
				button "www.heroescommunity.com", left: 110, top: 100 do
					system("start http://heroescommunity.com/viewthread.php3?TID=42212") 
				end
			end
		end
	end
	@menu=stack height: 10 do end.hide ############################################# Pop up bar #################################################################	
end