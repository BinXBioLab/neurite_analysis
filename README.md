# neurite_analysis
This pipeline will need imageJ/Fiji, vaa3d programs install locally and nGauge program is a jupter notebook can run on colab
1. install vaa3d-x.exe
2. install fiji/imageJ.
3. run ijm macro 'auto_segmentation_v2.1.ijm' in Fiji with a folder with raw neurons.tif and nuclei.tif images to get individual neuron swc files.
4. import binNeuron.swc files into Colab and run nGauge => to get statistics analysis of neuron features.
