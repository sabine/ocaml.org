---
id: "formatting-your-code"
title: "Formatting Your Code With OCamlFormat"
short_title: "Formatting Your Code"
description: |
  How to set up OCamlFormat to automatically format your code
category: "Additional Tooling"
---

<!--
DOCUMENTATION REFERENCES:
- OCamlFormat Documentation: https://ocamlformat.org/
- OCamlFormat GitHub: https://github.com/ocaml-ppx/ocamlformat
- Dune Formatting: https://dune.readthedocs.io/en/stable/howto/formatting.html
- OCaml Style Guide: https://ocaml.org/docs/guidelines

OCAMLFORMAT FEATURES:
- Automatic code formatting
- Consistent code style across projects
- Configurable formatting options
- Integration with editors (VSCode, Emacs, Vim)
- Works with Dune build system

CONFIGURATION:
- .ocamlformat file at project root
- version = <version> - Lock OCamlFormat version
- profile = <default|compact|sparse|janestreet>
- Many granular options available
- Documentation: https://ocamlformat.org/

USAGE:
- ocamlformat <file.ml> - Format single file
- ocamlformat --inplace <file.ml> - Format in place
- dune fmt - Format entire project
- opam exec -- dune fmt - Via opam

INSTALLATION:
- opam install ocamlformat
- Should match version in .ocamlformat
- Pin to specific version if needed

EDITOR INTEGRATION:
- VSCode: OCaml Platform extension
- Emacs: tuareg-mode with ocamlformat
- Vim: vim-ocamlformat or ALE
- Format on save available in most editors

CONFIGURATION OPTIONS:
- profile: Preset formatting styles
- margin: Line width (default 80)
- indent: Number of spaces
- break-cases: How to break pattern matches
- if-then-else: Formatting of conditionals
- Many more: see documentation

PROFILES:
- default: Standard OCaml formatting
- compact: More compact style
- sparse: More vertical space
- janestreet: Jane Street style

RELATED TUTORIALS:
- OCaml Programming Guidelines: /docs/guidelines
- Editor Setup: /docs/set-up-editor
- Your First OCaml Program: /docs/your-first-program
- Dune Tutorial: /docs/dune

EXTERNAL RESOURCES:
- OCamlFormat configuration: https://ocamlformat.org/
- GitHub repo: https://github.com/ocaml-ppx/ocamlformat
- ocp-indent (alternative): https://github.com/OCamlPro/ocp-indent
-->

Automatic formatting with OCamlFormat requires an `.ocamlformat` configuration file at the root of the project.

An empty file is accepted, but since different versions of OCamlFormat will vary in formatting, it
is good practice to specify the version you're using. Running

```shell
$ echo "version = `ocamlformat --version`" > .ocamlformat
```

creates a configuration file for the currently installed version of OCamlFormat.

In addition to editor plugins that use OCamlFormat for automatic code formatting, Dune also offers a command to run OCamlFormat to automatically format all files from your codebase:

```shell
$ opam exec -- dune fmt
```
