codevec=[BivariateBicycleCode(6,12, ((3,0),(0,1),(0,2)), ((0,3),(1,0),(2,0)))] pvec=[0.001,0.002,0.003,0.004,0.005,0.006,0.007,0.008,0.009,0.01] nsample=100 make benchmark-ldpc


nvec=[24,54,96,150] pvec=0.01:0.01:0.1 nsample=10000 make generate-error-samples
pvec=[0.01,0.02,0.03,0.04,0.05,0.06,0.07,0.08,0.09,0.1] nsample=10000 make benchmark-ldpc-benchcode


pvec=[0.01,0.02] nsample=10000 make benchmark-ldpc-benchcode

nvec=[600] pvec=[0.001,0.002,0.005,0.008,0.01,0.015,0.02] nsample=100000 make generate-error-samples

pvec=[0.001,0.002,0.005,0.008,0.01,0.015,0.02] nsample=100000 make benchmark-ldpc-benchcode

nvec=[600] pvec=[0.001,0.002,0.005] nsample=1000000 make generate-error-samples

pvec=[0.001,0.002,0.005] nsample=1000000 make benchmark-ldpc-benchcode


nvec=[1400] pvec=[0.001,0.002,0.005,0.008,0.01,0.015,0.02] nsample=100000 make generate-error-samples

nvec=[1400] pvec=[0.001,0.002] nsample=1000000 make generate-error-samples

pvec=[0.001,0.002] nsample=1000000 make benchmark-ldpc-benchcode


julia -p4 

