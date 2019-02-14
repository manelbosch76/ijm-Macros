////////////////////////////////////////////////////////////////////////////////
/* Name: RandomPatterGenerator
 * Author: Manel Bosch (1,2)
 * Affiliation:	(1)Biochemistry and Molecular Biomedicine department. Universitat de Barcelona
 * 				(2)Advanced Optical Microscopy Unit.  	
 * 				   Scientific and Technological Centers. Universitat de Barcelona
 * Version: 1	Date: 16th March 2018
 *
 * Description: Draw random blue dots and red circles. 
 * 				Some circles are filled with green
 * 
 * Input: -
 * Output: RGB composite
 *
 * Notes: 
 *	1) this macro is based on two other macros
 *	https://imagej.nih.gov/ij/macros/RandomSampleAndMeasure.txt
 *	https://imagej.nih.gov/ij/macros/RandomSamplePerimeterMethod.txt
 */ 
///////////////////////////////////////////////////////////////////////////////

macro "RandomPatternGenerator"{
	//Create dialog for user input
	Dialog.create("Random Sample Configuration Dialog");
	Dialog.addString("Name of in silico image:", "Random pattern");
	Dialog.addNumber("Width of in silico image:", 512);
	Dialog.addNumber("Height of in silico image:", 512);
	Dialog.addNumber("Small dot size:", 5);// Width and height are equal
	Dialog.addNumber("Circle size:", 50);// Width and height are equal
	Dialog.addNumber("Max number of small samples:", 350); //Number of small dots
	Dialog.addNumber("Max number of big samples:", 50); //Number of big circles
	Dialog.addNumber("Max.Trials:", 1000);//Avoid infinite loop
	Dialog.show();
	title = Dialog.getString();
	width = Dialog.getNumber();
	height = Dialog.getNumber();
	dotSize = Dialog.getNumber();
	circleSize = Dialog.getNumber();
	nDots = Dialog.getNumber();
	nCircles = Dialog.getNumber();
	trials = Dialog.getNumber();
	//Create a new RGB image with entered values in the dialog
	newImage(title + " blue", "RGB black", width, height, 1);
	setForegroundColor(255,0,0);
	//Initialize variables to store intermediate results
	i=0;
	j=0;
	xaCircles=newArray(nCircles);
	yaCircles=newArray(nCircles);
	xaDots=newArray(nDots);
	yaDots=newArray(nDots);
	//Get coordinates where to draw the objects. User defined function
	getCoordinates(nCircles, circleSize, xaCircles, yaCircles);
	getCoordinates(nDots, dotSize, xaDots, yaDots);
	//Draw blue dots	
	selectWindow(title + " blue");
	setForegroundColor(0,0,255);
	for (j=0;j<nDots;j++){
	    makeOval(xaDots[j], yaDots[j], dotSize, dotSize);
	    run("Fill");
	}
	run("Select None");
	newImage(title+ " red", "RGB black", width, height, 1);
	newImage(title+ " green", "RGB black", width, height, 1);
	//Draw red circles
	for (j=0;j<nCircles;j++){
		setForegroundColor(255,0,0);
		selectWindow(title + " red");
	    makeOval(xaCircles[j], yaCircles[j], circleSize, circleSize);
	    run("Draw");
		//Draw green signal
	    if(random()>0.5){
	    	selectWindow(title + " green");
	    	makeOval(xaCircles[j]+1, yaCircles[j]+1, circleSize-1, circleSize-1);
	    	setForegroundColor(0,255,0);
	    	run("Fill");
	    }
	}
	run("Select None");
	//Merge channels as a composite
	run("Merge Channels...", "c1=[Random pattern red] c2=[Random pattern green] c3=[Random pattern blue] create");
	rename(title);
	//FUNCTIONS
	function getCoordinates(nSamples, size, arrayX, arrayY){
		run("Duplicate...", "title=Reference");
		while (i<nSamples && j<trials){
	        w = size;
	        h = size;
	        x = random()*width;
	        y = random()*height;
	        j++;
	        //Check for pixels with value (255,0,0):
	        flag= -1;
	        makeRectangle(x, y, w, h);
	        //Check all the points in the rectangle (slow)
	        for (xs=x;xs<=x+w;xs++){
	            for (ys=y;ys<=y+h;ys++){
	                if (getPixel(xs,ys)==-65536){ // pixel is (255,0,0)
	                    flag=0;
	                }
	            }
	        }
	        if (flag==-1){
	            arrayX[i]=x;
	            arrayY[i]=y;
	            run("Fill");
	            i++;
	        }
		}
		close();
	}
}
