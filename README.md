# auto_segmentation neurite_analysis
This pipeline will need imageJ/Fiji, vaa3d programs install locally and nGauge program is a jupter notebook can run on colab
1. install vaa3d-x.exe [Vaa3D-x.1.1.2_Windows_64bit]
   * https://github.com/Vaa3D/release/releases/download/v1.1.2/Vaa3D-x.1.1.2_Windows_64bit.zip
2. install fiji/imageJ.
   * https://imagej.net/software/fiji/downloads
3. run ijm macro 'auto_segmentation_v2.1.ijm' in Fiji with a folder with raw neurons.tif and nuclei.tif images to get individual neuron swc files.
4. import binNeuron.swc files into Colab and run nGauge_BX.ipynb => to get statistics analysis of neuron features.
   * https://github.com/Cai-Lab-at-University-of-Michigan/nGauge
