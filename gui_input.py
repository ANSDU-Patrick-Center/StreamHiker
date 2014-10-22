
import os, sys, shutil
from Tkinter import *

mydir = os.getcwd()
os.chdir(mydir)
inputfile = 'input_specs'
inputfile_old = inputfile + '_old.txt'
inputfile = inputfile + '.txt'
print "input file: ", inputfile
help_text = "default"
gomain = ".\main.py"

class mainwindow:
    def __init__(self, master):
        global os
        self.fields = 'File Suffix Tag', 'Raster File Type', 'Stream Link Raster', 'Flow Direction Raster', 'Target Reach Map', 'Target Drainage Map', 'EPSG/SRID Code', 'PGSQL Bin Path', 'PGSQL Database Name', 'PGSQL User Name', 'PGSQL Password', 'PGSQL Database Schema', 'Target Reach Length (m)', 'Target Flow Network Table'
        self.master = master
        self.frame = Frame(self.master)
        self.ents = self.makeform(self.fields)
        self.b1 = Button(text='Enter Input Specs',
              command=(lambda e=self.ents: self.fetch(e)))
        self.b1.pack(side=LEFT, padx=5, pady=5)
        self.b2 = Button(text='Quit', command=quit)
        self.b2.pack(side=RIGHT, padx=5, pady=5)
        self.b3 = Button(text='Clear Inputs', command=(lambda e=self.ents: self.reset_entries(e)))
        self.b3.pack(side=LEFT, padx=5, pady=5)  
        self.b4 = Button(text='GO', command = (lambda g=self: os.system(gomain))) #command=quit)
        self.b4.pack(side=LEFT, padx=5, pady=5) 
            
    def reset_entries(self, entries):
        for entry in entries:
            entry[1].delete(0,END)
    
    def fetch(self, entries):
        shutil.copy(inputfile,inputfile_old)
        self.outfile_test = mydir + "\\" + inputfile
        self.outf2 = open(self.outfile_test, 'w')
        for entry in entries:
            self.field = entry[0]
            self.text  = entry[1].get()
            print('%s: "%s"' % (self.field, self.text))
            self.outf2.write('%s' % (self.text) + '\n')
        self.outf2.close()
        self.lines = [i for i in open(self.outfile_test) if i[:-1]]
        self.outf2 = open(self.outfile_test, 'w')
        for line in self.lines:
            self.outf2.write(line)
        self.outf2.close()
           
    def makeform(self, fields):
        self.entries = []
        self.saved_inputs = mydir + "\\" + inputfile
        self.inf1 = open(self.saved_inputs, 'r')
        for self.field in fields:
            self.row = Frame(self.master)
            self.lab = Label(self.row, width=25, text=self.field, anchor='w')
            self.ent = Entry(self.row)
            self.bi = Button(self.row, text='help',
                        command=(lambda f=self.field: self.get_help(f)))

            self.row.pack(side=TOP, fill=X, padx=5, pady=4)
            self.lab.pack(side=LEFT)
            self.bi.pack(side=LEFT, padx=4, pady=2)
            self.ent.pack(side=RIGHT, expand=YES, fill=X)
            self.ent.delete(0, END)
            self.def_ent = self.inf1.readline()
            self.ent.insert(0, self.def_ent)
            self.entries.append((self.field, self.ent))
        self.inf1.close()
        return self.entries

    def get_help(self,f):
            global help_text
            if f == "File Suffix Tag":
                help_text = "Enter a short tag to be added to the files created in this program to distingh them from files created in other program runs, i.e. ver1"
            elif f == "Raster File Type":
                help_text = "file format of raster input files (stream link and flow direction rasters). Currently, 'flt' is the only working raster file-type"
            elif f == "Stream Link Raster":
                help_text = "Input raster of the stream network with unique values for stream 'links', that is, continuous reaches between junctions (currently value data type must be 32 bit float, and raster format must be .flt (float))"
            elif f == "Flow Direction Raster":
                help_text = "Input raster of the flow direction map, created from a 'hydrologically correct' DEM (i.e. sink filled, AgreeDEM). (currently value data type must be 32 bit float, and raster format must be .flt (float))"
            elif f == "Target Reach Map":
                help_text = "Desired name of outputted segmented reach map (stream link map segmented into desired target reach lengths) "
            elif f == "Target Drainage Map":
                help_text = "Desired name of outputted lateralshed (reach drainage) map "
            elif f == "EPSG/SRID Code":
                help_text = "This is the spatial reference code for your inputted raster dataset. You can look-up the code here: http://spatialreference.org/  "
            elif f == "PGSQL Bin Path":
                help_text = "The path specifying the location of PGSQL/Bin on your local machine "
            elif f == "PGSQL Database Name":
                help_text = "The name of an existing PGSQL database that you would like this program to use "
            elif f == "PGSQL User Name":
                help_text = "The user name for accessing the PGSQL database "
            elif f == "PGSQL Password":
                help_text = "The password for accessing the PGSQL database"
            elif f == "PGSQL Database Schema":
                help_text = "Name of the schema to store program outputs (if left blank, the public (default) schema will be used"
            elif f == "Target Reach Length (m)":
                help_text = "Desired length of reach segments (i.e. 200) "
            else:
                help_text = "Desired table name for calculated flow network specifications"
            self.newWindow = Toplevel(self.master)
            self.app = make_help_box(self.newWindow)


class make_help_box:
    def __init__(self, master):
        self.master = master
        self.frame = Frame(self.master)
        self.text = Text(self.frame)
        self.text.insert(INSERT, help_text)
        self.text.pack()      
        self.quitButton = Button(self.frame, text = 'Quit', width = 25, command = self.close_windows)
        self.quitButton.pack()
        self.frame.pack()
    def close_windows(self):
        self.master.destroy()
    def say_hi(self):
        print help_text

    def createWidgets(self):
        self.QUIT = Button(self)
        self.QUIT["text"] = "EXIT"
        self.QUIT["fg"]   = "red"
        self.QUIT["command"] =  self.quit
        self.QUIT.pack({"side": "left"})
    
def main():
    root = Tk()
    app = mainwindow(root)
    root.mainloop()
    
if __name__ == '__main__':
    main()
    

