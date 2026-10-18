"""Run the real iOS workflow and capture unedited simctl screenshots at its checkpoints."""
import pathlib
import re
import subprocess
import sys

if len(sys.argv) != 2:
    raise SystemExit("Usage: python3 tool/capture_simulator.py <dedicated-simulator-id>")
device = sys.argv[1]
output = pathlib.Path("docs/screenshots")
output.mkdir(parents=True, exist_ok=True)
command = ["flutter", "test", "integration_test/notebook_test.dart", "-d", device,
           "--dart-define=CAPTURE_SCREENSHOTS=true"]
process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
assert process.stdout is not None
for line in process.stdout:
    print(line, end="", flush=True)
    checkpoint = re.search(r"FIELDBOOK_SCREENSHOT:([a-z-]+)", line)
    if checkpoint:
        subprocess.run(["xcrun", "simctl", "io", device, "screenshot",
                        str(output / f"{checkpoint.group(1)}.png")], check=True)
raise SystemExit(process.wait())
