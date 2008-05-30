using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Text.RegularExpressions;

namespace BitSampleProcessor
{
    class SampleProcessor
    {
        string rawData;

        public string ProcessedData { get { return this.rawData; } }

        public void LoadFromFile( FileInfo rawSampleFile )
        {
            using (StreamReader rawStream = rawSampleFile.OpenText())
            {
                rawData = rawStream.ReadToEnd();

                Regex matchAllButBinary = new Regex("([^01]+)", RegexOptions.Multiline);
                rawData = matchAllButBinary.Replace(rawData, string.Empty);
            }
        }

        public void BreakPlacingDigitSequencePerLine()
        {
            Regex matchSequences = new Regex("(0+|1+)");
            rawData = matchSequences.Replace(rawData, @"$1" + Environment.NewLine);
        }

        public void SaveToFile(string filePath)
        {
            using (StreamWriter sw = new StreamWriter(filePath))
            {
                sw.Write(this.rawData);
            }            
        }
    }
}
