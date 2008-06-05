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

        public void PlaceCharacterCountInFirstColumn()
        {
            StringReader reader = new StringReader(this.rawData);
            StringWriter writer = new StringWriter();
            
            string line; 
            while ((line = reader.ReadLine()) != null)
            {
                writer.WriteLine(line.Length + "\t" + line);
            }

            this.rawData = writer.GetStringBuilder().ToString();
        }

        public void SaveToFile(string filePath)
        {
            using (StreamWriter sw = new StreamWriter(filePath))
            {
                sw.Write(this.rawData);
            }            
        }

        internal void AddCountFrequencyAtEnd()
        {
            Dictionary<string, int> frequencyCount = new Dictionary<string, int>();
            Regex matchFirstColumn = new Regex("(.+)\\t");
            foreach (Match count in matchFirstColumn.Matches(this.rawData))
            {
                if (frequencyCount.ContainsKey(count.Value))
                    frequencyCount[count.Value]++;
                else
                    frequencyCount.Add(count.Value, 1);
            }

            StringBuilder builder = new StringBuilder(this.rawData);
            builder.Append(Environment.NewLine);
            builder.AppendLine("Count\tFrequency");
            foreach (string count in frequencyCount.Keys)
            {
                builder.Append(count);
                builder.Append("\t");
                builder.Append(frequencyCount[count]);
                builder.Append(Environment.NewLine);
            }

            this.rawData = builder.ToString();
        }
    }
}
