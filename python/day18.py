"""Reference placeholder for day18.

Keep a simple Python sketch here if you want a second implementation for cross-checking.
"""

import sys


def parse_input(raw: str) -> list[str]:
    return [line for line in raw.splitlines() if line.strip()]


def part1(parsed: list[str]) -> str:
    return "TODO: day18 part1"


def part2(parsed: list[str]) -> str:
    return "TODO: day18 part2"


def solve(raw: str) -> tuple[str, str]:
    parsed = parse_input(raw)
    return part1(parsed), part2(parsed)


def main(argv: list[str]) -> int:
    path = argv[1] if len(argv) > 1 else "inputs/day18.txt"
    try:
        with open(path, encoding="utf-8") as handle:
            raw = handle.read()
    except OSError as error:
        print(f"Could not read {path}: {error}", file=sys.stderr)
        print(
            f"Create {path} locally (it is gitignored) or pass an explicit path.",
            file=sys.stderr,
        )
        return 1
    one, two = solve(raw)
    print("day18")
    print(f"  part1: {one}")
    print(f"  part2: {two}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
