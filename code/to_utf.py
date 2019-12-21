import os;
import sys;
filePathSrc="D:\\mod workplace\\app_migration\\source\\tempfiles_rc13\\MMH55-Texts-EN"

for root, dirs, fils in os.walk(filePathSrc):
		for fls in fils:
			notepad.open(root + "\\" + fls)
			console.write(root + "\\" + fls + "\r\n")
			#notepad.runMenuCommand("Encoding", "Convert to UTF-8")
			notepad.runMenuCommand("Encoding", "Convert to UCS-2 LE BOM")
			notepad.save()
			notepad.close()




# spare code for other operatoins

#files = [f for f in os.listdir(filePathSrc)]
#for fold in files:
		#print(fold)
		#texts = [t for t in os.listdir(filePathSrc + "\\" + fold + "\\Text\\Game\\Creatures\\Neutrals\\")]
			#if "desc" not in fls and "Desc" not in fls: