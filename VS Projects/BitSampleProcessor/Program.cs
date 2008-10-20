using System;
using System.Collections.Generic;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.IO;
using System.Diagnostics;

namespace BitSampleProcessor
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }

        internal static string ProcessAndOpen( string rawFilePath )
        {
            SampleProcessor sampleProcessor = new SampleProcessor();
            sampleProcessor.LoadFromFile(new FileInfo(rawFilePath));

			sampleProcessor.BreakPlacingDigitSequencePerLine();
			sampleProcessor.PlaceCharacterCountInFirstColumn();
			sampleProcessor.AddCountFrequencyAtEnd();

            Regex matchFileName = new Regex(@"(.+)(\.txt)$", RegexOptions.IgnoreCase);
            string processedFilePath = matchFileName.Replace(rawFilePath, "$1_processed$2");
            
            sampleProcessor.SaveToFile(processedFilePath);
            Program.OpenProcessedFile(processedFilePath);

            return processedFilePath;
        }

		internal static string ProcessData( string rawData )
		{
			SampleProcessor sampleProcessor = new SampleProcessor();
			sampleProcessor.Load( rawData );

			sampleProcessor.ManchesterDecode();
			//sampleProcessor.CalculateParity();

			return sampleProcessor.ProcessedData;
		}

        internal static void OpenProcessedFile(string fileName)
        {
            Process.Start(fileName);
        }
    }
}