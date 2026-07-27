"""Reference placeholder for day08.

Keep a simple Python sketch here if you want a second implementation for cross-checking.
"""


def parse_input(raw: str) -> list[str]:
    return [line for line in raw.splitlines() if line.strip()]


def part1(parsed: list[str]) -> str:
    return "TODO: day08 part1"


def part2(parsed: list[str]) -> str:
    return "TODO: day08 part2"


def solve(raw: str) -> tuple[str, str]:
    parsed = parse_input(raw)
    return part1(parsed), part2(parsed)
