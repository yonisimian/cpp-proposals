
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
	// ... start parsing
}
```

While effective, `std::tie` is not a language-level feature. Its use presents two main challenges:

1.  **Standard Library Dependency:** `std::tie` is part of the standard library. Many developers, particularly in embedded systems, work on platforms where the standard library is either unavailable or has a significant footprint, making its use unfeasible. The core C++ language could provide a solution for this common problem.
    
2.  **Cognitive Load:** Structured bindings are highly intuitive and now a core part of C++ pedagogy. In contrast, `std::tie` is a less-known utility function. Providing a language-level alternative aligns with the philosophy of "keeping the simple things simple" and reduces the amount of specialized knowledge required for common programming tasks.
    

This proposal aims to address these issues by extending structured binding syntax to support assignment to existing variables.

----------

### Proposal

We've explored several syntactic approaches to this problem, guided by the following principles: avoiding parsing ambiguities, maintaining a high degree of intuition, and leveraging existing language features where possible. Below are the two most promising options.


#### Option 1: The `&` Symbol

This option extends the `auto` structured binding syntax to use the `&` symbol inside the binding list to denote a binding to an existing variable.

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

C++

```
int x;
auto [&x, y] = get_pair(); // y is a new variable, x is assigned to

```

**Reference Collapsing:**

Reference collapsing is a crucial consideration for this approach. C++'s reference collapsing rules (`T& &` becomes `T&`, `T& &&` becomes `T&`, `T&& &` becomes `T&`, and `T&& &&` becomes `T&&`) ensure that the resulting reference has the correct value category. We can leverage these rules for our `&` syntax.

If `get_pair()` returns a `std::pair<T, U>`, and the binding list contains `&x` where `x` is of type `V`, the type of the binding for `x` would be deduced as `U&`. The compiler would then check for reference collapsing. To explicitly deal with move semantics, a new syntax like `&&` or a keyword could be proposed, but let's stick to the simplest case: `&` for assignment.

To handle cases where a variable is an l-value reference, we could propose `auto [&x&] = ...` to allow for the collapsing of references, or a more simplified approach: allow the compiler to handle reference collapsing automatically based on the type of the variable and the return type.

#### Option 2: The `let` Keyword

This option introduces the contextual keyword `let`, which is already being considered for C++29's pattern matching. We can leverage this keyword for structured assignments.

**Syntax:**

`let [binding-list] = expression;`

The `binding-list` would contain variables to be assigned to, as the `let` keyword would signal that this is an assignment operation.

**Parsing Analysis:**

You are correct that parsing is a critical consideration. The C++ parser, being a greedy, top-down parser, needs to resolve ambiguities early. A statement beginning with `[` is ambiguous with a lambda capture list. However, a statement beginning with `let` is not. The moment the parser sees `let`, it can determine that the following `[` is the start of a structured binding list for assignment, not a lambda. This resolves the parsing ambiguity completely.

**Mixing New and Existing Variables:**

The primary challenge with this approach is allowing for the mixing of new and existing variables, as a key requirement. `let` by its nature implies a declaration. We can propose a syntax where `let` is used for assignment, and we use a separate keyword for declaration within the binding list.

C++

```
int x;
let [&x, auto y] = get_pair(); // x is assigned to, y is a new variable

```

This syntax, using `let` for the assignment operation and `auto` for a new variable inside the list, is a strong candidate. It is a bit verbose, but it's explicit and avoids any ambiguity. It aligns well with the future direction of C++ with pattern matching.

### Recommendation

Both options have merit, but **Option 2 (the `let` keyword)** is the more robust and future-proof choice. The `&` symbol approach (Option 1) has potential for ambiguity, especially when considering more advanced reference types, and could lead to complex reference collapsing rules that are not immediately obvious to developers.

The `let` keyword, on the other hand, provides a clear, non-ambiguous signal to the parser. The proposed syntax `let [&x, auto y] = get_pair();` is explicit and readable. It directly addresses the need to mix new and existing variables and aligns with the general direction of the C++ language.

Therefore, I recommend proceeding with the `let` keyword approach for the full proposal.















#### Examples

**1. Assigning to Existing Variables Only**

C++

```
int x;
int y;
std::pair<int, int> p = {10, 20};

// Proposed: Assigns to existing variables x and y
[assigns x, assigns y] = p;

// The above is equivalent to:
// x = p.first;
// y = p.second;

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
eyJoaXN0b3J5IjpbMjExNDcwMzUsMTE4NDAyMTQxOCwxMjEyNj
A1OTQsMjA3NzQwMzcxMywtNTI3OTEwMjk5LC04NTU2MDc3OCwz
MjIzNDU3ODBdfQ==
-->