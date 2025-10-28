---
id: "creating-libraries"
title: "Creating Libraries to Structure a Project with Dune"
short_title: "Creating Libraries"
description: |
  How to create libraries with Dune
category: "Libraries & Packages"
---

<!--
## Reference Documentation
- [Dune Library Stanza](https://dune.readthedocs.io/en/stable/reference/dune/library.html) - Complete library stanza reference
- [Dune Tutorial - Creating Libraries](https://dune.readthedocs.io/en/stable/tutorials/developing-with-dune/creating-libraries.html) - Step-by-step guide
- [Dune - Visibility](https://dune.readthedocs.io/en/stable/concepts/visibility.html) - Public vs private libraries
- [Dune - Library Dependencies](https://dune.readthedocs.io/en/stable/reference/library-dependencies.html) - Specifying dependencies
- [Dune - Scopes](https://dune.readthedocs.io/en/stable/explanations/scopes.html) - Understanding scopes and packages
- [Publishing Packages Tutorial](/docs/publishing-packages) - Next steps after creating libraries
-->

> **TL;DR**
> 
> Add a `library` stanza in your `dune` file.

Creating a library with dune is as simple as adding a `library` stanza in your dune file:

```dune
(library
 (name <name>)
 (public_name <public_name>)
 (libraries <libraries...>))
```

Where `<name>` is the name of the library used inside internally, `<public_name>` is the name of the library used by users of the package and `<libaries...>` is the list of libraries to link to your library.

Note that if the library does not have a `public_name`, it will not be installed when installing the package through opam. As a consequence, you cannot use an internal library that does not have a `public_name` in a library or executable that has one.
