namespace BitSampleProcessor
{
    partial class MainForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
			this.openFileDialog1 = new System.Windows.Forms.OpenFileDialog();
			this.label1 = new System.Windows.Forms.Label();
			this.selectButton = new System.Windows.Forms.Button();
			this.processButton = new System.Windows.Forms.Button();
			this.closeButton = new System.Windows.Forms.Button();
			this.label2 = new System.Windows.Forms.Label();
			this.rawDataTextBox = new System.Windows.Forms.TextBox();
			this.processedDataTextBox = new System.Windows.Forms.TextBox();
			this.label3 = new System.Windows.Forms.Label();
			this.button1 = new System.Windows.Forms.Button();
			this.label4 = new System.Windows.Forms.Label();
			this.SuspendLayout();
			// 
			// label1
			// 
			this.label1.Anchor = ((System.Windows.Forms.AnchorStyles) (((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
						| System.Windows.Forms.AnchorStyles.Right)));
			this.label1.Location = new System.Drawing.Point( 13, 9 );
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size( 277, 22 );
			this.label1.TabIndex = 0;
			this.label1.Text = "Raw file not selected";
			this.label1.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
			// 
			// selectButton
			// 
			this.selectButton.Anchor = ((System.Windows.Forms.AnchorStyles) ((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
			this.selectButton.Location = new System.Drawing.Point( 296, 8 );
			this.selectButton.Name = "selectButton";
			this.selectButton.Size = new System.Drawing.Size( 75, 23 );
			this.selectButton.TabIndex = 1;
			this.selectButton.Text = "Select";
			this.selectButton.UseVisualStyleBackColor = true;
			this.selectButton.Click += new System.EventHandler( this.button1_Click );
			// 
			// processButton
			// 
			this.processButton.Anchor = ((System.Windows.Forms.AnchorStyles) ((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
			this.processButton.Location = new System.Drawing.Point( 225, 37 );
			this.processButton.Name = "processButton";
			this.processButton.Size = new System.Drawing.Size( 146, 23 );
			this.processButton.TabIndex = 2;
			this.processButton.Text = "Process and Open";
			this.processButton.UseVisualStyleBackColor = true;
			this.processButton.Click += new System.EventHandler( this.processButton_Click );
			// 
			// closeButton
			// 
			this.closeButton.Anchor = ((System.Windows.Forms.AnchorStyles) ((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
			this.closeButton.DialogResult = System.Windows.Forms.DialogResult.Cancel;
			this.closeButton.Location = new System.Drawing.Point( 296, 414 );
			this.closeButton.Name = "closeButton";
			this.closeButton.Size = new System.Drawing.Size( 75, 23 );
			this.closeButton.TabIndex = 3;
			this.closeButton.Text = "Close";
			this.closeButton.UseVisualStyleBackColor = true;
			this.closeButton.Click += new System.EventHandler( this.closeButton_Click );
			// 
			// label2
			// 
			this.label2.Anchor = ((System.Windows.Forms.AnchorStyles) (((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
						| System.Windows.Forms.AnchorStyles.Right)));
			this.label2.Location = new System.Drawing.Point( 13, 38 );
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size( 206, 22 );
			this.label2.TabIndex = 0;
			this.label2.Text = "File not processed yet";
			this.label2.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
			// 
			// rawDataTextBox
			// 
			this.rawDataTextBox.Location = new System.Drawing.Point( 12, 113 );
			this.rawDataTextBox.Multiline = true;
			this.rawDataTextBox.Name = "rawDataTextBox";
			this.rawDataTextBox.Size = new System.Drawing.Size( 355, 89 );
			this.rawDataTextBox.TabIndex = 4;
			// 
			// processedDataTextBox
			// 
			this.processedDataTextBox.Location = new System.Drawing.Point( 11, 238 );
			this.processedDataTextBox.Multiline = true;
			this.processedDataTextBox.Name = "processedDataTextBox";
			this.processedDataTextBox.Size = new System.Drawing.Size( 355, 160 );
			this.processedDataTextBox.TabIndex = 4;
			// 
			// label3
			// 
			this.label3.Anchor = ((System.Windows.Forms.AnchorStyles) (((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
						| System.Windows.Forms.AnchorStyles.Right)));
			this.label3.Location = new System.Drawing.Point( 9, 88 );
			this.label3.Name = "label3";
			this.label3.Size = new System.Drawing.Size( 277, 22 );
			this.label3.TabIndex = 0;
			this.label3.Text = "Raw data";
			this.label3.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
			// 
			// button1
			// 
			this.button1.Location = new System.Drawing.Point( 291, 209 );
			this.button1.Name = "button1";
			this.button1.Size = new System.Drawing.Size( 75, 23 );
			this.button1.TabIndex = 5;
			this.button1.Text = "Process";
			this.button1.UseVisualStyleBackColor = true;
			this.button1.Click += new System.EventHandler( this.button1_Click_1 );
			// 
			// label4
			// 
			this.label4.Anchor = ((System.Windows.Forms.AnchorStyles) (((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
						| System.Windows.Forms.AnchorStyles.Right)));
			this.label4.Location = new System.Drawing.Point( 13, 210 );
			this.label4.Name = "label4";
			this.label4.Size = new System.Drawing.Size( 277, 22 );
			this.label4.TabIndex = 0;
			this.label4.Text = "Processed data";
			this.label4.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
			// 
			// MainForm
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF( 6F, 13F );
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.CancelButton = this.closeButton;
			this.ClientSize = new System.Drawing.Size( 383, 449 );
			this.Controls.Add( this.button1 );
			this.Controls.Add( this.processedDataTextBox );
			this.Controls.Add( this.rawDataTextBox );
			this.Controls.Add( this.closeButton );
			this.Controls.Add( this.processButton );
			this.Controls.Add( this.selectButton );
			this.Controls.Add( this.label2 );
			this.Controls.Add( this.label4 );
			this.Controls.Add( this.label3 );
			this.Controls.Add( this.label1 );
			this.Name = "MainForm";
			this.Text = "Sample Processor";
			this.ResumeLayout( false );
			this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.OpenFileDialog openFileDialog1;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Button selectButton;
        private System.Windows.Forms.Button processButton;
        private System.Windows.Forms.Button closeButton;
        private System.Windows.Forms.Label label2;
		private System.Windows.Forms.TextBox rawDataTextBox;
		private System.Windows.Forms.TextBox processedDataTextBox;
		private System.Windows.Forms.Label label3;
		private System.Windows.Forms.Button button1;
		private System.Windows.Forms.Label label4;
    }
}

