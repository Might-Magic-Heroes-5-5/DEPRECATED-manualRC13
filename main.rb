require 'sqlite3'
require 'yaml'
require 'zip'
require 'code/GlobalVars'
require 'code/language_repo'
require 'code/Tooltip'
require 'code/ReadSkills'
require 'net/https'
#require 'math'
Dir["code/panes/*.rb"].each {|file| require file } 

class Array
  def same_values?
    self.uniq.length == 1
  end
end

def trim num
  i, f = num.to_i, num.to_f
  i == f ? i : f
end

def set_button hero, count, direction = "up"
	direction == "up" ? hero+=1 : hero-=1 			## direction points if going up or down the list
	( set_hero hero; set_wheel; ) if ( hero > -1 && hero < count )
end

def reading f_name; begin return @texts.read(f_name) rescue nil end; end

def filter_files path, ingore=nil					## returns all files found in a specific path
	return Dir.entries(path).reject { |rj| ['.','..', ingore].include?(rj) }
end
 
def get_url url
	uri = URI(url)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	request = Net::HTTP::Get.new(uri.request_uri)
	begin
		response = http.request(request)
	rescue
		messages 3
	end
	return response
end
Shoes.app(title: "Might & Magic: Heroes 5.5 RC13", width: @@a_width[@@res], height: @@a_height[@@res], resizable: false ) do
	
	###### defining styling #####
	font "settings/fonts/2-vivaldi.ttf" unless Shoes::FONTS.include? "1 Vivaldi "
	font "settings/fonts/belmt.ttf" unless Shoes::FONTS.include? "Bell MT"
	style Shoes::Subtitle, font: "Gabriola", size: 28
	style Shoes::Tagline, font: "Bookman Old Style", size: 16, align: "center"
	
	###### defining vars #####
	
	begin
		@texts = Zip::File.open("text/#{@@lg}") 		# load app text pack 
	rescue
		@@lg = "en.pak"
		@texts = Zip::File.open("text/#{@@lg}")
		@@APP_DB.execute( "update settings set value='#{@@lg}' where name = 'language';" )
	end
	
	@offense = OFFENSE_BONUS[1]							# multiplier based on offense
	@defense = DEFENSE_BONUS[1]							# multiplier based on defense
	@mana_multiplier = 10     							# multiplier based on intelligence perk
	@wheel_turn = 0										# enables skillwheel rotation: 0 - 12-skill-hero; 1 - 13-skill-hero
	@events = { "menu" => true, "primary" => true, "secondary" => true }        # Arrange drawing slots into groups to filter and hide
	@icon_size, @icon_size2, @icon_size3, @M_SL_L, @M_SL_T, @M_WH, @M_BR, @M_SR, @M_WH_L, @M_WH_R, @ARR_L, @ARR_T = GUI_SETTINGS[@@res]
	@hovers = tooltip(reading("properties/font_type.txt").split("\r\n"), 		## set default text fonts (should be monospaced)
		reading("properties/font_size.txt").split("\r\n").map(&:to_i),			## set default font size
		reading("properties/calc_text_size.txt").split("\r\n").map(&:to_i),		## define width and height size per char for (text and text2) popup size calculation (monospaced font is advisable)
		reading("properties/calc_header_size.txt").split("\r\n").map(&:to_i))   ## define width and height size per char for (header) popup size calculation 
	
	def set (img, options={} )
		img.hover { @events[options[:event]] == true ? (@hovers.show text: options[:text], header: options[:header], size: 9, text2: options[:text2], width: options[:width], height: options[:height]; img.scale 1.25, 1.25) : nil }
		img.leave { @events[options[:event]] == true ? (@hovers.hide; img.scale 0.8, 0.8) : nil }
		img.click { |press| @events[options[:event]] == true ? (@hovers.hide; yield(press) if block_given?) : nil } 
	end
			
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
				( set_slot page, object[i][0], 
				( image "pics/#{dir_img}/#{object[i][0]}.png", width: @icon_size ),
				text: (reading "#{dir_txt}/#{object[i][0]}/name.txt"), event: "menu" ) unless object[i].nil?
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
			when "CREATURE" then creature_pane_update item
			when "SPELL" then spell_pane_pages item
			when "HERO" then @ch_class = item;
							 @wheel_turn = 0
							 set_hero 0
							 set_wheel
			when "ARTIFACT" then @artifact_list.clear; artifact_slot item; 
			end
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