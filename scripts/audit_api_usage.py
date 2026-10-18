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
GUARD_PATTERN = r'\b(\w+) has :(\w+)'
SYMBOL_PATTERN = r'\b([A-Z][A-Za-z]+)\.(\w+)'


def collect_used_symbols():
    """Return {(module, symbol)} pairs referenced as Module.symbol in
    executable code, plus symbols protected by `has :sym` guards."""
    used = set()
    guarded = set()
    for path in source_files():
        file_used, file_guarded = file_symbols(strip_type_annotations(read_text(path)))
        used |= file_used
        guarded |= file_guarded
    return used, guarded


def read_text(path):
    with open(path) as handle:
        return handle.read()


def file_symbols(text):
    """Return (Toybox symbols one file uses, symbols its `has` guards protect)."""
    guards = set(re.findall(GUARD_PATTERN, text))
    used = {(module, symbol) for module, symbol in re.findall(SYMBOL_PATTERN, text)
            if module in TOYBOX_MODULES}
    return used, guards | {reference for reference in used if is_family_guarded(reference, guards)}


def is_family_guarded(reference, file_guards):
    module, symbol = reference
    return any(guard in file_guards and module == guard[0] and family.match(symbol)
               for guard, family in GUARD_FAMILIES.items())


def load_device_api(devices_dir, device):
    path = os.path.join(devices_dir, device, f"{device}.api.debug.xml")
    if not os.path.exists(path):
        return None
    return open(path).read()


DEFAULT_DEVICES_DIR = os.path.expanduser("~/.Garmin/ConnectIQ/Devices")
GUARDED_MARKER = " (has-guarded)"


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--devices-dir", default=DEFAULT_DEVICES_DIR)
    return parser.parse_args()


def audit_device(device, api, used, guarded):
    """Print every symbol missing on one device; True when an unguarded one is missing."""
    has_unguarded_gap = False
    for module, symbol in sorted(used):
        # A quoted occurrence is also a plain substring, so one check covers all forms.
        if symbol in api:
            continue
        is_guarded = (module, symbol) in guarded
        print(f"MISSING on {device}: {module}.{symbol}{GUARDED_MARKER if is_guarded else ''}")
        has_unguarded_gap = has_unguarded_gap or not is_guarded
    return has_unguarded_gap


def audit_devices(devices_dir, devices, used, guarded):
    """Return (has_failed, devices without api.debug.xml)."""
    has_failed = False
    missing_devices = []
    for device in devices:
        api = load_device_api(devices_dir, device)
        if api is None:
            missing_devices.append(device)
            continue
        has_failed = audit_device(device, api, used, guarded) or has_failed
    return has_failed, missing_devices


def report_result(has_failed, devices, missing_devices, guarded):
    if missing_devices:
        print(f"WARNING: no api.debug.xml for: {', '.join(missing_devices)} "
              f"(download device files first)")
    if has_failed:
        print("AUDIT FAILED — some symbols are unavailable on target devices")
        sys.exit(1)
    print(f"AUDIT OK — every referenced Toybox symbol exists on all "
          f"{len(devices) - len(missing_devices)} audited devices "
          f"({len(guarded)} has-guarded)")


def main():
    args = parse_arguments()
    used, guarded = collect_used_symbols()
    devices = manifest_devices()
    print(f"Auditing {len(used)} Toybox symbol usages across "
          f"{len(devices)} devices…")
    has_failed, missing_devices = audit_devices(args.devices_dir, devices, used, guarded)
    report_result(has_failed, devices, missing_devices, guarded)


if __name__ == "__main__":
    main()
