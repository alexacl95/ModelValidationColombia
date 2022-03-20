import argparse
from itertools import product
from functools import partial
import json
from typing import Optional, Dict, Any
import unicodedata
import pandas as pd
from pandarallel import pandarallel
from sodapy import Socrata

def normalize_text(input_str):
    input_str = input_str.replace('ñ', '*_*')
    nfkd_form = unicodedata.normalize('NFKD', input_str.upper())
    only_ascii = nfkd_form.encode('ASCII', 'ignore').decode('utf-8')
    only_ascii = only_ascii.replace('*_*', 'Ñ')

    out_str = only_ascii.split('(')[0].strip()

    return out_str


def get_data(
        data_path: str,
        download: bool = True,
) -> pd.DataFrame:
    if download:
        client = Socrata('www.datos.gov.co', 'tLEFpGcWvrqyQpLsbuPvmYD1c')
        results = client.get('gt2j-8ykr', limit=int(1e9))

        json.dump(results, open(data_path, 'w'))
    else:
        results = json.load(open(data_path))

    return pd.DataFrame(results)


def preprocess_dates(df: pd.DataFrame) -> pd.DataFrame:

    # Parse date
    df.fecha_reporte_web = pd.to_datetime(
        df.fecha_reporte_web, format='%Y/%m/%d %H:%M:%S'
    )
    df.fecha_inicio_sintomas = pd.to_datetime(
        df.fecha_inicio_sintomas, format='%Y/%m/%d %H:%M:%S'
    )
    df.fecha_muerte = pd.to_datetime(
        df.fecha_muerte, format='%Y/%m/%d %H:%M:%S'
    )
    df.fecha_recuperado = pd.to_datetime(
        df.fecha_recuperado, format='%Y/%m/%d %H:%M:%S'
    )
    df.fecha_diagnostico = pd.to_datetime(
        df.fecha_diagnostico, format='%Y/%m/%d %H:%M:%S'
    )

    recuperados = df['recuperado']
    # Filter meaningfull information
    df = df[['fecha_reporte_web', 'departamento_nom',
             'ciudad_municipio_nom', 'fecha_muerte',
             'fecha_diagnostico', 'fecha_recuperado',
             'fecha_inicio_sintomas']]

    # THIS IS A TEST
    #df.fecha_diagnostico = df.fecha_inicio_sintomas

    df.loc[:,'ciudad_municipio_nom'] = df['ciudad_municipio_nom'].apply(normalize_text)
    df.loc[:,'departamento_nom'] = df['departamento_nom'].apply(normalize_text)

    # create status
    df['status'] = 'activos'
    df.loc[:,'status'] = df['status'].where(
        ~recuperados.isnull(),
        'activos'
    )

    df.loc[:,'status'] = df['status'].where(
        recuperados.str.lower() != 'fallecido',
        'muerto'
    )

    df.loc[:,'status'] = df['status'].where(
        recuperados != 'Recuperado',
        'recuperado'
    )

    df.loc[:,'status'] = df['status'].where(
        recuperados != 'N/A',
        'muerte no covid'
    )

    # create event date
    df['event_date'] = None
    df.loc[df['status'] == 'muerto', 'event_date'] \
        = df.loc[df['status'] == 'muerto', 'fecha_muerte']
    df.loc[df['status'] == 'recuperado', 'event_date']\
        = df.loc[df['status'] == 'recuperado', 'fecha_recuperado']
    df.loc[df['status'] == 'muerte no covid', 'event_date'] \
        = df.loc[df['status'] == 'muerte no covid', 'fecha_muerte']

    return df

def fill_missing_values(df: pd.DataFrame) -> pd.DataFrame:
    """
    Rellenar fechas faltantes
    -------------------------

    Si la persona muere pero no de covid y no se posee la fecha, entonces
    se rellena la fecha de recuperacion con la fecha de reporte web

    Si no posee la fecha de diagnostico, se utiliza la fecha de inicio
    de sintomas
    """

    df.loc[(df.status == 'muerto') & df.fecha_diagnostico.isnull(), 'fecha_diagnostico'] \
        = df.loc[(df.status == 'muerto') & df.fecha_diagnostico.isnull(), 'fecha_inicio_sintomas']

    df.loc[(df.status == 'muerte no covid') & df.fecha_diagnostico.isnull(), 'fecha_diagnostico'] \
        = df.loc[(df.status == 'muerte no covid') & df.fecha_diagnostico.isnull(), 'fecha_inicio_sintomas']

    df.loc[(df.status == 'muerte no covid') & df.event_date.isnull(), 'event_date'] \
        = df.loc[(df.status == 'muerte no covid') & df.event_date.isnull(), 'fecha_diagnostico'] + pd.DateOffset(15)

    df.loc[df.fecha_diagnostico.isnull(), 'fecha_diagnostico'] \
        = df.loc[df.fecha_diagnostico.isnull(), 'fecha_reporte_web']

    return df

def get_stats(df: pd.DataFrame, date: pd.Timestamp) -> pd.Series:
    """               d        e
    curr_active       |--dt----|
    ignore        dt  |--------|
    event             |--------| dt
    """
    curr_df = df[date >= df.fecha_diagnostico] # active cases from at
    curr_df.loc[curr_df.event_date.isnull() | (date < curr_df.event_date), 'status'] = 'activos'
    stats = curr_df.groupby(['departamento_nom', 'ciudad_municipio_nom']).status.value_counts()

    index = [(dep, mun, kind)
             for (dep, mun), kind in product(
                     {(dep, mun) for dep, mun, _ in stats.index}, stats.index.levels[-1]
             )]

    index = pd.MultiIndex.from_tuples(index, names=stats.index.names)

    stats = (
        stats
        .reindex(index, fill_value=0)
        .sort_index()
    )

    return stats


def make_data(
        seed_dataset: pd.DataFrame,
        last_date: str,
        num_workers: Optional[int] = None
) -> pd.DataFrame:
    if num_workers < 0:
        num_workers = None

    pandarallel.initialize(nb_workers=num_workers)


    seed_dataset = preprocess_dates(seed_dataset)
    seed_dataset = fill_missing_values(seed_dataset)

    date_range = pd.date_range('2020-03-06', last_date)
    data = (
        pd.Series(date_range)
        .parallel_apply(lambda date: get_stats(seed_dataset, date))
        .T
    )

    data.columns = date_range
    data = data.fillna(0)

    return data

def from_code(df: pd.DataFrame, meta_path: str, code: str) -> Dict[str, Any]:
    """

    TODO: Distritos especiales!
    return {
        name: str,
        ActCasos: List[int],
        Recuperados: List[int],
        Muertos: List[int],
        Poblacion: int,
        t0: int
    }

    """

    meta = json.load(open(meta_path))
    curr_dict = meta
    curr_name = curr_dict['nombre']
    curr_poblacion = curr_dict['poblacion']
    curr_df = df

    with open('ValidacionChimera/Data/special_locations.json') as f:
        special_locations = json.load(f)

    if code in special_locations.keys():
        curr_poblacion = 0
        dicts = []
        original_dict = curr_dict
        for cod in special_locations[code]:
            curr_code = cod[:2]
            curr_dict = original_dict['entidades'][curr_code]
            dep_name = curr_dict['nombre']
            curr_dict = curr_dict['entidades'][cod]
            curr_poblacion += int(curr_dict['poblacion'])
            curr_name = curr_dict['nombre']
            dicts.append(curr_df.loc[dep_name].loc[curr_name])
        curr_df = pd.concat(dicts)
        curr_name = code

    elif code == '47001':
        curr_df = curr_df.loc['STA MARTA D.E.']
        curr_code = code[:2]
        curr_dict = curr_dict['entidades'][curr_code]
        curr_dict = curr_dict['entidades'][code]
        curr_name = curr_dict['nombre']
        curr_poblacion = curr_dict['poblacion']
        curr_df = curr_df.loc[curr_name]

    elif code == '08001':
        curr_df = curr_df.loc['BARRANQUILLA']
        curr_code = code[:2]
        curr_dict = curr_dict['entidades'][curr_code]
        curr_dict = curr_dict['entidades'][code]
        curr_name = curr_dict['nombre']
        curr_poblacion = curr_dict['poblacion']
        curr_df = curr_df.loc[curr_name]

    elif code == '13001':
        curr_df = curr_df.loc['CARTAGENA']
        curr_code = code[:2]
        curr_dict = curr_dict['entidades'][curr_code]
        curr_dict = curr_dict['entidades'][code]
        curr_name = curr_dict['nombre']
        curr_poblacion = curr_dict['poblacion']
        curr_df = curr_df.loc[curr_name]

    elif code == '11':
        curr_df = curr_df.loc['BOGOTA']
        curr_dict = curr_dict['entidades'][code]
        curr_name = curr_dict['nombre']
        curr_poblacion = curr_dict['poblacion']
        curr_df = curr_df.loc['BOGOTA']

    elif code != 'co':
        curr_code = code[:2]
        curr_dict = curr_dict['entidades'][curr_code]
        curr_name = curr_dict['nombre']
        curr_poblacion = curr_dict['poblacion']
        curr_df = curr_df.loc[curr_name]

        if code != curr_code:
            curr_dict = curr_dict['entidades'][code]
            curr_name = curr_dict['nombre']
            curr_poblacion = curr_dict['poblacion']
            curr_df = curr_df.loc[curr_name]

    stats = curr_df.groupby(level=-1).sum()

    activos = stats.loc['activos']
    muertos = stats.loc['muerto']
    recuperados = stats.loc['recuperado']

    t0 = ((activos != 0).cumsum() == 1).argmax()
    inicio = activos.index.astype(int)[t0]

    activos = activos[t0:].astype(int)
    muertos = muertos[t0:].astype(int)
    recuperados = recuperados[t0:].astype(int)

    res = {
        'name': curr_name,
        'ActCasos': activos.tolist(),
        'Recuperados': recuperados.tolist(),
        'Muertes': muertos.tolist(),
        'Poblacion': int(curr_poblacion),
        't0': int(inicio) / 10**9
    }

    return res

def update(localidades):
    default_date = str(pd.Timestamp.today() - pd.DateOffset(4)).split()[0]
    meta_path = 'ValidacionChimera/Data/codigos.json'
    data_dir = 'ValidacionChimera/Data/.results.json'
    download = True
    num_workers = 2
    data = get_data(data_dir, download)
    data = make_data(data, default_date, num_workers)
    results = {}
    for localidad in localidades:
        results[localidad] = from_code(data, meta_path, localidad)
    return results



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='actualizacion de datos')

    default_date = str(pd.Timestamp.today() - pd.DateOffset(4)).split()[0]

    parser.add_argument(
        '--data_dir', action='store', type=str,
        help='carpeta donde la descarga será guardada'
    )
    parser.add_argument(
        '--download', action='store_true',
        help='actualizar los datos'
    )
    parser.add_argument(
        '--last_date', action='store', type=str, default=default_date,
        help='ultima fecha en consideracion (dd/mm/yyyy)'
    )
    parser.add_argument(
        '--num_workers', action='store', type=int, defaults=-1,
        help='numero de nucleos utilizados para preprocesar los datos'
    )

    res = parser.parse_args()

    data = get_data(res.data_path, res.download)
    data = make_data(data, last_date, num_workers)

