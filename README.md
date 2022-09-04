# Gen 1 Escape Plan
As you'll know, the first two generations of Pokémon can't transfer to later generations. In addition, save files for those games run on batteries, which means that when those batteries run out the save files will be erased.

This repository contains an arbitrary code execution program (ACE) for pokémon Red and Blue (english version) that, when executed, will read the data for the pokémon in your current box, and then write it to the screen by changing the tile data to the data read from the box.

This way, it is possible to transfer pokémon from gen1: there are many other ways of doing it, but all the ones i could find require some external device to read your save file, and I didn't want to buy something that I would only use once. Instead, the idea behind this program is being able to do it with just your GameBoy, a smartphone, and some glitch magic.

# Usage
More detailed instructions can be found [here](https://docs.google.com/document/d/1CY9rRGymB8hse_mWoYx-IilI3dXrkb2gseOIo8w0cNw/edit?usp=sharing).

First step is to execute the ACE program. Find any setup that you like (i recommend [this](https://www.youtube.com/watch?v=D3EvpRHL_vk) one for RB), write the program you find in the version of bytes.txt corresponding to the game you're playing on and execute it.

**Important**: before executing the program, you should enter a pokémon centre. It doesn't _have_ to be a pokémon centre, as long as the top-left tile of your screen is at co-ordinates 0-0 and there are no moving tiles on screen, but entering a building is the easiest way of achieving this.

After executing the program, exit any menus you may be in: your GameBoy screen will show a code. If you want to continue the process in a later moment you'll have to take a picture; if you do, make sure that _each individual_ pixel of the GameBoy screen are perfectly visible and distinct, otherwise you will _not_ be able to decode it from the picture.

After that, the code will have to be read for its data to be decripted. I'm working on a way to do this automatically, but currently there isn't one yet. If you want to read it manually, follow these instructions exactly:
1) The code has black and dark pixels: you should read the code by squares, 8 pixels by 8 pixels
2) The first square is the top left, second is the one to its right and so on. Once you reach the end of the line, go back to the left and down one line
3) Each square will be read in the following way: take the first row of pixels (the topmost line) and write down all dark pixels as a 0, and all black pixels as a 1. Then, use a binary converter (like [this](https://www.mathsisfun.com/binary-decimal-hexadecimal-converter.html)) to convert this binary string to a number in decimal and write down the number you get. Once you have written down the number you can go to the next row, and start with a new binary string.

_Note_: to make things faster if you want to interpret manually, note that you don't have to transcribe all of the 672 lines. Instead, you only have to read (33 times the number of pokémons in your box) lines. For example, if you have only five pokémon you must read 33 * 5 = 165 lines, which means you should end in the 21st square.

When you have all the numbers in place, you can download the decoder and pass in the numbers when asked to. If you did not decode all of the lines, simply write 0 (or any other value) when the program asks you for those lines.



# Building
There are two .py files in the root directory, and running those will give you the build. There are a couple of requirements, however: you should have csc.exe (the C# compiler) in your PATH, and vasmz80_oldstyle_win32.exe (the assembler I use for gbz80 Assembly) in the same folder as the .py scripts. Finally, to build the C# app you'll need PKHeX.Core.dll and netstandard.dll.



# To Do
I'm working on a way to automatically read the printed code and interpret its data, but it's probably going to take a while because I have no idea of what I'm doing.
