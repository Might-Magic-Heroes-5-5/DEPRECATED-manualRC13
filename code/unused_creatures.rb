class Creatures < Shoes::Widget
	attr_accessor :name, :abilities, :spells, :price, :size
	
	def initialize(x)
		@name = app.reading "creatures/#{x[0]}/name.txt"
		@abilities = x[16].split(",")
		@spells = x[10].split(",")
		@price = Hash[RESOURCE.zip x[17..-1]]
		@font = (fmts[:font] ? fmts[:font] : "Gabriola" )
		@size = fmts[:size] || 28
	end





end