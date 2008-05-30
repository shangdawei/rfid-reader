using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.IO;
using System.Text.RegularExpressions;
using System.Diagnostics;

namespace BitSampleProcessor
{
    public partial class MainForm : Form
    {
        string rawFilePath;
        string processedFilePath;

        public MainForm()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if (openFileDialog1.ShowDialog() == DialogResult.OK)
            {
                this.rawFilePath = openFileDialog1.FileName;
                this.label1.Text = openFileDialog1.FileName;
            }
        }

        private void processButton_Click(object sender, EventArgs e)
        {
            if( ! this.rawFilePath.Equals( string.Empty ) )
            {
                SampleProcessor sampleProcessor = new SampleProcessor();
                sampleProcessor.LoadFromFile(new FileInfo(this.rawFilePath));
                sampleProcessor.BreakPlacingDigitSequencePerLine();

                Regex matchFileName = new Regex(@"(.+)(\.txt)$", RegexOptions.IgnoreCase);
                this.processedFilePath = matchFileName.Replace(this.rawFilePath, "$1_processed$2");
                sampleProcessor.SaveToFile(processedFilePath);
            }
            else
                MessageBox.Show( "Please select a raw file." );             
        }

        private void closeButton_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void button1_Click_1(object sender, EventArgs e)
        {
            Process.Start(this.processedFilePath);
        }
    }
}