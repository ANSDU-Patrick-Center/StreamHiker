! Developed for compiling with Compaq Visual Fortran Ver. 6.6
PROGRAM Reach_Drainage
REAL(4)::TempRow,TempCol,NoValue,Real_Reach,FlowDir_Map 
REAL(4)::Value
INTEGER(4)::Row,Col, HikeRow,HikeCol,NRows, NCols, Endrow
INTEGER(4)::MoveDownCell
INTEGER(4)::FlowDir_MapINT
INTEGER(8)::NumRec,WSrchRec,Col_Hiker,Row_Hiker,MaxReach,HikingRec,Srch_WshdRec
INTEGER(4)::ReachBasinAssessed,MoveNextReach,WShed_searchd,All_Searched,NotTop,WSearchNbor,SearchNbor
INTEGER(4)::NotEnd,NotSrchedDir,Loop,WHikeRow,WHikeCol
INTEGER(4),DIMENSION(8)::Shd_SearchOption,SearchOption,FlowRefOut,FlowIn,SrchRecAdj
INTEGER(4),DIMENSION(128)::FlowOut
INTEGER(4),DIMENSION(9)::FlowInDir
INTEGER(4)::Assessd_Cell,FlowOut_accounted,Reach,SrchReach,NextReach,Reach_INT
INTEGER(4),DIMENSION(3000000)::Assessd_Reach
REAL(8)::REAL_HikingRec,REAL_NCols
INTEGER(8)::NewHikeRec,MaxRec,ReachRec,TempRec,SrchRec				  
REAL(8)::MinX,MaxX,MinY,MaxY
INTEGER(4)::StopRun
CHARACTER(64)::ReachMap,Flowdirection,LocShedMap
!PUBLIC::DirectionGuide,GoUpStream,GoDownStream, ReachWShed

Value              = 1.0
NoValue            = 0.0
ReachBasinAssessed = 0.0
Assessd_Cell	   = 0
Assessd_Reach	   = 0
FlowOut_accounted  = 0
FlowDir_Map	   = 0
Reach              = 0

! ***************************************************** Full version *****************************************************
OPEN(5, file = "output_specs1.txt", FORM = "FORMATTED", STATUS = "OLD")
!Geographic extent of map.
!WRITE(*,*) "open"

READ(5,2) ReachMap
!WRITE(*,*) ReachMap
READ(5,2) Flowdirection
!WRITE(*,*) Flowdirection
READ(5,2) LocShedMap
!WRITE(*,*) LocShedMap
READ(5,3) NCols
!WRITE(*,*) NCols
READ(5,3) NRows
!WRITE(*,*) NRows
READ(5,1) MinX
!WRITE(*,*) MinX
READ(5,1) MinY
!WRITE(*,*) MinY
READ(5,1) MaxX
!WRITE(*,*) MaxX
READ(5,1) MaxY
!WRITE(*,*) MaxY

1 FORMAT(F15.3)
2 FORMAT(A64)
3 FORMAT(i8)
! ********************************************************************************************************************
!----------- Base information
OPEN(1, file = "reachmap_int.flt"      , FORM = "BINARY"   , RECL = 4, ACCESS ="DIRECT")
OPEN(2, file = Flowdirection           , FORM = "BINARY"   , RECL = 4, ACCESS ="DIRECT")
!OPEN(3, file = ReachMap                , FORM = "BINARY"   , RECL = 4, ACCESS ="DIRECT")
OPEN(4, file = LocShedMap              , FORM = "BINARY"   , RECL = 4, ACCESS ="DIRECT")

! Files used for virtual memory
OPEN(10, file = "Assessd_Cell.flt"     , FORM = "BINARY"   , RECL = 4, ACCESS ="DIRECT")
OPEN(11, file = "FlowOut_accounted.flt", FORM = "BINARY"   , RECL = 4, ACCESS ="DIRECT") 
OPEN(12, file = "Assessd_Reach.flt"    , FORM = "BINARY"   , RECL = 4, ACCESS ="DIRECT")  
OPEN(13, file = "Reach_LocShed.flt"    , FORM = "BINARY"   , RECL = 4, ACCESS ="DIRECT")


!----------------------Calculated grid cell resolution for each of the map extents---------------------------------------

EndRow = NRows !Terminates the program when the hikerow hits bottom edge of map

CALL DirectionGuide !Initialize memory of flow directions 

! Set memory of cells searched to zero for watershed cells and reach cells.
Reach             = 0
Assessd_Cell      = 0
Assessd_Reach     = 0
FlowOut_accounted = 0
FlowDir_Map       = 0
StopRun           = 0  
MaxRec            = NCols * NRows

NumRec         = 0
MaxReach       = 0      

DO Row = 1,NRows
   DO Col = 1, NCols
	  NumRec = ((Row - 1)*NCols)+Col
      READ(1, rec = numrec) Reach
	  IF(Reach.GT.MaxReach) MaxReach = Reach
	  Col_Hiker = Col 
	  Row_Hiker = Row	  
	  IF(Reach.gt.0) THEN !If it is a stream reach then consider hiking up it.
		 IF(Assessd_Reach(Reach).EQ.0) THEN !Reach has not been assessed.	
		    HikingRec = NumRec
		    NotTop    = 1.0
		    CALL GoUpStream !Go to the furthest upstream reach
		    CALL GoDownStream
		    IF(StopRun.EQ.1) GOTO 1000
		 END IF
	  END IF  
   END DO
END DO

1000 WRITE(*,*) "End of Watershed Hiker analysis. Writing out results"
DO Row = 1,NRows 
   DO Col = 1, NCols 
      NumRec = ((Row - 1)*NCols)+Col
      READ(13,rec = numrec) Reach
      Real_Reach = Reach
      WRITE(4,rec = numrec) Real_Reach
   END DO
END DO
DO Loop = 1,4
   CLOSE(Loop)
END DO
DO Loop = 10,13
   CLOSE(Loop)
END DO

10 FORMAT(I7,(",",F17.8),",",F22.5)
CONTAINS
SUBROUTINE DirectionGuide()
DidOnce = 0

FlowOut (1)   =  1 !1 = right cell OutcreasOutg clockwise.
FlowOut (2)   =  2
FlowOut (4)   =  3
FlowOut (8)   =  4
FlowOut (16)  =  5
FlowOut (32)  =  6
FlowOut (64)  =  7
FlowOut (128) =  8

FlowRefOut(1) =  1
FlowRefOut(2) =  2
FlowRefOut(3) =  4
FlowRefOut(4) =  8
FlowRefOut(5) = 16
FlowRefOut(6) = 32
FlowRefOut(7) = 64
FlowRefOut(8) =128

FlowInDir (1) = 2  !Flow in for watershed hiker
FlowInDir (2) = 4
FlowInDir (3) = 8
FlowInDir (4) = 1
FlowInDir (5) = 1000 !No value - equals flow directions into itself
FlowInDir (6) = 16
FlowInDir (7) = 128
FlowInDir (8) = 64
FlowInDir (9) = 32
 
FlowIn  (1) =  16 ! of focal!Right
FlowIn  (2) =  32
FlowIn  (3) =  64 !below focal
FlowIn  (4) = 128
FlowIn  (5) =   1 !If the neighbor flowdir = this THEN it flows into the cell.
FlowIn  (6) =   2
FlowIn  (7) =   4
FlowIn  (8) =   8

!Define how many records to add or subtract to find the correct neighbor.
SrchRecAdj(1) =  1
SrchRecAdj(2) =  NCols + 1
SrchRecAdj(3) =  NCols
SrchRecAdj(4) =  NCols - 1
SrchRecAdj(5) = -1
SrchRecAdj(6) = -NCols - 1
SrchRecAdj(7) = -NCols
SrchRecAdj(8) = -NCols + 1


RETURN
END SUBROUTINE DirectionGuide
SUBROUTINE GoUpStream()
NotTop = 1
DO WHILE (NotTop.eq.1) !Go to head of reachHikeRowCol  = HikeRowReal
   !  Determine row and col cordinates of a cell
   READ(1, rec = HikingRec) NextReach
   REAL_NCols     = NCols
   REAL_HikingRec = HikingRec
   TempRow  = REAL_HikingRec/REAL_NCols
   HikeRow  = CEILING(TempRow) !Round Hike real row UP 
   
   TempCol  = (HikingRec - ((HikeRow-1)*NCols))  
   HikeCol  = TempCol !Round NCols up
   
   1100 FORMAT(A16,TR1,I6,Tr1,I6)
   SearchOption = 1.0 ! Reset search window options to all directions available.
   IF (HikeCol.eq.1) THEN
      SearchOption(4) = 0; SearchOption(5) = 0; SearchOption(6) = 0
   END IF
   IF (HikeCol.eq.NCols) THEN
      SearchOption(8) = 0; SearchOption(1) = 0; SearchOption(2) = 0
   END IF   
   IF (HikeRow.eq.1) THEN
      SearchOption(6) = 0; SearchOption(7) = 0; SearchOption(8) = 0
   END IF
   IF (HikeRow.eq.NRows) THEN
      SearchOption(2) = 0; SearchOption(3) = 0; SearchOption(4) = 0
   END IF   

   NewHikeRec = 0 !Reset new hike rec to 0.  0 equals no upstream flow located.
   DO SearchNbor = 1,8
      IF(SearchOption(SearchNbor).NE.0) THEN
	     SrchRec = HikingRec + SrchRecAdj(SearchNBor)
		 
		 !xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Determine base search variables xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		 READ(1,  REC = SrchRec) SrchReach
		 READ(2,  REC = SrchRec) FlowDir_Map
		 READ(11, REC = SrchRec) FlowOut_Accounted
		 READ(10, REC = SrchRec) Assessd_Cell 
		 !xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		 IF(FlowDir_Map.gt.0) THEN
		    IF(FlowDir_Map.eq.FlowIn(SearchNbor).AND.(SrchReach.gt.0)) THEN !This is a inflowing reach
			      IF(Assessd_Cell.EQ.0) THEN !This reach has not been assessed so move upstream
				 HikingRec = SrchRec
			         NewHikeRec = 1				  
				 GO TO 1		        
			      END IF
                    END IF
                   END IF
	  END IF 
   END DO 
1  CONTINUE
   IF(NewHikeRec.EQ.0) THEN
      NotTop = 0 !Reached top of reach or further reaches have been assessed; end Do while loop
   ELSE IF(NewHikeRec.NE.0) THEN
      !Keep hiking up
   END IF    
END DO
1000 FORMAT (A31,TR1,I5,TR1,I5)
NotEnd = 1 !Activate downstream reach hiker 
RETURN

END SUBROUTINE GoUpStream
!***************************************************************************************************************************
SUBROUTINE GoDownStream()

INTEGER(4)::Row_INT,Col_INT

! The program moves the focal cell downstream while searching it's neighbors

!****************** CALCULATE RECORD ID of HiRES that matches location of hiking rec in LOWResGrid *******************
! Convert HikingRec into Row,Col

3 FORMAT (A18,f17.3)

TempRec = HikingRec

!xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Determine base search variables xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
READ(1, rec = TempRec) Reach	 
!xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Reach_INT   = Reach
NextReach   = Reach

DO WHILE (NotEnd.eq.1) !Go to bottom of the reach

   ReachRec = HikingRec
   	!xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Determine base search variables xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   READ(1, rec = ReachRec) Reach	
   !xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

   Reach_INT   = Reach
   NextReach   = Reach

   IF(Reach.GT.0) THEN !This is not the end of the basin so continue moving downstream
	  
      !Determine if this cell is a junction of reaches, if it is a junction whether branches have been assessed,  
	  
      !  Determine row and col cordinates of a cell
      TempRow  = HikingRec/REAL_NCols
      HikeRow  = CEILING(TempRow) !Round Hike real row UP 
   
      TempCol  = (HikingRec - ((HikeRow-1)*NCols))  
      HikeCol  = CEILING(TempCol) !Round NCols up
   
      SearchOption = 1.0 ! Reset search window options to all directions available.
      IF (HikeCol.eq.1) THEN
         SearchOption(4) = 0; SearchOption(5) = 0; SearchOption(6) = 0
      END IF
      IF (HikeCol.eq.NCols) THEN
         SearchOption(8) = 0; SearchOption(1) = 0; SearchOption(2) = 0
      END IF   
      IF (HikeRow.eq.1) THEN
         SearchOption(6) = 0; SearchOption(7) = 0; SearchOption(8) = 0
      END IF
      IF (HikeRow.eq.NRows) THEN
         SearchOption(2) = 0; SearchOption(3) = 0; SearchOption(4) = 0
      END IF   
      
      MoveNextReach = 1
      NewHikeRec    = 0 !Reset new hike rec to 0.  0 equals All upstream cells have been assessed.

      DO SearchNbor = 1,8

         IF(SearchOption(SearchNbor).NE.0) THEN
		    SrchRec = HikingRec + SrchRecAdj(SearchNBor)
		    
		    ! XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX Populate search variables using virtual array variables XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
		    READ( 1, rec = SrchRec) SrchReach
		    READ( 2, rec = SrchRec) FlowDir_Map
		    READ(10, rec = SrchRec) Assessd_Cell
		    READ(11, rec = SrchRec) FlowOut_Accounted
	            ! XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

		    IF(FlowDir_Map.eq.FlowIn(SearchNbor).AND.(SrchReach.GT.0)) THEN !The upstream cell is a reach and flows into the reach being assessed.
		       IF(FlowOut_accounted.EQ.1) THEN !This reach cell has been assessed.  So just add its values to the reach
			      IF(Assessd_Cell.EQ.0.AND.SrchReach.EQ.NextReach) THEN !If the value of the upstream has not 
					 !xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Determine base search variables xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                                         Assessd_Cell = 1
					 WRITE(10, rec = SrchRec) Assessd_Cell	
					 WRITE(13, rec = SrchRec) NextReach
                              !xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
			      ELSE IF (Assessd_Reach(SrchReach).EQ.1.AND.SrchReach.NE.NextReach) THEN !it is a different upstream reach that has been assessed. So move it into downstream reach
			         READ(11, rec = ReachRec) FlowOut_Accounted  
                                 IF(Assessd_Reach(Reach_INT).EQ.0.AND.Assessd_Cell.EQ.0) THEN !Needs to be flow accounted for the reach the hiker is on. Not search reach
  			         !xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Determine base search variables xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                                    Assessd_Cell = 1
				    WRITE(10, rec = SrchRec) Assessd_Cell			 
                                    WRITE(13, rec = SrchRec) SrchReach
  				  END IF
			      END IF
                       ELSE IF(FlowOut_accounted.EQ.0) THEN !This reach has not been assessed. So hike to the top of branch.
			      HikingRec  = SrchRec !Label this has an unassessed branch so I can not complete current reach summary. 
		              NewHikeRec = 0 
		              IF(SrchReach.EQ.NextReach.AND.SrchReach.GT.0) THEN
				  WRITE(13, rec = SrchRec) NextReach
				  END IF
				  IF(SrchReach.NE.NextReach.AND.SrchReach.GT.0) THEN
				     WRITE(13, rec = SrchRec) SrchReach
				  END IF
				  CALL GoUpStream
				  READ( 1, rec = HikingRec) NextReach
				  IF(NextReach.GT.0) WRITE(13, rec = HikingRec) NextReach
				  MoveNextReach = 0 !Hiking to top of the reach, so do not step down reach cell when assessing.			  
				  GOTO 50
			      END IF
		       ELSE IF(FlowDir_Map.eq.FlowIn(SearchNbor).AND.(SrchReach.LE.0)) THEN !The cell flows into the reach, but it is not another reach
			   IF (FlowOut_accounted.EQ.0) THEN !Flow out has not been counted. So count it then mark it as counted.
				  WRITE(13, rec = SrchRec) Reach_INT
				  WSrchRec        = SrchRec
				  NewHikeRec    = 1
				  IF(NextReach.Gt.0) WRITE(13, rec = SrchRec) NextReach
				  CALL ReachWShed
				  MoveNextReach = 0
				  DidOnce = 1
			   ELSE IF(FlowOut_accounted.EQ.1.AND.Assessd_Cell.EQ.0) THEN !Flow has been accounted but conditions not assessed and added to downstream cell
				  Assessd_Cell  = 1; WRITE(10, Rec = ReachRec) Assessd_Cell  !Define flow out has now been accounted for.
				  WRITE(13, rec = SrchRec) NextReach			     			  
			   END IF
		     END IF
	 END IF 
      END DO 
   ELSE IF(NextReach.LE.0) THEN !Hiker is on the last grid cell of the reach or been summarized because it was on                                                             ! the end of a 4 grid cell reach.                             
      NotEnd = 0 !At bottom of basin. So terminate DO WHILE 
   END IF 
   IF(NewHikeRec.EQ.0) THEN !The current reach cell has been assessed.
      MoveNextReach = 1
   END IF
   50 CONTINUE
   IF(MoveNextReach.EQ.1) THEN !The search window made it through a search without any rejection of finished ends or search directions. Wrap up reach and move downstream
      ! ************************Move down stream to the next reach.*********************************************    
	  ! XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX Populate search variables using array variables XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	  READ( 1, rec = HikingRec) Reach
	  READ( 2, rec = HikingRec) FlowDir_Map
	  READ(10, rec = HikingRec) Assessd_Cell
          FlowOut_Accounted = 1; WRITE(11, rec = ReachRec) FlowOut_Accounted 
          WRITE(13, rec = HikingRec) NextReach
	  Assessd_Reach(Reach) = 1 !Define flow out has now been accounted for.
	  ! XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	  IF(MaxReach.LT.Reach) MaxReach = Reach
! ***** why 999999, should this be the no data value?? !!!	  
	  IF(Reach_INT.EQ.999999) THEN
                NotEnd = 0
                WRITE(*,*) "Reach_INT 9999999 0"   
                GOTO 100
          END IF 
          FlowDir_MapINT = FlowDir_Map 
	  SearchNBor = FlowOut(FlowDir_MapINT) 
	  HikingRec  = HikingRec + SrchRecAdj(SearchNBor)
      TempRow  = HikingRec/REAL_NCols
      HikeRow  = CEILING(TempRow) !Round Hike real row UP    
      TempCol  = (HikingRec - ((HikeRow-1)*NCols))  
      HikeCol  = CEILING(TempCol) !Round NCols up
 	  ReachRec = HikingRec
	  Row_INT = HikeRow; Col_INT = HikeCOL;
	  IF(HikeRow.EQ.EndRow) THEN
	     STOPRUN = 1
             GOTO 100
	  END IF
      
	  READ(1,  Rec = HikingRec) Reach 

      IF (Row_INT.GE.1.AND.Col_INT.GE.1) THEN
		 IF(Row_INT.LE.NRows.AND.Col_INT.LE.NCols) THEN
			IF(Reach.LE.0) THEN !If there are no more reaches to move to then stop
			   NotEnd = 0
			END IF
		 ELSE !No more reaches STOP go down stream	
            NotEnd = 0
         END IF
	  ELSE !No more reaches STOP go down stream	 
	     NotEnd = 0  
      END IF
   ELSE !Do not move to next reach (Still searching).
	  WRITE(13, rec = HikingRec) NextReach
   END IF
END DO
55 FORMAT( I6,21(TR2,F15.8))
100 CONTINUE
RETURN
END SUBROUTINE GoDownStream
!******************************************************Subroutine reach watershed******************************************
SUBROUTINE ReachWShed
! This subroutine summarizes the watershed area upstream of a given reach.

INTEGER(4)::Row_INT,Col_INT
WShed_searchd = 0
DO WHILE (WShed_searchd.EQ.0)
   MoveDownCell = 1
   NotSrchedDir = 0  
   
   TempRow  = WSrchRec/REAL_NCols
   WHikeRow = CEILING(TempRow) 
   WHikeCol = WSrchRec - ((WHikeRow - 1)*NCols)
   
   Shd_SearchOption = 1.0 ! Reset search window options to all directions available.
   IF (WHikeCol.eq.1) THEN
      Shd_SearchOption(4) = 0; Shd_SearchOption(5) = 0; Shd_SearchOption(6) = 0
   END IF
   IF (WHikeCol.eq.NCols) THEN
      Shd_SearchOption(8) = 0; Shd_SearchOption(1) = 0; Shd_SearchOption(2) = 0
   END IF   
   IF (WHikeRow.eq.1) THEN
      Shd_SearchOption(6) = 0; Shd_SearchOption(7) = 0; Shd_SearchOption(8) = 0
   END IF
   IF (WHikeRow.eq.NRows) THEN
      Shd_SearchOption(2) = 0; Shd_SearchOption(3) = 0; Shd_SearchOption(4) = 0
   END IF  
    
   All_Searched = 1 
   DO WSearchNbor = 1,8
	  IF(Shd_SearchOption(WSearchNbor).NE.0) THEN
	     Srch_WshdRec  = WSrchRec + SrchRecAdj(WSearchNBor)	    
		 ! XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX Populate search variables using array variables XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
		 READ( 2, rec = Srch_WshdRec) FlowDir_Map
		 READ(10, rec = Srch_WshdRec) Assessd_Cell
		 READ(11, rec = Srch_WshdRec) FlowOut_Accounted
		 READ( 1, rec = Srch_WshdRec) SrchReach
		 ! XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

		 IF(FlowDir_Map.EQ.FlowIn(WSearchNbor).AND.FlowOut_accounted.EQ.0) THEN !Cell flows in and has not been assessed.
		    IF(SrchReach.LE.0) THEN  
			  All_Searched  = 0	
			  WRITE(13, rec = Srch_WshdRec) NextReach
			  WSrchRec = Srch_WshdRec !Move up hill to the next cell
		      GOTO 60
		    END IF
                 ELSE IF(FlowDir_Map.EQ.FlowIn(WSearchNbor).AND.FlowOut_accounted.EQ.1) THEN !Cell flows in and has been assessed.
  	            IF(Assessd_Cell.eq.0.AND.SrchReach.LE.0) THEN !Flows for the cell have all been assessd but not added to the reach
		    WRITE(13, rec = Srch_WshdRec) NextReach	
                    !xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Determine base search variables xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                    Assessd_Cell = 1.0
        	    WRITE(10, rec = Srch_WshdRec) Assessd_Cell
                    !xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
	            END IF
                 END IF
          END IF        
   END DO
   60 CONTINUE
   IF(All_Searched.eq.1) THEN !All of the cells flowing into a cell have been searched.
      TempRow  = (WSrchRec/REAL_NCols)
      TempRow  = CEILING(TempRow)
      TempCol  = WSrchRec - (NCols*(TempRow-1))
      Row_INT  = TempRow
      Col_INT  = TempCol
      ReachRec = WSrchRec
	  
	  ! XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX Populate search variables using array variables XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      READ( 2, rec = WSrchRec) FlowDir_Map; FlowDir_MapINT = FlowDir_Map
      FlowOut_Accounted = 1; WRITE(11, rec = WSrchRec) FlowOut_Accounted
      WRITE(13, rec = WSrchRec) NextReach
	  ! XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      IF(WSrchRec.NE.HikingRec) THEN !Move the water shed hiker down hill to the next cell.
	     ! WHAT DO I DO IF IT WANTED TO SEND CELL OUTSIDE OF BOUNDARY?
      WSrchRec = WSrchRec + SrchRecAdj(FlowOut(FlowDir_MapINT))
      ELSE IF(WSrchRec.EQ.HikingRec) THEN !shed hiker is back to it's origin at HikingRec with all cells assessed
	 WShed_searchd = 1 !End watershed assessment
	 GOTO 70
      END IF
  	  ! XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ELSE !All of the INflowing cells have not been searched
      GOTO 65 
   END IF
   65 CONTINUE	    
END DO
70 CONTINUE
RETURN
END SUBROUTINE ReachWShed
END PROGRAM Reach_Drainage
