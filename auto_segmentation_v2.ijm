//######################################################################################################### 
/* This macro allow the segmentation of individual neurons from mosaic acquisitions 
(stitched X20 objective image from high content imaging system)

This macro requires in each folder :
		2 images(beware to the naming ) :
			An original image of neurons (e.g neurons.tif)
			The corresponding original image of nucleus (e.g nuclei.tif)

It creates three outputs: 
	tif for each Neuron = OriNeuron_
	Binary tif for each Neuron = BinNeuron_
	orignal tif for each Neuron = OriNeuron
	Composit tif for each Neuron+nuclei = Comp_
*/

//////////////////////// Parameters////////////////////////////////////////////////////
Taille=1;                   // Scalling factor to reduce image size before processing 
minNeuron_part1=1500;	    // Minimal neuron area in order to exclude debris
NucleusDiameter=30;	    // Diameter of nuclei
minNeuriticTree=15;         // Defines the minimal length to be a primary neurite tree if smaller it is erased from the skeleton
minNeuron_part2=2000;        // Defines the minimal area in the binary image to be a neuron if less the neuron is not considered
minLengthSkelet=100;         // Defines the minimal length of a neuritic skeleton if smaller the neuron is not considered
minAxon=150; 		    // Minimal length to be an axon (pixels)
minNeurite=15; 		    // Minimal length to be a neurite (pixels)
ratio=1.5; 		    // Minimal ratio between (mean primary neurite length) and (axonal length)--> Minimal ratio to be an axon

/////////////////////////////pic up the previewsly used settings///////////////////////////
ParameterFile=getDirectory("temp"); 
print(ParameterFile);

filesaver=File.exists(ParameterFile+"/AutoNeuronSegment_settings.txt");

if (filesaver==1){									// verify if the macro has already been used is the current computer and gets previously used parameters if true
	
	filestring=File.openAsString(ParameterFile+"/AutoNeuronSegment_settings.txt");
	rows=split(filestring, "\n");
	settings=newArray(rows.length);
		
	for(i=0; i<rows.length; i++){                 ///////////transform text from txt files into integers
		columns=split(rows[i],"\t");
		settings[i]=parseFloat(columns[0]);
	}
	Taille=settings[0];
	minNeuron_part1=settings[1];
	NucleusDiameter=settings[2];
	minNeuriticTree=settings[3]; 
	minNeuron_part2=settings[4];  
	minLengthSkelet=settings[5];
	minAxon=settings[6];				
	minNeurite=settings[7]; 				
	ratio=settings[8];
}

//////////////////////////////////////////// Step1: User adjusts key parameters /////////////////////////
Dialog.create("Files names and parameter settings (AutoNeuronSegment)");

Dialog.addString("Nucleus image name must contain ?","w1");
Dialog.addString("Neuron image name must contain :","w3");
Dialog.addNumber("Original image pixel size (in um):",Taille);
Dialog.addNumber("Minimal area for a neuron (in pixels) ?",minNeuron_part1);
Dialog.addNumber("Nucleus diameter (in pixels)",NucleusDiameter);

Dialog.show();

nucleiName=Dialog.getString();
tubName=Dialog.getString();
Taille=Dialog.getNumber();
minNeuron_part1=Dialog.getNumber();
NucleusDiameter=Dialog.getNumber();

minDoG=1;
maxDoG=NucleusDiameter*3;

NucleusSurface=NucleusDiameter/2*NucleusDiameter/2*PI;
minNucleusSurface=NucleusSurface/3;
maxNucleusSurface=NucleusSurface*3;

// Save the new parameters /////////////////////////
filesaver=File.exists(ParameterFile+"/AutoNeuronSegment_settings.txt");
if (filesaver==1){
	File.delete(ParameterFile+"/AutoNeuronSegment_settings.txt");
}
	print("Log");
	selectWindow("Log"); run("Close");
		////Part1settings////
	print(Taille); /// (1)
	print(minNeuron_part1); /// (2)
	print(NucleusDiameter); ///(3)
	////Part2_settings////
	print(minNeuriticTree); // (4) 
	print(minNeuron_part2);  // (5)
	print(minLengthSkelet); // (6) 
	////Part3 settings////
	print(minAxon); 	///(7)			
	print(minNeurite); 	///(8)			
	print(ratio); 		///(9)	
	
	selectWindow("Log"); saveAs("Text",ParameterFile+"/AutoNeuronSegment_settings.txt"); run("Close");
////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////// Step2: set input/output data structure /////////////////////////
rep=getDirectory("Where is Image Folder ?"); //top path
nomrep=File.getName(rep); // folder name
liste=getFileList(rep); // file list
File.makeDirectory(rep+"\\results_"+nomrep+"\\"); // make output folder
newRep=rep+"\\results_"+nomrep+"\\"; // output folder full path

//open images and add a small edge
for (i=0;i<liste.length;i++) {
	setBatchMode(false);	
	
	if (indexOf(liste[i], nucleiName)!=-1){
  		open(rep+liste[i]);
  		title1 = getTitle();
  		run("Duplicate...", "title=nuclei");
  		getDimensions(width, height, channels, slices, frames);
  		width1 = width + 10;
  		height1 = height + 10;
  		run("Canvas Size...", "width=" + width1 + " height=" + height1 + "  position=Center");
  		selectWindow(title1);close();
	}
	if (indexOf(liste[i], tubName)!=-1){
		open(rep+liste[i]);
		title2 = getTitle();
		run("Duplicate...", "title=neurons");
		getDimensions(width, height, channels, slices, frames);
  		width1 = width + 10;
  		height1 = height + 10;
  		run("Canvas Size...", "width=" + width1 + " height=" + height1 + "  position=Center");
  		selectWindow(title2);close();
	}
}

//////////////////////////////////////////// Step3: identify all neurons with nuclei /////////////////////////
// identify all nuclei
NucleusDiameter=30;
roiManager("reset");	
selectWindow("nuclei");
//filter(title1, "Gaussian Blur", "Gaussian Blur", NucleusDiameter/4, NucleusDiameter*4);  
//setBatchMode(false);
//run("Threshold...");
//waitForUser("Set the threshold for nuclei : \n You may do nothing !!!\n Zoom in to see better !!!");
//filter(title1, "Gaussian Blur", "Gaussian Blur", NucleusDiameter/4, NucleusDiameter*4);
setAutoThreshold("Triangle dark");
//run("Analyze Particles...", "size=300-2500 circularity=0-1.00 show=Overlay exclude in_situ");
//run("Convert to Mask");
//run("Watershed");
run("Analyze Particles...", "size=300-2500 circularity=0-1.00 show=Overlay exclude in_situ add");
print(roiManager("size"));

// identify neurons with nuclei
neuron_with_nucleus("neurons");
selectWindow("nuclei");
run("Remove Overlay");
run("From ROI Manager");
	
function neuron_with_nucleus(title){// adapted from https://forum.image.sc/t/select-overlapping-rois-and-exclude-other-rois/69775/3
	tobeDeleted = newArray(); // delete nucleus not overlap with neuron
	selectWindow(title);
	for (i = 0; i < roiManager("Count"); i++){ 
		roiManager("Select", i);
		getStatistics(area, mean, min, max, std, histogram);    
		if (mean < 127.5) {
			tobeDeleted = Array.concat(tobeDeleted,i);
		}
	}
	
	if (tobeDeleted.length > 0){
		roiManager("Select", tobeDeleted);
		roiManager("Delete");
	}
	selectWindow(title);
	run("Remove Overlay");
	run("From ROI Manager");
}

//////////////////////////////////////////// Step4: segment individual neurons /////////////////////////

// isolate individual neurons by finding the best threshold
for (ro = 11; ro < roiManager("count"); ro++){
	roCor = getCor("nuclei",ro);
	// Removes Neurons and nuclei when more or less than one nucleus per neuron or the area is too small
	filter = rm_bad(roCor);
	if(filter[0] > 2 || filter[1] < minNeuron_part1){		
	}
	else{
		bestT= best_ext("neurons", roCor);
		setBatchMode(false);
		selectWindow("neurons");
		setThreshold(0, bestT);
		doWand(roCor[0], roCor[1], 100, "Legacy");
		roiManager("Add");
		run("Copy");
		run("Internal Clipboard");rename("Neuron_"+ro);
		getDimensions(width, height, channels, slices, frames);
		run("Canvas Size...", "width="+width*1.5+" height="+height*1.5+" position=Center");
		thisTitle = getTitle();
		run("16-bit");
		run("Duplicate...", "title=OriNeuron_"+ro+".tif"); 
		saveAs("Tiff", newRep+"OriNeuron_"+ro+".tif");close(); // save orignal neuron image
		selectWindow(thisTitle);
		run("Duplicate...", "title=BinNeuron_"+ro+".tif");
		setThreshold(0, bestT);run("Convert to Mask");
		saveAs("Tiff", newRep+"BinNeuron_"+ro+".tif");close(); // save binary neuron image for vaa3d
		
		selectWindow("neurons");
		cutROI ("nuclei",roiManager("count")-1, ro);
		roiManager("select", roiManager("count")-1);
		roiManager("delete");
		run("Merge Channels...", "c2=Neuron_"+ro+" c3=DAPI_"+ro+" create keep");rename("Comp1_"+ro);
		run("Flatten");rename("Composite_"+ro);
		run("Color Balance...");
		run("Enhance Contrast", "saturated=0.35");
		saveAs("Tiff", newRep+"Comp_"+ro+".tif");close("Comp*"); // save a composited image
		close("nuclei_*");
		close("DAPI_*");
		close("Neuron_*");
	}
}
run("Close All");
//////////////////////////////////////////// Step5: digitalize individual neurons /////////////////////////
// Get the source folder path
sourceFolder = getDirectory("Choose a source folder");
mydes1 = "Ori";
mydes2 = "Bin";
mydes3 = "Comp";
move2sub(sourceFolder, mydes1)
move2sub(sourceFolder, mydes2)
move2sub(sourceFolder, mydes3)

function move2sub(sourceFolder, des){
	// Get the destination folder path
	destinationFolder = sourceFolder + File.separator + des;
	// Create the destination folder if it doesn't exist
	File.makeDirectory(destinationFolder);
	// Get the list of files in the source folder
	fileList = getFileList(sourceFolder);
	// Iterate through the files
	for (i = 0; i < fileList.length; i++) {
	   // Check if the file starts with "Ori"
	  	if (startsWith(fileList[i], des)) {
	       // Build the source file path
	       sourceFile = sourceFolder + File.separator + fileList[i];
	       // Build the destination file path
	       destinationFile = destinationFolder + File.separator + fileList[i];
	       // Move the file to the destination folder
	        File.rename(sourceFile, destinationFile);
	    }
	}
}

  
function rm_bad(anchCor){
	setBatchMode(true);
	myFilter = newArray(2);
	selectWindow("neurons");
	doWand(anchCor[0], anchCor[1], 100, "Legacy");
	roiManager("Add");
	selectWindow("nuclei");
	roiManager("select", roiManager("count")-1);
	setAutoThreshold("Triangle dark");
	run("Clear Results");
	run("Measure");
	myFilter[1]=getResult("Area", 0);
	run("Analyze Particles...", "size=300-2500 summarize");
	selectWindow("Summary");
	IJ.renameResults("Results");
	selectWindow("Results");
	myFilter[0]=getResult("Count",0);
	roiManager("select", roiManager("count")-1);
	roiManager("delete");
	setBatchMode(false);
	return myFilter;
}

function cutROI (image,z,ro) {
		selectWindow(image);
		roiManager("Select", z);
		run("Duplicate...", "title="+image+"_"+z);getDimensions(width, height, channels, slices, frames);
		setBackgroundColor(0, 0, 0); run("Clear Outside");run("Canvas Size...", "width="+width*1.5+" height="+height*1.5+" position=Center");
		run("Flatten");rename("DAPI_"+ro);
		run("16-bit");
	}
	
function getCor(img, ro){
	myCor = newArray(3);
	selectWindow(img);
	roiManager("Select", ro);
	run("Set Measurements...", "area centroid redirect=None decimal=3");
	run("Clear Results");
	run("Measure");
	myCor[0] = getResult("X", 0);
	myCor[1] = getResult("Y", 0);
	myCor[2] = getResult("AREA", 0);
	return myCor;
}

function best_ext(img, myCor){// find the best extension
	setBatchMode(true);
	myPrev = myCor[2];
	tuj_img = img;
	Table.create("myTable2");
	Table.setColumn("T");
	Table.setColumn("Old");
	Table.setColumn("New");
	Table.setColumn("Increase Rate");
	end_threshold = 100000;
	myIndex = 0;	
	i = 100;
	myCount = 0;
	myFlag = 0;
	myFinalT = 0;
	increaseRate1 = 0;
	while (myFlag == 0) {
		i--;
		selectWindow(img);
		setThreshold(0, i);	
		doWand(myCor[0], myCor[1], 100, "Legacy");
		run("Clear Results");
		run("Measure");
		myNew = getResult("Area", 0);
		selectWindow("myTable2");
		Table.set("T", myIndex, i); 
		Table.set("Old", myIndex, myPrev);
		Table.set("New", myIndex, myNew);                                   
		increaseRate1 = myNew/myPrev;
		Table.set("Increase Rate", myIndex, increaseRate1);		
		Table.update("myTable2");
		myIndex = myIndex + 1 ;
		if(increaseRate1 > 1.2 || increaseRate1 < 1){
			myFinalT = i+1;
			myFlag = 1;
		}
		else if(increaseRate1 == 1){
			if(myCount >= 5){
				myFinalT = i;
				myFlag = 1;
			}
			else{
				myCount++;
			}
		}
		else{
			myPrev = myNew;
		}
	}
	setBatchMode(false);
	print("Best T is: " + myFinalT);
	return(myFinalT);
}

///////////////////////////////////////////////////////////////////////