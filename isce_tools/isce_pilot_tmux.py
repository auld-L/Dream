#!/usr/bin/env python3
import os
import subprocess
import sys
import time
import argparse
import re
from datetime import datetime
from pathlib import Path

# --- 环境配置 ---
RUN_DIR = "."                    # 运行时请在 run_files 目录执行，或用 --run-dir 指定
LOG_BASE_DIR = "./isce_logs"      # 日志主目录，默认建在 run_files 下
os.environ.setdefault("OMP_NUM_THREADS", "1")  # 防止超多核机器 OpenMP 过度并行


def in_tmux() -> bool:
    """判断当前是否已经在 tmux 会话中。"""
    return bool(os.environ.get("TMUX"))


def relaunch_in_tmux(session_name: str, args: list[str]) -> None:
    """如果当前不在 tmux 中，则把本脚本重新放入 tmux 会话运行。"""
    tmux_bin = subprocess.run(["bash", "-lc", "command -v tmux"], capture_output=True, text=True)
    if tmux_bin.returncode != 0:
        print("❌ 没有找到 tmux。请先安装：sudo apt install tmux", flush=True)
        sys.exit(1)

    # 用绝对路径，避免 tmux 新 shell 中找不到脚本
    script = str(Path(__file__).resolve())
    cmd = [sys.executable, script] + args + ["--no-tmux"]
    cmd_str = " ".join(subprocess.list2cmdline([x]) for x in cmd)

    print(f"🧷 当前不在 tmux 中，自动创建 tmux 会话: {session_name}", flush=True)
    print(f"🔁 进入方式: tmux attach -t {session_name}", flush=True)
    print("ℹ️  退出但不中断任务：Ctrl+b，然后按 d", flush=True)

    os.execvp("tmux", ["tmux", "new-session", "-s", session_name, cmd_str])


def get_all_run_scripts(run_dir: str) -> list[str]:
    """获取目录下所有 run_ 脚本并按步骤编号排序。"""
    if not os.path.exists(run_dir):
        print(f"❌ 错误: 找不到目录 {run_dir}", flush=True)
        sys.exit(1)

    files = []
    for f in os.listdir(run_dir):
        if f.startswith("run_") and re.search(r"run_(\d+)", f):
            files.append(f)

    files.sort(key=lambda x: int(re.search(r"run_(\d+)", x).group(1)))
    return files


def parse_step_range(step_str: str, all_scripts: list[str]) -> list[str]:
    """解析步骤字符串，例如 1-5、1,3,5、10。"""
    target_indices = set()
    script_map = {int(re.search(r"run_(\d+)", f).group(1)): f for f in all_scripts}

    for part in step_str.split(','):
        part = part.strip()
        if not part:
            continue
        if '-' in part:
            start, end = map(int, part.split('-', 1))
            for i in range(start, end + 1):
                if i in script_map:
                    target_indices.add(i)
        else:
            idx = int(part)
            if idx in script_map:
                target_indices.add(idx)

    return [script_map[i] for i in sorted(target_indices)]


def wait_after_step(seconds: int, script_name: str) -> None:
    """每一步结束后等待，避免文件系统/后台子进程未完全同步。"""
    if seconds <= 0:
        return
    print(f"⏸️  {script_name} 已结束，等待 {seconds} 秒后再进入下一步...", flush=True)
    for remain in range(seconds, 0, -30):
        sleep_time = min(30, remain)
        print(f"   剩余约 {remain} 秒", flush=True)
        time.sleep(sleep_time)


def execute_task(script_name: str, run_dir: str, log_dir: str) -> tuple[bool, object]:
    """执行单个 run 脚本并记录日志。"""
    script_path = os.path.join(run_dir, script_name)
    log_file = os.path.join(log_dir, f"{script_name}.log")

    start_time = datetime.now()
    print(f"\n{'=' * 60}", flush=True)
    print(f"🚀 正在启动: {script_name}", flush=True)
    print(f"⏰ 开始时间: {start_time.strftime('%Y-%m-%d %H:%M:%S')}", flush=True)
    print(f"📝 日志文件: {log_file}", flush=True)

    try:
        with open(log_file, "w", buffering=1) as f:
            f.write(f"# Command: bash {script_path}\n")
            f.write(f"# Start: {start_time.strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            f.flush()

            process = subprocess.Popen(
                ["bash", script_path],
                stdout=f,
                stderr=subprocess.STDOUT,
                cwd=run_dir,
                text=True,
                env=os.environ.copy(),
            )

            while process.poll() is None:
                time.sleep(10)

        end_time = datetime.now()
        duration = end_time - start_time

        if process.returncode == 0:
            print(f"✅ 完成: {script_name}", flush=True)
            print(f"⏱️  耗时: {str(duration).split('.')[0]}", flush=True)
            return True, duration

        print(f"❌ 失败: {script_name}，错误码: {process.returncode}", flush=True)
        print(f"🔎 查看最后日志: tail -80 {log_file}", flush=True)
        return False, duration

    except Exception as e:
        print(f"💥 运行异常: {e}", flush=True)
        return False, None


def main():
    parser = argparse.ArgumentParser(description="ISCE2 run_files 自动执行脚本，支持 tmux 和步骤间隔等待")
    parser.add_argument("-s", "--steps", required=True,
                        help="指定步骤，例如 '1-5'、'1,3,5'、'10'")
    parser.add_argument("--run-dir", default=RUN_DIR,
                        help="run_files 目录，默认当前目录 .")
    parser.add_argument("--log-base-dir", default=LOG_BASE_DIR,
                        help="日志主目录，默认 ./isce_logs")
    parser.add_argument("--pause", type=int, default=180,
                        help="每一步成功后暂停秒数，默认 180 秒，即 3 分钟")
    parser.add_argument("--tmux-session", default="isce_run",
                        help="tmux 会话名，默认 isce_run")
    parser.add_argument("--no-tmux", action="store_true",
                        help="不自动进入 tmux。内部重启时使用，普通用户一般不用")
    args = parser.parse_args()

    # 自动进入 tmux。避免 SSH/终端关闭导致长任务中断。
    if not args.no_tmux and not in_tmux():
        relaunch_in_tmux(args.tmux_session, sys.argv[1:])

    run_dir = os.path.abspath(args.run_dir)
    log_base_dir = os.path.abspath(args.log_base_dir)

    all_scripts = get_all_run_scripts(run_dir)
    selected_scripts = parse_step_range(args.steps, all_scripts)

    if not selected_scripts:
        print("⚠️ 未找到匹配的步骤，请检查输入。", flush=True)
        return

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    current_log_dir = os.path.join(log_base_dir, f"session_{timestamp}")
    os.makedirs(current_log_dir, exist_ok=True)

    summary_report = []
    print(f"📂 run_files 目录: {run_dir}", flush=True)
    print(f"📊 待处理步骤: {', '.join(selected_scripts)}", flush=True)
    print(f"⏸️  每一步成功后暂停: {args.pause} 秒", flush=True)
    print(f"🧷 tmux 状态: {'已在 tmux 中' if in_tmux() else '未使用 tmux'}", flush=True)

    for idx, script in enumerate(selected_scripts):
        success, duration = execute_task(script, run_dir, current_log_dir)
        summary_report.append((script, "成功" if success else "失败", duration))

        if not success:
            print("\n🛑 任务中断。", flush=True)
            break

        # 最后一步无需等待；中间步骤等待 3 分钟，给文件系统/后台写入留时间。
        if idx < len(selected_scripts) - 1:
            wait_after_step(args.pause, script)

    print("\n\n" + " " * 15 + "📈 任务耗时汇总报表", flush=True)
    print("-" * 70, flush=True)
    print(f"{'步骤名称':<40} | {'状态':<6} | {'耗时'}", flush=True)
    print("-" * 70, flush=True)
    for name, status, dur in summary_report:
        dur_str = str(dur).split('.')[0] if dur else "N/A"
        print(f"{name:<40} | {status:<6} | {dur_str}", flush=True)
    print("-" * 70, flush=True)
    print(f"📝 详细日志见: {current_log_dir}\n", flush=True)


if __name__ == "__main__":
    main()
