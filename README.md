# Heroes of Might and Magic 5.5 manual

Open source manual for [Might & Magic: Heroes 5.5 mod](http://www.moddb.com/mods/might-magic-heroes-55).

Written on Ruby with [Shoes 3.3.7 framework](http://walkabout.mvmanila.com)

Latest version: [1.3 with MMH55 RC12b database](https://www.moddb.com/mods/might-magic-heroes-55/downloads/mmh55-reference-manual-rc12b)
 
## Repository files

**main.rb** - application code

**changes.txt** - tracker of release changes.

**text** - includes text packages for different languages (currently English and Russian)

**pics** - images only

 **settings->skillwheel.db** - MMH55 game information
 
 **settings->app_settings.db** - keeps contants related to the app behaiour (resolution, default language)
 
 **settings->fonts** - includes app fonts
 
**code->Tooltip** - popup functionality

**code->readskills** - used for reading text files

**code->GlobalVars** - file sources, static arrays and vars

These are all the files the manual is built from.

Author: dredknight


## Build instructions

1. Download and install it the proper Linux/Windowx distribution from [here](https://walkabout.mvmanila.com/downloads/)
2. Open Shoes cobler and install **Zip 2.0.2** gem as it is required to extract the manual text.
![image](https://user-images.githubusercontent.com/12410314/70260905-f9680380-1799-11ea-8838-d578c3a00180.png)
3. Clone the repo on your pc
4. Launch main.rb using the framework
