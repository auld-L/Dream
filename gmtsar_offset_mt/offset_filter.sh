#!/usr/bin/env bash
# Filter geocoded offset grids: clip -> median -> gaussian (Wang Xin Run5).
set -euo pipefail

usage() {
  cat <<'HELP'
Usage:
  offset_filter.sh [median_cells] [gaussian_cells] [clip_m]
  offset_filter.sh -h

必须在含有这两个文件的目录运行：
  azimuth_offset_ll_m.grd
  range_offset_ll_m.grd

和王鑫 Run5 同一套滤波，只做后处理，不重跑 xcorr：
  1. clip     |位移| > clip_m 的格子改成 NaN
  2. 中值滤波  球面 -Fm，去掉孤立噪点
  3. 高斯滤波  球面 -Fg，抹一点小纹理
     -Nr 表示原来是空的格子不填

参数（都可省略）：
  median_cells    中值窗口格子数（直径），默认 5
  gaussian_cells  高斯窗口格子数（全宽），默认 6
  clip_m          裁掉超过该米数的值，默认 10；0 表示不裁

对应王鑫 profile：
  mild      3  6  10
  balanced  5  6  10   （默认）
  strong    7 12  10

滤波宽度 = 格子大小 × 格子数，单位 km。

输出目录（自动新建，不覆盖原始网格）：
  filtered_m<median>_g<gaussian>_clip<clip_m>/
    azimuth_offset_ll_m_filtered.grd / _map.png / .kml / .kmz
    range_offset_ll_m_filtered.grd / _map.png / .kml / .kmz
    kml_cpt_range.txt     KML 无 colorbar，色标范围写在这里

Examples:
  offset_filter.sh
  offset_filter.sh 5 6 10
  offset_filter.sh 3 6 10
  offset_filter.sh 7 12 10
HELP
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
  usage
  exit 0
fi
if (( $# > 3 )); then
  usage >&2
  exit 1
fi

median_cells=${1:-5}
gaussian_cells=${2:-6}
clip_m=${3:-10}

azi=azimuth_offset_ll_m.grd
rng=range_offset_ll_m.grd
for f in "$azi" "$rng"; do
  if [[ ! -f $f ]]; then
    echo "ERROR: not found: $f" >&2
    echo "在 offset_geocode.sh 跑完的目录运行" >&2
    exit 1
  fi
done

read _ west east south north _ _ dx dy nx ny _ <<< $(gmt grdinfo "$azi" -C)
lat=$(awk -v s="$south" -v n="$north" 'BEGIN{print (s+n)/2}')
cell_m=$(awk -v dx="$dx" -v dy="$dy" -v lat="$lat" '
  BEGIN{
    pi=atan2(0,-1)
    x=dx*111320*cos(lat*pi/180)
    y=dy*110574
    print (x>y?x:y)
  }')
median_km=$(awk -v c="$cell_m" -v n="$median_cells" 'BEGIN{print c*n/1000}')
gaussian_km=$(awk -v c="$cell_m" -v n="$gaussian_cells" 'BEGIN{print c*n/1000}')

here=$(pwd)
outdir=$here/filtered_m${median_cells}_g${gaussian_cells}_clip${clip_m}
mkdir -p "$outdir"

echo "outdir $outdir"
echo "grid $nx x $ny  cell ~ ${cell_m} m"
echo "clip +/- $clip_m m"
echo "median $median_cells cells = $median_km km"
echo "gaussian $gaussian_cells cells = $gaussian_km km"

filter_one() {
  local src=$1
  local out=$2
  local tmp=${out%.grd}
  if awk -v m="$clip_m" 'BEGIN{exit !(m+0>0)}'; then
    gmt grdclip "$src" -Sb-"$clip_m"/NaN -Sa"$clip_m"/NaN -G"${tmp}_clip.grd"
  else
    cp -f "$src" "${tmp}_clip.grd"
  fi
  echo "median $(basename "$src") ..."
  gmt grdfilter "${tmp}_clip.grd" -D4 -Fm"$median_km" -Nr -G"${tmp}_med.grd"
  echo "gaussian $(basename "$src") ..."
  gmt grdfilter "${tmp}_med.grd" -D4 -Fg"$gaussian_km" -Nr -G"$out"
  rm -f "${tmp}_clip.grd" "${tmp}_med.grd"
}

filter_one "$here/$azi" "$outdir/azimuth_offset_ll_m_filtered.grd"
filter_one "$here/$rng" "$outdir/range_offset_ll_m_filtered.grd"
cd "$outdir"

cat > kml_cpt_range.txt <<EOF
KML/KMZ 没有 colorbar，色标范围如下。
CPT: polar, gmt grd2cpt -E30 -D
按每张网格自己的 min/max 拉伸，单位 m，0 不一定在正中间。
带色标的图看 *_map.png。

file  zmin  zmax  unit
EOF

plot_ll() {
  local g=$1
  local b=${g%.grd}
  echo "plotting ${b}_map.png ..."
  gmt grd2cpt "$g" -Cpolar -E30 -D > "$b.cpt"
  read _ _ _ _ _ zmin zmax _ <<< $(gmt grdinfo "$g" -C)
  echo "$b  $zmin  $zmax  m" >> kml_cpt_range.txt
  bounds=$(gmt grdinfo -I- "$g")
  read xmin xmax ymin ymax <<< "$(gmt grdinfo "$g" -C | awk '{print $2,$3,$4,$5}')"
  scl=$(awk -v a="$xmax" -v b="$xmin" -v c="$ymax" -v d="$ymin" \
    'BEGIN{x=a-b; y=c-d; s1=16/y; s2=12/x; print (s1<s2)?s1:s2}')
  gmt gmtdefaults -Ds > gmt.conf
  gmt set MAP_FRAME_TYPE plain
  gmt psbasemap -Baf -BWSne -Jm${scl}c $bounds -K -P > "$b.ps"
  if [[ -f dem_shade.grd ]]; then
    gmt grdimage dem_shade.grd -J -R -Ctopo.cpt -K -O -Q >> "$b.ps"
  fi
  gmt grdimage "$g" -J -R -C"$b.cpt" -Q -K -O >> "$b.ps"
  gmt pscoast -N3/0.5p -W0.5p -Slightblue -J -R -K -O -Df -I1 >> "$b.ps" || true
  gmt psscale -R"$g" -J -DJTC+w5c/0.35c+e -C"$b.cpt" -Bxaf -By+lm -O >> "$b.ps"
  gmt psconvert "$b.ps" -P -Tg -Z
  mv -f "$b.png" "${b}_map.png"
  echo "wrote ${b}_map.png"
  echo "kml $b ..."
  grd2kml.csh "$b" "$b.cpt"
  if [[ -f $b.kml && -f $b.png ]]; then
    zip -q -j "$b.kmz" "$b.kml" "$b.png"
    echo "wrote $b.kml $b.kmz"
  else
    echo "wrote $b.kml"
  fi
}

if [[ -f $here/dem.grd ]]; then
  gmt grdsample "$here/dem.grd" -Gs_dem.grd -Razimuth_offset_ll_m_filtered.grd || true
  if [[ -f s_dem.grd ]]; then
    gmt makecpt -Cgray -T-1/1/0.1 -Z > topo.cpt
    gmt grdgradient s_dem.grd -Gs_dem_grd.grd -A45 -Nt.5
    gmt grdmath s_dem_grd.grd 0.5 ADD = dem_shade.grd
  fi
fi

plot_ll azimuth_offset_ll_m_filtered.grd
plot_ll range_offset_ll_m_filtered.grd
rm -f s_dem.grd s_dem_grd.grd dem_shade.grd topo.cpt
echo "wrote $outdir/azimuth_offset_ll_m_filtered.grd"
echo "wrote $outdir/range_offset_ll_m_filtered.grd"
