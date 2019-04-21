class Tooltip < Shoes::Widget

	def initialize(t_fonts, t_sizes, calc_t_size, calc_h_size)
		motion { |x, y| @move_left = x; @move_top = y }
		@menu1 = stack;
		@t_fonts = t_fonts
		@t_sizes = t_sizes
		@calc_t_size = calc_t_size
		@calc_h_size = calc_h_size
		@stroke = [ rgb(255,255,255), rgb(255,255,255), rgb(50,50,50) ]
		@justify = [ false, true, true ]
	end
	
	def change(t_fonts, t_sizes, calc_t_size, calc_h_size)
		@t_fonts = t_fonts
		@t_sizes = t_sizes
		@calc_t_size = calc_t_size
		@calc_h_size = calc_h_size
	end

	def resize ( t, i )
		if i == 0 then @w << t.length*@calc_h_size[0]; @h << @calc_h_size[1]; return;
		else char_w, char_h = @calc_t_size[0]+1, @calc_t_size[1]-1
		end
		wide, high = t.length*char_w, char_h
		while not (wide/high).between?(0,3) do
			wide=(wide*2)/3;
			high=(high*3)/2
		end
		@w << (wide < 320 ? 320 : wide)
		@h << (high+(t.lines.count-1)*(char_h/2) + 5)
	end

	def show ( options={} )
		@menu1.clear { @menu = stack height: 0 do end.hide }
		offset, high, wide = 10, options[:height], options[:width] 
		text, text2, header = options[:text] || "ERROR: Missing options \"width:\", \"height:\" or \"text:\"\nAvailable options:\ntext: the text presented in the tooltip window\nwidth: the width of the tooltip\nheight: the height of the tooltip\nfont: the font of the text\nstroke: the stroke of the text\nsize: the size of the text\nborder: the colour of the border of the tooltip\nbackground: the colour of the tooltip box\nExample:   slot.hover { @sign.open text: \"tooltip comming through\", width: 200, height: 100, border: rgb(0,20,5,0.5), background: rgb(0,244,99,0.5) , font: \"Vivaldi\" , size: 10, stroke: white }", options[:text2] || "", options[:header] || ""
		back1, back2 = options[:border] || rgb(120,42,5,0.5), options[:background] || rgb(180,150,110,0.7) 
		texts, @w, @h = [ header, text, text2 ], [] , []
		texts.each_with_index { |t,i| t != "" ? (resize t, i) : next }
		wide = wide || @w.max; 
		high = high || @h.inject(0, :+)
		@menu.style width: offset + wide, height: offset + high
		@menu.move(((@move_left + @menu.width >= app.width) ? ( app.width - @menu.width ) : @move_left),
				   ((@move_top + @menu.height >= app.height) ? ( app.height - @menu.height ) : @move_top))
		@menu.clear do
			background back1, curve: 15
			background back2, curve: 15, width: @menu.width-4, height: @menu.height - 4, left: 2, top: 2
			stack margin_left: offset/2, width: wide, height: high do
				texts.each_with_index do |t,i| 
					t != "" ? (para t, size: @t_sizes[i], stroke: @stroke[i], font: @t_fonts[i], align: "center", justify: @justify[i]) : next
				end
			end
		end
		start { @menu.show }
	end

	def hide; @menu.hide; end
end


class Click_box < Shoes::Widget
  attr_accessor :width, :align, :color, :font, :size
  
	def initialize(fmts={})
		@width = fmts[:width] || 50
		@height = 40
		@align = fmts[:align] || "center"
		@color = fmts[:color] || black
		@font = (fmts[:font] ? fmts[:font] : "Gabriola" )
		@size = fmts[:size] || 28
	end
  
	def create( v={})
		@v = v
		flow { @box = flow left: v[:left], top: v[:top], width: @width, height: @height }
		app.set @box, text: v[:text], event: "primary"
	end
	
	def update(&block)
		@box.clear { subtitle @v[:val], top: -25, align: @v[:align] || @align, stroke: @v[:strole] || @color, font: @v[:font] || @font, size: @v[:size] || @size }
		block.call if block_given?
		@box.click do |press|
			app.instance_variable_get(:@hovers).hide
			case press
			when 1 then @v[:val]<@v[:max] ? @v[:val]+=1 : nil
			when 2 then @v[:val] = @v[:min]
			when 3 then @v[:val]<(@v[:max] - @v[:jump] + 1) ? @v[:val]+=@v[:jump] : nil
			end
			update {block.call}
		end
	end
	
	def reset(new=1); @v[:val]=new; update end
	
	def show; return @v[:val] end
  
end