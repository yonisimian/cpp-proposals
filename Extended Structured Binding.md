
### C++ Proposal: Structured Bindings for Existing Variables

**Document Number:** PxxxxR0
**Date:** August 23, 2025
**Audience:** Evolution Working Group (EWG)
**Authors:** Yehonatan Simian, ... honestly idc, just add your names here :)

----------

### Abstract

This proposal introduces an extension to C++'s structured bindings, allowing for the assignment of values to existing variables. This provides a clean, consistent syntax that serves as a modern alternative to `std::tie`, particularly for environments where the standard library is unavailable, such as in embedded or bare-metal development.

----------

### Introduction

C++17 introduced structured bindings, a powerful language feature that allows for the decomposition of a tuple-like object into its constituent elements. The syntax `auto [x, y] = foo();` is a significant improvement in readability and conciseness over traditional methods.

However, a core limitation of structured bindings is their inability to assign to pre-existing variables. The current approach requires the use of `std::tie` from the `<tuple>` header, as shown below:

```
#include <tuple>

std::tuple<Token, Value> scan(); // scans the next line on each invokation

for (auto [token, value] = scan(); token != EOF; std::tie(token, value) = scan()) {
	// ... parse token
}
```

While effective, `std::tie` is not a language-level feature. Its use presents two main challenges:

1.  **Standard Library Dependency:** `std::tie` is part of the standard library. Many developers, particularly in embedded systems, work on platforms where the standard library is either unavailable or has a significant footprint, making its use unfeasible. The core C++ language could provide a solution for this common problem.
    
2.  **Cognitive Load:** Structured bindings are highly intuitive and now a core part of C++ pedagogy. In contrast, `std::tie` is a less-known utility function. Providing a language-level alternative aligns with the philosophy of "keeping the simple things simple" and reduces the amount of specialized knowledge required for common programming tasks.
    

This proposal aims to address these issues by extending structured binding syntax to support assignment to existing variables.

----------

### Proposal

Extend the `auto` structured binding syntax to use the `&` symbol inside the binding list to denote a binding to an existing variable.

**Syntax:**

`auto [binding-list] = expression;`

The `binding-list` would be a comma-separated list of:

-   `name`: to declare a new variable.

-   `&name`: to assign to an existing variable.

**Explanation:**

The `&` symbol already signifies a reference in C++. By allowing it inside the structured binding list, we can extend this meaning to "referencing an existing variable in the scope." This approach is intuitive and consistent with C++'s syntax for references.

When an existing variable is prefixed with `&`, the compiler would find the variable in the current scope and assign the corresponding element of the tuple-like object to it using `operator=`. The `auto` keyword at the beginning of the statement would signal that this is a structured binding operation.

**Mixing New and Existing Variables:**

This syntax seamlessly allows for mixing new and existing variables, a key requirement.

```
int x;
auto [&x, y] = get_pair(); // y is a new variable, x is assigned to
```

**Reference Collapsing:**

TODO: compare `auto &[x, y]` to `auto [&x, &y]` and `auto &[&x, &y]`.
Also... discuss rvalue-references?

#### Examples

**1. Assigning to Existing Variables Only**

```
MyTuple<Token, Value> scan(); // scans the next line on each invokation

for (auto [token, value] = scan(); token != EOF; auto [&token, &value] = scan()) {
	// ... parse token
}
```

**2. Hybrid Declaration and Assignment**

C++

```
// Existing variables
int result_code;
std::string error_message;

// A function that returns a new value and a value for an existing variable.
std::tuple<int, int> get_info() { return {42, 100}; }

// Proposed: `new_value` is declared, `result_code` is assigned.
[auto new_value, assigns result_code] = get_info();

// This is equivalent to:
// int new_value = std::get<0>(get_info());
// result_code = std::get<1>(get_info());

```

**3. Reference to a new variable and assignment to an existing variable**

C++

```
int x;
std::tuple<int, std::string> get_user_data();

// Proposed: 'name' is declared as a reference, 'x' is assigned
[auto& name, assigns x] = get_user_data();

// The above is equivalent to:
// auto& name = std::get<0>(get_user_data());
// x = std::get<1>(get_user_data());

```

### Alternative Proposals

#### `using` keyword

```
int x;
auto [using x, y] = get_values();
```

A bit less intuitive imo (Yoni).

#### `let` keyword
```
int x;
let [&x, y] = get_values();
```
More robust, yet has a potential of ambiguity with Pattern Matching.

----------

### Motivation and Use Cases

#### 1. Embedded and Bare-Metal Systems

The most compelling technical motivation for this proposal is its applicability in **constrained environments**. In projects for embedded systems, game consoles, or operating system kernels, a full C++ standard library is often unavailable. These environments lack headers like `<tuple>`, making `std::tie` inaccessible. A language-level feature provides a uniform, built-in solution that is always available.

#### 2. Readability and Consistency

Structured bindings are a well-loved feature for their intuitive nature. `std::tie` requires a separate header, a different syntax, and introduces a new concept (a function that returns a `tuple` of references) to solve a common problem. The proposed syntax leverages an existing, familiar pattern, reducing cognitive overhead and making code more consistent and easier to understand for newcomers and seasoned developers alike.

#### 3. Performance in Loops

In performance-critical code, especially within loops, creating and destroying objects can be costly. While the return value optimization (RVO) can mitigate this, ensuring that an existing variable is assigned to rather than a new one being created can be a clear signal to the compiler and can lead to more efficient code in some cases. The `[assigns var]` syntax makes it explicit that `var` is not being created, but assigned to.

C++

```
// Imagine a function that is part of an outer loop
std::tuple<std::vector<int>, bool> process_data_chunk(const Data& d);

// Before this proposal
std::vector<int> chunk; // Created outside the loop
bool success;
// In the loop
std::tie(chunk, success) = process_data_chunk(data_stream);

// With this proposal
std::vector<int> chunk; // Created outside the loop
bool success;
// In the loop
[assigns chunk, assigns success] = process_data_chunk(data_stream);

```

This explicit syntax helps document the intent of assignment rather than declaration.

----------

### Alternative Syntaxes Considered

1.  **`[using x, y] = ...`**: The use of `using` was initially considered. However, `using` is an overloaded keyword in C++ with specific meanings (e.g., namespace and declaration directives). Reusing it as a contextual keyword could lead to parsing ambiguities and developer confusion. The proposed `assigns` keyword is less likely to collide with existing syntax and clearly states the intent.
    
2.  **`[x, y] = ...` (without `auto`)**: This was also considered but would introduce ambiguities with existing syntax, such as lambdas. For example, `[x, y] = foo();` could be misread. The explicit keyword `assigns` prevents this ambiguity.
    

----------

### Implementation Notes

This is a language extension, not a standard library addition. A compiler would need to implement this new parsing rule. The implementation would involve checking the variables in the `binding-list` against the variables in the current scope. If an existing variable is found with the `assigns` keyword, the compiler would generate code to perform an assignment using the variable's `operator=`. If `auto` is used, a new variable would be declared.

----------

### Previous Papers

-   **P0144R2 - `Structured Bindings`**: This paper introduced structured bindings. Section 3.3 explicitly mentions that structured bindings should not be used for assignment to existing variables, stating, "We know of no use cases where this is better than using `std::tie`." This proposal provides new use cases (embedded systems) and a strong argument for uniform syntax, directly addressing the original paper's concern.
    
-   **P2392 - `C++ Standard Library Support for Structured Bindings`**: While not directly related to this proposal, Herb Sutter's paper and similar documents highlight the evolution of structured bindings and the community's interest in extending their utility.
    

----------

### Conclusion

This proposal for structured bindings for existing variables offers a clean, consistent, and powerful language feature. It solves a real-world problem for developers in constrained environments and provides a more intuitive syntax for all C++ programmers. The proposed syntax is explicit, avoids keyword ambiguity, and aligns with the modern direction of the C++ language.

The working group is encouraged to discuss this proposal and provide feedback on the proposed syntax and rationale.
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTMxMjc4Nzk0NiwxMTg0MDIxNDE4LDEyMT
I2MDU5NCwyMDc3NDAzNzEzLC01Mjc5MTAyOTksLTg1NTYwNzc4
LDMyMjM0NTc4MF19
-->