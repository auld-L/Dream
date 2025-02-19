#!/bin/csh -f
##
##
##此脚本用于四叉树降采样的insar数据准备
##生成qt_pre.txt文件，此文件有三列，分别为经度、纬度、unwrap值
##dem_sample1.lltn文件是用于matlab脚本求取方位角与入射角
##每次只需要修改PRM和GRD文件
##

set PRM=S1_20211113_141733_F1.PRM
set GRD=los_cor_dtr_cut_mask.grd

gmt grdinfo $GRD -Ir
gmt grd2xyz $GRD -do0 > tmp.txt
#删除等于0的行
#awk '$3 != 0' "phase_GBIS.txt" > tmp.txt

awk  '{printf("%.4f %.4f %.4f\n", $1, $2, $3)}' tmp.txt > tmp2.txt
rm tmp.txt 
mv tmp2.txt qt_pre.txt
wc -l qt_pre.txt
#awk '{print $0, "-9.9178"}' phase_GBIS.txt > tmp3.txt
#awk '{print $0, "41.5615"}' tmp3.txt > tmp4.txt
#set range=55.8/56.6/27.3/27.9 

#gmt grdinfo unwrap_mask_ll_cut.grd
#将dem采样到与los_ll_sample.grd一样大范围
set lon1=`gmt grdinfo $GRD -C | cut -f2`
set lon2=`gmt grdinfo $GRD -C | cut -f3`
set lat1=`gmt grdinfo $GRD -C | cut -f4`
set lat2=`gmt grdinfo $GRD -C | cut -f5`
gmt grdsample dem.grd -Gdem_sample.grd -R$lon1/$lon2/$lat1/$lat2
#gmt grdinfo dem_sample.grd
#将grdinfo的输出信息以Tab分隔显示在一行中    然后截取第8个 第9个字段（即x与y单元格大小）
set X = `gmt grdinfo $GRD -C | cut -f10`
set Y = `gmt grdinfo $GRD -C | cut -f11`
#echo $X
#echo $Y
gmt grdsample dem_sample.grd -Gdem_sample1.grd -I$X+n/$Y+n
#gmt grdinfo dem_sample1.grd
gmt grd2xyz dem_sample1.grd -do0 > dem_sample1.llt
SAT_look $PRM <dem_sample1.llt> dem_sample1.lltn

rm dem_sample1.grd dem_sample1.llt dem_sample.grd
