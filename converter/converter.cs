using System;
using System.Data.SqlTypes;
using System.IO;
using PKHeX.Core;

namespace byteToPk1
{
	class converter
	{
		//last 12 bytes are useless, except last one that contains the number of nums to decode
		static void Main(string[] args)
		{
			//"lGqaAUQGZmrsAAAAAAAAAAAAAAS(DU'sAA'lyNxuBAGAAU(CAU";

			Console.WriteLine("Insert your 48-character string and then hit enter:");
			var str = Console.ReadLine();

			var data = DecodeMonDataFromString(str);
			Console.WriteLine("\nWhere do you want your files to be saved? (path)");
			var path = Console.ReadLine();
			Console.WriteLine();

			// print("decoded the data, now doing the thing");

			var retcode = CreatePokeFileFromData(data, path);
			switch(retcode)
			{
				case poke_ok:
					Console.WriteLine("File written succesfully! Do you want to decode another Pokémon?");
					break;
				case io_error:
					Console.WriteLine("Couldn't write the file (I/O error)");
					break;
				case invalid_species:
					Console.WriteLine("Couldn't decode pokémon: invalid species number.");
					break;
			}
		}

		const int poke_ok = 0;
		const int io_error = -1;
		const int invalid_species = -2;
		static int CreatePokeFileFromData(byte[] data, string path) {

			var mon = new PK1();

			#region Data Decoding
			//try to set species. if impossible then fuck you // this comment was so unnecessary lol
			try {
				mon.Species = SpeciesConverter.GetG1Species(data[0]);
			}
			catch {
				return invalid_species;
			}

			mon.Move1 = data[08];
			mon.Move2 = data[09];
			mon.Move3 = data[10];
			mon.Move4 = data[11];

			mon.TID = (data[12] * 0x100) + data[13];
			mon.EXP = ((uint)data[14] * 0x10000) + ((uint)data[15] * 0x100) + data[16];

			mon.EV_HP  = (data[17] * 0x100) + data[18];
			mon.EV_ATK = (data[19] * 0x100) + data[20];
			mon.EV_DEF = (data[21] * 0x100) + data[22];
			mon.EV_SPE = (data[23] * 0x100) + data[24];
			mon.EV_SPC = (data[25] * 0x100) + data[26];

			mon.IV_ATK = data[27] / 0x10;   //first four bytes are atk iv
			mon.IV_DEF = data[27] % 0x10;   // last four bytes are def iv
			mon.IV_SPE = data[28] / 0x10;
			mon.IV_SPC = data[28] % 0x10;

			//offset 1-2 has current hp. not needed
			//offset 3 has current level, but we calculate based on experience. not needed
			//offsets 4-7 have status, types and held items. not needed
			//offsets 29-32 are PP of moves. not needed
			#endregion

			#region Last Bits
			//we don't read the nickname data with everything else because
			//a: it would require more tiles, and probably wouldn't be able to fit the code in one screen which would make it much harder to program in assembly
			//b: it would be a nightmare to convert from rb bytes to strings because rb doesn't use ASCII encoding
			Console.WriteLine("Succesfully decoded " + mon.Nickname + ". Do you want to nickname it? Leave blank for no nickname: ");
		NNLoop:
			string nn = Console.ReadLine();
			if (nn.Length == 0)  //user doesnt want nickname
			{
				mon.ClearNickname();
				mon.SetNotNicknamed();
			}
			else if (nn.Length > 12) //nicknames longer than 12 are invalid
			{
				Console.WriteLine("Nickname too long. Enter a new one");
				goto NNLoop;//i dont care what people say, i love gotos
			}
			else //user wants a nickname
			{
				mon.IsNicknamed = true;
				mon.Nickname = nn;
			}

		OTLoop:
			Console.WriteLine("What's the OT name?");
			string ot = Console.ReadLine();
			if (ot.Length == 0 || ot.Length > 7)
			{
				Console.WriteLine("Invalid OT. Please retry");
				goto OTLoop;
			}
			mon.OT_Name = ot;

			//i'm not sure what these do but they're probably a good idea
			mon.FixMoves();
			mon.Heal();
			mon.RefreshChecksum();
			#endregion

			#region File
			try {
				File.WriteAllBytes(path + "/" + mon.FileName, mon.DecryptedBoxData);
			}
			catch (Exception ex) {
				Console.WriteLine("I/O error: " + ex);
				return io_error;
			}
			#endregion

			return 0;
		}

		/// <summary>
		/// the wise man says: "never asks how this code works for i don't know either. it just does".
		/// this whole things is basically built on trial and error
		/// </summary>
		/// <param name="arg"></param>
		/// <exception cref="Exception"></exception>
		static byte[] DecodeMonDataFromString(string arg) {

			const int monSize = 33;

			byte[] bytesfromstr = new byte[0x30];
			byte[] decodedbytes = new byte[monSize];
			int c = 0;

			for (int i = 0; i < arg.Length; i++, c++) {
				if (arg[i] == '\'') {
					i++;
					bytesfromstr[c] = FromEncodedChar(arg[i], true);
				}
				else {
					bytesfromstr[c] = FromEncodedChar(arg[i]);
				}
			}

			// impossible in case of well formatted strings
			if (c < bytesfromstr.Length) throw new Exception("bad byte: " + c.ToString());

			// now we start decoding from the last byte
			// all values are 6bit
			// i is the counter for the string, j for the bytes
			for (int i = bytesfromstr.Length - 1, j = 0; i > 3; i -= 4, j += 3) {

				// print("start of loop", i, j);

				byte b1 = bytesfromstr[i],
					 b2 = bytesfromstr[i - 1],
					 b3 = bytesfromstr[i - 2],
					 b4 = bytesfromstr[i - 3];

				// print(b1, b2, b3, b4);

				Int32 outval;
				/// db1 = aaaaaabb	\
				/// db2 = bbbbcccc	 |--- outval = 00000000_aaaaaabb_bbbbcccc_ccdddddd
				/// db3 = ccdddddd	/
				outval = b4 + (b3 << 6) + (b2 << 12) + (b1 << 18);
				// Console.WriteLine("Hex: {0:X}", outval);

				decodedbytes[j] = (byte)((outval & 0b11111111_00000000_00000000) >> 16);
				decodedbytes[j + 1] = (byte)((outval & 0b11111111_00000000) >> 8);
				decodedbytes[j + 2] = (byte)((outval & 0b11111111) >> 0);

				// print("end of loop");

			}

			return decodedbytes;
		}
		// decode a character from the pokemon RB font into the byte it was generated by
		static byte FromEncodedChar(char c, bool useApostrophe=false) {

			// characters that start with an apostrophe are handled differently
			if (useApostrophe) {
				switch (c)
				{
					case 'e':
						return 0x3A;
					case 'd':
						return 0x3B;
					case 'l':
						return 0x3C;
					case 's':
						return 0x3D;
					case 't':
						return 0x3E;
					case 'v':
						return 0x3F;
				}

				// in case we didn't find our char throw exception
				goto err;
			}

			if (c >= 'A' && c <= 'Z') {
				return (byte)(c - 'A');
			}
			if (c >= 'a' && c <= 'z') {
				return (byte)(0x20 + c - 'a');
			}
			switch (c)
			{
				case '(':
					return 0x1A;
				case ')':
					return 0x1B;
				case ':':
					return 0x1C;
				case ';':
					return 0x1D;
				case '[':
					return 0x1E;
				case ']':
					return 0x1F;
			}

			err:
			throw new Exception("attempted to decode an invalid character. check your string again.");
		}

		// func to decode old version of the program. no longer needed
		static void DecodeFromByteArray(string[] args) {

			const int maxMons = 20;  //size of gen1 box
			const int monSize = 33;  //size in bytes of each mon

			const int nOfBytes = 84 * 8; //number of total bytes to read in the code. there's 84 tiles, each tile having 8 bytes encoded in it

			//if there's a problem with the args then this will execute asking the user to fix them
			#region Args Checking
			//if a bad number of arguments is detected, redo them. this way we can don't HAVE to execute it from window, but can just double click it
			if (args.Length != nOfBytes + 1)  // +1 because args also contain the path to save to
			{
				args = new string[nOfBytes + 1];

				Console.WriteLine("Write the path to the folder you want to save your files to: ");
				args[0] = Console.ReadLine();

				byte monsToDecode; //temp variable used to only ask bytes for this number of mons
				Console.WriteLine("How many pokémons are you trying to decode?");
				do
					args[nOfBytes] = Console.ReadLine();
				while (!byte.TryParse(args[nOfBytes], out monsToDecode));
				//if the string can't be interpreted as a byte, repeat

				byte emptyVar;
				Console.WriteLine("Now write the bytes of data from your code: ");
				for (int i = 1; i <= (monSize * monsToDecode); i++)
				{
					Console.WriteLine("\n" + i + ": ");
					do
						args[i] = Console.ReadLine();
					while (!byte.TryParse(args[i], out emptyVar));
				}
				//set all bytes we didn't set already to avoid errors
				for (int i = (monSize * monsToDecode) + 1; i < args.Length - 1; i++) //-1 because we did set the "number of pokémon" byte to zero
					args[i] = "0";
			}
			#endregion

			string path = args[0]; //first arg is path to save the files to
			byte[] data = new byte[nOfBytes];
			for (int i = 1; i <= data.Length; i++) //the rest is the bytes
				data[i - 1] = byte.Parse(args[i]);

			//last byte encodes the number of valid pokémon that have been read
			int monsToConvert = data[data.Length - 1];
			if (monsToConvert > maxMons)//can't happen, so if it does some data got misread
			{
				Console.WriteLine("Invalid data detected: more than 20 pokémon in box. The rest of the data could also be misread. Do you still want to decode your pokémon? ");
				if (Console.ReadLine().ToLower()[0] != 'y')
				{
					Console.WriteLine("Please review your data and try again.");
					return;
				}
				monsToConvert = maxMons;
			}
			if (monsToConvert == 0)
			{
				Console.WriteLine("Invalid data detected: no pokémon in box. The rest of the data could also be misread. Do you still want to decode your pokémon? ");
				if (Console.ReadLine().ToLower()[0] != 'y')
				{
					Console.WriteLine("Please review your data and try again.");
					return;
				}
				monsToConvert = maxMons;
			}

			//number of pokémon succesfully decoded
			int succesfulCount = 0;
			for (int i = 0; i < monsToConvert; i++)
			{
				byte[] current = new byte[monSize];  //the data of the current mon
				for (int j = 0; j < monSize; j++)    //set the data from the full array to the temp
				{
					current[j] = data[(i * monSize) + j];
				}

				var retcode = CreatePokeFileFromData(current, path);
				switch (retcode)
				{
					case poke_ok:
						succesfulCount++;
						break;
					case io_error:
						Console.WriteLine("Couldn't write the file for pokemon number " + (1+i) + " (I/O error)");
						break;
					case invalid_species:
						Console.WriteLine("Couldn't decode pokémon number " + (1+i) + ": invalid species number.");
						break;
				}
			}

			if (succesfulCount > 0) Console.Write("\nSuccesfully decoded " + succesfulCount + " pokémon. The files are at: " + path);
			else Console.WriteLine("No pokémon could be decoded. Please check your image and retry.");
		}

		#region Utilities
		static void PrintHex(byte b) {
			Console.WriteLine("{0:X}", b);
		}
		static void print(params object[] objs)
		{
			string msg = "";

			foreach (object obj in objs)
				msg += obj + " ";

			Console.WriteLine(msg);
		}
		#endregion
	}
}
