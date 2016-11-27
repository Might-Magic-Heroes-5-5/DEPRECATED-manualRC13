class Tooltip < Shoes::Widget

	def initialize ()
		motion { |x, y| @move_left = x; @move_top = y }
		@menu1 = stack;
	end

	def resize ( length, length2=0, h_length=0 )
		row, char = 16, 9
		wide, high = length*char, 1
		while (wide < char*length*row/high-1) do
			(wide/high).between?(0,7) ? nil : ( wide-=wide/2 )
			high+=row
		end	
		wide < 260 ? ( high = (high.to_f/(260/wide.to_f)).round; wide = 260 ) : nil
		(h_length+5)*10>wide ? ( wide = (h_length+5)*10 ) : nil
		h_length > 0 ? high+=50 : nil
		length2 == 0 ? high+=row : high+=row*(3 + length2*char/wide)
		return wide, high
	end

	def present ( options={} )
		text, text2, header, offset, wide, high = options[:text], options[:text2], options[:header], options[:offset], options[:wide], options[:high]
		flow margin_left: offset, width: wide, height: high do
			header == "" ? nil : ( para ("#{header}"), size: 17, stroke: white, font: "Bell MT", align: "center", justify: false )
			para ("#{text}"), size: 9, stroke: white, font: "Courier New", align: "center", justify: true
			text2 == "" ? nil : ( para ("#{text2}"), size: 9, stroke: rgb(50,50,50), font: "Courier New", align: "center", justify: true )
		end
	end

	def open ( options={} )
		@menu1.clear {	@menu = stack height: 0 do end.hide }
		offset, high, wide, text, text2, header, back1, back2 = 10, options[:height], options[:width], options[:text] || "ERROR: Missing mandatory options \"width:\", \"height:\" or \"text:\"\nAvailable options:\ntext: the text presented in the tooltip window\nwidth: the width of the tooltip\nheight: the height of the tooltip\nfont: the font of the text\nstroke: the stroke of the text\nsize: the size of the text\nborder: the colour of the border of the tooltip\nbackground: the colour of the tooltip box\nExample:   slot.hover { @sign.open text: \"tooltip comming through\", width: 200, height: 100, border: rgb(0,20,5,0.5), background: rgb(0,244,99,0.5) , font: \"Vivaldi\" , size: 10, stroke: white }", options[:text2] || "", options[:header] || "", options[:border] || rgb(120,42,5,0.5), options[:background] || rgb(180,150,110,0.7) 
		( wide.nil? || high.nil? ) ? (wide, high = resize text.length, text2.length, header.length ) : nil
		@menu.style width: offset + wide, height: offset + high
		menu_left, menu_top = @move_left, @move_top;
		@move_left + @menu.width >= app.width + offset ? menu_left = @move_left - @menu.width : nil
		@move_top + @menu.height >= app.height + offset ? menu_top = @move_top - 2*@menu.height/3 : nil
		@menu.move(menu_left, menu_top)
		@menu.clear do
			background back1, curve: 15
			background back2, curve: 15, width: @menu.width-4, height: @menu.height - 4, left: 2, top: 2
			present text: text, text2: text2, header: header, offset: offset/2, wide: wide, high: high
		end
		start { @menu.show }
	end

	def close
		@menu.hide
	end
end
