# Gen 1 Escape Plan
As you might know, the first two generations of Pokémon can't transfer to later generations. In addition, save files for those games run on batteries, which means that when those batteries run out the save files will be erased.

This repository contains an arbitrary code execution program (ACE) for pokémon Red and Blue (english version) that, when executed, will read the data for the pokémon in your current box (one at a time), and then write it to the screen in the form of a string of characters. This string can then be interpreted to get back your Pokémon, and you can import it in newer generation in any way you want.

This way, it is possible to transfer pokémon from gen1: there are many other (better and faster) ways of doing it, but all the ones I could find require some external device to read your save file, and I didn't want to buy something that I would only use once. Instead, the idea behind this program is being able to do it with just your GameBoy, a computer, and some glitch magic.

# Usage
More detailed instructions can be found [here](https://docs.google.com/document/d/1AcA9x5-y9iM6aY70qXIajFFR1EC2oiL3/edit?usp=sharing&ouid=105723787028341327526&rtpof=true&sd=true).

First step is to execute the ACE program. Find any setup that you like (i recommend [this](https://www.youtube.com/watch?v=D3EvpRHL_vk) one for RB), write the program you find in the version of bytes.txt corresponding to the game you're playing on and execute it (if you're using the setup I mentioned above, the [bytesReader.py](byteReader/bytesReader.py) script you'll find in the release will automatically convert it into coordinates so you don't have to).

After you execute the program you'll get a textbox: take not of what it says, as that is your Pokémon. Write all the characters in the converter script (write accented and apostrophed characters as the normal character preceded by an apostrophe ') in a single line, and press enter. If you don't get any errors, congrats! Choose where you want to save you Pokémon, its nickname and its trainer name (OT) and you're done. You'll find a `.pk1` file in your chosen directory, that you can use as a backup of your Pokémon or to transfer it to later generations via console modding or genning services.

# Building
All you have to do is run the [build file](build) in the root directory, but to compile you need to have a C# compiler (I use csc.exe) and [rgbds](https://rgbds.gbdev.io/).

The dependencies to build the C# script are:
+ PKHeX.Core.dll
+ netstandard.dll