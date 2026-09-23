# CSE 415: Compiler Construction
**Theory Assignment: Lexical & Syntax Analysis**

**Name:** Rajib Dab
**Student ID:** 231-115-103

### **Personalized Variable Calculation**
*   **Student ID:** 231-115-103
*   **$N$ (Last digit of ID):** 3
*   **$X$ (Second-to-last digit mod 3):** $0 \pmod 3 = 0$

*(Note: Since $N = 3$, it is an **odd** number. Thus, for Part A, a PID starts with a letter, followed by zero or more letters or digits, and ends with the letter X. Because your calculated $X=0$ is a digit and the prompt specifies the "letter $X$", the literal character 'X' is used for the terminal.)*
*(For Part B, $X = 0$, so the operator `op` is `+`)*

---

### **Part A: Token Design (5 marks)**

Since $N = 3$ (odd), the rule is: *A PID starts with a letter, followed by zero or more letters or digits, and ends with the letter X.*

**1. Regular Definition for PID**
```text
letter → A-Z | a-z
digit  → 0-9
PID    → letter (letter | digit)* X

```

**2. Transition Diagram for PID**
*(To draw this on your paper, create 3 circles representing the states, with State 2 being a double circle for the accepting state.)*

* **State 0 (Start State)**
* On input `letter (excluding X)`, go to **State 1**.
* On input `X`, go to **State 2**.


* **State 1 (Intermediate State)**
* On input `letter or digit (excluding X)`, stay in **State 1**.
* On input `X`, go to **State 2**.


* **State 2 (Accepting State)**
* On input `X`, stay in **State 2**.
* On input `letter or digit (excluding X)`, go to **State 1**.
* *Note: If the input ends while in State 2, the token is accepted.*



**3. Valid and Invalid Lexemes**

* **Valid PIDs:**
1. `aX`
2. `compile123X`
3. `RajibX`


* **Invalid PIDs:**
1. `123tokenX` – **Rejected because:** It starts with a digit, violating the rule that it must start with a letter.
2. `token123` – **Rejected because:** It does not end with the letter 'X'. The transition diagram would end in State 1, which is not an accepting state.



---

### **Part B: Grammar Analysis & Predictive Parsing (7 marks)**

Since $X = 0$, the operator `op` is `+`. The grammar $G$ is:
$S \rightarrow S + T \mid T$
$T \rightarrow ( S ) \mid \text{id}$

**1. Eliminating Left Recursion**
The production $S \rightarrow S + T \mid T$ has immediate left recursion. Using the elimination algorithm, the new productions are:
$S \rightarrow T S'$
$S' \rightarrow + T S' \mid \epsilon$
$T \rightarrow ( S ) \mid \text{id}$

**2. FIRST and FOLLOW Sets**

* **FIRST Sets:**
* $\text{FIRST}(T) = \{ \text{'(', 'id'} \}$
* $\text{FIRST}(S) = \text{FIRST}(T) = \{ \text{'(', 'id'} \}$
* $\text{FIRST}(S') = \{ \text{'+'}, \epsilon \}$


* **FOLLOW Sets:**
* $\text{FOLLOW}(S) = \{ \text{'\$'}, \text{')'} \}$ *(Start symbol gets '$', and ')' comes from $T \rightarrow ( S )$)*
* $\text{FOLLOW}(S') = \text{FOLLOW}(S) = \{ \text{'\$'}, \text{')'} \}$
* $\text{FOLLOW}(T) = \{ \text{'+'}, \text{'\$'}, \text{')'} \}$ *(Followed by '+' in $S'$, and inherits FOLLOW($S$) and FOLLOW($S'$))*



**3. LL(1) Parsing Table**

| Non-Terminal | id | + | ( | ) | $ |
| --- | --- | --- | --- | --- | --- |
| **S** | $S \rightarrow T S'$ |  | $S \rightarrow T S'$ |  |  |
| **S'** |  | $S' \rightarrow + T S'$ |  | $S' \rightarrow \epsilon$ | $S' \rightarrow \epsilon$ |
| **T** | $T \rightarrow \text{id}$ |  | $T \rightarrow ( S )$ |  |  |

**Justification for original grammar $G$:**
The original grammar $G$ **could not** have been used directly for predictive parsing. A grammar with left recursion (like $S \rightarrow S + T$) violates the LL(1) conditions because the FIRST sets of the alternatives are not disjoint. A top-down predictive parser would fall into an infinite loop trying to expand $S$.

**4. Table-Tracing for "id + ( id + id )"**

| Matched | Stack | Input | Action |
| --- | --- | --- | --- |
|  | `$` $S$ | `id + ( id + id ) $` | $S \rightarrow T S'$ |
|  | `$` $S'$ $T$ | `id + ( id + id ) $` | $T \rightarrow \text{id}$ |
|  | `$` $S'$ $\text{id}$ | `id + ( id + id ) $` | Match `id` |
| `id` | `$` $S'$ | `+ ( id + id ) $` | $S' \rightarrow + T S'$ |
| `id` | `$` $S'$ $T$ $+$ | `+ ( id + id ) $` | Match `+` |
| `id +` | `$` $S'$ $T$ | `( id + id ) $` | $T \rightarrow ( S )$ |
| `id +` | `$` $S'$ $)$ $S$ $($ | `( id + id ) $` | Match `(` |
| `id + (` | `$` $S'$ $)$ $S$ | `id + id ) $` | $S \rightarrow T S'$ |
| `id + (` | `$` $S'$ $)$ $S'$ $T$ | `id + id ) $` | $T \rightarrow \text{id}$ |
| `id + (` | `$` $S'$ $)$ $S'$ $\text{id}$ | `id + id ) $` | Match `id` |
| `id + ( id` | `$` $S'$ $)$ $S'$ | `+ id ) $` | $S' \rightarrow + T S'$ |
| `id + ( id` | `$` $S'$ $)$ $S'$ $T$ $+$ | `+ id ) $` | Match `+` |
| `id + ( id +` | `$` $S'$ $)$ $S'$ $T$ | `id ) $` | $T \rightarrow \text{id}$ |
| `id + ( id +` | `$` $S'$ $)$ $S'$ $\text{id}$ | `id ) $` | Match `id` |
| `id + ( id + id` | `$` $S'$ $)$ $S'$ | `) $` | $S' \rightarrow \epsilon$ |
| `id + ( id + id` | `$` $S'$ $)$ | `) $` | Match `)` |
| `id + ( id + id )` | `$` $S'$ | `$` | $S' \rightarrow \epsilon$ |
| `id + ( id + id )` | `$` | `$` | **Accept** |

---

### **Part C: Short Analytical Questions (3 marks)**

**1. Dangling-Else Ambiguity:**
The classic dangling-else grammar is ambiguous because a nested statement like `if E then if E then S else S` can be parsed two different ways: attaching the `else` to the outer `if`, or to the inner `if`. The rewritten "matched/unmatched" grammar resolves this by mathematically forcing an `if-then` statement appearing inside a `then` branch to be "matched" (meaning it must have its own `else`). This enforces standard language rules (matching `else` to the closest preceding `then`) without altering the actual language generated.

**2. Regular Expressions vs. CFGs:**
Regular expressions rely on closure operations (like the Kleene star), which can only indicate repetition but lack the memory to count or pair items, making them unable to describe recursive structures like balanced parentheses. Context-Free Grammars (CFGs) utilize non-terminals that can call themselves recursively (e.g., $S \rightarrow ( S ) \mid \epsilon$), allowing them to inherently track nesting depth and memory constraints that finite automata cannot handle.

**3. Separation of Lexical and Syntax Analysis:**

* **Lecture Reason 1:** Simplicity of design. Separating the phases simplifies both the lexer (which handles messy character-level details like whitespace and comments) and the parser (which can focus purely on structural grammar).
* **Lecture Reason 2:** Compiler efficiency. A specialized lexical analyzer (using Finite Automata) processes raw characters much faster than a full syntax parser could.
* **My Own Reason:** Portability and Modularity. Separating the lexer allows the compiler to easily adapt to different character encodings (like transitioning from ASCII to UTF-8) or input devices without needing to rewrite any of the complex grammatical rules in the syntax phase.

I have provided all the calculations, tables, and theoretical answers formatted clearly for you to write down. Since the submission requires a handwritten copy, you can simply copy this logic directly onto your paper. Let me know if you need any clarification on how the transition diagram is structured or how the FIRST/FOLLOW sets were derived!