# Tutorial Day 1 — Values, Expressions, Bindings, and Function Definitions

**Track goal:** 11 days to read and understand an Advent of Code solution written in OCaml.  
**Today's goal:** Install OCaml, open the REPL, and understand the basic building blocks: values, expressions, let bindings, and function definitions.

---

## Part 0 — Setting Up OCaml

OCaml is distributed through **opam**, the OCaml package manager. It installs the compiler, standard library, and any packages you need (including `dune`, the build tool used throughout this repo).

### macOS

```bash
# Install Homebrew if you don't already have it (https://brew.sh)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install opam via Homebrew
brew install opam

# Initialize opam (creates ~/.opam, installs a default OCaml compiler)
opam init --auto-setup

# Apply changes to the current shell (or restart your terminal)
eval $(opam env)
```

### Linux (Debian / Ubuntu)

```bash
# Install opam from the system package manager
sudo apt-get update && sudo apt-get install -y opam

# Initialize opam
opam init --auto-setup
eval $(opam env)
```

### Windows

The recommended path on Windows is **WSL 2** (Windows Subsystem for Linux) running Ubuntu.  
Follow the Linux instructions above inside WSL.  
Native Windows support is improving, but WSL gives the smoothest experience right now.

### Verify the install

```bash
ocaml --version    # should print e.g. "The OCaml toplevel, version 5.x.x"
opam --version     # should print e.g. "2.x.x"
```

### Install dune and other tools

```bash
opam install dune ocaml-lsp-server ocamlformat
eval $(opam env)   # refresh PATH so dune is visible
dune --version     # should print e.g. "3.x.x"
```

`dune` is the build system used in this repository.  
`ocaml-lsp-server` provides editor intelligence (VS Code, Neovim, Emacs, etc.).  
`ocamlformat` is the standard auto-formatter.

### Editor setup (optional but recommended)

- **VS Code**: install the *OCaml Platform* extension (identifier `ocamllabs.ocaml-platform`).
- **Neovim / Emacs**: configure your LSP client to use `ocamllsp` (installed above).

---

## Part 1 — The OCaml Toplevel (REPL)

OCaml ships with an interactive REPL called the **toplevel**. Start it with:

```bash
ocaml
```

You will see a prompt `#`. Type expressions followed by `;;` to evaluate them:

```
# 1 + 2;;
- : int = 3
```

The reply `- : int = 3` means:
- `-` — no name was bound to this result.
- `: int` — the inferred type.
- `= 3` — the value.

Exit the toplevel with `Ctrl-D` or `#quit;;`.

> **Tip:** `utop` is a nicer REPL with tab completion. Install it with `opam install utop` and run it with `utop`.

---

## Part 2 — Values and Expressions

### Integers and arithmetic

```ocaml
1 + 2        (* 3 *)
10 - 4       (* 6 *)
3 * 7        (* 21 *)
10 / 3       (* 3  — integer division, truncates *)
10 mod 3     (* 1  — remainder *)
```

OCaml uses `*` for multiplication, `/` for integer division, and `mod` for remainder.

### Floats use different operators

OCaml is strict about numeric types. Integer operators do **not** work on floats:

```ocaml
1.5 +. 2.5   (* 4.0 — note the dot: +. -. *. /. *)
sqrt 2.0     (* 1.4142... *)
```

If you try `1.5 + 2.5` the compiler will reject it with a type error. This is intentional — OCaml never silently coerces numbers.

### Booleans

```ocaml
true
false
not true        (* false *)
true && false   (* false *)
true || false   (* true *)
```

### Comparison operators

```ocaml
1 = 1     (* true  — structural equality, works on any type *)
1 <> 2    (* true  — not equal *)
3 < 5     (* true *)
5 >= 5    (* true *)
```

Note: OCaml uses `=` for equality testing (not `==`) and `<>` for inequality (not `!=`).

### Strings and characters

```ocaml
"hello"          (* string literal *)
"hello" ^ " world"   (* string concatenation with ^ *)
String.length "hello"  (* 5 *)
'a'              (* character literal, single quotes *)
```

### Unit

`unit` is OCaml's equivalent of `void` — a type with exactly one value, written `()`. Functions that perform side effects (like printing) and return nothing meaningful return `unit`:

```ocaml
print_endline "hello"   (* prints "hello\n", returns unit *)
```

---

## Part 3 — Let Bindings

A **let binding** gives a name to a value. It is the primary way to introduce names in OCaml.

```ocaml
let x = 42
let greeting = "hello"
let pi = 3.14159
```

In the toplevel, add `;;` to execute:

```ocaml
# let x = 42;;
val x : int = 42
```

The reply `val x : int = 42` tells you a name was bound (`val`), the type is `int`, and the value is `42`.

### Let bindings are immutable

Unlike variables in most imperative languages, a let binding cannot be reassigned. This is not a limitation — it is a design choice that makes OCaml programs easier to reason about.

```ocaml
let x = 10
(* x = 20  — this is a type error, not reassignment *)
let x = 20  (* this shadows the previous x, it does not mutate it *)
```

Shadowing replaces the name `x` in subsequent code; the original `10` still exists if anything else already captured it.

### Local let bindings with `in`

Inside a function or larger expression, use `let ... in` to introduce a local name:

```ocaml
let result =
  let a = 3 in
  let b = 4 in
  a + b
```

`a` and `b` are only visible inside the `in` clause. This is how you build up computations step by step.

---

## Part 4 — Function Definitions

Functions are values in OCaml. They are defined with `let`, just like any other value.

### Basic syntax

```ocaml
let double x = x * 2
```

- `double` is the function name.
- `x` is the parameter (no parentheses needed).
- `x * 2` is the body — the value the function returns.

There is no `return` keyword. The last expression in the body is the return value.

### Calling a function

```ocaml
double 5        (* 10 *)
double (3 + 1)  (* 8 — parentheses only needed to group arguments *)
```

### Multiple parameters

```ocaml
let add x y = x + y
add 3 4        (* 7 *)
```

Parameters are separated by spaces, both in the definition and the call. There are no commas between arguments.

### Type annotations (optional, but useful for clarity)

```ocaml
let add (x : int) (y : int) : int = x + y
```

The `: int` annotations are optional — OCaml infers them automatically — but they can make intent clearer and produce better error messages.

### Anonymous functions (lambdas)

OCaml has first-class anonymous functions, written with `fun`:

```ocaml
fun x -> x * 2           (* same as double, but unnamed *)
let double = fun x -> x * 2   (* equivalent to: let double x = x * 2 *)
```

You will see `fun` frequently when passing functions as arguments.

### Recursive functions

A function that calls itself must be declared with `let rec`:

```ocaml
let rec factorial n =
  if n <= 1 then 1
  else n * factorial (n - 1)
```

Without `rec`, the name `factorial` is not in scope inside the function body. OCaml requires you to be explicit about recursion.

### If expressions

`if`/`then`/`else` is an expression in OCaml, not a statement:

```ocaml
let abs_val x = if x >= 0 then x else -x
```

Both branches must have the same type. There is no `if` without `else` (unless the result type is `unit`).

---

## Part 5 — Worked Example

See [`example.ml`](./example.ml) for a small complete program that demonstrates all of today's concepts. It computes fuel costs using integer arithmetic, let bindings, and a recursive function — the same shape you will see in AoC solutions.

To run it directly with the OCaml interpreter:

```bash
ocaml tutorial/day1/example.ml
```

Or compile and run it with dune from the repo root:

```bash
dune exec tutorial/day1/example.exe
```

Both produce the same output. The interpreter is quicker for scratch experiments; the dune build type-checks the example as part of `dune build`. Each tutorial day that ships an `example.ml` needs a `dune` file beside it declaring `(executable (name example))`.

---

## Key Takeaways for Day 1

| Concept | OCaml syntax | Rust analogy |
|---|---|---|
| Integer literal | `42` | `42i32` |
| Float operators | `+.` `-. *.` `/.` | `+` `-` `*` `/` (on `f64`) |
| Immutable binding | `let x = 5` | `let x = 5;` |
| Function def | `let f x = x + 1` | `fn f(x: i32) -> i32 { x + 1 }` |
| Recursive fn | `let rec f n = ...` | `fn f(n: i32) -> i32 { ... }` |
| Anonymous fn | `fun x -> x + 1` | `\|x\| x + 1` |
| Equality | `x = y` | `x == y` |
| Not-equal | `x <> y` | `x != y` |
| Unit type | `unit` / `()` | `()` |

---

## Day 2 Preview

Tomorrow: **lists, pattern matching, and recursion** — the three constructs that appear in every AoC OCaml solution.
