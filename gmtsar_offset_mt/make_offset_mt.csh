#!/bin/csh -f
# make_offset_mt.csh Master.PRM Aligned.PRM nx ny xsearch ysearch do_xcorr [nproc]

if ($#argv < 7 || $#argv > 8) then
  echo "Usage: make_offset_mt.csh Master.PRM Aligned.PRM nx ny xsearch ysearch do_xcorr [nproc]"
  exit 1
endif

echo "make_offset_mt.csh" $1 $2 $3 $4 $5 $6 $7 $8
set master = $1
set aligned = $2
set nx = $3
set ny = $4
set xsearch = $5
set ysearch = $6
set do_xcorr = $7
set nproc = 32
if ($#argv >= 8) set nproc = $8
echo "nproc: " $nproc

cd intf/*/
mkdir -p offset_mt
cd offset_mt
cp -f ../../../SLC/$master .
cp -f ../../../SLC/$aligned .
ln -sf ../../../SLC/*.SLC .
ln -sf ../../../topo/trans.dat .
ln -sf ../../../topo/dem.grd .

set PRF = `grep PRF $master | awk -F= '{print $2}'`
set SC_vel = `grep SC_vel $master | awk -F= '{print $2}'`
set earth_radius = `grep earth_radius $master | awk -F= '{print $2}'`
set SC_height = `grep SC_height $master | awk -F= '{print $2}'`
set ground_vel = `echo $SC_vel $earth_radius $SC_height | awk '{print $1/sqrt(1+$3/$2)}'`
set azi_size = `echo $ground_vel $PRF | awk '{printf "%10.3f",$1/$2}'`
echo "ground velocity: " $ground_vel
echo "azi pixel size", $azi_size

foreach f ($master $aligned)
  update_PRM $f rshift 0
  update_PRM $f sub_int_r 0
  update_PRM $f stretch_r 0.0
  update_PRM $f a_stretch_r 0.0
  update_PRM $f ashift 0
  update_PRM $f sub_int_a 0.0
  update_PRM $f stretch_a 0.0
  update_PRM $f a_stretch_a 0.0
end

if ($do_xcorr != 1) then
  echo "xcorr_mt finish"
  exit 0
endif

setenv OMP_NUM_THREADS 1
set total = `echo $nx $ny | awk '{print $1*$2}'`
set nonomatch
rm -f freq_xcorr.dat freq_xcorr.dat.part.* xcorr_mt.log
echo "xcorr_mt $master $aligned -nx $nx -ny $ny -xsearch $xsearch -ysearch $ysearch -noshift -nproc $nproc"

bash -s -- "$master" "$aligned" "$nx" "$ny" "$xsearch" "$ysearch" "$nproc" "$total" << 'BASH'
trap 'pkill -KILL -x xcorr_mt; exit 130' INT TERM
setsid -w xcorr_mt "$1" "$2" -nx "$3" -ny "$4" -xsearch "$5" -ysearch "$6" -noshift -nproc "$7" > xcorr_mt.log 2>&1 &
pid=$!
until grep -q locations xcorr_mt.log 2>/dev/null || ! kill -0 $pid 2>/dev/null; do sleep 1; done
echo "===== initialization ====="
awk '{print} /locations/{exit}' xcorr_mt.log
echo "===== progress ====="
while kill -0 $pid 2>/dev/null; do
  n=$(cat freq_xcorr.dat freq_xcorr.dat.part.* 2>/dev/null | wc -l)
  awk -v n="$n" -v t="$8" -v p="$7" -v d="$(date '+%F %T')" \
    'BEGIN{if(n>t)n=t; printf "%s  %.2f%%  %d/%d  nproc=%s\n", d, 100*n/t, n, t, p}'
  sleep 10
done
wait $pid || true
elapsed=$(awk '/elapsed time/{print $NF; exit}' xcorr_mt.log)
if [ -z "$elapsed" ]; then
  echo "ERROR: xcorr_mt failed"
  tail -20 xcorr_mt.log
  exit 1
fi
echo "elapsed time: $elapsed s"
echo "xcorr_mt finish"
exit 0
BASH
