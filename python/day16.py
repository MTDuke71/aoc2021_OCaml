"""Reference placeholder for day16.

Keep a simple Python sketch here if you want a second implementation for cross-checking.
"""


def parse_input(raw: str) -> list[str]:
    return [line for line in raw.splitlines() if line.strip()]


def part1(parsed: list[str]) -> str:
    return "TODO: day16 part1"


def part2(parsed: list[str]) -> str:
    return "TODO: day16 part2"


def solve(raw: str) -> tuple[str, str]:
    parsed = parse_input(raw)
    return part1(parsed), part2(parsed)
