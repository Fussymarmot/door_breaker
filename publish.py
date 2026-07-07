"""
publish.py — сборка .gma и публикация обновления в Steam Workshop одной командой.

Делает то же, что вручную:
    ./gmad_linux create -folder "<addon>" -out "<addon>.gma"
    ./gmpublish_linux update -id "<workshop_id>" -addon "<addon>.gma" -changes "<текст>"

    python publish.py
    python publish.py --bump patch
    python publish.py --changes "Добавил анимацию ударов"

Если --changes не указан, а версия менялась (--bump) — в чейнджлог
автоматически идёт "Update version X.Y.Z". Если --bump не указан и
--changes тоже не указан — спросит текст чейнджлога в консоли.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

DEFAULTS = {
    "gmad_bin":      "/home/fussy/.local/share/Steam/steamapps/common/GarrysMod/bin/gmad_linux",
    "gmpublish_bin": "/home/fussy/.local/share/Steam/steamapps/common/GarrysMod/bin/gmpublish_linux",
    "addon_folder":  "/home/fussy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/addons/door_breaker",
    "gma_out":       "/home/fussy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/addons/door_breaker.gma",
    "workshop_id":   "3755230335",
}


def bump_version(version: str, part: str) -> str:
    try:
        major, minor, patch = (int(x) for x in version.split("."))
    except ValueError:
        print(f"[!] Не смог разобрать версию '{version}', оставляю как есть.")
        return version

    if part == "major":
        major, minor, patch = major + 1, 0, 0
    elif part == "minor":
        minor, patch = minor + 1, 0
    elif part == "patch":
        patch += 1

    return f"{major}.{minor}.{patch}"


def load_addon_json(addon_dir: Path) -> dict:
    p = addon_dir / "addon.json"
    if not p.exists():
        return {}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"[!] addon.json повреждён ({e})")
        return {}


def save_addon_json(addon_dir: Path, data: dict) -> None:
    (addon_dir / "addon.json").write_text(
        json.dumps(data, ensure_ascii=False, indent=4) + "\n", encoding="utf-8"
    )


def run(cmd: list) -> None:
    print(f"\n$ {' '.join(cmd)}\n")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"[x] Команда завершилась с ошибкой (код {result.returncode}), останавливаюсь.")
        sys.exit(result.returncode)


def main():
    parser = argparse.ArgumentParser(description="Сборка .gma и публикация в Workshop одной командой")
    parser.add_argument("--bump", choices=["major", "minor", "patch"], help="Поднять версию перед публикацией.")
    parser.add_argument("--changes", help="Текст чейнджлога для Workshop. Если не указан — будет предложено ввести.")
    parser.add_argument("--gmad", default=DEFAULTS["gmad_bin"])
    parser.add_argument("--gmpublish", default=DEFAULTS["gmpublish_bin"])
    parser.add_argument("--folder", default=DEFAULTS["addon_folder"])
    parser.add_argument("--out", default=DEFAULTS["gma_out"])
    parser.add_argument("--id", default=DEFAULTS["workshop_id"])
    parser.add_argument("--skip-publish", action="store_true", help="Только собрать .gma, не публиковать.")
    args = parser.parse_args()

    addon_dir = Path(args.folder).resolve()
    if not addon_dir.exists():
        print(f"[x] Папка аддона не найдена: {addon_dir}")
        sys.exit(1)

    addon_data = load_addon_json(addon_dir)
    version = addon_data.get("version", "0.0.0")

    if args.bump:
        new_version = bump_version(version, args.bump)
        print(f"[+] Версия: {version} -> {new_version}")
        version = new_version
        if addon_data:
            addon_data["version"] = version
            save_addon_json(addon_dir, addon_data)
            print("[+] addon.json обновлён.")

    changes = args.changes
    if not changes:
        if args.bump:
            changes = f"Update version {version}"
        else:
            changes = input("Текст чейнджлога для Workshop: ").strip() or f"Update {version}"

    out_path = Path(args.out)
    if out_path.suffix:
        out_path = out_path.with_name(f"{out_path.stem}-v{version}{out_path.suffix}")
    else:
        out_path = out_path.with_name(f"{out_path.name}-v{version}")

    run([args.gmad, "create", "-folder", str(addon_dir), "-out", str(out_path)])

    if args.skip_publish:
        print(f"\n[OK] .gma собран: {out_path} (публикация пропущена, --skip-publish)")
        return

    run([args.gmpublish, "update", "-id", args.id, "-addon", str(out_path), "-changes", changes])

    print(f"\n[OK] Опубликовано. Версия: {version}. Чейнджлог: \"{changes}\"")


if __name__ == "__main__":
    main()
