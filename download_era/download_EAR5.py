import cdsapi
import os
import subprocess
import time
import argparse
from datetime import datetime

def split_list(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

def download_with_retry(client, request_dict, target_path, max_retries=5):
    """Handles CDS API requests with an exponential backoff retry logic."""
    for attempt in range(max_retries):
        try:
            client.retrieve('reanalysis-era5-pressure-levels', request_dict, target_path)
            return True
        except Exception as e:
            print(f"   [Network Error] Attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                # Wait longer after each failure to allow server/network recovery
                time.sleep(30 * (attempt + 1))
    return False

def main():
    # --- 1. Argument Parser Configuration ---
    parser = argparse.ArgumentParser(
        description='ERA5 Batch Downloader for MintPy (List-driven with auto-split)',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    parser.add_argument('--dir', '-d', type=str, required=True, 
                        help='Directory to store downloaded ERA5 files')
    parser.add_argument('--dates', '-f', type=str, required=True, 
                        help='Path to the date list file (one YYYYMMDD per line)')
    parser.add_argument('--hour', '-hr', type=str, default='10', 
                        help='SAR acquisition hour (UTC, 2-digit format)')
    parser.add_argument('--area', '-a', type=float, nargs=4, default=[50, 110, 30, 120],
                        metavar=('N', 'W', 'S', 'E'),
                        help='Geographic bounding box: North West South East')
    parser.add_argument('--batch', '-b', type=int, default=300, 
                        help='Number of dates to bundle in a single CDS request')

    args = parser.parse_args()

    # Normalize paths
    download_dir = os.path.abspath(args.dir)
    dates_file = os.path.abspath(args.dates)
    
    if not os.path.exists(download_dir):
        os.makedirs(download_dir)

    # Fixed ERA5 parameters for MintPy (PyAPS3)
    variables = ['geopotential', 'temperature', 'specific_humidity']
    levels = ['1','2','3','5','7','10','20','30','50','70','100','125','150',
              '175','200','225','250','300','350','400','450','500','550',
              '600','650','700','750','775','800','825','850','875','900',
              '925','950','975','1000']

    # --- 2. Date Filtering and Existence Check ---
    if not os.path.exists(dates_file):
        print(f"Error: Date list file not found at {dates_file}")
        return

    with open(dates_file, 'r') as f:
        all_dates = [line.strip() for line in f if line.strip()]

    print(f"\n[*] Initialization...")
    print(f"    Target Directory: {download_dir}")
    print(f"    Bounding Box: {args.area}")
    print(f"    Acquisition Time: {args.hour}:00 UTC")

    needed_dates = []
    # MintPy/PyAPS3 naming convention: ERA5_NS_NN_EW_EE_YYYYMMDD_HH.grb
    # Note: Area coordinates are converted to integers for the filename string
    for d in all_dates:
        check_name = (f"ERA5_N{int(args.area[2])}_N{int(args.area[0])}_"
                      f"E{int(args.area[1])}_E{int(args.area[3])}_{d}_{int(args.hour):02d}.grb")
        if not os.path.exists(os.path.join(download_dir, check_name)):
            needed_dates.append(d)

    if not needed_dates:
        print("\n All data already exists. Nothing to download.")
        return

    print(f"    Missing Dates: {len(needed_dates)} out of {len(all_dates)}")

    # --- 3. Batch Download and Split Loop ---
    c = cdsapi.Client(timeout=100)
    batches = list(split_list(needed_dates, args.batch))

    for i, batch in enumerate(batches):
        print(f"\n[{i+1}/{len(batches)}] Processing Batch ({len(batch)} dates)...")
        formatted_dates = [f"{d[:4]}-{d[4:6]}-{d[6:8]}" for d in batch]
        temp_bulk_file = os.path.join(download_dir, f"temp_batch_{i}.grb")

        request = {
            'product_type': 'reanalysis',
            'format': 'grib',
            'variable': variables,
            'pressure_level': levels,
            'date': formatted_dates,
            'time': f"{int(args.hour):02d}:00",
            'area': args.area,
        }

        if download_with_retry(c, request, temp_bulk_file):
            print(f"    -> Download complete. Splitting GRIB file...")
            # Use grib_copy from ecCodes to split the multi-message GRIB into daily files
            split_pattern = os.path.join(download_dir, 
                f"ERA5_N{int(args.area[2])}_N{int(args.area[0])}_E{int(args.area[1])}_E{int(args.area[3])}_[dataDate]_{int(args.hour):02d}.grb")
            
            try:
                subprocess.run(['grib_copy', temp_bulk_file, split_pattern], check=True)
                os.remove(temp_bulk_file)
                print(f"     Batch {i+1} successfully processed.")
            except Exception as e:
                print(f"     Split failed. Ensure 'eccodes' is installed: {e}")
        else:
            print(f"     Batch {i+1} failed after multiple retries. Skipping...")

    print(f"\n{'='*60}\n[Done] All tasks finished.\n{'='*60}")

if __name__ == "__main__":
    main()