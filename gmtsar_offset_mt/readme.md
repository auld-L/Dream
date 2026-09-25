这些脚本都借鉴了中科大王欣的offset脚本写的



## 用cpu加速计算offset脚本，可以打印进度

cpu加速程序来自：https://github.com/Jazz-0626/xcorr_mt



## offset分辨率主要在 `xcorr_mt` 这一步就定了

## xsearch/ysearch确定分辨率；窗口越小，空间分辨率越高，但是有代价的

**更吵**：窗口小，相关不稳，SNR 掉、坏点多

**能测的位移变小**：`xsearch` 也是搜索半径。形变比它大，容易配错峰

recommend_nxny.sh 该脚本根据总的点数，推荐你nx，ny参数



## 三个offset脚本如下解释（可以看一下脚本，都很简单）

bash offset_blockmedian.sh 6800 7000 4 10 2：提取range和azimuth两个方向的offset结果

bash offset_geocode.sh IMG-HH-ALOS2605990680-250812-UBSL1.1__A.PRM：进行地理编码

bash offset_filter.sh 10 6 2：进行后处理滤波



有问题可以邮箱联系：lianghw@ies.ac.cn
