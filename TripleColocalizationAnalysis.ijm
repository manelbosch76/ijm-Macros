///////////////////////////////////////////////////////////////////////////////////////////////
/* Name: TripleColocalizationAnalysis
 * Authors: Daniel Sastre(1) & Manel Bosch(1,2)
 * Afiliation: 	(1)Biochemistry and Molecular Biomedicine department. Universitat de Barcelona
 * 				(2)Advanced Optical Microscopy Unit.  	
 * 				   Scientific and Technological Centers. Universitat de Barcelona
 * Version: 1	Date: 01.02.2017
 * Input: 3 channel image (composite): red, blue, green
 * Output: log file with Colocalization coefficients
 */ 
///////////////////////////////////////////////////////////////////////////////////////////////

//OPEN FILE
open();

//GET DATA FROM IMAGES
getDimensions(width, height, channels, slices, frames);
if(!is("composite") || channels != 3){
	exit("The file is not a three-channel composite image");
}
title = getTitle();
input = File.directory();
//Change names accordingly in the following array
arrayNames = newArray("membrane", "KCNE", "channel");

//CREATE AN OUTPUT DIRECTORY FOR THE RESULTS
output = input + "Results" + File.separator;
File.makeDirectory(output);

//SPLIT CHANNELS AND REMOVE BRIGHTFIELD
run("Split Channels");

//PREPROCESSING
selectWindow("C1-" + title);
run("HiLo");
makeRectangle(0, 0, width*15/100, height*15/100);//allows to work with different image sizes
waitForUser("Move ROI to background");
roiManager("Add");
processImage(50);
selectWindow("C2-" + title);
run("HiLo");
processImage(500);
selectWindow("C3-" + title);
run("HiLo");
processImage(500);

//STAY WITH A SINGLE CELL FOR THE ANALYSIS
setBackgroundColor(0, 0, 255);
selectWindow("C1-"+title);
setTool("polygon");
waitForUser("Add ROI to select a single cell");
roiManager("Add");
selectSingleCell();
selectWindow("C2-"+title);
selectSingleCell();
selectWindow("C3-"+title);
selectSingleCell();

//SAVE PROCESSED IMAGES
selectWindow("C1-"+title);
saveIntermediate(arrayNames[0], "processed");
selectWindow("C2-"+title);
saveIntermediate(arrayNames[1], "processed");
selectWindow("C3-"+title);
saveIntermediate(arrayNames[2], "processed");

//THRESHOLD IMAGES
selectWindow("C1-"+title);
run("Duplicate...", "title=" + arrayNames[0]);
autoAdjust();
segment();
arg = getBoolean("Are there any intracellular particles?");
if (arg==1) {
	setBackgroundColor(255, 255, 255);
	setTool("polygon");
	waitForUser("Add ROI to clear out intracellular particles");
	run("Clear", "slice");
}
run("Select None");
selectWindow("C2-"+title);
run("Duplicate...", "title=" + arrayNames[1]);
autoAdjust();
segment();
run("Open");
selectWindow("C3-"+title);
run("Duplicate...", "title=" + arrayNames[2]);
autoAdjust();
segment();
run("Open");

//SAVE MASKS
selectWindow(arrayNames[0]);
saveIntermediate(arrayNames[0], "mask");
selectWindow(arrayNames[1]);
saveIntermediate(arrayNames[1], "mask");
selectWindow(arrayNames[2]);
saveIntermediate(arrayNames[2], "mask");

//OBTAIN & SAVE ORIGINAL INTENSITY INSIDE MASK
imageCalculator("Min create", "C1-"+title, arrayNames[0]);
rename(arrayNames[0] + " int");
saveIntermediate(arrayNames[0], "intensityInsideMask");
imageCalculator("Min create", "C2-"+title, arrayNames[1]);
rename(arrayNames[1] + " int");
saveIntermediate(arrayNames[1], "intensityInsideMask");
imageCalculator("Min create", "C3-"+title, arrayNames[2]);
rename(arrayNames[2] + " int");
saveIntermediate(arrayNames[2], "intensityInsideMask");

//CALCULATE MEMBRANE/RETENTION RATIO
run("Set Measurements...", "mean display redirect=None decimal=3");
selectWindow(arrayNames[2] + " int");
run("Measure");
imageCalculator("AND create", arrayNames[2], arrayNames[1]);
result1 = getTitle();
imageCalculator("AND create", result1, arrayNames[0]);
result2 = getTitle();
imageCalculator("Min create", "C3-"+title, result2);
rename("intensityInsideTripleMask");
run("Measure");
saveIntermediate(arrayNames[2], "intensityInsideTripleMask");

//CLOSE UNNECESSARY WINDOWS
clean("C1-"+title);
clean(arrayNames[0]);
clean("C2-"+title);
clean(arrayNames[1]);
clean("C3-"+title);
clean(arrayNames[2]);
clean(result1);
clean(result2);
clean("ROI Manager");

//CALCULATE COLOCALIZATION
run("JACoP ", "imga=[" + arrayNames[0] + " int" +"] imgb=[" + arrayNames[1] + " int" +"] thra=1 thrb=1 pearson mm");
run("JACoP ", "imga=[" + arrayNames[0] + " int" +"] imgb=[" + arrayNames[2] + " int" +"] thra=1 thrb=1 pearson mm");
run("JACoP ", "imga=[" + arrayNames[1] + " int" +"] imgb=[" + arrayNames[2] + " int" +"] thra=1 thrb=1 pearson mm");

//SAVE RESULTS
selectWindow("Log");
saveAs("Text", output + "ColocalizationLog.txt");
selectWindow("Results");
saveAs("Results", output + "Results.csv");

//FUNCTIONS
//Function to process each channel image
function processImage(rollingBall){
	roiManager("Select", 0);
	run("BG Subtraction from ROI");
	run("Subtract Background...", "rolling="+rollingBall);
	run("Select None");
	run("Median...", "radius=1");
	run("Gaussian Blur...", "sigma=1");
	run("Select None");
}
//Function to stay with one cell per experiment
function selectSingleCell(){
	roiManager("Select", 1);
	run("Clear Outside");
	run("Select None");
}
//Function to save intermediate files
function saveIntermediate(protein, step){
	run("Duplicate...", "title=duplicate");
	saveAs("Tiff", output + protein + " " + step);
	close();
}
//Function to adjust Brightness & Contrast automatically
function autoAdjust(){
   	/*ImageJ Automatic Brightness & Contrast Enhancement in ImageJ macro
	 "Auto" button in the brightness and contrast interface and the contrast enhancement provided in the menu as "Process > Enhance Contrast" use different algorithms. This macro mimics the algorithm used for the former enhancement. 
	See the link below:
	http://imagej.1557.x6.nabble.com/Auto-Brightness-Contrast-and-setMinAndMax-td4968628.html
	May 16th, 2012 Version 1.0
	Author: Kota Miura & Damien Guimond
	Contact: miura@embl.de
	Lisence: GNU General Public License, version 2
	http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
	 */
	 AUTO_THRESHOLD = 5000; 
	 getRawStatistics(pixcount); 
	 limit = pixcount/10; 
	 threshold = pixcount/AUTO_THRESHOLD; 
	 nBins = 256; 
	 getHistogram(values, histA, nBins); 
	 i = -1; 
	 found = false; 
	 do { 
		counts = histA[++i]; 
		if (counts > limit) counts = 0; 
		found = counts > threshold; 
	 } while ((!found) && (i < histA.length-1)) 
	 hmin = values[i]; 
	 i = histA.length; 
	 do { 
		counts = histA[--i]; 
		if (counts > limit) counts = 0; 
		found = counts > threshold; 
	 } while ((!found) && (i > 0)) 
	 hmax = values[i]; 
	 setMinAndMax(hmin, hmax); 
	run("Apply LUT"); 
}
//Function to segment each channel image
function segment(){
	setAutoThreshold("Default dark");
	run("Convert to Mask");
	run("Erode");
}
//Function to close a selected window
function clean(a){
	selectWindow(a);
	run("Close");
}
