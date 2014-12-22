! Developed for compiling with Compaq Visual Fortran Ver. 6.6
PROGRAM GetNetwork
IMPLICIT NONE
INTEGER(8)::Row, Col, NRows, NCols, SrchRec, NumRec, NumValues, SearchNbor, Loop,Counted, MaxReach
INTEGER(8),DIMENSION(9)::SearchOption,SrchRecAdj, FlowIn
INTEGER(8),DIMENSION(128)::FlowOut
INTEGER(4),DIMENSION(3000000,8)::FlowsINReach
INTEGER(4),DIMENSION(3000000)::FlowOutReach, NumInflowReach
INTEGER(4)::Reach, FocalCell, SearchReach, FlowDir
REAL(4)::Value, Real_FlowDir, Real_Reach
CHARACTER(64)::ReachMap,Flowdirection
! ***************************************************** Full version *****************************************************
OPEN(6, file = "output_specs1.txt", FORM = "FORMATTED", STATUS = "OLD")
!Geographic extent of map.
WRITE(*,*) "open"

READ(6,2) ReachMap
!WRITE(*,*) ReachMap
READ(6,2) Flowdirection 
!WRITE(*,*) Flowdirection
READ(6,*)
READ(6,3) NCols
!WRITE(*,*) NCols
READ(6,3) NRows
!WRITE(*,*) NRows

2 FORMAT(A64)
3 FORMAT(i8)

CLOSE(6)
! ********************************************************************************************************************

OPEN(1, file = "ReachFlows.CSV"            , FORM = "FORMATTED", STATUS = "UNKNOWN") 
OPEN(2, file = ReachMap                    , FORM = "BINARY", RECL = 4, ACCESS ="DIRECT", STATUS = "OLD")
OPEN(3, file = Flowdirection               , FORM = "BINARY", RECL = 4, ACCESS ="DIRECT", STATUS = "OLD")
OPEN(4, file = "reachmap_int.flt"          , FORM = "BINARY", RECL = 4, ACCESS ="DIRECT")
OPEN(5, file = "flowdir_int.flt"           , FORM = "BINARY", RECL = 4, ACCESS ="DIRECT")

MaxReach     = 0  
! ********************************************************************************************************************
WRITE(*,*) "Resetting virtual memory"
NumRec = 0
DO Row = 1,NRows 
   DO Col = 1, NCols 
      NumRec = ((Row - 1)*NCols)+Col
      READ(2,rec = numrec) Real_Reach
      Reach = Real_Reach
	  IF(Reach.GT.MaxReach) MaxReach = Reach
      READ(3,rec = numrec) Real_FlowDir
      FlowDir = Real_FlowDir
      WRITE(4, rec = numrec) Reach        ! Create reachmap of integer data type to be used here and later by WatershedHiker.exe
      WRITE(5, rec = numrec) FlowDir
   END DO
END DO
WRITE(*,*) "Done Resetting virtual memory"
! ********************************************************************************************************************
 
FLowsInReach  = 0
NumInflowReach= 0
SrchRecAdj(1) =  1
SrchRecAdj(2) =  NCols + 1
SrchRecAdj(3) =  NCols
SrchRecAdj(4) =  NCols - 1
SrchRecAdj(5) = -1
SrchRecAdj(6) = -NCols - 1
SrchRecAdj(7) = -NCols
SrchRecAdj(8) = -NCols + 1

FlowIn  (1) =  16 ! of focal!Right
FlowIn  (2) =  32
FlowIn  (3) =  64 !below focal
FlowIn  (4) = 128
FlowIn  (5) =   1 !If the neighbor flowdir = this THEN it flows into the cell.
FlowIn  (6) =   2
FlowIn  (7) =   4
FlowIn  (8) =   8

FlowOut (1)   =  1 !1 = right cell OutcreasOutg clockwise.
FlowOut (2)   =  2
FlowOut (4)   =  3
FlowOut (8)   =  4
FlowOut (16)  =  5
FlowOut (32)  =  6
FlowOut (64)  =  7
FlowOut (128) =  8

DO Row = 1,NRows 
   DO Col = 1, NCols 
      NumRec = ((Row - 1)*NCols)+Col
      READ(4, rec = NumRec) FocalCell
	  SearchOption = 1.0 ! Reset search window options to all directions available.
      IF (Col.eq.1) THEN
         SearchOption(4) = 0; SearchOption(5) = 0; SearchOption(6) = 0
      END IF
      IF (Col.eq.NCols) THEN
         SearchOption(8) = 0; SearchOption(1) = 0; SearchOption(2) = 0
      END IF   
      IF (Row.eq.1) THEN
         SearchOption(6) = 0; SearchOption(7) = 0; SearchOption(8) = 0
      END IF
      IF (Row.eq.NRows) THEN
         SearchOption(2) = 0; SearchOption(3) = 0; SearchOption(4) = 0
      END IF   

	  READ(4,rec = NumRec) Reach
	  READ(5,rec = NumRec) FlowDir
	  IF(Reach.GT.0) THEN
	     IF(FlowDir.GT.0) THEN
		    SearchNBor = FlowOut(FlowDir)
	                IF(SearchOption(SearchNBor).NE.0) THEN
			   SrchRec = NumRec + SrchRecAdj(SearchNBor)
			   READ(4,rec = SrchRec) SearchReach
			   IF(SearchReach.GT.0) THEN
			      IF(SearchReach.NE.Reach) THEN
				     FlowOutReach(Reach) = SearchReach
		              END IF
			   END IF
			END IF
	     END IF
	  END IF
      IF(Reach.Gt.0) THEN           
         DO SearchNbor = 1,8
            IF(SearchOption(SearchNbor).NE.0) THEN
			   SrchRec = NumRec + SrchRecAdj(SearchNBor)
			   READ(4,rec = SrchRec) SearchReach
			   IF(SearchReach.GT.0) THEN				  
			      READ(5,rec = SrchRec) FlowDir
			      IF(FlowIn(SearchNBor).EQ.FlowDir) THEN 
				     Counted = 0
				     DO Loop = 1,8
                                        IF(FlowsINReach(Reach,Loop).EQ.SearchReach) Counted = 1
			             END DO
				     IF(Counted.EQ.0) THEN
				        NumInflowReach(Reach) = NumInflowReach(Reach) + 1
					FlowsINReach(Reach,NumInflowReach(Reach)) = SearchReach
			             END IF 
			      END IF
			   END IF
            END IF
	 END DO	  
      END IF
   END DO
END DO
DO Loop = 1, MaxReach
   WRITE(1,10) Loop,FlowOutReach(Loop),NumInflowReach(Loop),FlowsINReach(Loop,1),FlowsINReach(Loop,2),FlowsINReach(Loop,3), &
        FlowsINReach(Loop,4)
END DO
10 FORMAT(I6,6(",",I6))
CLOSE(1)
CLOSE(2)
CLOSE(3)
CLOSE(4)
CLOSE(5)
WRITE(*,*) "DONE"
END PROGRAM GetNetwork
