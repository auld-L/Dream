用于批量下载era5大气数据
获取影像数据
info.py inputs/timeseries.h5 --date > sar_dates.txt


get_mintpy_era5_area.py获取要下载区域的范围

python download_EAR5.py -h

example ：python download_EAR5.py -d ../WEATHER/ERA5/ -f sar_dates.txt -h 10 -a 50 100 30 120

记住要进入mintpy环境

