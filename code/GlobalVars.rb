#Defining App globals
DB_VER = "RC13a"
@@TXT_VER = "RC13a"
@@SERVER_URL = "https://raw.githubusercontent.com/Might-Magic-Heroes-5-5/Cloud-services/master/translations_list.txt"
@@APP_DB = SQLite3::Database.new "settings/app_settings.db"									# application misc db
@@lg=@@APP_DB.execute( "select value from settings where name='language';" )[0][0]   		# current app language
@@res=@@APP_DB.execute( "select value from settings where name='app_size';" )[0][0].to_i	# app size choice
@@a_width = [ 1200, 1200 ]																	# app width choices
@@a_height = [ 800, 750 ] 																	# app height choices
DB = SQLite3::Database.new "settings/skillwheel.db"											# MMH55 database
GUI_SETTINGS = [																			# skillwheel size for different resolutions
	[60, 40, 40,  0,   0,   0,   0,  0,  0, 0,  0,  0 ],
	[60, 40, 36, 15, -30, -50, -22, -2, 40, 0, 15,  -10 ]
]

#Defining Game DB globals
FACTIONS = DB.execute( "select name from factions where name!='TOWN_NO_TYPE';" )  			# get faction list
MASTERIES = { MASTERY_BASIC: 1, MASTERY_ADVANCED: 2, MASTERY_EXPERT: 3 }
RESOURCE = [ "Gold", "Wood", "Ore", "Mercury", "Crystal", "Sulfur", "Gem"]
OFFENSE_BONUS = [ 1, 1.1, 1.15, 1.2 ]
DEFENSE_BONUS = [ 1, 1.1, 1.15, 1.2 ]
MASS_SPELLS = [	"SPELL_BLESS", "SPELL_HASTE", "SPELL_STONESKIN", "SPELL_BLOODLUST", "SPELL_DEFLECT_ARROWS",
"SPELL_CURSE", "SPELL_SLOW", "SPELL_DISRUPTING_RAY", "SPELL_WEAKNESS", "SPELL_PLAGUE", "SPELL_FORGETFULNESS" ]
EMPOWERED_SPELLS = [ "SPELL_MAGIC_ARROW", "SPELL_LIGHTNING_BOLT", "SPELL_ICE_BOLT", "SPELL_FIREBALL", "SPELL_FROST_RING", "SPELL_CHAIN_LIGHTNING", "SPELL_METEOR_SHOWER", "SPELL_IMPLOSION", "SPELL_ARMAGEDDON", "SPELL_STONE_SPIKES", "SPELL_CURSE", "SPELL_DISPEL", "SPELL_MAGIC_FIST", "SPELL_DEEP_FREEZE" ]


