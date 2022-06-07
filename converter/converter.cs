using System;
using System.IO;
using PKHeX.Core;

namespace byteToPk1
{
    class converter
    {
        //last 12 bytes are useless, except last one that contains the number of nums to decode
        static void Main(string[] args)
        {
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
                #region Init
                var mon = new PK1();                 //current mon
                byte[] current = new byte[monSize];  //the data of the current mon
                for (int j = 0; j < monSize; j++)    //set the data from the full array to the temp
                {
                    current[j] = data[(i * monSize) + j];
                }
                #endregion

                #region Data Decoding
                try//try to set species. if impossible then fuck you
                {
                    mon.Species = SpeciesConverter.GetG1Species(current[0]);
                }
                catch
                {
                    Console.WriteLine("Couldn't decode pokémon number " + (i + 1) + ": invalid species number.");
                    continue;
                }

                mon.Move1 = current[08];
                mon.Move2 = current[09];
                mon.Move3 = current[10];
                mon.Move4 = current[11];

                mon.TID = (data[12] * 256) + data[13];
                mon.EXP = ((uint)data[14] * 256 * 256) + ((uint)data[15] * 256) + data[16];

                mon.EV_HP = (data[17] * 256) + data[18];
                mon.EV_ATK = (data[19] * 256) + data[20];
                mon.EV_DEF = (data[21] * 256) + data[22];
                mon.EV_SPE = (data[23] * 256) + data[24];
                mon.EV_SPC = (data[25] * 256) + data[26];

                mon.IV_ATK = data[27] / 16;   //first four bytes are atk iv, this takes them out
                mon.IV_DEF = data[27] % 16;   // last four bytes are def iv, this takes them out
                mon.IV_SPE = data[28] / 16;
                mon.IV_SPC = data[28] % 16;

                //offset 1-2 has current hp. useless
                //offset 3 has current level, but we calculate based on experience. useless
                //offsets 4-7 have status, types and held items. useless
                //offsets 29-32 are PP of moves. useless
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

                //i'm not sure what these do but probably they're a good idea
                mon.FixMoves();
                mon.Heal();
                mon.RefreshChecksum();
                #endregion

                #region File
                try
                {
                    //create file at correct path and write pkhex data to it
                    File.WriteAllBytes(path + "/" + mon.FileName, mon.DecryptedBoxData);
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Couldn't decode pokémon number " + i + ": " + ex);
                }
                #endregion

                succesfulCount++;
            }

            if (succesfulCount > 0) Console.Write("\nSuccesfully decoded " + succesfulCount + " pokémon. The files are at: " + path);
            else Console.WriteLine("No pokémon could be decoded. Please check your image and retry.");
        }

        static void print(params object[] objs)
        {
            string msg = "";

            foreach (object obj in objs)
                msg += obj + " ";

            Console.WriteLine(msg);
        }
    }
}
