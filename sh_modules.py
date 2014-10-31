import sys, os, subprocess, shutil
import gdal, ogr, osr
from gdalconst import *
import psycopg2.extras

#------------------------------------------------------------------------------
#  getRasterDims:  Get Raster Dimensions (# rows & columns + extents)         |
# ----------------(adapted from: https://www.siafoo.net/snippet/69/rev/1)     |
#------------------------------------------------------------------------------

def getRasterDims(path):
    if not os.path.isfile(path):
        return []
    data = gdal.Open(path,GA_ReadOnly)
    if data is None:
        return []
    geoTransform = data.GetGeoTransform()
    numcols = data.RasterXSize
    numrows = data.RasterYSize
    minx = geoTransform[0]
    maxy = geoTransform[3]
    xres = geoTransform[1]
    yres = abs(geoTransform[5])
    
    maxx = minx + xres*numcols
    miny = maxy - yres*numrows
    minx = format(minx, '.3f')
    maxx = format(maxx, '.3f')
    miny = format(miny, '.3f')
    maxy = format(maxy, '.3f')
    numcols = format(numcols, '.3f')
    numrows = format(numrows, '.3f')
    #file.close()

    return [numcols,numrows,minx,miny,maxx,maxy,xres,yres]

#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
#  poly2ras:   Convert shapefile to raster - used when input shapefile is polyline file from segmented   |
#                stream network (output from NHDflowline segmentation routine)                           |
#---------------------------------------------------------------------------------------------------------
def poly2ras(fdrrasname, reachmapshp):   
    
    # Define pixel_size and NoData value of new raster
#   raster_dims = sh_modules02.getRasterDims("fdrb_testarea.flt")
    raster_dims = getRasterDims(fdrrasname)
    NoData_value = -9999.0
    ncols = int(float(raster_dims[0]))
    nrows = int(float(raster_dims[1]))
    x_min = float(raster_dims[2])
    y_max = float(raster_dims[5])
    x_res = float(raster_dims[6])
    y_res = float(raster_dims[7])
    geotransform=(x_min,x_res,0,y_max,0,-y_res)
    
    # Filename of input OGR file
    vector_fn = "'" + reachmapshp + "'"
#   vector_fn = nhd200y_tarzz_sel.shp'                         # update to assign from input_specs.txt file
    # Filename of the raster that will be created
    raster_fn = 'nhd200y_tarzz_sel_ras.flt'                     # update to by dynamically named based on input shapefile name (inshpfilename + "_ras.flt")
    
    # Open the data source and read in the extent & projection
    source_ds = ogr.Open(vector_fn)
    source_layer = source_ds.GetLayer()
    
    # Create the destination data source
    
    target_ds = gdal.GetDriverByName('EHdr').Create(raster_fn, ncols, nrows, 1, gdal.GDT_Float32)
    target_ds.SetGeoTransform(geotransform)
    
    # Get projection of shapefile and assigned to raster
    srs = osr.SpatialReference()
    srs.ImportFromWkt(source_layer.GetSpatialRef().__str__())
    target_ds.SetProjection(srs.ExportToWkt())
    
    band = target_ds.GetRasterBand(1)
    #band.Fill(NoData_value)
    band.SetNoDataValue(NoData_value)
    
    # Rasterize
    gdal.RasterizeLayer(target_ds, [1], source_layer, options = ["ATTRIBUTE=REACHID"])

#-----------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------
#  ras2poly:  Convert LocShed Output raster to ESRI shapefile (polygon)                                          |
#------------ (adapted from http://bundleblogadjustment.wordpress.com/2011/04/17/extracting-raster-infromation/) |
#-----------------------------------------------------------------------------------------------------------------

def ras2poly(path2, outShapefile):   # add outshpefile name specified from main (user-specified)
    if not os.path.isfile(path2):
        return []
    data2 = gdal.Open(path2,GA_ReadOnly)
    if data2 is None:
        return []
    #-----first we access the projection information within our datafile using the GetProjection() method. This returns a string in WKT format 
    prj = data2.GetProjection()
    #-----Then we use the osr module that comes with GDAL to create a spatial reference object
    spatialRef = osr.SpatialReference()
    #-----We import our WKT string into spatialRef
    spatialRef.ImportFromWkt(prj)
    #-----We use the ExportToProj4() method to return a proj4 style spatial reference string
    #-----spatialRefProj = spatialRef.ExportToProj4()
    band = data2.GetRasterBand(1)
    #outShapefile = "LocalReachPoly"
    driver = ogr.GetDriverByName("ESRI Shapefile")
    if os.path.exists(outShapefile + ".shp"):
        driver.DeleteDataSource(outShapefile + ".shp")
    outDatasource = driver.CreateDataSource(outShapefile + ".shp")
    outLayer = outDatasource.CreateLayer(outShapefile, srs=None)
    newField = ogr.FieldDefn('ReachID', ogr.OFTInteger)
    outLayer.CreateField(newField)
    gdal.Polygonize( band, None, outLayer, 0, [], callback=None )
    outDatasource.Destroy()
    data2 = None
    spatialRef.MorphToESRI()
    outShapefile_prj = outShapefile + ".prj"
    file2 = open(outShapefile_prj, 'w')
    file2.write(spatialRef.ExportToWkt())
    file2.close() 
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#  copyras:     Makes copy of a raster with a specified target name                              |
#----------------------------------------------------------------------------------------------------
def copyras(tarras,refras, dir):
    shutil.copy(refras, tarras)
    
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#  getrasprj:     Copies raster projection info from input raster prj info                          |
#----------------------------------------------------------------------------------------------------
def getrasprj(tarras,refras, dir):
    tarras_prj = tarras[:len(tarras) - 3] + "prj"
    tarras_hdr = tarras[:len(tarras) - 3] + "hdr"
    refras_prj = refras[:len(refras) - 3] + "prj"
    refras_hdr = refras[:len(refras) - 3] + "hdr"
    shutil.copy(refras_prj, tarras_prj)
    shutil.copy(refras_hdr, tarras_hdr)
    
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#  loadshppgis:     Load    |
#----------------------------------------------------------------------------------------------------
def loadshppgis(dbname, dbusrname, dbpw, dbschema, dir, pgsqlbinpath, inshp_name, srid):

    inshp_loc = dir + "\\" + inshp_name + ".shp"
    inshptable_name = inshp_name

    # Choose your PostgreSQL version here
    os.environ['PATH'] += "r" + pgsqlbinpath
    # http://www.postgresql.org/docs/current/static/libpq-envars.html
    os.environ['PGHOST'] = 'localhost'
    os.environ['PGPORT'] = '5432'
    os.environ['PGUSER'] = dbusrname
    os.environ['PGPASSWORD'] = dbpw
    os.environ['PGDATABASE'] = dbname
    
    cmds = "shp2pgsql -d -I -s " + srid + " " + inshp_loc + " " + dbschema + "." + inshptable_name + "| psql -d " + dbname 
    print cmds
    subprocess.call(cmds, shell=True)
#---------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
# loadraspgis:  import raster with specified specs to post gis                                       |
#----------------------------------------------------------------------------------------------------
def loadraspgis(dbname, dbusrname, dbpw, dbschema, dir, pgsqlbinpath, inras_name, srid):    #improve by also inputting tile size or dynamically calculating optimal size
    
    inras_loc = dir + "\\" + inras_name + ".flt"
    inrastable_name = inras_name

    os.environ['PATH'] += "r" + pgsqlbinpath
    # http://www.postgresql.org/docs/current/static/libpq-envars.html
    os.environ['PGHOST'] = 'localhost'
    os.environ['PGPORT'] = '5432'
    os.environ['PGUSER'] = dbusrname
    os.environ['PGPASSWORD'] = dbpw
    os.environ['PGDATABASE'] = dbname
    
    cmds = "raster2pgsql -d -s " + srid + " " + "-I -C -Y " + inras_loc + " -F -t 1000x1000 " + dbschema + "." + inrastable_name + "| psql -d " + dbname
    print cmds
    subprocess.call(cmds, shell=True)
#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#  getffs:   Count number of flow from reaches and get flow from freachIDs; make postgresql table   |
#----------------------------------------------------------------------------------------------------
def getffs(dbname, dbusrname, dbpw, dbschema, dir, ftable_name, fcsv_name):
    con = None
    reachid = 0
    numff = 0
    ff1 = 0
    ff2 = 0
    ff3 = 0
    myschema = dbschema
    reachflowsloc = myschema + "." + ftable_name
    reachflowscsvloc = dir + "\\" + fcsv_name
    reachflowscsvloc = "'" + reachflowscsvloc + "'"
    
    try:
        con = psycopg2.connect(database = dbname, user= dbusrname, password= dbpw)  
        cur1 = con.cursor(cursor_factory=psycopg2.extras.DictCursor)
    #===========================================================================    
        cur1.execute('SELECT version()')
        ver = cur1.fetchone()  
    #===========================================================================              
        SQL01 = (
                 "DROP TABLE IF EXISTS %s; "
                 "CREATE TABLE %s "
                "( "
                  "reachid integer , "
                  "reachto integer , "
                  "numff integer , "
                  "ff0 integer , "
                  "ff1 integer , "
                  "ff2 integer , "
                  "ff3 integer "
                ") "
                "WITH ( "
                  "OIDS=FALSE "
                "); "
                "ALTER TABLE %s "
                  "OWNER TO postgres; "           
                "COPY %s FROM %s CSV ; "    # use relative path from fortran output
                 )%(reachflowsloc, reachflowsloc, reachflowsloc, reachflowsloc, reachflowscsvloc)
         
        try:
            cur1.execute(SQL01)
            con.commit()
            
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(1) 
                  
        SQL0 = (
                "SELECT * "
                    "FROM %s ;"
                )%(reachflowsloc)
        
        try:
            cur1.execute(SQL0)
            rows = cur1.fetchall()
            j = 0
            
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(1)
              
        try:
                    
            for row in rows:

                reachid = row['reachid']
                numff = 0
                ff1 = 0
                ff2 = 0
                ff3 = 0
                
                ffs = [row['ff0'], row['ff1'], row['ff2'], row['ff3']]
     
                if reachid in ffs:
                    ffs.remove(reachid)
                
                ffs = sorted(ffs, reverse = True)
               
                ff1 = ffs[0] 
                ff2 = ffs[1]
                ff3 = ffs[2]
    
                if ff3 != 0:
                    numff = 3
                elif ff2 != 0:
                    numff = 2
                elif ff1 != 0:
                    numff = 1
                else: numff = 0    
                 
                SQL1 = (
                        "UPDATE %s SET numff = %s, ff1 = %s, ff2 = %s, ff3 = %s "
                            "WHERE reachid = %s ;"
                        )%(reachflowsloc, numff, ff1, ff2, ff3, reachid)
                                                
                cur1.execute(SQL1)
                con.commit()
    
                j = j + 1
    
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(1)
            
        SQL2 = (
                "ALTER TABLE %s DROP COLUMN IF EXISTS %s"
                )%(reachflowsloc, "ff0")
        
        try:
            cur1.execute(SQL2)
            con.commit()
            
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(2)
    
    finally:
        if con:
            con.close()
            print "finished"
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
#  getaggseq:   Assigns aggregation sequence and reach ID of nearest upstream junction or headwaters reach |   |
#-----------------------------------------------------------------------------------------------------------
def getaggseq(dbname, dbusrname, dbpw, dbschema, dir, ftable_name, seqtable_name, lcsv_name, tlentab_name):
    
    con = None    
    reachid = 0
    reachto = 0
    ftab_loc = dbschema + "." + ftable_name
    seqtab_loc = dbschema + "." + seqtable_name
    reachlengthscsvloc = dir + "\\" + lcsv_name
    reachlengthscsvloc = "'" + reachlengthscsvloc + "'"
    tlentab_loc = dbschema + "." + tlentab_name
 
    try:
        con = psycopg2.connect(database = dbname, user= dbusrname, password= dbpw) 
        cur1 = con.cursor(cursor_factory=psycopg2.extras.DictCursor)
    #==============================================================================    
        cur1.execute('SELECT version()')
        ver = cur1.fetchone() 
    #===============================================================================
        # Upload reachlengths.csv (reachlengthscsvloc) output from ReachSplitter.exe to temp table (tlentab_loc) for later joining to network flow specs table
        SQL00 = (
                 "DROP TABLE IF EXISTS %s; "
                 "CREATE TABLE %s "
                 "( "
                    "reachid integer, "
                    "reach_length float8 "
                 ") "
                 "WITH ( "
                    "OIDS=FALSE "
                 "); "
                 "ALTER TABLE %s OWNER TO %s; "
                 "COPY %s FROM %s CSV; "
                 )%(tlentab_loc, tlentab_loc, tlentab_loc, dbusrname, tlentab_loc, reachlengthscsvloc)
        
        try:
            cur1.execute(SQL00)
            con.commit()
            
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(1)
        
        #Create new table (copy ftable_name & add columns for aggseq_rid & upjun_rid
        SQL0 = (
                 "DROP TABLE IF EXISTS %s; "
                 "CREATE TABLE %s AS "
                    "TABLE %s; "
                 "ALTER TABLE %s ADD COLUMN aggseq_rid integer DEFAULT 0 ; "
                 "ALTER TABLE %s ADD COLUMN upjun_rid integer DEFAULT 0 ; "
                 "ALTER TABLE %s ADD COLUMN reach_length float8 DEFAULT 0.0 ; "
                 "UPDATE %s st "
                 "SET reach_length = tlt.reach_length "
                 "FROM %s tlt "
                 "WHERE st.reachid = tlt.reachid; "                
                 "DROP TABLE IF EXISTS %s; "
                 "DROP TABLE IF EXISTS %s; "
                 )%(seqtab_loc, seqtab_loc, ftab_loc, seqtab_loc, seqtab_loc, seqtab_loc, seqtab_loc, tlentab_loc, ftab_loc, tlentab_loc)
        
        try:
            cur1.execute(SQL0)
            con.commit()
            
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(1)

    #Select headwaters (numff = 0) reaches:    
        
        SQL1 = (
                "SELECT * "
                    "FROM %s "
                 "WHERE numff = 0 "
                 "ORDER BY reachid; " 
                )%(seqtab_loc)
        
        try:
            cur1.execute(SQL1)
            rows = cur1.fetchall()
            myseq = 0
            
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(1)
            
        try:
    #For each headwater reach:                        
            for row in rows:
                myseq += 1
                mynumff = 0
                reachid = row['reachid']
                reachto = row['reachto']
                myreachto = reachto
                myupjun_rid = reachid
                
                SQL2 = (
                           "UPDATE %s "
                           "SET aggseq_rid = %s,"         
                               "upjun_rid = %s "        
                               "WHERE reachid = %s ;"
                               )%(seqtab_loc, 
                                  myseq, myupjun_rid,  
                                  reachid)
                                                    
                cur1.execute(SQL2)
                con.commit()

    #Select downstream reach (reachto):
                while mynumff < 2 and myreachto > 0: # and myreachto < 290:  # make this less than the max reachid 
                    
                    #print "myreachto", myreachto
                    
                    SQL3 = (
                            "SELECT * "
                                "FROM %s "
                            "WHERE reachid = %s ;" 
                            )%(seqtab_loc, myreachto)
        
                    try:
                        cur1.execute(SQL3)
                        nextreach = cur1.fetchone()
      
                    except psycopg2.DatabaseError, e:
                        print 'Error %s' % e
                        sys.exit(1)
                        
    #Populate variables for downstream reach values:                    
                    myreachid = nextreach['reachid']
                    mynumff = nextreach['numff']
                    myff1 = nextreach['ff1']
                    myff2 = nextreach['ff2']
                    myff3 = nextreach['ff3']
    
    #If downstream reach is not a junction (mynumff < 2) :               
    
                    if mynumff < 2:
                        myseq += 1
                         
                        SQL4 = (
                            "UPDATE %s "
                            "SET aggseq_rid = %s,"         
                                "upjun_rid = %s "        
                                "WHERE reachid = %s ;"
                                )%(seqtab_loc, 
                                   myseq, myupjun_rid,  
                                   myreachid)
                                                    
                        cur1.execute(SQL4)
                        con.commit()
                        
    #If downstream reach is a junction of 2 upstream reaches (mynumff = 2) :                      
                    elif mynumff == 2:
                        
                        SQL5 = (
                            "SELECT * "
                                "FROM %s "
                            "WHERE reachid = %s ;"                                                
                            )%(seqtab_loc, myff1)
                                
                        cur1.execute(SQL5)
                        x1 = cur1.fetchone()
                        ff1_agg_seq = x1['aggseq_rid']
                        
                        if ff1_agg_seq > 0:
                            
                            SQL6 = (
                                "SELECT * "
                                    "FROM %s "
                                "WHERE reachid = %s ;"                                                
                                )%(seqtab_loc, myff2)
                                    
                            cur1.execute(SQL6)
                            #con.commit()
                            x2 = cur1.fetchone()
                            ff2_agg_seq = x2['aggseq_rid']
                            
                            if ff2_agg_seq > 0:
                                myseq += 1
                                myupjun_rid = myreachid
                                SQL7 = (
                                    "UPDATE %s "
                                    "SET aggseq_rid = %s,"         
                                        "upjun_rid = %s "         
                                        "WHERE reachid = %s ;"
                                        )%(seqtab_loc, 
                                           myseq, myupjun_rid,   
                                           myreachid)
                                                            
                                cur1.execute(SQL7)
                                con.commit()
    
                                mynumff = 1
                    
                    else:
                        
                        SQL8 = (
                            "SELECT * "
                            "FROM %s "
                            "WHERE reachid = %s ;"                                                
                            )%(seqtab_loc, myff1)
                                
                        cur1.execute(SQL8)
                        #con.commit()
                        x1 = cur1.fetchone()
                        ff1_agg_seq = x1['aggseq_rid']
                        
                        if ff1_agg_seq > 0:
                            
                            SQL9 = (
                                "SELECT * "
                                "FROM %s "
                                "WHERE reachid = %s ;"                                                
                                )%(seqtab_loc, myff2)
                                    
                            cur1.execute(SQL9)
                            #con.commit()
                            x2 = cur1.fetchone()
                            ff2_agg_seq = x2['aggseq_rid']
                            
                            if ff2_agg_seq > 0:
                                
                                SQL10 = (
                                    "SELECT * "
                                    "FROM %s "
                                    "WHERE reachid = %s ;"                                                
                                    )%(seqtab_loc, myff3)
                                        
                                cur1.execute(SQL10)
                                #con.commit()
                                x3 = cur1.fetchone()
                                ff3_agg_seq = x3['aggseq_rid']
                            
                                if ff3_agg_seq > 0:
                                    myseq += 1
                                    myupjun_rid = myreachid
                                    
                                    SQL11 = (
                                    "UPDATE %s "
                                    "SET aggseq_rid = %s,"         
                                        "upjun_rid = %s "         
                                        "WHERE reachid = %s ;"
                                        )%(seqtab_loc, 
                                           myseq, myupjun_rid,   
                                           myreachid)
                                                                         
                                    cur1.execute(SQL11)
                                    con.commit()
    
                                    mynumff = 1    
            # set next reachto        
                    myreachto = nextreach['reachto']
    
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(1)
    
    finally:
        if con:
            con.close()
            print "finished"

#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
#  calc_ls_area:   Calculates lateral shed areas (in sqkm) and populates postgis table                     |
#-----------------------------------------------------------------------------------------------------------
def calc_ls_area(dbname, dbusrname, dbpw, dbschema, dir, pgsqlbinpath, ls_geom_tab_name, srid, seqtable_name):
    
    con = None    
    reachid = 0
    reachto = 0
    ls_geom_tab_loc = dbschema + "." + ls_geom_tab_name
    seqtab_loc = dbschema + "." + seqtable_name
    print seqtab_loc
    temp_ls_area_tab = dbschema + "." + 'temp_ls_area'
    
 
    try:
        con = psycopg2.connect(database = dbname, user= dbusrname, password= dbpw) 
        cur1 = con.cursor(cursor_factory=psycopg2.extras.DictCursor)
    #==============================================================================    
        cur1.execute('SELECT version()')
        ver = cur1.fetchone() 
    #===============================================================================
        
        SQL1 = (
                "DROP TABLE IF EXISTS %s ; "
                "CREATE TABLE %s AS "
                "SELECT reachid, sum(ST_AREA(geom)) / 1000000 AS ls_area_sqkm "     # units taken from geom coordinate system (here, meters)
                "FROM %s "
                "WHERE reachid > 0 "
                "GROUP BY reachid;"
                )%(temp_ls_area_tab, temp_ls_area_tab, ls_geom_tab_loc)
                
        try:
            cur1.execute(SQL1)
            con.commit()
      
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(1)
            
        SQL2 = (             
               "ALTER TABLE %s ADD COLUMN ls_area_sqkm float8 default 0.0; "
             
               "UPDATE %s rs set ls_area_sqkm = asqkm.ls_area_sqkm "
                    "FROM %s asqkm "
                    "WHERE rs.reachid = asqkm.reachid; "
               "DROP TABLE IF EXISTS %s; "
               )%(seqtab_loc, seqtab_loc, temp_ls_area_tab,temp_ls_area_tab) 
               
        try:
            cur1.execute(SQL2)
            con.commit()
      
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(2)

    finally:
        if con:
            con.close()
            print "finished"

#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
#  Make Juntion_Specs Table:   Calculates Junction specs and populates PostGIS                             |
#-----------------------------------------------------------------------------------------------------------

def make_j_specs(dbname, dbusrname, dbpw, dbschema, dir, pgsqlbinpath, seqtable_name, srid, j_tab_name):
    
    con = None    
    reachid = 0
    reachto = 0
    j_tab_loc = dbschema + "." + j_tab_name
    seqtab_loc = dbschema + "." + seqtable_name
    my_j_aggseq = 0

    try:
        con = psycopg2.connect(database = dbname, user= dbusrname, password= dbpw) 
        cur1 = con.cursor(cursor_factory=psycopg2.extras.DictCursor)
    #==============================================================================    
        cur1.execute('SELECT version()')
        ver = cur1.fetchone() 
    #===============================================================================

        SQL1 = (
                "DROP TABLE IF EXISTS %s ; "
                "CREATE TABLE %s AS "
                "SELECT rs.reachid, rs.reachto, rs.numff, rs.ff1 AS reach_ff1, rs.ff2 AS reach_ff2, rs.ff3 AS reach_ff3, rs.aggseq_rid AS reach_aggseq, rs.reach_length AS reach_length_m " 
                "FROM %s rs "
                "WHERE numff != 1; "
                       
                "DROP TABLE IF EXISTS shdev.junction_specs2; "
                "CREATE TABLE shdev.junction_specs2 AS "
                    "SELECT foo2.*, rs3.upjun_rid AS j_ff3 "
                    "FROM ( "
                        "SELECT foo1.*, rs2.upjun_rid AS j_ff2 "
                        "FROM ( "
                            "SELECT js.*, rs1.upjun_rid AS j_ff1 "
                            "FROM %s js "
                            "LEFT JOIN %s rs1 ON rs1.reachid = js.reach_ff1 "
                            ") foo1 "
                        "LEFT JOIN %s rs2 ON rs2.reachid = reach_ff2 "
                        ") foo2 "
                    "LEFT JOIN %s rs3 ON rs3.reachid = reach_ff3 "
                "; "
                
                "DROP TABLE IF EXISTS %s; "
                "CREATE TABLE %s AS "
                
                "SELECT js.*, foo.* "
                "FROM shdev.junction_specs2 js "
                "LEFT JOIN (SELECT upjun_rid, sum(reach_length) AS j_reach_length_m, sum(ls_area_sqkm) AS j_ls_area_sqkm "
                "FROM %s rs "
                "GROUP BY rs.upjun_rid) foo ON foo.upjun_rid = js.reachid; "
                
                "UPDATE %s "
                    "SET j_ff1 = 0 "
                    "WHERE j_ff1 IS NULL; "
                "UPDATE %s " 
                    "SET j_ff2 = 0 "
                    "WHERE j_ff2 IS NULL; "
                "UPDATE %s " 
                    "SET j_ff3 = 0 "
                    "WHERE j_ff3 IS NULL; "
                
                "DROP TABLE IF EXISTS shdev.junction_specs2; "
                )%(j_tab_loc, j_tab_loc, seqtab_loc, j_tab_loc, seqtab_loc, seqtab_loc, seqtab_loc, j_tab_loc, j_tab_loc, seqtab_loc, j_tab_loc, j_tab_loc, j_tab_loc) 
        
        try:
                cur1.execute(SQL1)
                con.commit()
         
        except psycopg2.DatabaseError, e:
                print 'Error %s' % e
                sys.exit(1)
                
        SQL2 = (
                "SELECT * "
                "FROM %s "
                "ORDER BY reach_aggseq; " 
                    )%(j_tab_loc)
            
        try:
            cur1.execute(SQL2)
            jrows = cur1.fetchall()
            
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(2)
            
        SQL3 = (
                "ALTER TABLE %s ADD COLUMN j_to integer; " 
                "ALTER TABLE %s ADD COLUMN j_agg_seq integer; "         
                )%(j_tab_loc, j_tab_loc)
        try:
            cur1.execute(SQL3)
            con.commit()
            
        except psycopg2.DatabaseError, e:
            print 'Error %s' % e
            sys.exit(3)
            
        for jrow in jrows:
            
            j_rid = jrow['reachid']
            my_j_aggseq += 1
            
            SQL4 = (
                    "SELECT * "
                    "FROM %s rs "
                    "WHERE rs.upjun_rid = %s "
                    "ORDER BY aggseq_rid DESC "
                    "LIMIT 1; "                 
                    )%(seqtab_loc, j_rid)
            try:
                cur1.execute(SQL4)
                rsrow = cur1.fetchone()
                
            except psycopg2.DatabaseError, e:
                print 'Error %s' % e
                sys.exit(4)
            
            my_j_to = rsrow['reachto']
            
            SQL5 = (
                    "UPDATE %s SET j_to = %s WHERE reachid = %s; "
                    "UPDATE %s SET j_agg_seq = %s WHERE reachid = %s; "                                
                    )%(j_tab_loc, my_j_to, j_rid, j_tab_loc, my_j_aggseq, j_rid)
                    
            try:
                cur1.execute(SQL5)
                con.commit()
                
            except psycopg2.DatabaseError, e:
                print 'Error %s' % e
                sys.exit(5)
        
    finally:
        if con:
            con.close()
            print "finished"
