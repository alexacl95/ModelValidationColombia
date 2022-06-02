# Parameter estimation of COVID-19 cases in Colombia

In this repository, we present the codes and results to perform the parameter estimation for a mathematical model of COVID-19 propagation applied to 71 localities in Colombia.

## Tools implemented

* Download and real data are taken from [https://www.datos.gov.co/](Datos Abiertos Colombia). We saved the organized data as .json in _ModelValidationColombia/ValidacionChimera/Data/_

* The model and its diffusion systems are in the folder _ModelValidationColombia/ValidacionChimera/Model/_ . Also,
We originally validated the model in [https://github.com/alexacl95/ChimeraModelForCovid19](this repository) using sensitivity, uncertainty, and practical identifiablity analyses.

* For simulations, parameter estimations and their validation, we implemented the [GSUA_CSB toolbox](https://github.com/drojasd/GSUA-CSB) in Matlab2021a. The version implemented in this study is available in the folder _ModelValidationColombia/ValidacionChimera/Tool/_

## Web platform and outputs

* All figures of the model fitting are available in the notebook []()
* All parameter values for each locality and extension estimations are available in the folder  _ModelValidationColombia/ValidacionChimera/Informs/InformsPDF/_

* The model and its parameter estimations are available in [Mathcovid](https://epidemiologia-matematica.org/), in the [https://epidemiologia-matematica.org/politicas/](politics module). Professors, investigators, and students from the [https://www.eafit.edu.co](Universidad EAFIT) developed the platform with the support of [https://minciencias.gov.co/](MinCiencias)
