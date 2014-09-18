! Developed for compiling with Compaq Visual Fortran Ver. 6.6
PROGRAM MakeTemp
IMPLICIT None
INTEGER::Loop
INTEGER(8)::Row,Col, RecId, NRows, NCols, StartPos

! ***************************************************** Full version *****************************************************
OPEN(1, file = "output_specs2.txt", FORM = "FORMATTED", STATUS = "OLD")

READ(1,*)
READ(1,*) 
READ(1,*)
READ(1,3) NCols
!WRITE(*,*) NCols
READ(1,3) NRows
!WRITE(*,*) NRows

3 FORMAT(i8)

! ********************************************************************************************************************
OPEN(2, file = "RchSrch.flt"  , FORM = "binary" , Status = "UNKNOWN" , access = "direct",RECL = 4)
!**************************************************************************************************************************     

RecID    = 0
StartPos = 0

DO Row = 1,NRows !This the # of rows in the DEM and flow direction map
   DO Col = 1,Ncols !This is the # of columns in the DEM and flow direction map 
      RecID = (((Row-1)*NCols)+Col)
      WRITE(2,rec = RecID) StartPos
   END DO
END DO

END PROGRAM MakeTemp
