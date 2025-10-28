---
id: "generating-documentation"
title: "Generating Documentation With odoc"
short_title: "Generating Documentation"
description: |
  How to use odoc to generate documentation.
category: "Additional Tooling"
---

<!--
DOCUMENTATION REFERENCES:
- odoc Documentation: https://ocaml.github.io/odoc/
- odoc for Authors: https://ocaml.github.io/odoc/odoc/odoc_for_authors.html
- odoc GitHub: https://github.com/ocaml/odoc
- Dune Documentation Generation: https://dune.readthedocs.io/en/stable/reference/dune/documentation.html

ODOC FEATURES:
- Generates HTML, LaTeX, or man pages
- Extracts from .mli interface files
- Parses special comment syntax
- Cross-references between modules
- Custom documentation pages (.mld files)
- Integrates with Dune

OUTPUT FORMATS:
- HTML (default, recommended)
- LaTeX (for PDF generation)
- Man pages (Unix manual format)

DOCSTRING SYNTAX:
- (** ... *) - Documentation comment
- @param, @return, @raise - Special tags
- {b bold}, {i italic} - Inline formatting
- {[ ... ]} - Code blocks
- {{:url}text} - Links
- {!Module.value} - Cross-references

USAGE WITH DUNE:
- dune build @doc - Generate documentation
- (documentation (package <name>)) - Dune stanza
- Output in _build/default/_doc/_html/

MLD FILES:
- .mld extension for custom pages
- index.mld replaces default index
- Placed in doc/ or docs/ directory
- Same syntax as docstrings

DOCSTRING EXAMPLE:
(** Short description.

    Longer description with {b emphasis}.

    @param x Description of parameter x
    @return What the function returns
    @raise Not_found When element not found *)

INSTALLATION:
- opam install odoc
- Usually included in OCaml Platform
- Dune handles invocation automatically

RELATED TUTORIALS:
- Your First OCaml Program: /docs/your-first-program
- Dune Tutorial: /docs/dune
- OCaml Programming Guidelines: /docs/guidelines
- Creating Libraries: /docs/creating-libraries

EXTERNAL RESOURCES:
- odoc homepage: https://ocaml.github.io/odoc/
- odoc GitHub: https://github.com/ocaml/odoc
- OCaml.org package docs: https://ocaml.org/packages
- Odoc examples: Various open-source OCaml projects
-->

The documentation rendering tool `odoc` generates documentation
in the form of HTML, LaTeX, or man pages,
from the docstrings and interfaces of the project's modules

Dune can run `odoc` on your project to generate HTML documentation with this command:

```shell
$ opam exec -- dune build @doc

# Unix or macOS
$ open _build/default/_doc/_html/index.html

# Windows
$ explorer _build\default\_doc\_html\index.html
```

## Generating `.mld` Documentation Pages

In addition to documenting the publicly-visible API of your project,
`odoc` also gives you the ability to add individual documentation pages.

For example, to replace the automatically generated documentation
index file, you have to add a file `index.mld` to your project.

To make Dune find your `.mld` pages and process them with `odoc`,
the `dune` file in the same directory as your `.mld` files needs to
include this stanza:

```
(documentation
 (package name-of-your-package))
```

A common place to put `.mld` files is a directory named `doc` or `docs`.

For more information on how to write documentation pages for `odoc`,
see the [`odoc` for authors documentation](https://ocaml.github.io/odoc/odoc/odoc_for_authors.html).
