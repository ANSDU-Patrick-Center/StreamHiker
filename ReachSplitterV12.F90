! Developed for compiling with Compaq Visual Fortran Ver. 6.6
PROGRAM Lnk2Rch
IMPLICIT None
INTEGER::Loop
REAL(4)::StartPos
INTEGER(8)::Row,Col, RecId, LookReach, NewReach, NotTop, NotEnd,HikingRec, NRows, NCols,SearchCol, SearchRow
INTEGER(8)::HikeRow,HikeCol,SearchNbor,SrchRec,IntFlowDir,INTLnkReach,NewHikeRec,ReachCounter
INTEGER(4),DIMENSION(3000000)::LnkMem
INTEGER,Dimension(8)::FlowIn, SearchOption, SrchRecAdj,FlowRefOut
INTEGER,Dimension(128)::FlowOut
REAL(8),DIMENSION(3)::ResBank_NumCells, AVGY, AVGX
REAL(8),DIMENSION(8)::ReachCellDist
REAL(8)::TempRow, TempCol, ReachLength,TargetLength, GridRes 
REAL(8)::HikingX, HikingY, MinX, MaxX, MinY, MaxY
REAL(4)::FlowDir,LnkReach,RealNewReach
INTEGER(4)::TempValue
REAL(8)::FirstReach,ReachX,ReachY, SrchRow,SrchCol,VectDist,TestMine
INTEGER(4),DIMENSION(10)::MapFile,MaxRec
CHARACTER(64)::StreamLink,Flowdirection,ReachMap
! ***************************************************** Full version *****************************************************
OPEN(5, file = "output_specs2.txt", FORM = "FORMATTED", STATUS = "OLD")
!Geographic extent of map.
!WRITE(*,*) "open"

READ(5,2) StreamLink
!WRITE(*,*) StreamLink
READ(5,2) Flowdirection 
!WRITE(*,*) Flowdirection
READ(5,2) ReachMap 
!WRITE(*,*) Flowdirection
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
READ(5,1) GridRes
!WRITE(*,*) GridRes
READ(5,1) TargetLength
!WRITE(*,*) TargetLength
1 FORMAT(F15.3)
2 FORMAT(A64)
3 FORMAT(i8)
! ********************************************************************************************************************

! This version of hiker was setup to split a processed Link map up into reach segments
LnkMem = 0 
OPEN(1, file = StreamLink               , FORM = "binary"   , Status = "OLD"    , access = "direct",RECL = 4)   
OPEN(2, file = Flowdirection            , FORM = "binary"   , Status = "OLD"    , access = "direct",RECL = 4)
OPEN(3, file = ReachMap                 , FORM = "binary"   , Status = "UNKNOWN", access = "direct",RECL = 4)

!************************************** Temporary files ******************************************                          
OPEN(17, file = "RchSrch2.flt" , FORM = "binary" , Status = "UNKNOWN" , access = "direct",RECL = 4)
OPEN(18, file = "SearchMem.flt", FORM = "binary" , Status = "UNKNOWN" , access = "direct",RECL = 4)
OPEN(19, file = "ReachLengths.csv", FORM = "formatted", Status = "UNKNOWN")
!**************************************************************************************************************************     

RecID    = 0
NewReach = 0
LnkMem          = 0
StartPos        = 0.0
NewReach        = 0

CALL DirectionGuide () !Define which direction flow numbers indicate.

DO Row = 1,NRows !This the # of rows in the DEM and flow direction map
   DO Col = 1,NCols !This is the # of columns in the DEM and flow direction map 
      RecID = (((Row-1)*NCols)+Col)
      Read(1, Rec = RecID) LnkReach 
	  Read(2, Rec = RecID) FlowDir
	  INTLnkReach = LnkReach
	  IF(LnkReach.GE.1) THEN !determine if reach needs splitting
	     IF(LnkMem(INTLnkReach).eq.0) THEN !This reach needs to be split (send read to the top of the reach).
		    LookReach = LnkReach
			NotTop    = 1 !Set subroutine GoUpstream to run perpetually until the top of reach is found.
			HikingRec = RecID
			CALL GoUpStream ()
			5 NotEnd = 1 !Set subroutine GoDownstream to run perpetually until the end of reach is found.			
			CALL GoDownStream ()
			10 LnkMem(INTLnkReach) = 1 !This link reach has been split  
	     ELSE !This grid cell has been split up.
	     END IF
          ELSE !Reach does not have a creek on it
	     WRITE(3,Rec = RecID) LnkReach
	  END IF	  
   END DO
END DO

DO Loop = 1,19
   CLOSE(Loop)
END DO
STOP

CONTAINS
SUBROUTINE DirectionGuide()
INTEGER::Class, Loop

FlowOut (1)   =  1  !1 = right cell OutcreasOutg clockwise. 
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
 
FlowIn  (1) =  16
FlowIn  (2) =  32
FlowIn  (3) =  64
FlowIn  (4) = 128
FlowIn  (5) =   1 !If the neighbor flowdir = this it flows in.
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

ReachCellDist(1) = GridRes !As the rook moves
ReachCellDist(2) = SQRT((GridRes**2.0) * 2.0) ! As the bishop moves  
ReachCellDist(3) = GridRes
ReachCellDist(4) = SQRT((GridRes**2.0) * 2.0)
ReachCellDist(5) = GridRes
ReachCellDist(6) = SQRT((GridRes**2.0) * 2.0)
ReachCellDist(7) = GridRes
ReachCellDist(8) = SQRT((GridRes**2.0) * 2.0)

RETURN
END SUBROUTINE DirectionGuide

SUBROUTINE GoUpStream()

DO WHILE (NotTop.eq.1) !Go to head of reachHikeRowCol  = HikeRowReal
   !  Determine row and col cordinates of a cell
   TempRow  = HikingRec/NCols
   HikeRow  = CEILING(TempRow) !Round Hike real row UP 
   
   TempCol  = (HikingRec - ((HikeRow-1)*NCols))  
   HikeCol  = TempCol !Round NCols up
   
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

   NewHikeRec = 0 !Reset new hike rec to 0.  0 equals no upstream flow located with the same linknumber.
   DO SearchNbor = 1,8
        IF(SearchOption(SearchNbor).NE.0) THEN
                SrchRec = HikingRec + SrchRecAdj(SearchNBor)
	        Read(1, Rec = SrchRec) LnkReach
                Read(2, Rec = SrchRec) FlowDir
		 
		IF(FlowDir.eq.FlowIn(SearchNbor).AND.(LnkReach.eq.LookReach)) THEN !We found our direction
		    NewHikeRec = SrchRec
                END IF
        END IF 
   END DO 

   IF(NewHikeRec.EQ.0) THEN
      NotTop = 0 !Reached top of reach; end Do while loop
   ELSE IF(NewHikeRec.NE.0) THEN
      HikingRec = NewHikeRec
   END IF    
END DO
NewReach     = NewReach + 1  !Start the hiker off on descent with a new reach label.
ReachCounter = 0
SrchRec      = HikingRec !Start off on the top reach cell
FirstReach   = 1.0 !Label as computing first reach of the upstream hike, so if not a full reach then do not count two reaches
RETURN
END SUBROUTINE GoUpStream
!---------------------------------------------------------------------------------------------------------------------------
!***************************************************************************************************************************
SUBROUTINE GoDownStream()
!Initiallize upstream elevaton and reach length
INTEGER::FType

ReachLength = 0.0

3 FORMAT (A18,f17.3)
DO WHILE (NotEnd.eq.1) !Go to bottom of the reach
   ReachCounter = ReachCounter + 1
   RealNewReach = NewReach
   TempRow  = (HikingRec/NCols)
   TempCol  = HikingRec - (NCols*FLOOR(TempRow)) 
   HikeRow  = CEILING(TempRow)
   WRITE(3,Rec = HikingRec) RealNewReach 
   !Prepare to evaluate down downstream cell
   Read(2, Rec = HikingRec) FlowDir
   
   !Add reach length for the new stream cell.
   IntFlowDir = FlowDir
   SearchNBor = FlowOut(IntFlowDir) 
      
   SrchRec = HikingRec + SrchRecAdj(SearchNBor)

   ReachLength = ReachLength + ReachCellDist(SearchNBor) !Downstream cell is in link reach define how much distance to add to reach length based on flow direction.

   IF(ReachLength.GE.TargetLength) THEN  !<number of cells per unit length of reach is equal to or greater than the user defined reach length
      ReachCounter = 0 !Do labelling
	  !See if the cell that this cell is flowing into is on the same link reach.
      IntFlowDir = FlowDir
      SearchNBor = FlowOut(IntFlowDir) 
      SrchRec = HikingRec + SrchRecAdj(SearchNBor)
      Read(1, Rec = SrchRec) LnkReach
	  WRITE(19, *) NewReach, ",", ReachLength
      IF(LnkReach.eq.LookReach) THEN !There is a next reach so add a new reach
         NewReach     = NewReach + 1
      ELSE IF (LnkReach.NE.LookReach) THEN !There is not a next reach so stop search
	     NotEnd = 0 !Stop down hill search
      END IF
      ReachLength  = 0.0 !Reset reachlength to zero to count a new reach.
   END IF
   !See if the cell that this cell is flowing into is on the same link reach.
   IntFlowDir = FlowDir
   SearchNBor = FlowOut(IntFlowDir) 
   SrchRec = HikingRec + SrchRecAdj(SearchNBor)
   IF(HikeRow.EQ.NRows-1) THEN !There is not a next reach so stop search
      IF(SearchNBor.EQ.4) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
      ELSE IF(SearchNBor.EQ.3) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
      ELSE IF(SearchNBor.EQ.2) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
	  END IF       
   END IF
   IF(HikeRow.EQ.1) THEN !There is not a next reach so stop search
      IF(SearchNBor.EQ.6) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
      ELSE IF(SearchNBor.EQ.7) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
      ELSE IF(SearchNBor.EQ.8) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
	  END IF
   END IF
   IF(TempCol.EQ.1) THEN !There is not a next reach so stop search
      IF(SearchNBor.EQ.6) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
      ELSE IF(SearchNBor.EQ.5) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
      ELSE IF(SearchNBor.EQ.4) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
	  END IF
   END IF
   IF(TempCol.EQ.NCols-1) THEN !There is not a next reach so stop search
      IF(SearchNBor.EQ.8) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
      ELSE IF(SearchNBor.EQ.1) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
      ELSE IF(SearchNBor.EQ.2) THEN
        NotEnd = 0 !Stop down hill search. Reading off of the map border
        WRITE(19, *) NewReach, ",", ReachLength
	  END IF
   END IF
   IF(NotEnd.EQ.0) THEN !Reading off map. Terminate going downhill
   ELSE
      Read(1, Rec = SrchRec) LnkReach
      IF(LnkReach.eq.LookReach) THEN !We found our direction
         HikingRec = SrchRec
      ELSE IF(LnkReach.NE.LookReach.AND.ReachLength.NE.0) THEN !Hiker is on the last grid cell of the reach or been summarized                                                             ! the end of a 4 grid cell reach.                             
         NotEnd = 0 !Terminate DO WHILE
         WRITE(19, *) NewReach, ",", ReachLength 
	     !****************** CALCULATE RECORD ID of HiRES that matches location of hiking rec in LOWResGrid *******************
         ! Convert HikingRec into Row,Col
         TempRow  = (HikingRec/NCols) 
         TempCol  = HikingRec - (NCols*FLOOR(TempRow))
         TempRow  = CEILING(TempRow)

         ! Convert Row Col into x,y UTM cordinate
         HikingX = MinX + (TempCol * GridRes)
         HikingY = MaxY - (TempRow * GridRes)

         ReachX  = HikingX
	 ReachY  = HikingY

         ReachCounter = 0 !Do labelling
	 ReachLength  = 0.0 !Reset reachlength to zero to count a new reach.
      END IF 
   END IF
END DO

55 FORMAT( I7,2(",",f18.2),12(",",F15.8),7(",",F15.8))
RETURN
END SUBROUTINE GoDownStream

END PROGRAM Lnk2Rch
