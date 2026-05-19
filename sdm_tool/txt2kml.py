import pandas as pd
import simplekml
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors

def txt_to_kml(txt_file, kml_file):
    # 1. 读取数据 (假设顺序为: Lat, Lon, Displacement)
    # 如果你的 txt 没有表头，使用 names 指定列名
    df = pd.read_csv(txt_file, sep='\t', names=['lat', 'lon', 'dis', 'err'])
    
    # 2. 创建 KML 对象
    kml = simplekml.Kml()
    
    # 3. 设置颜色映射 (使用 matplotlib 生成颜色，对应 KML 颜色格式)
    # 映射范围可以根据你的数据调整，比如 -0.05 到 0.05
    norm = mcolors.Normalize(vmin=-0.4, vmax=0.4)
    cmap = plt.get_cmap('jet')  # 红-白-蓝渐变

    print(f"正在处理 {len(df)} 个点...")

    # 4. 遍历点数据
    # 注意：如果点数过多（超过 10,000 个），Google Earth 可能会卡顿
    # 建议在这种情况下对数据进行抽样：df = df.sample(n=5000)
    for i, row in df.iterrows():
        # 获取颜色
        rgba = cmap(norm(row['dis']))
        # 将 matplotlib 的 RGBA 转为 KML 的 AABBGGRR 格式
        kml_color = simplekml.Color.rgb(
            int(rgba[0]*255), int(rgba[1]*255), int(rgba[2]*255)
        )
        
        # 添加点
        pnt = kml.newpoint(coords=[(row['lon'], row['lat'])])
        pnt.style.iconstyle.color = kml_color
        pnt.style.iconstyle.scale = 0.5  # 点的大小
        pnt.style.iconstyle.icon.href = 'http://maps.google.com/mapfiles/kml/shapes/sh_filled_dot.png'
        
        # 气泡窗口显示数值
        pnt.description = f"Displacement: {row['dis']:.4f} m"

    # 5. 保存
    kml.save(kml_file)
    print(f"转换完成！文件已保存为: {kml_file}")

# 调用示例
txt_to_kml('D.txt', 'D.kml')
