---
id: data-structures-comparison 
title: Comparison of Standard Containers
description: >
  Rough comparison of the different container types in OCaml
category: "Resources"
---

<!--
DOCUMENTATION REFERENCES:
- OCaml Manual - Standard library: https://ocaml.org/manual/5.2/api/index.html
- OCaml Manual - List module: https://ocaml.org/manual/5.2/api/List.html
- OCaml Manual - Array module: https://ocaml.org/manual/5.2/api/Array.html
- OCaml Manual - String module: https://ocaml.org/manual/5.2/api/String.html
- OCaml Manual - Set module: https://ocaml.org/manual/5.2/api/Set.html
- OCaml Manual - Map module: https://ocaml.org/manual/5.2/api/Map.html
- OCaml Manual - Hashtbl module: https://ocaml.org/manual/5.2/api/Hashtbl.html
- OCaml Manual - Buffer module: https://ocaml.org/manual/5.2/api/Buffer.html
- OCaml Manual - Queue module: https://ocaml.org/manual/5.2/api/Queue.html
- OCaml Manual - Stack module: https://ocaml.org/manual/5.2/api/Stack.html

CONTAINER COMPARISON:

Lists (immutable, singly-linked):
- Add: O(1) cons (::)
- Length: O(n)
- Access i: O(i)
- Find: O(n)
- Use for: I/O, pattern matching

Arrays (mutable, indexed):
- Add: O(n) (create new)
- Length: O(1)
- Access i: O(1)
- Find: O(n)
- Use for: random access, known size

Strings (immutable, bytes):
- Add: O(n) (create new)
- Length: O(1)
- Access i: O(1)
- Find: O(n)
- Use for: text data, fixed length

Set/Map (immutable, balanced trees):
- Add: O(log n)
- Size: O(n)
- Find: O(log n)
- Use for: versioned data, compilation

Hashtbl (mutable, hash table):
- Add: O(1) average
- Size: O(1)
- Find: O(1) average
- Use for: key-value storage

Buffer (mutable, extensible):
- Add char: O(1) amortized
- Add string: O(k)
- Length: O(1)
- Access i: O(1)
- Use for: building strings

Queue (mutable, FIFO):
- Add: O(1)
- Take: O(1)
- Length: O(1)

Stack (mutable, LIFO):
- Add (push): O(1)
- Take (pop): O(1)
- Length: O(1)

RELATED TUTORIALS:
- Lists: /docs/lists
- Arrays: /docs/arrays
- Maps: /docs/maps
- Sets: /docs/sets
- Hash Tables: /docs/hashtbl
- Options: /docs/options
- Sequences: /docs/seq

EXTERNAL RESOURCES:
- Big-O notation: https://en.wikipedia.org/wiki/Big_O_notation
- Data structures: https://en.wikipedia.org/wiki/Data_structure
- OCaml source code: https://github.com/ocaml/ocaml/tree/trunk/stdlib
- Cons operator: https://en.wikipedia.org/wiki/Cons
-->

This is a rough comparison of the different container types
provided by the OCaml standard library. In each
case, _n_ is the number of valid elements in the container.

Note that the big-O cost given for some operations reflects the current
implementation but is not guaranteed by the official documentation.
Hopefully it will not become worse. Anyway, if you want more details,
you can read the [documentation](/manual/api/index.html) about each of the modules or the OCaml [source code](https://github.com/ocaml/ocaml/tree/trunk/stdlib). Often, it
is also instructive to read the corresponding implementation.

## Lists: Immutable Singly-Linked Lists

Adding an element always creates a new list _l_ from an element _x_ List
_tl_. _tl_ remains unchanged, but it is not copied either.

* Adding an element: _O(1)_, [cons](https://en.wikipedia.org/wiki/Cons) operator `::`
* Length: _O(n)_, function `List.length`
* Accessing cell `i`: _O(i)_
* Finding an element: _O(n)_

Well-suited for: I/O, pattern-matching

Not very efficient for: random access, indexed elements

## Arrays: Mutable Vectors

Arrays are mutable data structures with a fixed length and random access.

* Adding an element (by creating a new array): _O(n)_
* Length: _O(1)_, function `Array.length`
* Accessing cell `i`: _O(1)_
* Finding an element: _O(n)_

Well-suited for the following cases: dealing with sets of elements of known size, accessing elements by numeric index, and modifying in-place elements. Basic arrays have a fixed length.

## Strings: Immutable Vectors

Strings are very similar to arrays, but they are immutable. Strings are
specialised for storing chars (bytes) and have some convenient syntax.
Strings have a fixed length. For extensible strings, the standard buffer
module can be used (see below).

* Adding an element (by creating a new string): _O(n)_
* Length: _O(1)_
* Accessing character `i`: _O(1)_
* Finding an element: _O(n)_

## Set and Map: Immutable Trees

Like lists, these are immutable, and they may share some subtrees. These trees
are a good solution for keeping older versions of sets of items.

* Adding an element: _O(log n)_
* Returning the number of elements: _O(n)_
* Finding an element: _O(log n)_

Sets and maps are very useful in compilation and metaprogramming, but
in other situations, hash tables are often more appropriate (see below).

## Hashtbl: Automatically Growing Hash Tables

OCaml hash tables are mutable data structures, which are a good solution
for storing (key, data) pairs in one single place.

* Adding an element: _O(1)_ if the initial size of the table is larger
 than the number of elements it contains; _O(log n)_ on average if _n_
 elements have been added in a table which is initially much smaller
 than _n_.
* Returning the number of elements: _O(1)_
* Finding an element: _O(1)_

## Buffer: Extensible Strings

Buffers provide an efficient way to accumulate a byte sequence in a
single place. They are mutable.

* Adding a char: _O(1)_ if the buffer is big enough, or _O(log n)_ on
 average if the initial buffer size was much smaller than the
 number of bytes _n_.
* Adding a string of _k_ chars: _O(k * "adding a char")_
* Length: _O(1)_
* Accessing cell `i`: _O(1)_

## Queue

OCaml queues are mutable first-in-first-out (FIFO) data structures.

* Adding an element: _O(1)_
* Taking an element: _O(1)_
* Length: _O(1)_

## Stack

OCaml stacks are mutable last-in-first-out (LIFO) data structures. They
are just like lists except they are mutable, i.e., adding an
element doesn't create a new stack but simply adds it to the stack.

* Adding an element: _O(1)_
* Taking an element: _O(1)_
* Length: _O(1)_
