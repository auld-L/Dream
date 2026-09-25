#!/usr/bin/env bash
#!/usr/bin/env bash
# Recommend nx/ny for GMTSAR xcorr / make_offset_mt.csh from a PRM.
set -euo pipefail

usage() {
  cat <<'HELP'
Usage:
  recommend_nxny.sh -h
  recommend_nxny.sh Master.PRM
  recommend_nxny.sh Master.PRM [target_points]

Purpose / 用途:
  根据主影像 PRM 的影像尺寸，推荐 offset tracking 的采样点数 nx、ny。
  规则与 run2_recommend_grid.sh 相同：总点数接近 target_points，
  且 nx:ny 跟距离向:方位向像素数成比例，再四舍五入到 100。

  nx = round100( sqrt(target * num_rng_bins / num_valid_az) )
  ny = round100( num_valid_az * nx / num_rng_bins )

  算出的 nx ny 直接给 make_offset_mt.csh 用。
  只推荐网格，不跑计算。

Arguments:
  Master.PRM       主影像 PRM（读 num_rng_bins、num_valid_az）
  target_points    目标总点数，默认 4800000

Options:
  -h, --help       显示本说明

Example:
  recommend_nxny.sh IMG-HH-ALOS2605990680-250812-UBSL1.1__A.PRM
  recommend_nxny.sh IMG-HH-ALOS2605990680-250812-UBSL1.1__A.PRM 4800000
HELP
}

if (( $# == 0 )) || [[ ${1:-} == -h || ${1:-} == --help ]]; then
  usage
  exit 0
fi
if (( $# > 2 )); then
  usage >&2
  exit 1
fi

prm=$1
target=${2:-4800000}
round_to=100

if [[ ! -f $prm ]]; then
  echo "ERROR: PRM not found: $prm" >&2
  exit 1
fi
if [[ ! $target =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: target_points must be a positive integer: $target" >&2
  exit 1
fi

read_prm() {
  awk -F= -v wanted="$2" '
    {
      key=$1
      gsub(/[[:space:]]/, "", key)
      if (key == wanted) {
        value=$2
        gsub(/[[:space:]]/, "", value)
        print value
        exit
      }
    }
  ' "$1"
}

rng=$(read_prm "$prm" num_rng_bins)
azi=$(read_prm "$prm" num_valid_az)

if [[ ! $rng =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: bad num_rng_bins in $prm: ${rng:-missing}" >&2
  exit 1
fi
if [[ ! $azi =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: bad num_valid_az in $prm: ${azi:-missing}" >&2
  exit 1
fi

round100() {
  awk -v x="$1" -v r="$round_to" 'BEGIN { printf "%d", int((x + r/2) / r) * r }'
}

raw_nx=$(awk -v t="$target" -v rng="$rng" -v azi="$azi" \
  'BEGIN { printf "%.0f", sqrt(t * rng / azi) }')
nx=$(round100 "$raw_nx")

raw_ny=$(awk -v azi="$azi" -v nx="$nx" -v rng="$rng" \
  'BEGIN { printf "%.0f", azi * nx / rng }')
ny=$(round100 "$raw_ny")

if (( nx < 100 || ny < 100 )); then
  echo "ERROR: recommended nx/ny too small: $nx $ny" >&2
  exit 1
fi

total=$((nx * ny))
rng_sp=$(awk -v a="$rng" -v n="$nx" 'BEGIN { printf "%.2f", a / n }')
azi_sp=$(awk -v a="$azi" -v n="$ny" 'BEGIN { printf "%.2f", a / n }')
x_inc=$((rng / nx))
y_inc=$((azi / ny))

echo "PRM:              $prm"
echo "num_rng_bins:     $rng"
echo "num_valid_az:     $azi"
echo "target_points:    $target"
echo
echo "raw nx ny:        $raw_nx  $raw_ny"
echo "recommended:      nx=$nx  ny=$ny"
echo "total points:     $total"
echo "center spacing:   range=$rng_sp px  azimuth=$azi_sp px"
echo "integer step:     x_inc=$x_inc  y_inc=$y_inc"
echo
echo "example:"
echo "  make_offset_mt.csh Master.PRM Aligned.PRM $nx $ny 16 16 1 48"

