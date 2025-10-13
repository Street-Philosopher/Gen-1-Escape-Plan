import os, glob
import tkinter as tk
try:
	from PIL import Image, ImageTk
except:
	os.system("pip install pillow")
	from PIL import Image, ImageTk

#window setup
window = tk.Tk()
window.geometry("256x370")

#TODO: raw per versioni che non usano il setup di ZZAZZ
def ShowMap():
	#remove all previous widgets
	for child in window.winfo_children():
		#yes
		child.destroy()

	#now we'll add the canvas
	canvas = tk.Canvas(window)
	canvas.pack()

	#next byte to be read
	currentbyte = 0
	#current position of the red sprite on the screen
	currentpos = (0,0)	#in format YX, not XY

	#moves the character to the next position
	def NextByte():
		nonlocal currentpos, currentbyte

		remainingBytes = (len(allbytes) - currentbyte)
		if remainingBytes == 0:
			currentbytelabel["text"] = "done!"
			nextbtn.destroy()
			return
		
		#this is the current byte, a two digit hex string
		cb = allbytes[currentbyte]

		#do the thing
		if remainingBytes == 1:
			currentbytelabel["text"] = cb
		elif remainingBytes == 2:
			currentbytelabel["text"] = f"{cb} {allbytes[currentbyte+1]}"
		elif remainingBytes == 3:
			currentbytelabel["text"] = f"{cb} {allbytes[currentbyte+1]} {allbytes[currentbyte+2]}"
		else:
			currentbytelabel["text"] = f"{cb} {allbytes[currentbyte+1]} {allbytes[currentbyte+2]} ..."

		currentbytelabel["text"] += f"\n{currentbyte}/{len(allbytes)} ({round(100 * currentbyte / len(allbytes), 2)}%)"

		#get the change in position (desired position - current position)
		deltax = int(cb[1], 16) - currentpos[1]
		deltay = int(cb[0], 16) - currentpos[0]

		#change the position on the screen
		currentpos = (currentpos[0]+deltay, currentpos[1]+deltax)
		# print(deltax, deltay, currentpos, allbytes[currentbyte])

		#multiplied by 16 because a tile is 16 pixels
		canvas.move(red, 16*deltax, 16*deltay)
		
		currentbyte += 1
	#END

	#map
	mapImage = ImageTk.PhotoImage(Image.open('res/map.png'))
	canvas.create_image(0, 0, anchor=tk.NW, image=mapImage)

	#red sprite
	redImage = ImageTk.PhotoImage(Image.open('res/red.png'))
	red = canvas.create_image(0, 0, anchor=tk.NW, image=redImage)

	#label that says current byte
	currentbytelabel = tk.Label(window, font="Consolas")
	currentbytelabel.pack(anchor="center")

	#button to advance to next one
	nextbtn = tk.Button(window, text="next", background="#BBB", width=10, command=NextByte)
	nextbtn.pack(anchor="center")
	window.bind("<Return>", lambda x: NextByte())

	NextByte()	#start by showing the first one

	#for some reason this is necessary again, otherwise sprites don't show up
	window.mainloop()
#END

#ask for which release you want to use
allbytes = []
def readbytes(file):
	with open(file) as file:
		for line in file:
			if "\n" in line:	#remove any newlines
				line = line.replace("\n", "")
			allbytes.append(line)

#main menu selection
lab1 = tk.Label(window, text="What release are you playing?"); lab1.pack()
bytes_dir = "../build/*.txt" if os.path.isdir("../build") else "res/*.txt"
for file in glob.glob(bytes_dir):
	fname = os.path.basename(file)[:-len(".txt")].replace("_", " ").replace("-", "/")
	btn = tk.Button(window, text=fname, command=lambda:(readbytes(file), ShowMap()))
	btn.pack()

window.mainloop()