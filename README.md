# VHDL

- The below two algorithms are fed with the test data having two targets by taking absolute magnitudes in positive frequency (two targets) and negative frequency (two targets), to analyse their importance in homogeneous and heterogeneous environments. 


## CA-CFAR Algorithm
- This is a RADAR detection algorithm that performs averaging of the neighborhood cells to calculate noise levels. Sometimes one target in the close range might artificially increase the noise levels of the other target and identifies that as a noise. In the below figure, although there are two targets in the left plane of the test data, only one is identified as target.

![seq_det](https://github.com/SaiEshwarReddyYellu/Master_Thesis/blob/main/CA_CFAR/CA-CFAR_simulation_results.PNG)


## OS-CFAR Algorithm
- This is another radar detection algorithm that uses sorting technique instead of averaging. As a result, nearby targets threshold do not interfere with the detection of other targets. The simulation below demonstrates that both targets are correctly identified, enhancing the efficiency and performance of target detection in a multi-target environment. 

![seq_det](https://github.com/SaiEshwarReddyYellu/Master_Thesis/blob/main/OS_CFAR/os_cfar_simulation.PNG)
