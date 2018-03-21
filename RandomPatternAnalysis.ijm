////////////////////////////////////////////////////////////////////////////////
/* Name: RandomPatternAnalysis
 * Author: Manel Bosch
 * Affiliation:	Advanced Optical Microscopy Unit  
 * 				Scientific and Technological Centers 
 *				University of Barcelona (CCiTUB)
 * Version: 1	Date: 16th March 2018
 *
 * Description: Counts blue dots and checks for green signal inside red circles
 * 
 * Input: Composite .tif image with three channels generated in silico (see Note 2)
 * Output: ROIset for red circles and table with results
 *
 * Notes: 
 *	1) This macro was created for teaching purposes only
 *	2) It analyzes images generated with "Random pattern generator.ijm"
 */ 
///////////////////////////////////////////////////////////////////////////////

macro "RandomPatternAnalysis"{
	//Get data from image
	title = getTitle();
	name = substring(title, 0, lengthOf(title)-4);//Remove .tif ending
	
	//Split channels
	run("Split Channels");
	
	//Obtain objects from red channel
	selectWindow("C1-" + title);
	run("Analyze Particles...", "exclude add");
	
	//Define variables to store intermediate results
	nROIs = roiManager("count");
	arrayDots = newArray(nROIs);
	arrayGreen = newArray(nROIs);
	
	//Count dots and check green staining in each ROI
	for(i=0; i<nROIs; i++){
		//Count dots
		selectWindow("C3-" + title);
		arrayDots[i] = count(i);
		//Check green staining
		selectWindow("C2-" + title);
		arrayGreen[i] = count(i);
	}
	
	//Create a Results table
	tableName = "[" + name + "_Table]";
	run("Table...", "name=" + tableName + " width=400 height=400");
	print(tableName, "\\Headings: Cell number \t Number of Dots \t Green Staining");
	for(i=0; i<lengthOf(arrayDots); i++){
		green = "+";
		if(arrayGreen[i] == 0){
			green = "-";
		}
		print(tableName, i+1 + "\t" + arrayDots[i] + "\t" + green);
	}
	//Show results
	selectWindow("C2-" + title);
	roiManager("Show All");
	selectWindow("C3-" + title);
	roiManager("Show All");
	selectWindow("C1-" + title);
	close();
	selectWindow("Results");
	run("Close");
	//Save results
	output = getDirectory("Select an output directory");
	roiManager("Deselect");
	roiManager("Save", output + name + " RoiSet.zip");
	selectWindow(name + "_Table");
	saveAs("Results", output + name + ".csv");
	
	/*--------------------------
		Functions
		---------- 
	*/
	function count(a){
		roiManager("Select", a);
		run("Find Maxima...", "noise=1 output=Count");
		result = getResult("Count", 0);
		run("Clear Results");
		return result;
	}
}
