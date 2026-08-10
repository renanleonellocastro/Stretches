#!/usr/bin/env python3
"""Audit every Toybox API the app uses against every target device.

For each product in manifest.xml this script loads the device's
``<device>.api.debug.xml`` (from the Connect IQ device files) and verifies
that every Toybox symbol referenced in ``source/`` exists there. This is the
class of bug that only shows up on a real watch otherwise — e.g. a menu item
type, tone constant or method that one device family simply doesn't have.

Usage:
    python3 scripts/audit_api_usage.py [--devices-dir DIR]

Exit code 1 if any symbol is missing on any device.
"""

import argparse
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Symbols that are guarded with `X has :sym` checks in source, or provided by
# the app itself, may legitimately be absent on some devices.
GUARDED_OK = set()


def manifest_devices():
    with open(os.path.join(ROOT, "manifest.xml")) as f:
        return re.findall(r'iq:product id="([^"]+)"', f.read())


def source_files():
    return [p for p in glob.glob(os.path.join(ROOT, "source", "**", "*.mc"),
                                 recursive=True)
            if os.sep + "tests" + os.sep not in p]


TOYBOX_MODULES = {
    "Activity", "ActivityRecording", "Application", "Attention", "Background",
    "FitContributor", "Graphics", "Lang", "Math", "System", "Time", "Timer",
    "WatchUi",
}


def strip_type_annotations(text):
    """Remove `as <Type>` annotations and typed signatures: type names only
    exist at compile time, so they never fail symbol resolution at runtime."""
    text = re.sub(r'//.*', '', text)
    # `as [A, B]` tuple annotations (and `or [...]` alternatives), then
    # plain `as Foo.Bar<Baz>?` ones.
    text = re.sub(r'\bas\s+\[[^\]]*\]', '', text)
    text = re.sub(r'\bor\s+\[[^\]]*\]', '', text)
    text = re.sub(r'\bas\s+[\w.]+(\s*<[^>]*>)?\??', '', text)
    return text


# A `Module has :guard` check also protects related symbols that only exist
# alongside the guard (e.g. TONE_* constants exist iff playTone does).
GUARD_FAMILIES = {
    ("Attention", "playTone"): re.compile(r"^TONE_"),
}


def collect_used_symbols():
    """Return {(module, symbol)} pairs referenced as Module.symbol in
    executable code, plus symbols protected by `has :sym` guards."""
    used = set()
    guarded = set()
    for path in source_files():
        text = strip_type_annotations(open(path).read())
        file_guards = set(re.findall(r'\b(\w+) has :(\w+)', text))
        guarded |= file_guards
        for module, symbol in re.findall(r'\b([A-Z][A-Za-z]+)\.(\w+)', text):
            if module not in TOYBOX_MODULES:
                continue
            used.add((module, symbol))
            for (gmod, gsym), family in GUARD_FAMILIES.items():
                if (gmod, gsym) in file_guards and module == gmod \
                        and family.match(symbol):
                    guarded.add((module, symbol))
    return used, guarded


def load_device_api(devices_dir, device):
    path = os.path.join(devices_dir, device, f"{device}.api.debug.xml")
    if not os.path.exists(path):
        return None
    return open(path).read()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--devices-dir",
                        default=os.path.expanduser("~/.Garmin/ConnectIQ/Devices"))
    args = parser.parse_args()

    used, guarded = collect_used_symbols()
    devices = manifest_devices()
    print(f"Auditing {len(used)} Toybox symbol usages across "
          f"{len(devices)} devices…")

    failed = False
    missing_devices = []
    for device in devices:
        api = load_device_api(args.devices_dir, device)
        if api is None:
            missing_devices.append(device)
            continue
        for module, symbol in sorted(used):
            if f'"{symbol}"' in api or f"'{symbol}'" in api or symbol in api:
                continue
            marker = " (has-guarded)" if (module, symbol) in guarded else ""
            print(f"MISSING on {device}: {module}.{symbol}{marker}")
            if not marker:
                failed = True

    if missing_devices:
        print(f"WARNING: no api.debug.xml for: {', '.join(missing_devices)} "
              f"(download device files first)")
    if failed:
        print("AUDIT FAILED — some symbols are unavailable on target devices")
        sys.exit(1)
    print(f"AUDIT OK — every referenced Toybox symbol exists on all "
          f"{len(devices) - len(missing_devices)} audited devices "
          f"({len(guarded)} has-guarded)")


if __name__ == "__main__":
    main()
