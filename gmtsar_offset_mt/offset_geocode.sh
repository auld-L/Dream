#!/usr/bin/env bash
# Geocode radar offset points to lon/lat and convert pixels to metres.
set -euo pipefail

usage() {
  cat <<'HELP'
Usage:
  offset_geocode.sh Master.PRM
  offset_geocode.sh -h

必须在 offset_blockmedian.sh 跑完的目录里运行（例如 offset_mt/）。
只做地理编码和单位换算，不画图。

需要文件：
  Master.PRM
  trans.dat
  rng_b.dat  azi_b.dat
  range_offset_ra_px.grd
  azimuth_offset_ra_px.grd

两步：
  1. proj_ra2ll_ascii.csh + trans.dat
     把雷达坐标 (range px, azimuth px) 投到 (lon, lat)
  2. 偏移值从像素换成米（乘的是偏移，不是坐标）
     方位向像素 ≈ ground_vel / PRF
     距离向像素 ≈ 光速 / (2 * rng_samp_rate)，这是斜距，不是地距

输出：
  range_offset_ra_m.grd / azimuth_offset_ra_m.grd     雷达坐标，米
  range_offset_ll.xyz / azimuth_offset_ll.xyz         经纬度散点
  range_offset_ll_px.grd / azimuth_offset_ll_px.grd   经纬度，像素
  range_offset_ll_m.grd / azimuth_offset_ll_m.grd     经纬度，米
  对应 png：雷达坐标米图、经纬度米图（有 dem.grd 会垫底）

Example:
  cd intf/2025224_2026209/offset_mt
  offset_blockmedian.sh 2200 2300 4 10 5
  offset_geocode.sh IMG-HH-ALOS2605990680-250812-UBSL1.1__A.PRM
HELP
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
  usage
  exit 0
fi
if (( $# != 1 )); then
  usage >&2
  exit 1
fi

master=$1
for f in "$master" trans.dat rng_b.dat azi_b.dat \
         range_offset_ra_px.grd azimuth_offset_ra_px.grd; do
  if [[ ! -f $f ]]; then
    echo "ERROR: not found: $f" >&2
    echo "先在本目录跑完 offset_blockmedian.sh" >&2
    exit 1
  fi
done

prf=$(awk -F= '/^PRF/{print $2; exit}' "$master")
sc_vel=$(awk -F= '/^SC_vel/{print $2; exit}' "$master")
earth_radius=$(awk -F= '/^earth_radius/{print $2; exit}' "$master")
sc_height=$(awk -F= '/^SC_height/{print $2; exit}' "$master")
rng_samp_rate=$(awk -F= '/^rng_samp_rate/{print $2; exit}' "$master")

azi_size=$(awk -v v="$sc_vel" -v r="$earth_radius" -v h="$sc_height" -v p="$prf" \
  'BEGIN{printf "%.12g", (v/sqrt(1+h/r))/p}')
rng_size=$(awk -v rate="$rng_samp_rate" \
  'BEGIN{printf "%.12g", 299792458/(2*rate)}')

echo "master:     $master"
echo "azi pixel:  $azi_size m"
echo "rng pixel:  $rng_size m   (slant range)"

gmt grdmath range_offset_ra_px.grd "$rng_size" MUL = range_offset_ra_m.grd
gmt grdmath azimuth_offset_ra_px.grd "$azi_size" MUL = azimuth_offset_ra_m.grd

echo "geocoding rng_b.dat / azi_b.dat ..."
set +e
proj_ra2ll_ascii.csh trans.dat rng_b.dat range_offset_ll.xyz
proj_ra2ll_ascii.csh trans.dat azi_b.dat azimuth_offset_ll.xyz
set -e
if [[ ! -s range_offset_ll.xyz || ! -s azimuth_offset_ll.xyz ]]; then
  echo "ERROR: geocode failed" >&2
  exit 1
fi

nx=$(gmt grdinfo range_offset_ra_px.grd -C | awk '{print $10}')
ny=$(gmt grdinfo range_offset_ra_px.grd -C | awk '{print $11}')
read lonmin lonmax latmin latmax <<< $(gmt info range_offset_ll.xyz azimuth_offset_ll.xyz -C -fg | awk '{print $1,$2,$3,$4}')
lon_inc=$(awk -v a="$lonmax" -v b="$lonmin" -v n="$nx" 'BEGIN{print (a-b)/(n-1)}')
lat_inc=$(awk -v a="$latmax" -v b="$latmin" -v n="$ny" 'BEGIN{print (a-b)/(n-1)}')
R=$(gmt info range_offset_ll.xyz azimuth_offset_ll.xyz -I$lon_inc/$lat_inc -fg)
S=$(awk -v x="$lon_inc" -v y="$lat_inc" 'BEGIN{print 1.8*(x>y?x:y)}')
echo "ll grid $R  -I$lon_inc/$lat_inc"

gmt nearneighbor range_offset_ll.xyz $R -fg -I"$lon_inc"/"$lat_inc" -S"${S}d" -N1 \
  -Grange_offset_ll_px.grd
gmt nearneighbor azimuth_offset_ll.xyz $R -fg -I"$lon_inc"/"$lat_inc" -S"${S}d" -N1 \
  -Gazimuth_offset_ll_px.grd
gmt grdmath range_offset_ll_px.grd "$rng_size" MUL = range_offset_ll_m.grd
gmt grdmath azimuth_offset_ll_px.grd "$azi_size" MUL = azimuth_offset_ll_m.grd

echo "wrote range_offset_ra_m.grd azimuth_offset_ra_m.grd"
echo "wrote range_offset_ll_px.grd azimuth_offset_ll_px.grd"
echo "wrote range_offset_ll_m.grd azimuth_offset_ll_m.grd"

plot_ra() {
  local g=$1
  local b=${g%.grd}
  echo "plotting $b.png ..."
  gmt grd2cpt "$g" -Cpolar -E30 -D > "$b.cpt"
  gmt grdimage "$g" -JX12c/12c -C"$b.cpt" -Ba -BWSne -Q -P -K > "$b.ps"
  gmt psscale -C"$b.cpt" -Dx12.5c/6c+w8c/0.35c+e -By+lm -O >> "$b.ps"
  gmt psconvert "$b.ps" -P -Tg -Z
  echo "wrote $b.png"
}

plot_ll() {
  local g=$1
  local b=${g%.grd}
  echo "plotting $b.png ..."
  gmt grd2cpt "$g" -Cpolar -E30 -D > "$b.cpt"
  bounds=$(gmt grdinfo -I- "$g")
  read xmin xmax ymin ymax <<< "$(gmt grdinfo "$g" -C | awk '{print $2,$3,$4,$5}')"
  scl=$(awk -v a="$xmax" -v b="$xmin" -v c="$ymax" -v d="$ymin"     'BEGIN{x=a-b; y=c-d; s1=16/y; s2=12/x; print (s1<s2)?s1:s2}')
  gmt gmtdefaults -Ds > gmt.conf
  gmt set MAP_FRAME_TYPE plain
  gmt psbasemap -Baf -BWSne -Jm${scl}c $bounds -K -P > "$b.ps"
  if [[ -f s_dem.grd ]]; then
    gmt grdimage dem_shade.grd -J -R -Ctopo.cpt -K -O -Q >> "$b.ps"
  fi
  gmt grdimage "$g" -J -R -C"$b.cpt" -Q -K -O >> "$b.ps"
  gmt pscoast -N3/0.5p -W0.5p -Slightblue -J -R -K -O -Df -I1 >> "$b.ps" || true
  gmt psscale -R"$g" -J -DJTC+w5c/0.35c+e -C"$b.cpt" -Bxaf -By+lm -O >> "$b.ps"
  gmt psconvert "$b.ps" -P -Tg -Z
  echo "wrote $b.png"
}

if [[ -f dem.grd ]]; then
  gmt grdsample dem.grd -Gs_dem.grd -Rrange_offset_ll_m.grd || true
  if [[ -f s_dem.grd ]]; then
    gmt makecpt -Cgray -T-1/1/0.1 -Z > topo.cpt
    gmt grdgradient s_dem.grd -Gs_dem_grd.grd -A45 -Nt.5
    gmt grdmath s_dem_grd.grd 0.5 ADD = dem_shade.grd
  fi
fi

plot_ra range_offset_ra_m.grd
plot_ra azimuth_offset_ra_m.grd
plot_ll range_offset_ll_m.grd
plot_ll azimuth_offset_ll_m.grd
rm -f s_dem.grd s_dem_grd.grd dem_shade.grd topo.cpt
