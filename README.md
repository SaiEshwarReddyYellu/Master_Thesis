# VHDL

- The below two algorithms are fed with the test data having two targets by taking absolute magnitudes in positive frequency (two targets) and negative frequency (two targets), where as the detections are better in the OS-CFAR algorithm


## CA-CFAR Algorithm
- This is a RADAR detection algorithm that performs averaging of the neighborhood cells to calculate noise levels. Sometimes one target in the close range might artificially increase the noise levels of the other target and identifies that as a noise. In the below figure, although there are two targets in the test data, only one is identified as target.

![seq_det](https://github.com/SaiEshwarReddyYellu/Master_Thesis/blob/main/CA_CFAR/CA-CFAR_simulation_results.PNG)


## OS-CFAR Algorithm
- This is another RADAR detection algorithm which performs sorting instead of averaging. So, the target present in the close range won't affect the other targets. In the below simulation it showed both the targets correctly. This has increased the efficiency and performance of identifying targets in the multi-target environment. 

![seq_det](https://github.com/SaiEshwarReddyYellu/Master_Thesis/blob/main/OS_CFAR/os_cfar_simulation.PNG)
