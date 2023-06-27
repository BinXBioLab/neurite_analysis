//######################################################################################################### 
/* This macro allow the segmentation of individual neurons from mosaic acquisitions 
(stitched X20 objective image from high content imaging system)

This macro requires in each folder :
	2 images:
	An original image of neurons (e.g neurons.tif)
	The corresponding original image of nucleus (e.g nuclei.tif)

It creates four outputs: 
	a tif for each Neuron = OriNeuron_
	a binary tif for each Neuron = BinNeuron_
	a composit tif for each Neuron+nuclei = ComNeuron_
	a corrs file with all nuclei XY positions = corrs.csv
*/
///////////////////////////////////////////////////////////// Main ////////////////////////////////////////
run("Close All");
//////////////////////// Parameters////////////////////////////////////////////////////
Taille=1;                   // Scalling factor to reduce image size before processing 
minNeuron_part1=2500;	    // Minimal neuron area in order to exclude debris
NucleusDiameter=30;	    // Diameter of nuclei
minNeuriticTree=15;         // Defines the minimal length to be a primary neurite tree if smaller it is erased from the skeleton
minNeuron_part2=2000;        // Defines the minimal area in the binary image to be a neuron if less the neuron is not considered
minLengthSkelet=100;         // Defines the minimal length of a neuritic skeleton if smaller the neuron is not considered
minAxon=150; 		    // Minimal length to be an axon (pixels)
minNeurite=15; 		    // Minimal length to be a neurite (pixels)
ratio=1.5; 		    // Minimal ratio between (mean primary neurite length) and (axonal length)--> Minimal ratio to be an axon

/////////////////////////////save or retrieve the saved settings///////////////////////////
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
Dialog.addString("where is vaa3d?:","E:\\Vaa3D\\Vaa3D-x.1.1.2_Windows_64bit\\Vaa3D-x.exe");

Dialog.show();

nucleiName=Dialog.getString();
neuronName=Dialog.getString();
Taille=Dialog.getNumber();
minNeuron_part1=Dialog.getNumber();
NucleusDiameter=Dialog.getNumber();
vaa3d=Dialog.getString();

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
File.makeDirectory(newRep)
BinFolder = newRep + "BinNeurons\\";
File.makeDirectory(BinFolder)
OriFolder = newRep + "OriNeurons\\";
File.makeDirectory(OriFolder)
LocFolder = newRep + "LocNeurons\\";
File.makeDirectory(LocFolder)
CompFolder = newRep + "CompNeurons\\";
File.makeDirectory(CompFolder)

//open images and add a small edge to avoid wandtool edge problem
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
	if (indexOf(liste[i], neuronName)!=-1){
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
	selectWindow("nuclei");
	roiManager("reset");	
	setAutoThreshold("Triangle dark");
	run("Analyze Particles...", "size=" + minNucleusSurface + "-" + maxNucleusSurface + " circularity=0-1.00 show=Overlay exclude in_situ");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Watershed");
	run("Analyze Particles...", "size=" + minNucleusSurface + "-" + maxNucleusSurface + " circularity=0-1.00 show=Overlay exclude in_situ add");
	print(roiManager("size"));
	
	// identify neurons with nuclei
	selectWindow("neurons");
	setAutoThreshold("Triangle");
	call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W");
	getThreshold(lower, upper);
	startT = upper; // this is the best start threshold to get individaul neurons
	neuron_with_nucleus("neurons");
	selectWindow("nuclei");
	run("Remove Overlay");
	run("From ROI Manager");
	
	//////////////////////////////////////////// Step4: segment individual neurons /////////////////////////
	
	// isolate individual neurons by finding the best threshold
	for (ro = 0; ro < roiManager("count"); ro++){
	//for test comments the above line and uncomments the below line
	//for (ro = 0; ro < 3; ro++){
		roCor = getCor("nuclei",ro); // get the XY position of a ROI
		filter = get_filter_info(roCor); //get # of nuclei and the area covered by the neuron
		// Removes Neurons and nuclei when more than one nucleus per neuron or the neuron area is smaller than predefined size
		if(filter[0] > 1){ // single neurons
			// don't consider this ro		
		}
		else if(filter[1] < minNeuron_part1){
			// don't consider this ro
		}
		else{
			bestT= find_best_ext("neurons", roCor, startT);
			setBatchMode(false);
			selectWindow("neurons");
			setThreshold(0, bestT);
			doWand(roCor[0], roCor[1], 100, "Legacy");
			roiManager("Add");
			// generate a binary image with original location
			getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
			TimeString = toString(month) + '-' + toString(dayOfMonth) + '-' + toString(year) + '_' +toString(hour)+"-"+ toString(minute);
			run("Create Mask");rename("locNeuron_"+ro);
			saveAs("Tiff", LocFolder+"locNeuron_"+ro+'_'+TimeString+".tif");close(); // save orignal location of the neuron
	
			// generate an individual original neuron image	
			selectWindow("neurons");
			run("Duplicate...", "title=OriNeuron_"+ro+".tif");
			saveAs("Tiff", OriFolder+"OriNeuron_"+ro+'_'+TimeString+".tif"); // save orignal individual neuron image		
	
			// generate an individual binary neuron image
			selectWindow("OriNeuron_"+ro+'_'+TimeString+".tif");
			run("Clear Outside");
			setThreshold(0, bestT);
			run("Convert to Mask");
			saveAs("Tiff", BinFolder+"BinNeuron_"+ro+'_'+TimeString+".tif");close(); // save binary neuron image for vaa3d
			
			// generate an individual composite neuron with nuclei image						
			cutROI ("neurons",roiManager("count")-1, ro);
			cutROI ("nuclei",roiManager("count")-1, ro);
			roiManager("select", roiManager("count")-1);
			roiManager("delete");
			run("Merge Channels...", "c2=neurons_"+ro+" c3=nuclei_"+ro+" create keep");rename("Comp1_"+ro);
			run("Flatten");rename("Composite_"+ro);
			run("Color Balance...");
			run("Enhance Contrast", "saturated=0.35");
			saveAs("Tiff", CompFolder+"Comp_"+ro+'_'+TimeString+".tif");close("Comp*"); // save a composited image
			close("neurons_*");
			close("nuclei_*");
		}
	}
	run("Close All");
	
	//////////////////////////////////////////// Step5: digitalize individual neurons with vaa3d /////////////////////////
	list=getFileList(BinFolder); // file list
	for (i=0;i<list.length;i++) {
		if (endsWith(list[i], ".tif")){
			myFile = BinFolder+'\\'+list[i];
			vaa3dCmd = vaa3d + " /x vn2 /f app2 /i \"" + myFile + "\" /p NULL 0 -1 1 2 1 1 5 1 1 0";
			print(vaa3dCmd);
			exec("cmd", "/c", vaa3dCmd);
		}
	}
	
	list=getFileList(BinFolder); // file list
	for (i=0;i<list.length;i++) {
		if (endsWith(list[i], "app2.swc")){
			myFile = BinFolder+'\\'+list[i];
			vaa3dCmd1 = vaa3d + " /x standardize /f standardize  /i \"" + myFile + "\" \"" + myFile + "\" /o \"" + myFile + "\" /p 5 2";
			print(vaa3dCmd1);
			exec("cmd", "/c", vaa3dCmd1);
	
		}
	}

/////////////////////////////////////////// ALL DEFINED FUNCTIONS /////////////////////////////////////////

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

  
function get_filter_info(anchCor){
	setBatchMode(true);
	myFilter = newArray(2);
	selectWindow("neurons");
	doWand(anchCor[0], anchCor[1], 100, "Legacy");
	run("Clear Results");
	run("Measure");
	myFilter[1]=getResult("Area", 0); // get neuron size
	
	roiManager("Add");
	selectWindow("nuclei");
	roiManager("select", roiManager("count")-1);
	run("Analyze Particles...", "size=300-2500 summarize");
	selectWindow("Summary");
	IJ.renameResults("Results");
	selectWindow("Results");
	myFilter[0]=getResult("Count",0); // get nuclei counts
	
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
		run("Flatten");rename(image+"_"+ro);
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

function find_best_ext(img, myCor, startT){// the core function to find the best neurite extension
	setBatchMode(true);
	tuj_img = img;
	// setup a blank table to host the results
	Table.create("myTable2");
	Table.setColumn("Threshold");
	Table.setColumn("Old Area");
	Table.setColumn("New Area");
	Table.setColumn("Increase Rate");
	
	myIndex = 0;	
	mystep = 5; // minimum step is 1, higher will be faster but less accurate
	myCount = 0;
	stopFlag = 0; // to stop
	myFinalT = 0; // the best threshold
	increaseRate = 0; // the increase rate of the area. 
	increaseRateThreshold = 1.2; // You can adjust your cutoff here!!!
	
	//get start area
	myT = startT; // the start threshold
	myPrev = getResult("Area", 0);
	
	//extension
	while (stopFlag == 0) {
		selectWindow(img);
		setThreshold(0, myT);	
		doWand(myCor[0], myCor[1], 100, "Legacy");// identify initial neuron shape
		run("Clear Results");
		run("Measure");
		myNew = getResult("Area", 0);
		selectWindow("myTable2");
		Table.set("Threshold", myIndex, myT); 
		Table.set("Old Area", myIndex, myPrev);
		Table.set("New Area", myIndex, myNew);                                   
		increaseRate = myNew/myPrev;
		Table.set("Increase Rate", myIndex, increaseRate);		
		Table.update("myTable2");
		myIndex = myIndex + 1 ;
		if(increaseRate > 1.2 || increaseRate < 1){// Suddenly big increase or decrease indicates a bad change. stop here and get the previous Threshold
			myFinalT = myT+mystep;
			stopFlag = 1;
		}
		else if(increaseRate == 1){// if not more changes in the rate
			if(myCount >= 5){
				myFinalT = myT;
				stopFlag = 1;
			}
			else{
				myCount++;
			}
		}
		else{
			myPrev = myNew;
		}
		myT = myT - mystep;
	}
	setBatchMode(false);
	print("Best T is: " + myFinalT);
	return(myFinalT);
}

///////////////////////////////////////////////////////////////////////