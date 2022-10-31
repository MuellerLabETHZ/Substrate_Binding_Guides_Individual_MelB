#pragma rtGlobals=1		// Use modern global access method.

//#include <XY Pair To Waveform>
//#include <strings as lists>

//**************************************************************************************************************
//////////////////////////////////////////
//use only with jpk data needing correction for wrong z-height(measured) calibration
//////////////////////////////////////////////
//Menu definitions
//////////////////////////////////////////
Menu "Import"
	"Load_jpk_selected_cor", Load_jpk_select_cor()
end

//////////////////////////////////////////////
//Function to load data from txt files
//////////////////////////////////////////
//30.03.2020 condensed function to import protein pulling data. JH

Function Load_jpk_select_cor()
	Variable Correction= 1     //correction to measured height applies to spring constant as well
	Variable refNum
	
	string/g headerstrline,headerstrname
	variable/g ks
	
	// if there is not deflection window it creates it and brings it to the front to append graphs
	dowindow/f Deflection  // if deflection exist it bring it to the front, if does not exist nothing
	if(v_flag==0)  // v_flag if does not exist v_flag=0
		display as "Deflection" // create window wich title is "Deflection"
		dowindow/c Deflection // name the window as Deflection  //NOTE: title and names are diferents
	endif
	
	//opens selected txt files
	String fileFilters = "Data Files (*.txt,*.dat,*.csv):.txt,.dat,.csv;All Files:.*;"	
	String message = "Select one or more files"
	Open /D /R /MULT=1 /F=fileFilters /M=message refNum
	String outputPaths = S_fileName	// S_fileName: Stores the full path to the file that was copied.  If an error occurred or if the user cancelled, it is set to an empty string.
	
	if (strlen(outputPaths) == 0)		//checks to see if file(s) were selected
		Print "Cancelled"
	else
		Variable numFilesSelected = ItemsInList(outputPaths, "\r")   //The list of full paths is delimited with a carriage return character, represented by "\r" in the example above. We use carriage return as the delimiter because the customary delimiter, semicolon, is a legal character in a Macintosh file name. 
		Variable i
		for(i=0; i<numFilesSelected; i+=1)					//loop for each txt file
			// extracts string from name of file to use later
			String/g path = StringFromList(i, outputPaths, "\r")
			string FileName= replacestring(".txt",  replacestring("-",StringFromList(ItemsInList(path,":")-1, path,":")	,"") , "")
			string FileNameTSS=FileName+"tss"
			string FileNameDefl= FileName+"Defl"
			
			//////////////////////////Import spring constant which is in "N/m" ////////////////////////////////////////
			////////////  Nina change here the line of spring constant
			////////////Force robot: 86
			////////////AFM Yosh: 
			////////////AFM 1.14 right and Dark room: 78
			/////////sensitivity is one line above spring constant

			//finds value of spring constant in txt data file (in line 78 of file)
			KillStrings /Z headerstr0	 // Kill wave before re-defining it
			make/o/n=1/t headerstr0
			LoadWave /O /Q /J /K=0 /L={0,78,1,0,0} /N=headerstr path 
			headerstrline=headerstr0[0] 			//reads a line in txt file 
			headerstrname="# springConstant: %f" 		//finds number
			ks=SubStringValue() 				//assigns number to constant (ks) using function below
			variable ks_cor=ks/Correction^2	//correction of spring constant based on // //ks=kT/<x^2>    (ks_cor)

			//finds value of sensitivity in txt data file (in line 77 of file)
			LoadWave /O /Q /J /K=0 /L={0,77,1,0,0} /N=headerstr path
			headerstrline=headerstr0[0] 			//reads a line
			headerstrname="# sensitivity: %f" 		//finds number
			variable Sensitivity=SubStringValue() 		//assigns found number to “Sensitivity” using function below
			variable Sensitivity_cor=Sensitivity*Correction	//corrects “Sensitivity_cor” by correction factor

			////////////////////////Import curve points and name as tempwave//////////////////////////////////////
			LoadWave/O /Q/G/D/L={0,0,0,0,0}/N=tempwave path 
			duplicate/o tempwave4, M_distance				//tempwave0 should have measured distance heading in txt file
			duplicate/o tempwave1, Deflection_F			//tempwave1 should have deflection in force (N) heading in txt file	
			killwaves/z tempwave0,tempwave1,tempwave2,tempwave3,tempwave4,tempwave5,tempwave6	//removes unneeded date
			variable datapoint=numpnts(Deflection_F)
		
			//correction of thedeflection data from wrong for to voltage and back to write force 
			make/o/n=(datapoint) Deflection_dist=Deflection_F/ks		//turns  deflection force to distance using old spring constant (ks)
			make/o/n=(datapoint) Deflection_V=Deflection_dist/sensitivity		//turns deflection distance to voltage using old Sensitivity
			make/o/n=(datapoint) Deflection_dis_cor=Deflection_V*sensitivity_cor	//changes voltage to corrected deflection distance using //Sensitivity_cor
			make/o/n=(datapoint) Deflection_F_cor=Deflection_dis_cor*ks_cor	//change deflection distance to force using corrected ks (ks_cor)

			//correction of the distance
			make/o/n=(datapoint) M_distance_cor=M_distance*correction				
			
			//generates tip-sample separation data from corrected measured distance and corrected deflection distance (above)
			make/o/n=(datapoint) Tip_sample_sep=M_distance_cor
			Tip_sample_sep+=Deflection_dis_cor	//// Correction with the  F*(spring constant)
		
			// Scales force to be in pN
			Deflection_F_cor*= (-1E12)				//changes incorrect measured distance by correction factor
		
			// Scales distances to be in nm
			Smooth/B 51, M_distance_cor
			M_distance_cor*=1E9			
			Tip_sample_sep*=1E9

			//writes data to wave with names assosiated with txt file 
			duplicate/o Tip_sample_sep, $FileNametss 
			duplicate/o Deflection_F_cor,  $FileNameDefl
			
			ks=ks_cor		//saves corrected spring constant because this is a global variable
	
			// Append data to graph
			Appendtograph    $FileNameDefl vs $FileNametss		
			ModifyGraph mode=2
			ModifyGraph rgb=(26112,26112,26112)
   				
		endfor
	endif
	KillStrings /A/Z 
	killwaves/z/a 
End

////////////////////////////////////////////////////////////////////////////
//function to extract name of file
Function SubStringValue()
	Variable v1		//number to find
	SVAR tmpstr1=headerstrline
	SVAR tmpstr2=headerstrname
	sscanf tmpstr1, tmpstr2, v1
	if (V_flag !=1)
		return -1
	else
		return v1
	endif
End


