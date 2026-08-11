可以查看obsidian 2026-07-11查看view_isce_interferograms.py脚本的使用方法

`view_isce_interferograms.py` 用于批量读取：

```
merged/interferograms/日期1_日期2/
```

目录中的 ISCE 干涉图，并将每个干涉对绘制成一张 PNG 图片，统一保存到指定文件夹。

每张图片包含：

- 左图：干涉图幅度；
    
- 右图：包裹相位或解缠相位。
    

> [!NOTE]  
> 该脚本查看的是逐对干涉图，不是 MintPy 的 `timeseries.h5` 时间序列产品。

## 运行命令

```
python3 view_isce_interferograms.py \
/media/user/data2/isce_test/work/merged/interferograms \
/media/user/data2/isce_test/work/unwrapped_png \
--pattern filt_fine.unw \
--dpi 300 \
--clip-low 5 \
--clip-high 95
```

其中：

```
/media/user/data2/isce_test/work/merged/interferograms
```

是干涉对输入目录。

```
/media/user/data2/isce_test/work/unwrapped_png
```

是PNG图片输出目录。目录不存在时，脚本会自动创建。

## `--pattern` 参数

`--pattern` 用于指定需要绘制的产品，支持：

```
filt_fine.int
fine.int
filt_fine.unw
fine.unw
```

### `filt_fine.int`

滤波后的复数干涉图。

脚本绘制：

- 左图：干涉图幅度，以dB形式显示；
    
- 右图：滤波后的包裹相位。
    

