class Tooltip < Shoes::Widget

	def initialize
		motion { |x, y| @move_left = x; @move_top = y }
		@menu1 = stack;
	end

	def resize ( t_length, i, lines )
		t_length == 0 ? return : nil
		if i == 0 then @w << t_length*15; @h << 60; return;
		else char_w, char_h = 13, 22
		end
		wide, high = t_length*char_w, char_h
		while not (wide/high).between?(0,3) do
			wide=(wide*2)/3;
			high=(high*3)/2
		end
		@w << (wide < 320 ? 320 : wide); @h << (high+(lines-1)*(char_h/2) + 5)
	end

	def present ( options={} )
		txt, i = options[:text], options[:i]
		txt == "" ? return : nil
		case i
		when 0 then size = 18; stroke = rgb(255,255,255); font = "Bell MT"; justify = false
		when 1 then size = 12; stroke = rgb(255,255,255); font = "Courier New"; justify = true
		when 2 then size = 12; stroke = rgb(50,50,50); font = "Courier New"; justify = true
		end
		para txt, size: size, stroke: stroke, font: font, align: "center", justify: justify
	end

	def show ( options={} )
		@menu1.clear { @menu = stack height: 0 do end.hide }
		offset, high, wide = 10, options[:height], options[:width] 
		text, text2, header = options[:text] || "ERROR: Missing mandatory options \"width:\", \"height:\" or \"text:\"\nAvailable options:\ntext: the text presented in the tooltip window\nwidth: the width of the tooltip\nheight: the height of the tooltip\nfont: the font of the text\nstroke: the stroke of the text\nsize: the size of the text\nborder: the colour of the border of the tooltip\nbackground: the colour of the tooltip box\nExample:   slot.hover { @sign.open text: \"tooltip comming through\", width: 200, height: 100, border: rgb(0,20,5,0.5), background: rgb(0,244,99,0.5) , font: \"Vivaldi\" , size: 10, stroke: white }", options[:text2] || "", options[:header] || ""
		back1, back2 = options[:border] || rgb(120,42,5,0.5), options[:background] || rgb(180,150,110,0.7) 
		texts, @w, @h = [ header, text, text2 ], [] , []
		texts.each_with_index { |t,i| resize t.length, i, t.lines.count }
		wide = wide || @w.max; 
		high = high || @h.inject(0, :+)
		@menu.style width: offset + wide, height: offset + high
		@menu.move(((@move_left + @menu.width >= app.width) ? ( app.width - @menu.width ) : @move_left),
				   ((@move_top + @menu.height >= app.height) ? ( app.height - @menu.height ) : @move_top))
		@menu.clear do
			background back1, curve: 15
			background back2, curve: 15, width: @menu.width-4, height: @menu.height - 4, left: 2, top: 2
			stack margin_left: offset/2, width: wide, height: high do
				texts.each_with_index { |t,i| present text: t, i: i }
			end
		end
		start { @menu.show }
	end

	def hide; @menu.hide; end
end