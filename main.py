import os, timeit, shutil, subprocess
import sh_modules

mydir = os.getcwd()
os.chdir(mydir)

#rcode = subprocess.call(['python', 'gui_input09.py'])   # open GUI ~ this method is not currently used; instead GUI is executed and "GO" button calls os.subprocess to open main.py

infile = mydir + "\\" + 'input_specs.txt'       # input file used in main.py and GUI
outfile = mydir + "\\" + 'output_specs1.txt'    # input file used in ReachNeighbors.exe & WatershedHiker.exe
outfile2 = mydir + "\\" + 'output_specs2.txt'   # input file used in ReachSplitter.exe
#-----------------------------------------------------------------------------------------------------
# input names used by fortran executable files
#-----------------------------------------------------------------------------------------------------
fcsv_name = 'ReachFlows.csv'   #temporary file outputed from ReachNeighbor.exe for input into getffs
lcsv_name = 'ReachLengths.csv' #temporary file outputted from ReachSplitter.exe for input to PGSQL
tlentab_name = "reachlengths"  # name of temporary table populated from lcsv_name output from ReachSplitter.exe, used to update ftable_name (target flow network table)
templatetempras = 'RchSrch.flt' #template raster name made in MakeTempFile.exe and used in ReachSplitter.exe
#-----------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------
#   Start open input_specs.txt, process info and write to output_specs.txt (1 & 2)  |
#------------------------------------------------------------------------------------
inf = open(infile, 'r')

file_suffix = inf.readline()
file_suffix = "_" + file_suffix.replace('\n', '').replace('\r', '')
raster_format = inf.readline()
raster_format = raster_format.replace('\n', '').replace('\r', '')
stlink_name = inf.readline()
stlink_name = stlink_name.replace('\n', '').replace('\r', '') + "." + raster_format
stlink_loc = mydir + "\\" + stlink_name
fdrmap_name = inf.readline()
fdrmap_name = fdrmap_name.replace('\n', '').replace('\r', '') + "." + raster_format 
fdrmap_loc = mydir + "\\" + fdrmap_name
reachmap_name = inf.readline()
reachmap_name = reachmap_name.replace('\n', '').replace('\r', '') + file_suffix + "." + raster_format
reachmap_loc = mydir + "\\" + reachmap_name
sh_ls_ras_name = inf.readline()
sh_ls_ras_name = sh_ls_ras_name.replace('\n', '').replace('\r', '')
latshedpoly_name = sh_ls_ras_name + "_poly" + file_suffix
sh_ls_ras_name = sh_ls_ras_name + file_suffix + "." + raster_format
sh_ls_ras_loc = mydir + "\\" + sh_ls_ras_name
geom_srid = inf.readline()
geom_srid = geom_srid.replace('\n', '').replace('\r', '')
pgsqlbinpath = inf.readline()
pgsqlbinpath = pgsqlbinpath.replace('\n', '').replace('\r', '')
pgsqlbinpath = ';' + pgsqlbinpath
db_name = inf.readline()
db_name = db_name.replace('\n', '').replace('\r', '')
db_usr_name = inf.readline()
db_usr_name = db_usr_name.replace('\n', '').replace('\r', '')
db_pw = inf.readline()
db_pw = db_pw.replace('\n', '').replace('\r', '')
db_schema = inf.readline()
db_schema = db_schema.replace('\n', '').replace('\r', '')
reach_tar_len = inf.readline()
reach_tar_len = reach_tar_len.replace('\n', '').replace('\r', '')
ftable_name = inf.readline()
seqtable_name = ftable_name.replace('\n', '').replace('\r', '')
ftable_name = ftable_name.replace('\n', '').replace('\r', '') + "_temp_" + file_suffix
seqtable_name = seqtable_name + file_suffix
j_tab_name = "junction_specs" + file_suffix   #make default/dynamic in GUI

inf.close()

reach_tar_len = format(int(reach_tar_len), '.3f')

logfile = mydir + "\\" + 'logfile' + file_suffix + '.txt'   # assign logfile name
#-----------------------------------------------------------------------------------------------------
# get raster specs from stlink raster:
ras_specs = sh_modules12b.getRasterDims(stlink_loc)
#-----------------------------------------------------------------------------------------------------
# Populate output files for use in ReachSplitter, ReachNeighbors & WatershedHiker.exe
#-----------------------------------------------------------------------------------------------------
outf = open(outfile, 'w')

outf.write(reachmap_loc + '\n')
outf.write(fdrmap_loc + '\n')
outf.write(sh_ls_ras_loc + '\n')
outf.write(str(int(float(ras_specs[0]))) + '\n')
outf.write(str(int(float(ras_specs[1]))) + '\n')
outf.write(ras_specs[2] + '\n')
outf.write(ras_specs[3] + '\n')
outf.write(ras_specs[4] + '\n')
outf.write(ras_specs[5] + '\n')

outf.close()

outf2 = open(outfile2, 'w')

outf2.write(stlink_loc + '\n')
outf2.write(fdrmap_loc + '\n')
outf2.write(reachmap_loc + '\n')
outf2.write(str(int(float(ras_specs[0]))) + '\n')
outf2.write(str(int(float(ras_specs[1]))) + '\n')
outf2.write(ras_specs[2] + '\n')
outf2.write(ras_specs[3] + '\n')
outf2.write(ras_specs[4] + '\n')
outf2.write(ras_specs[5] + '\n')
outf2.write(str(ras_specs[6]) + '\n')
outf2.write(reach_tar_len + '\n')

outf2.close()

outlogf = open(logfile, 'w')
#------------------------------------------------------------------------------
#   End open input_specs.txt, process info and write to output_specs.txt      |
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#   Start run MakeTempFile.exe                                               |
#------------------------------------------------------------------------------
print "Start running MakeTempFile.exe "
outlogf.write("Start running MakeTempFile.exe ")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
os.remove(templatetempras)
os.system('MakeTempFileV12.exe')
print "Finished running MakeTempFile.exe "
print timeit.default_timer() - start_time
outlogf.write("Finished running MakeTempFile.exe ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#------------------------------------------------------------------------------
#   End run MakeTempFile.exe                                                 |
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#   Start making copies of temp files for use in ReachSplitter & WatershedHiker|
#-------------------------------------------------------------------------------
print "Start making copies of temp files for use in ReachSplitter & WatershedHiker "
outlogf.write("Start making copies of temp files for use in ReachSplitter & WatershedHiker")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
refras = templatetempras
shutil.copy(refras, 'Assessd_Cell.flt')
shutil.copy(refras, 'FlowOut_accounted.flt')
shutil.copy(refras, 'Assessd_Reach.flt')
shutil.copy(refras, 'Reach_LocShed.flt')
shutil.copy(refras, 'RchSrch2.flt')
shutil.copy(refras, 'SearchMem.flt')
print "Finished making copies of temp files for use in ReachSplitter & WatershedHiker "
print timeit.default_timer() - start_time
outlogf.write("Finished making copies of temp files for use in ReachSplitter & WatershedHiker ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#------------------------------------------------------------------------------
#   End making copies of temp files for use in ReachSplitter & WatershedHiker |
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#   Start run reachsplitter.exe                                               |
#------------------------------------------------------------------------------
print "Start running reachsplitter.exe "
outlogf.write("Start running reachsplitter.exe ")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
os.system('ReachSplitterV12.exe')
sh_modules12b.getrasprj(reachmap_name,fdrmap_name,mydir)  #assign raster prj from input fdr raster
print "Finished running reachsplitter.exe "
print timeit.default_timer() - start_time
outlogf.write("Finished running reachsplitter.exe ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#------------------------------------------------------------------------------
#   End run reachsplitter.exe                                                 |
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#   Start run reachneighbors.exe                                              |
#------------------------------------------------------------------------------
print "Start running ReachNeighbors.exe "
outlogf.write("Start running ReachNeighbors.exe ")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
os.system('ReachNeighborV12.exe')
print "Finished running ReachNeighbors.exe "
print timeit.default_timer() - start_time
outlogf.write("Finished running ReachNeighbors.exe ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#------------------------------------------------------------------------------
#   End run reachneighbors.exe                                                |
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------------
#   Start getting flow network specs                                                       |
#-------------------------------------------------------------------------------------------
print "Start getting flow network specs"
outlogf.write("Start getting flow network specs ")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
sh_modules12b.getffs(db_name, db_usr_name, db_pw, db_schema, mydir, ftable_name, fcsv_name)
print "Finished getting flow network specs"
print timeit.default_timer() - start_time
outlogf.write("Finished getting flow network specs ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#-------------------------------------------------------------------------------------------
#   End getting flow network specs                                                         |
#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------
#   Start getting network aggregation sequence and upstream junction reach IDs                 |
#-----------------------------------------------------------------------------------------------
print "Start getting network aggregation sequence and upstream junction reach IDs"
outlogf.write("Start getting network aggregation sequence and upstream junction reach IDs ")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
sh_modules12b.getaggseq(db_name, db_usr_name, db_pw, db_schema, mydir, ftable_name, seqtable_name, lcsv_name, tlentab_name)
print "Finished getting network aggregation sequence and upstream junction reach IDs"
print timeit.default_timer() - start_time
outlogf.write("Finished getting network aggregation sequence and upstream junction reach IDs ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#------------------------------------------------------------------------------------------------
#   End getting network aggregation sequence and upstream junction reach IDs                    |
#------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#   Start run watershedhiker.exe                                              |
#------------------------------------------------------------------------------
print "Start running WatershedHiker.exe "
outlogf.write("Start running WatershedHiker.exe ")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
os.system('WatershedHikerV12.exe')
sh_modules12b.getrasprj(sh_ls_ras_name,fdrmap_name,mydir)  #assign raster prj from input fdr raster
print "Finished running WatershedHiker.exe "
print timeit.default_timer() - start_time
outlogf.write("Finished running WatershedHiker.exe ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#------------------------------------------------------------------------------
#   End run watershedhiker.exe                                                |
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#   Start convert lateral shed raster to polygon shapefile                    |
#------------------------------------------------------------------------------
print "Start converting lateral shed raster to polygon shapefile  "
outlogf.write("Start converting lateral shed raster to polygon shapefile  ")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
sh_modules12b.ras2poly(sh_ls_ras_name, latshedpoly_name)
print "Finished converting lateral shed raster to polygon shapefile  "
print timeit.default_timer() - start_time
outlogf.write("Finished converting lateral shed raster to polygon shapefile  ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#------------------------------------------------------------------------------
#   End convert lateral shed raster to polygon shapefile                      |
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------------------------
#   Start upload lateral shed polygon shapefile to PostGIS database table                              |
#-------------------------------------------------------------------------------------------------------
print "Start uploading lateral shed polygon shapefile to PostGIS database table "
outlogf.write("Start uploading lateral shed polygon shapefile to PostGIS database table ")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
sh_modules12b.loadshppgis(db_name, db_usr_name, db_pw, db_schema, mydir, pgsqlbinpath, latshedpoly_name, geom_srid)
print "Finished uploading lateral shed polygon shapefile to PostGIS database table "
print timeit.default_timer() - start_time
outlogf.write("Finished uploading lateral shed polygon shapefile to PostGIS database table ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#-------------------------------------------------------------------------------------------------------
#   End upload lateral shed polygon shapefile to PostGIS database table                                |
#-------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------------------------
#   Start calc lateral shed areas and add to postgres table                              |
#-------------------------------------------------------------------------------------------------------
print "Start calculating lateral shed areas and update PostGIS database table "
outlogf.write("Start calculating lateral shed areas and update PostGIS database table ")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
sh_modules12b.calc_ls_area(db_name, db_usr_name, db_pw, db_schema, mydir, pgsqlbinpath, latshedpoly_name, geom_srid, seqtable_name)
print "Finished calculating lateral shed areas and update PostGIS database table "
print timeit.default_timer() - start_time
outlogf.write("Finished calculating lateral shed areas and update PostGIS database table ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#-------------------------------------------------------------------------------------------------------
#   End calc lateral shed areas and add to postgres table                                             |
#-------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------------------------
#   Start calc junction specs and add to postgres table                                                |
#-------------------------------------------------------------------------------------------------------
print "Start calculating junction specs and populate PostGIS database table "
outlogf.write("Start calculating junction specs and populate PostGIS database table ")
start_time = timeit.default_timer()
print start_time
outlogf.write(str(start_time) + '\n')
sh_modules12b.make_j_specs(db_name, db_usr_name, db_pw, db_schema, mydir, pgsqlbinpath, seqtable_name, geom_srid, j_tab_name)
print "Finished calculating junction specs and populate PostGIS database table   "
print timeit.default_timer() - start_time
outlogf.write("Finished calculating junction specs and populate PostGIS database table  ")
outlogf.write(str(timeit.default_timer() - start_time) + '\n')
#-------------------------------------------------------------------------------------------------------
#   End calc junction specs and add to postgres table                                                  |
#-------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------
