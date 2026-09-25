#!/usr/bin/env bash
# Filter freq_xcorr.dat and blockmedian to range/azimuth radar grids.
set -euo pipefail

usage() {
  cat <<'HELP'
Usage:
  offset_blockmedian.sh nx ny [factor] [snr] [max]
  offset_blockmedian.sh -h

必须在含有 freq_xcorr.dat 的目录里运行（例如 offset_mt/）。
只做过滤和成格，不成地理坐标、不画图。

位置参数（后面三个可省略）：
  nx       xcorr 距离向采样点数，必须和 make_offset_mt.csh 里用的 nx 一致
  ny       xcorr 方位向采样点数，必须和 make_offset_mt.csh 里用的 ny 一致
  factor   blockmedian 聚合倍数，默认 4
  snr      保留 SNR 大于该值的点（freq_xcorr.dat 第 5 列），默认 10
  max      保留 |偏移| <= 该值（像素）的点，默认 5；0 表示不过幅度

nx / ny
  用来还原 xcorr 的原始点间距：
    原始 x 间距 ≈ (xmax-xmin)/(nx-1)
    网格步长 xinc = 原始间距 × factor
  写错 nx ny，格子就会过密或过稀。
  例：试跑 1000 1000；正式景 2200 2300。

factor
  把相邻的 xcorr 点合成一格。每个格子用 SNR 加权取中位数。
  1  = 几乎不聚合，细节多、更吵
  4  = 王鑫 Run4 默认，画图常用
  8 或 12 = 更平滑，断层附近会糊
  只影响本脚本成格，不会改 freq_xcorr.dat，也不会重跑 xcorr。

snr
  第 5 列信噪比门槛。水体、阴影、失相关处 SNR 低，应当丢掉。
  太大：点太少，网格空洞
  太小：坏点进网格，噪声大

max
  距离向看第 2 列，方位向看第 4 列，单位是像素。
  官方老脚本用 ±1.1，只适合配准残差；地震位移会更大，默认 5。
  形变很大时再加大，例如 10。
  设成 0 表示不过幅度，只按 SNR 过滤。

输入 freq_xcorr.dat 列含义：
  1 距离向位置   2 距离向偏移(px)   3 方位向位置   4 方位向偏移(px)   5 SNR

输出（写在当前目录）：
  rng.dat / azi.dat                 过滤后的点 (x y offset SNR)
  rng_b.dat / azi_b.dat             blockmedian 后的点
  range_offset_ra_px.grd            距离向网格（像素）
  azimuth_offset_ra_px.grd          方位向网格（像素）

Examples:
  offset_blockmedian.sh 1000 1000
  offset_blockmedian.sh 1000 1000 4
  offset_blockmedian.sh 2200 2300 4 10 5
  offset_blockmedian.sh 2200 2300 8 8 10
HELP
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
  usage
  exit 0
fi
if (( $# < 2 || $# > 5 )); then
  usage >&2
  exit 1
fi

nx=$1
ny=$2
factor=${3:-4}
snr=${4:-10}
max=${5:-5}

if [[ ! -f freq_xcorr.dat ]]; then
  echo "ERROR: freq_xcorr.dat not found" >&2
  echo "在含有 freq_xcorr.dat 的目录运行，先看: offset_blockmedian.sh -h" >&2
  exit 1
fi

if awk -v m="$max" 'BEGIN{exit !(m+0<=0)}'; then
  echo "nx ny=$nx $ny  factor=$factor  SNR>$snr  |off| filter off"
else
  echo "nx ny=$nx $ny  factor=$factor  SNR>$snr  |off|<=$max"
fi

awk -v s="$snr" -v m="$max" \
  'NF>=5 && $5>s && (m<=0 || ($2>=-m && $2<=m)) {print $1,$3,$2,$5}' freq_xcorr.dat > rng.dat
awk -v s="$snr" -v m="$max" \
  'NF>=5 && $5>s && (m<=0 || ($4>=-m && $4<=m)) {print $1,$3,$4,$5}' freq_xcorr.dat > azi.dat

echo "kept rng: $(wc -l < rng.dat)  azi: $(wc -l < azi.dat)"

read -r xmin xmax ymin ymax _ < <(gmt info rng.dat azi.dat -C)
xinc=$(awk -v a="$xmax" -v b="$xmin" -v n="$nx" -v f="$factor" \
  'BEGIN{v=int((a-b)/(n-1)); if(v<1)v=1; print v*f}')
yinc=$(awk -v a="$ymax" -v b="$ymin" -v n="$ny" -v f="$factor" \
  'BEGIN{v=int((a-b)/(n-1)); if(v<1)v=1; print v*f}')
R=$(gmt info rng.dat azi.dat -I"$xinc"/"$yinc")
echo "grid $R  -I$xinc/$yinc"

gmt blockmedian rng.dat $R -I"$xinc"/"$yinc" -Wi | awk '{print $1,$2,$3}' > rng_b.dat
gmt blockmedian azi.dat $R -I"$xinc"/"$yinc" -Wi | awk '{print $1,$2,$3}' > azi_b.dat
gmt xyz2grd rng_b.dat $R -I"$xinc"/"$yinc" -Grange_offset_ra_px.grd
gmt xyz2grd azi_b.dat $R -I"$xinc"/"$yinc" -Gazimuth_offset_ra_px.grd
echo "wrote range_offset_ra_px.grd azimuth_offset_ra_px.grd"
