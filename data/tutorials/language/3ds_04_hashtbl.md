---
id: hash-tables
title: Hash Tables
description: >
  Discover efficient and mutable lookup tables with OCaml's Hashtbl module
category: "Data Structures"
---

<!--
DOCUMENTATION REFERENCES:
- OCaml Manual - Hashtbl module: https://ocaml.org/manual/5.2/api/Hashtbl.html
- OCaml Manual - Map module: https://ocaml.org/manual/5.2/api/Map.html
- OCaml Manual - Weak polymorphism: https://ocaml.org/manual/5.2/polymorphism.html

HASHTBL CHARACTERISTICS:
- Mutable associative array (key-value pairs)
- O(1) average time complexity for lookup/insert/delete
- Uses hashing function for efficient access
- Allows duplicate keys (keeps all values)
- Generic built-in hash function (Hashtbl.hash)
- Customizable via Hashtbl.Make functor

KEY FUNCTIONS:
- Hashtbl.create : int -> ('a, 'b) Hashtbl.t
- Hashtbl.add : ('a, 'b) t -> 'a -> 'b -> unit
- Hashtbl.replace : ('a, 'b) t -> 'a -> 'b -> unit
- Hashtbl.find : ('a, 'b) t -> 'a -> 'b
- Hashtbl.find_opt : ('a, 'b) t -> 'a -> 'b option
- Hashtbl.find_all : ('a, 'b) t -> 'a -> 'b list
- Hashtbl.remove : ('a, 'b) t -> 'a -> unit
- Hashtbl.mem : ('a, 'b) t -> 'a -> bool
- Hashtbl.iter : ('a -> 'b -> unit) -> ('a, 'b) t -> unit
- Hashtbl.fold : ('a -> 'b -> 'c -> 'c) -> ('a, 'b) t -> 'c -> 'c

HASHTBL VS MAP:
Hashtbl:
- Mutable, in-place updates
- O(1) average time complexity
- Duplicate keys allowed
- Generic polymorphic version available
- Better for frequent updates

Map:
- Immutable, functional style
- O(log n) time complexity
- No duplicate keys
- Must use functor (Map.Make)
- Better for versioning/persistence

WEAK POLYMORPHISM:
- '_weak1, '_weak2 : Types not yet determined
- Types become concrete after first use
- Cannot mix different types in same hashtbl
- Underscore prefix indicates monomorphic restriction

CUSTOM HASH FUNCTIONS:
- Hashtbl.Make functor for custom types
- Requires HashedType signature:
  - type t
  - val equal : t -> t -> bool
  - val hash : t -> int

RELATED TUTORIALS:
- Maps: /docs/maps
- Comparison of Standard Containers: /docs/data-structures-comparison
- Memoization: /docs/memoization
- Functors: /docs/functors

EXTERNAL RESOURCES:
- Hash table (Wikipedia): https://en.wikipedia.org/wiki/Hash_table
- Hash function: https://en.wikipedia.org/wiki/Hash_function
-->

## Introduction

The OCaml Standard Library's `Hashtbl` module implements an associative array
similar to the standard library's [`Map`](https://ocaml.org/docs/maps) module.

While these modules share a similar structure and purpose, there are several
differences that can be weighed when choosing between the two.

One of the benefits of a hash table over a map is that instead of having a
logarithmic time complexity (O(log n)), a [`hash
table`](https://en.wikipedia.org/wiki/Hash_table) is able to retrieve
information at a nearly instantaneous linear time complexity (O(1)).

A hash table data structure achieves efficient reads and writes by employing a
hashing function that converts the key of a key/value pair into an
algorithmically unique "fingerprint" known as a hash. OCaml has a built-in
hashing function within the `Hashtabl` module that is available for each key
The `Hashtbl` module implements an efficient, mutable lookup table.

## Creating a Polymorphic Hash Table

To create a hash table we could write:

```ocaml
# let my_hash = Hashtbl.create 123456;;
val my_hash : ('_weak1, '_weak2) Hashtbl.t = <abstr>
```

The 123456 is the initial size (in terms of element count) of the hash table.
This initial number is just your best guess as to the amount of data that you
will be putting into the hash table. The hash table can grow if you
under-estimate the size so don't worry about it too much. The type of my_hash
is:

```ocaml
# my_hash;;
- : ('_weak1, '_weak2) Hashtbl.t = <abstr>
```

The `'_weak1` and `'_weak2` correspond to the key and value types, respectively.
There are no concrete types (e.g., `int` or `float * string`) filled in those
slots because the type of the key and value are not yet determined. The
underscore indicates that the key and data types, once chosen, will be fixed. In
other words, you can't sometimes use a given hash table with `int`s for keys,
and then later use a string as a key in that same hash table.

### Adding Data to a Hash Table

Lets add some data to `my_hash`. Lets say I am working on a cross word
solving program and I want to find all words that start with a certain
letter. First I need to enter the data into `my_hash`.

Note that a hash table is modified by in-place updates, so unlike a
[map](https://ocaml.org/docs/maps), another hash table is _not_ created every
time you change the table. Thus, the code `let my_hash = Hashtbl.add my_hash
...` does not make sense. Instead, using an imperative style we would write
something like this:

```ocaml
# Hashtbl.add my_hash "h" "hello";
  Hashtbl.add my_hash "h" "hi";
  Hashtbl.add my_hash "h" "hug";
  Hashtbl.add my_hash "h" "hard";
  Hashtbl.add my_hash "w" "wimp";
  Hashtbl.add my_hash "w" "world";
  Hashtbl.add my_hash "w" "wine";;
- : unit = ()
```

The return type is `unit`, indicating that `Hashtbl.add` produces a side effect.

Now that we put data into `my_hash`, lets look at its type:

```ocaml
# my_hash;;
- : (string, string) Hashtbl.t = <abstr>
```

Where the type used to be the polymorphic `(_weak1, _weak2)`, it now has the
concrete representation of `(string * string)`.

### Finding Data in Hash Tables

If we want to find one element in `my_hash` that has an `"h"` in it then we
would write:

```ocaml
# Hashtbl.find my_hash "h";;
- : string = "hard"
```

As we would expect, querying the hash table `my_hash` with the key `h` returns a
single value, `"hard"` since this is the last element updated with the
value of `"h"`.

However, the previous values associated with the key `"h"` were not replaced.
What we may want instead is all the elements that start with `"h"`. To do this we
want to *find all* of them. What better name for this than `find_all`?

```ocaml
# Hashtbl.find_all my_hash "h";;
- : string list = ["hard"; "hug"p; "hi"; "hello"]
```

This returns `["hard"; "hug"; "hi"; "hello"]`, demonstrating that hashed key
collisions are associated with a list of values associated with that key.

### Removing Data from Hash Tables

If you remove a key, its previous value becomes again the default one
associated to the key.

```ocaml
# Hashtbl.remove my_hash "h";;
- : unit = ()
# Hashtbl.find my_hash "h";;
- : string = "hug"
```

This behavior is interesting for the above example or when, say, the
keys represent variables that can be temporarily masked by a local
variables of the same name.

### Replacing Data in Hash Tables

In other contexts, one may prefer new values *replace* the previous ones.  In
this case, one uses `Hashtbl.replace`:

```ocaml
# Hashtbl.replace my_hash "t" "try";
  Hashtbl.replace my_hash "t" "test";
  Hashtbl.find_all my_hash "t";;
- : string list = ["test"]

# Hashtbl.remove my_hash "t";
  Hashtbl.find my_hash "t";;
Exception: Not_found.
```

To find out whether there is an entry in `my_hash` for a letter we would do:

```ocaml
# Hashtbl.mem my_hash "h";;
- : bool = true
```
