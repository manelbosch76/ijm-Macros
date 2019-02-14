///////////////////////////////////////////////////////////////////////////////////////////////
/* Name: FRETRatioAnalysis	
 * Author: Manel Bosch (1,2) & Elena Kardash (3)
 * Afiliation: 	(1)Biochemistry and Molecular Biomedicine department. Universitat de Barcelona
 * 				(2)Advanced Optical Microscopy Unit.  	
 * 				   Scientific and Technological Centers. Universitat de Barcelona
 *				(3)BioEmergences Laboratory (USR 3695), CNRS, Université Paris-Saclay, 91190, Gif-sur-Yvette
 * Version: 3 	Date: 25.05.2018
 * 	
 * Description: measures the ratio between FRET and CFP images 
 * 
 * Input: Open a FRET image or stack. Then the macro opens its corresponding CFP image automatically 
 * Output: 	Ratio image 32bits 
 * 			Ratio image in RGB with the calibration bar ranging from user defined levels
 * 			Histogram ranging from user defined levels
 *
 * Notes:
 * 	1) Image pairs should be named equally except the end being FRET or CFP
 * 	2) Changed from version 1: Addition of Dialog box and calibration
 * 	3) Changed from version 2: Addition of Histogram
 */
///////////////////////////////////////////////////////////////////////////////////////////////

//Create the dialog box asking for ratio values
Dialog.create("FRETRatioAnalysis");
Dialog.addNumber("Minimum value for the ratio", 1.9);
Dialog.addNumber("Maximum value for the ratio", 3.4);
Dialog.show;
minRatio = Dialog.getNumber();
maxRatio = Dialog.getNumber();

//Open FRET image, collect data and open its corresponding CFP image
showMessage("Open a FRET image when asked");
open();
title = getTitle();
fretID = getImageID();
input = File.directory;
experiment = substring(title, 0, lengthOf(title)-8);//Removing FRET and file extension
cellType = substring(title, lengthOf(title)-8, lengthOf(title)-4);//Looking for FRET word
extension = substring(title, lengthOf(title)-4);//Looking for file extension
getDimensions(width, height, channels, slices, frames);
if(cellType=="FRET"){
	open(experiment + "CFP" + extension);//Pair of FRET image previously open
	cfpID = getImageID();
}else{
	exit("There is no FRET image open");
}

//Rename images
selectImage(fretID);
rename("FRET");
selectImage(cfpID);
rename("CFP");

//Crop the cell of interest
selectImage(fretID);
waitForUser("Draw a ROI around the cell to analyze");
roiManager("Add");
run("Crop");
selectImage(cfpID);
roiManager("Select", 0);
run("Crop");
selectWindow("ROI Manager");
run("Close");

//Process images
selectImage(fretID);
run("Subtract Background...", "rolling=50 stack");
selectImage(cfpID);
run("Subtract Background...", "rolling=50 stack");
run("MultiStackReg", "stack_1=CFP action_1=[Use as Reference] file_1=[] stack_2=FRET action_2=[Align to First Stack] file_2=[] transformation=[Rigid Body]");
selectImage(fretID);
run("32-bit");
run("Smooth", "stack");
selectImage(cfpID);
run("32-bit");
run("Smooth", "stack");

//Segment FRET image
selectImage(fretID);
setAutoThreshold("Default dark stack");
run("NaN Background", "stack");

//Calculate the ratio
run("Ratio Plus", "image1=[FRET] image2=[CFP] background1=0 clipping_value1=0 background2=0 clipping_value2=0 multiplication=1");
ratioID = getImageID();
setMinAndMax(minRatio, maxRatio);

//Add a calibration bar
selectImage(ratioID);
run("Lookup Tables", "resource=Lookup_Tables/ lut=[Blue Green Red]");
run("Duplicate...", "title=copy duplicate");
resizeImage();
run("Calibration Bar...", "location=[Upper Right] fill=Black label=White number=3 decimal=1 font=14 zoom=1.5 overlay");
run("Flatten", "stack");
calBarID = getImageID();

//Obtain histogram
selectImage(ratioID);
rename("Ratio");
if(slices>1){
	stackHistogram();
}else{
	run("Histogram", "bins=100 x_min=" + minRatio + " x_max=" + maxRatio + " y_max=Auto");
}

//Create Results folder inside the input folder
output = input + "Results" + File.separator;
File.makeDirectory(output);
if(!File.exists(output)){
	exit("Unable to create the folder");
}

//Save images and histogram
selectImage(calBarID);
saveAs("Tiff", output + experiment + " Ratio_RGB");
selectImage(ratioID);
saveAs("Tiff", output + experiment + " Ratio");
selectWindow("Histogram of Ratio");
saveAs("Tiff", output + experiment + " Ratio_Histogram");
if(isOpen("copy")){
	selectWindow("copy");
	close();
}

/**********
* Functions
**********/
//Function to resize an image and increase its canvas by 100px width
function resizeImage(){
	if(width<400){
		run("Size...", "width=400 height=400 constrain average interpolation=None");
		height = getHeight();
	}
	width = getWidth() + 100;
	run("Canvas Size...", "width="+width+" height="+height+" position=Center-Left zero");
}

//Function to create a stack of histograms obtained from each slice in a stack
function stackHistogram(){
	setBatchMode(true);
	for(i=1; i<=slices; i++){
		selectImage(ratioID);
		setSlice(i);
		run("Histogram", "bins=100 x_min=" + minRatio + " x_max=" + maxRatio + " y_max=Auto");
		rename("frame " + i);
	}
	run("Images to Stack", "name=histoStack title=frame use");
	rename("Histogram of Ratio");
	setBatchMode(false);
}
