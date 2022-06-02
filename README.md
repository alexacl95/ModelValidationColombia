# Parameter estimation of COVID-19 cases in Colombia

In this repository, we present the codes and results to perform the parameter estimation for a mathematical model of COVID-19 propagation applied to 71 localities in Colombia.

## Tools implemented

* Download and real data are taken from [Datos Abiertos Colombia](https://www.datos.gov.co/). We saved the organized data as .json in _ModelValidationColombia/ValidacionChimera/Data/_ using the codes update_data.py and download.py

* The model and its diffusion systems are in the folder _ModelValidationColombia/ValidacionChimera/Model/_ . Also,
We originally validated the model in [this repository](https://github.com/alexacl95/ChimeraModelForCovid19) using sensitivity, uncertainty, and practical identifiablity analyses.

* For simulations, parameter estimations and their validation, we implemented the [GSUA_CSB toolbox](https://github.com/drojasd/GSUA-CSB) in Matlab2021a. The version implemented in this study is available in the folder _ModelValidationColombia/ValidacionChimera/Tool/_

## Web platform and outputs

* All figures of the model fitting are available in the notebook [1](https://alexacl95.github.io/ModelValidationColombia/html/PlotingEstiamtions.html)
* All parameter values for each locality and extension estimations are available in the folder  _ModelValidationColombia/ValidacionChimera/Informs/InformsPDF/_

* The model and its parameter estimations are available in [Mathcovid](https://epidemiologia-matematica.org/), in the [politics module](https://epidemiologia-matematica.org/politicas/). Professors, investigators, and students from the [Universidad EAFIT](https://www.eafit.edu.co) developed the platform with the support of [MinCiencias](https://minciencias.gov.co/)
