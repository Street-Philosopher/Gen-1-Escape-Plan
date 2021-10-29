# MonConverter
This is an arbitrary code execution program (ACE) for pokémon Red and Blue (english version) on the GameBoy.
When executed, it will read the data for the pokémon in your current box, and then write it to the screen by changing the tile data to the data read from the box.
I made this as a way to transfer pokémon from gen1, as you can't do it normally: there are many other ways of doing it, but usually they all require some external device to read your save file, and I didn't want to buy something that I would never use again after this. Instead, the idea behind this program is being able to do it with just your GameBoy, a smartphone, and some patience.
# Usage
First step is to execute the ACE program. Find any setup that you like (i reccomend this one: https://www.youtube.com/watch?v=D3EvpRHL_vk) and write the program you find in "bytes.txt".
After executing the program, your GameBoy screen will show a code (check "exampleCode.jpg" to see what it should look like). Take a picture with your phone (I'd reccomend you take more than one, just in case).
After that, the code will have to be read for its data to be decripted. I'm working on a way to do this automatically, but currently there isn't one yet. If you want to read it manually, follow these instructions exactly:
1) The code has black and white pixels: you should read the code by squares, 8 pixels by 8 pixels
2) The first square is the top left, second is the one to its right and so on. Once you reach the end of the line, go back to the left and down one line
3) Each square will be read in the following way: take the first row of pixels (the topmost line) and count all white pixels as a 0, and all black pixels as a 1. Then, use a binary converter (like this one https://www.mathsisfun.com/binary-decimal-hexadecimal-converter.html) to convert this binary string to a number in decimal and write down the number you get. Write down all these numbers in order, and then write them in the correct order in the converter when asked to.


# To Do
I'm working on a way to automatically read the printed code and interpret its data, but it's probably going to take a while because I have no idea of what I'm doing.
