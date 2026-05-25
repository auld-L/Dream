#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Get the exact ERA5 SNWE range used by MintPy/PyAPS3.

Usage:
    python get_mintpy_era5_area.py
    python get_mintpy_era5_area.py -g inputs/geometryRadar.h5
"""

import argparse
from mintpy.utils import readfile


def main():
    parser = argparse.ArgumentParser(
        description="Get MintPy/PyAPS3 ERA5 bounding box from geometry file."
    )

    parser.add_argument(
        "-g", "--geom",
        default="../inputs/geometryRadar.h5",
        help="MintPy geometry file, default: inputs/geometryRadar.h5"
    )

    args = parser.parse_args()

    geom_file = args.geom

    try:
        from mintpy.tropo_pyaps3 import get_snwe
    except Exception:
        from tropo_pyaps3 import get_snwe

    atr = readfile.read_attribute(geom_file)
    snwe = get_snwe(atr, geom_file=geom_file)

    S, N, W, E = snwe

    print("MintPy/PyAPS3 使用的 SNWE 范围:")
    print(f"S = {S}")
    print(f"N = {N}")
    print(f"W = {W}")
    print(f"E = {E}")

    print("\n给 download_EAR5.py 使用的 --area 参数是 N W S E:")
    print(f"-a {N} {W} {S} {E}")

    print("\n完整下载命令示例:")
    print(
        "python download_EAR5.py "
        "-d ./WEATHER/ERA5 "
        "-f date_list.txt "
        f"-hr 10 "
        f"-a {N} {W} {S} {E}"
    )

    print("\n对应 ERA5 文件名前缀应为:")
    prefix = f"ERA5_N{S}_N{N}_E{W}_E{E}"
    print("\n对应 ERA5 文件名前缀应为:")
    print(f"{prefix}_YYYYMMDD_HH.grb")


if __name__ == "__main__":
    main()
