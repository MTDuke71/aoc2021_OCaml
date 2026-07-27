"""Day 0: The Tyranny of the Rocket Equation (tutorial dry run).

Python algorithm reference mirroring src/day00.ml, kept as a second
implementation to cross-check the OCaml answers. Input is one integer module
mass per line.
"""

import sys


def parse_input(raw: str) -> list[int]:
    return [int(line) for line in raw.splitlines() if line.strip()]


def fuel(mass: int) -> int:
    """Base equation: floor(mass / 3) - 2."""
    return mass // 3 - 2


def total_fuel(mass: int) -> int:
    """Part 2: fuel for the fuel, iterated until a step is <= 0."""
    total = 0
    f = fuel(mass)
    while f > 0:
        total += f
        f = fuel(f)
    return total


def part1(parsed: list[int]) -> str:
    return str(sum(fuel(mass) for mass in parsed))


def part2(parsed: list[int]) -> str:
    return str(sum(total_fuel(mass) for mass in parsed))


def solve(raw: str) -> tuple[str, str]:
    parsed = parse_input(raw)
    return part1(parsed), part2(parsed)


def main(argv: list[str]) -> int:
    path = argv[1] if len(argv) > 1 else "inputs/day00.txt"
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
    print("day00")
    print(f"  part1: {one}")
    print(f"  part2: {two}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
