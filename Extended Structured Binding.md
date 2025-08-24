
### Structured Binding Assignments 

- Document #: PxxxxR0
- Date: 2025-08-23
- Project: Programming Language C++
- Audience: EWGI, EWG
- Reply-to: 
  - Yehonatan Simian <yonisimian@gmail.com>
  - Ran Regev <regev.ran@gmail.com>

### Abstract

This proposal introduces an extension to C++'s structured bindings, allowing for the assignment of values to existing variables. This provides a clean, consistent syntax that serves as a modern alternative to `std::tie`, particularly for environments where the standard library is unavailable, such as in embedded or bare-metal development.

### Introduction

C++17 introduced structured bindings, a powerful language feature that allows for the decomposition of a tuple-like object into its constituent elements. The syntax `auto [x, y] = foo();` is a significant improvement in readability and conciseness over traditional methods.

However, a core limitation of structured bindings is their inability to assign to pre-existing variables. The current approach requires the use of `std::tie` from the `<tuple>` header, as shown below:

```cpp
#include <tuple>

std::tuple<Token, Value> scan(); // scans the next line on each invokation

for (auto [token, value] = scan(); token != EOF; std::tie(token, value) = scan()) {
	// ... parse token
}
```

While effective, `std::tie` is not a language-level feature. Its use presents three main challenges:

1. **Standard Library Dependency:** `std::tie` is part of the standard library. Many developers, particularly in embedded systems, work on platforms where the standard library is either unavailable or has a significant footprint, making its use unfeasible. The core C++ language could provide a solution for this common problem.
    
2. **Cognitive Load:** Structured bindings are highly intuitive and now a core part of C++ pedagogy. Providing a language-level alternative to std::tie reduces the amount of specialized knowledge required for common programming tasks.
3. **Only exisintg variables:** `std::tie` can only be used with existing variables, while structured bindings can only declare new ones. A unified syntax that allows both would enhance code clarity and reduce the need for multiple constructs to achieve similar goals.
    

This proposal aims to address these issues by extending structured binding syntax to support assignment to existing variables.

### Proposal

Extend structured binding syntax to optinally use the `&` symbol for elements in the _sb-identifier-list_ inside the binding list to denote a binding to an existing variable.

The main difference from current syntax is the ability to use `&` before a variable name in the structured binding list to indicate that the variable is already declared and should be assigned to and not initialized.<br>
**Example**
```cpp
int x;
auto [&x, y] = get_pair(); // y is a new variable, x is assigned to
```

**Explanation:**

The `&` symbol already signifies a reference in C++. By allowing it inside the structured binding list, we can extend this meaning to "referencing an existing variable in the scope." This approach is intuitive and consistent with C++'s syntax for references.

When an existing variable is prefixed with `&`, the compiler would find the variable in the current scope and assign the corresponding element of the tuple-like object to it using `operator=`. The `auto` keyword at the beginning of the statement would signal that this is a structured binding operation.

----------

### Examples
<table><tr>
<th class="col-6" >Before</th>
<th class="col-6" >After</th></tr>
<tr>
<td>

```cpp
#include <tuple>
std::pair<int, int> get_pair();
int x, y;
std::tie(x, y) = get_pair();
```
</td><td>

```cpp

std::pair<int, int> get_pair();
int x, y;
auto [&x, &y] = get_pair();
``` 

</td></tr>
<tr>
<td>

```cpp
// scans the next line on each invokation
std::tuple<Token, Value> scan(); 
...
for (
    auto [token, value] = scan(); 
    token != EOF; 
    std::tie(token, value) = scan()
) { // parse }
```
</td>
<td>    

```cpp
// scans the next line on each invokation
std::tuple<Token, Value> scan(); 
...
for (
    auto [token, value] = scan(); 
    token != EOF; 
    auto [&token, &value] = scan()
) { // parse }
```
</td></tr>
</table>

**Mixing New and Existing Variables:**

This syntax seamlessly allows for mixing new and existing variables, a key requirement.

```cpp
int x;
auto [&x, y] = get_pair(); // y is a new variable, x is assigned to
```

**Reference Collapsing:**

TODO: compare `auto &[x, y]` to `auto [&x, &y]` and `auto &[&x, &y]`.
Also... discuss rvalue-references?

#### Examples

**1. Assigning to Existing Variables Only**

```cpp
MyTuple<Token, Value> scan(); // scans the next line on each invokation

for (auto [token, value] = scan(); token != EOF; auto [&token, &value] = scan()) {
	// ... parse token
}
```

**2. Hybrid Declaration and Assignment**

```cpp
Age age;

MyTuple<Age, Height> get_info(); // pure function

auto [&age, height] = get_info(); // `age` is assigned, `height` is declared.

// This is equivalent to:
// age = std::get<0>(get_info());
// Height height = std::get<1>(get_info());
```

### Motivation and Use Cases

#### 1. Embedded and Bare-Metal Systems

The most compelling technical motivation for this proposal is its applicability in **constrained environments**. In projects for embedded systems, game consoles, or operating system kernels, a full C++ standard library is often unavailable. These environments lack headers like `<tuple>`, making `std::tie` inaccessible. A language-level feature provides a uniform, built-in solution that is always available.

#### 2. Readability and Consistency

Structured bindings are a well-loved feature for their intuitive nature. `std::tie` requires a separate header, a different syntax, and introduces a new concept (a function that returns a `tuple` of references) to solve a common problem. The proposed syntax leverages an existing, familiar pattern, reducing cognitive overhead and making code more consistent and easier to understand for newcomers and seasoned developers alike.


### Alternative Syntaxes Considered

#### `using` keyword

```cpp
int x;
auto [using x, y] = get_values();
```

A bit less intuitive imo (Yoni).

#### `let` keyword
```cpp
int x;
let [&x, y] = get_values();
```
More robust, yet has a potential of ambiguity with Pattern Matching.


### Implementation Notes

This is a language extension, not a standard library addition. A compiler would need to implement this new parsing rule. The implementation would involve checking the variables in the `binding-list` against the variables in the current scope. If an existing variable is found with the `assigns` keyword, the compiler would generate code to perform an assignment using the variable's `operator=`. If `auto` is used, a new variable would be declared.

### Previous Papers

-   **P0144R2 - `Structured Bindings`**: This paper introduced structured bindings. Section 3.3 explicitly mentions that structured bindings should not be used for assignment to existing variables "at least for now", see quote below. This proposal provides a use case (embedded systems) and a strong argument for uniform syntax, directly addressing the original paper's concern.
> We know of no use cases where this is better than using `std::tie`, [...] This can always be proposed separately later as a pure extension if desired.
    
-   **P2392 - `C++ Standard Library Support for Structured Bindings`**: While not directly related to this proposal, Herb Sutter's paper and similar documents highlight the evolution of structured bindings and the community's interest in extending their utility.
    

### Conclusion

This proposal for structured bindings for existing variables offers a clean, consistent, and powerful language feature. It solves a real-world problem for developers in constrained environments and provides a more intuitive syntax for all C++ programmers. The proposed syntax is explicit, avoids keyword ambiguity, and aligns with the modern direction of the C++ language.

The working group is encouraged to discuss this proposal and provide feedback on the proposed syntax and rationale.

<!--stackedit_data:
eyJoaXN0b3J5IjpbLTcxMTA5MjYyMSwtMzEyNzg3OTQ2LDExOD
QwMjE0MTgsMTIxMjYwNTk0LDIwNzc0MDM3MTMsLTUyNzkxMDI5
OSwtODU1NjA3NzgsMzIyMzQ1NzgwXX0=
-->
