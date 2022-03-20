import os
import pandas as pd
import json
import update_data
'''
Función que se encarga de actualizar los datos reales al momento actual
'''
localidades = pd.read_csv('localidades.csv',
                           header=None,dtype=str).values.T[0]
# Actualizamos los datos
data = update_data.update(localidades)
# Se definen las carpetas con las que trabajaremos
folder_est = 'ValidacionChimera/Outs' # Estimaciones existentes
folder_dat = 'ValidacionChimera/Data'   # Lugar donde se guardarán los nuevos datos

# Se cargan los intervalos
with open('ValidacionChimera/Data/example.json') as fp_est:
    example_in = json.load(fp_est)
# Se buscan los archivos con extensiones
for localidad in localidades:
    # Definimos el tiempo final de simulación
    tf = len(data[localidad]['ActCasos'])-1
    with open('{}/{}.json'.format(folder_dat,localidad),'w') as fp_dat:
        # Revisar si habia parámetros estimados
        if os.path.isfile('{}/{}.json'.format(folder_est,localidad)):
            with open(f'{folder_est}/{localidad}.json') as fp_est:
              data_est = json.load(fp_est)
              data[localidad]['domain'] = data_est['domain']
              # Actualizamos el último paso del dominio
              data[localidad]['domain'][-1] = tf
              data[localidad]['x0'] = data_est['x0']
        else:
          # Si no hay parámetros, definir el dominio
              data[localidad]['domain'] = [0,tf]
              data[localidad]['Cut'] = []
        # Intervalos de los parámetros
        output = example_in.copy()
        # Se añaden las condiciones iniciales por localidad
        output['Population'] = [data[localidad]['Poblacion'], data[localidad]['Poblacion']]
        output['J_1'] = [data[localidad]['ActCasos'][0], data[localidad]['ActCasos'][0]]
        output['D'] = [data[localidad]['Muertes'][0], data[localidad]['Muertes'][0]]
        output['R_j'] = [data[localidad]['Recuperados'][0], data[localidad]['Recuperados'][0]]
        data[localidad]['intervals'] = output
        json.dump(data[localidad], fp_dat, indent=2)

