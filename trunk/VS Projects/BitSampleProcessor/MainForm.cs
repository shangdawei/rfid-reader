using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace BitSampleProcessor
{
    public partial class MainForm : Form
    {
        public MainForm()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if (openFileDialog1.ShowDialog() == DialogResult.OK)
            {
                this.label1.Text = openFileDialog1.FileName;
            }
        }

        private void processButton_Click(object sender, EventArgs e)
        {
            if (!this.label1.Text.Equals(string.Empty))
            {
                label2.Text = Program.ProcessAndOpen(this.label1.Text);
            }
            else
                MessageBox.Show( "Please select a raw file." );             
        }

        private void closeButton_Click(object sender, EventArgs e)
        {
            this.Close();
        }
    }
}