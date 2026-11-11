---
title: Building an Inference Engine
date: 2026-11-09T14:38:23+05:30
tags: [ai engg, llms]
---

> A live demo is (temporarily) available [here](https://tinyinfer.himanshu.co)

With my recent foray into AI engineering, I decided building an inference
engine would be a good next step into understanding how LLM inference actually
works under the hood.

## Inside a model
Here's whats available when you download a model

```bash
himanshu@archbox ~/.cache/huggingface/hub/models--gpt2/snapshots/... ❯ ls
config.json  
generation_config.json  
merges.txt  
model.safetensors  
onnx  
tokenizer_config.json  
tokenizer.json  
vocab.json
```

Model weights are often stored inside `.safetensors` files. While the
vocab-to-token table is stored in a `vocab.json` file.

Here's what it looks like:
```json
{
  "!": 0,
  "\"": 1,
  "#": 2,
  "$": 3,
  "%": 4,
  ",": 11,
  "-": 12,
  ".": 13,
  "/": 14,
  "0": 15,
  ...
}
```

I needed a relatively small model since I don't have a dedicated GPU, so I went
with **GPT-2**, a 124M parameter model from OpenAI.

## Tokenization
Tokenization is the process responsible for converting raw text input into
numbers the model can perform operations on.

Using the sentence `The capital of France is` as an example.

**Step 1 (Pre-split)**: Where the string is split as per a regex.
```python
_PRESPLIT = re.compile(r"'s|'t|'re|'ve|'m|'ll|'d| ?[A-Za-z]+| ?[0-9]+| ?[^\sA-Za-z0-9]+|\s+(?!\S)|\s+")
```

This splits contractions ('s, 't, 're etc.) and we end up with radicals/word roots and contractions as separate tokens.

The result is: `['The', ' capital', ' of', ' France', ' is']` (yes, each word
from the second word onwards is prepended with a space, more on it in the next
section).

###  Byte Pair Encoding
GPT2 ranks how common it is for two tokens to appear together in `merges.txt`
based on the corpus of text it was trained on and subsequently merges them into
a single token. Common merge patterns appear near the top of the list.

For example: the first line is `Ġ t`. Ġ represents an empty space, meaning its
extremely common for an empty space to be followed by a t. A few lines down
(line 6), there's `Ġt he`. Meaning its common for Ġt to be followed by an he,
this collapses Ġt followed by an he into a single token `Ġthe`

Ġ is the stand-in character for a space. i.e "Ġthe" means " the"

We perform this process when converting the text into tokens. Rarer patterns
often do not exist in the `merges.txt` file which is why some words often span
more than one token.

Working through this algorithm with an example (` capital`).

` capital` -> `['Ġ','c','a','p','i','t','a','l']`

Going through merges.txt looking for pairs that appear with the lowest rank
(the first line is rank 0, second line is rank 1 and so on.) and merging the
adjacent pairs with the lowest rank.

```txt
Ġ+c (rank 13) -> ['Ġc','a','p','i','t','a','l']
i+t (rank 14) -> ['Ġc','a','p','it','a','l']
a+l (rank 26) -> ['Ġc','a','p','it','al']
a+p (rank 243) -> ['Ġc','ap','it','al']
it+al (rank 1031) -> ['Ġc','ap','ital']
Ġc+ap (rank 1195) -> ['Ġcap','ital']
Ġcap+ital (rank 2883) -> ['Ġcapital'] 
```

Performing this on the entire sentence gives us: `['The', 'Ġcapital', 'Ġof', 'ĠFrance','Ġis'}`

We end up with a list of tokens whose respective ID we then lookup  in the
`vocab.json` file.

The capital of France is becomes: `[464, 3139, 286, 4881, 318]`

## Embeddings
Embeddings are vectors (list of numbers) that represent the semantic meaning of
a word, meaning similar and related words are closer together. This is the
closest models get to "understanding".

There's 2 specific types of embeddings that GPT-2 uses:

- Word Token Embeddings (WTE)
- Word Position Embeddings (WPE)

### Word Token Embeddings
Vector representing the semantic meaning of a word. Since we got `4881` as the
ID for `France` above, if we were to look up `wte[4881]`, we'd end up with a
vector (a list of 768 numbers) that represent France, related words be close to
France. The metric most often used to compare embeddings is cosine similarity.
GPT 2 has 50,257 embeddings i.e a vocab size of 50k words.

$$
\text{Cosine Similarity}(A,B) =
\frac{A \cdot B}{\|A\| \|B\|}
$$

$$
A.B = {\sum_{i=1}^n{a_i \cdot b_i}}
$$

$$
\|A\| = \sqrt{\sum_{i=1}^n{a_i}^2}
\hspace{1cm}
\|B\| = \sqrt{\sum_{i=1}^n{b_i}^2}

$$


### Word Position Embeddings
WPE describes the position a token appears in, since the position of a word can
also affect its meaning (Dog bites man vs Man bites dog have wildly different
meanings).

`wpe[2]` for example, means the third token in a sentence. This is used in
conjunction with the WTE, describing both what the token is and where it
appears to decide the next token (described below).

## Forward Pass
We create a vector $X_0$ which is the sum of each of the token's WTE and WPE.

$$X_0 = WTE[token\_ids] + WPE[0:T]$$

For our example, $X_0$ is a $5 \times 768$ matrix.

### Transformers
A neural network architecture that allows each token to look back at all other
tokens.

GPT 2's transformer is a stack of 12 decoder blocks that comprise of:

- **Masked Self-Attention**: Allows a token to look back at all the tokens
  before itself including itself. This allows the model to gather context
  clues. Eg: The cat sat on the mat because it was tired, without attention,
  the model has no way of knowing what 'it' refers to, this is solved using
  attention, with the gathered context, the vector representing 'it' is updated
  and is passed onto the next component.
- **Feed-Forward Network**: It takes the updated vector from the attention
  component and applies the same transformation to all other tokens in the
  sequence.

```tikz
\usetikzlibrary{positioning,calc,fit,backgrounds}
\begin{tikzpicture}[
  scale=0.85,
  transform shape,
  box/.style={draw, rounded corners=2pt, align=center, inner sep=2pt,
              font=\scriptsize, minimum width=35mm},
  add/.style={draw, circle, inner sep=1pt, font=\scriptsize},
  arr/.style={->, thin},
  skip/.style={->, thin, dashed, orange!85!black},
  node distance=3mm
]

\node[box] (input) {Input Token IDs};
\node[box, below=of input] (ln1) {Layer Normalization};
\node[box, below=of ln1] (attn) {Masked Multi-Head Attention};
\node[add, below=of attn] (add1) {$+$};

\node[box, below=of add1] (ln2) {Layer Normalization};
\node[box, below=of ln2] (mlp) {Feed-Forward Network (MLP)};
\node[add, below=of mlp] (add2) {$+$};
\node[box, below=of add2] (output) {Next Token};

\draw[arr] (input) -- (ln1);
\draw[arr] (ln1) -- (attn);
\draw[arr] (attn) -- (add1);
\draw[arr] (add1) -- (ln2);
\draw[arr] (ln2) -- (mlp);
\draw[arr] (mlp) -- (add2);
\draw[arr] (add2) -- (output);

% Residual connections: two nested lanes on the left so the wires never overlap
\coordinate (laneA) at ($(input.west)+(-6mm,0)$);
\coordinate (laneB) at ($(input.west)+(-13mm,0)$);
\draw[skip] (input.west) -- (laneA) |- (add1.west);
\draw[skip] (add1.west) -- (laneB |- add1.west) |- (add2.west);

% Block boundary, widened so both residual lanes sit inside it
\node[
  draw=blue!65!black,
  dashed,
  rounded corners=3pt,
  inner xsep=15mm,
  inner ysep=3mm,
  fit=(ln1)(attn)(add1)(ln2)(mlp)(add2),
  label={[font=\scriptsize\bfseries]below right:One decoder block}
] (block) {};

\node[anchor=west, align=left, font=\scriptsize] (note) at ($(block.east)+(7mm,0)$)
  {\textbf{GPT-2 Small}\\
   12 blocks\\
   Independent weights};
\draw[dashed, thin, black!45] (block.east) -- (note.west);

\end{tikzpicture}
```

Within the `model.safetensors` file, there's parameters named
`h.0.attn.c_attn.weight`, `h.0.attn.c_attn.bias` etc.

`h.0` means the first (of 12) transformer blocks.
```python
qkv = h @ w[p + "attn.c_attn.weight"] + w[p + "attn.c_attn.bias"]
```

Using this weight and bias, we end up with

$$[Q|K|V] = X_0 W_{QKV} + b_{QKV}$$

We then end up with three new vectors, namely:

- **Query (Q)**: What information a token is looking for.
- **Key (K)**: What information a token makes available to other tokens in the sequence.
- **Value (V)**: The actual information contributed to the token that uses this token.

The Q, K and V vectors are $5 \times 768$ but of these $768$, its split among
12 attention heads, each of these heads holds a part of the Q, K and V vectors
($64$ numbers) and uses them to determine which of the preceding tokens to use.

Each head then calculates the following score:

$$
S = \frac{Q_iK_i^T}{\sqrt{64}}
$$

We end up with $S$, a $5 \times 5$ matrix representing how much a token
contributes to another token. However since we don't allow a token to consult
future tokens, we apply a mask over the $S$ matrix.

For our $5 \times 5$ matrix, the mask looks like:

$$
M =
\begin{bmatrix}
0 & -\infty & -\infty & -\infty & -\infty \\
0 & 0 & -\infty & -\infty & -\infty \\
0 & 0 & 0 & -\infty & -\infty \\
0 & 0 & 0 & 0 & -\infty \\
0 & 0 & 0 & 0 & 0
\end{bmatrix}
$$

$$
S_\text{Masked} = S + M
$$

We then apply softmax to the masked score matrix to convert the scores into probabilities.

$$
A = \text{softmax}(S_\text{masked})
$$

These probabilities are representative of how much attention each token pays to the preceding tokens including itself.

Finally we multiply these probabilities by the weights they are representative of:

$$
O = AV
$$

We then combine the results of the 12 attention heads into one

$$
O = [O_1 | O_2 | ... | O_{12}]
$$

This is then passed through a linear projection, the values for which are present in the model weights

$$
O^* = OW_O + b_O
$$

This attention output is finally added back to the original input

$$
X_1 = X_0 + O^*
$$

### MLP
GPT2's MLP applies 2 linear transformations with a GELU activation function in
between to each of the tokens.

$$
MLP(x) = W_2 \cdot GELU (W_1 x + b_1) + b_2
$$

$$
X_i' = X_i + MLP(X_i)
$$

Transformer allows for information exchange across tokens while the MLP allows
for information exchange within a single token.

This entire process is repeated 12 times, once for each of the transformer blocks.

## Predicting the next token
Having calculated the final output matrix after 12 Transformer blocks, all
that's left is to apply a final layer norm and begin sampling possible next tokens.

$$
X_\text{final} = LayerNorm(X_{12})
$$

We finally assign a score on how likely each token in the vocab is to be the next token

$$
\text{logits} = X_{final} W_{vocab}^T
$$

However these are just raw scores, not probabilities, to convert these scores
into probabilities, we apply the softmax function.

$$P(token) = softmax(logits[-1])$$

Following our 'The capital of France is' example, this would look somewhat like this:

$$
\begin{aligned}
\small
\text{logits}_{[4]} &=
\begin{bmatrix}
\text{Paris}: 18.2 \\
\text{London}: 15.1 \\
\text{Berlin}: 14.0 \\
\vdots
\end{bmatrix}
\end{aligned}
$$

$$
\begin{aligned}
\small
P = \text{softmax}(\text{logits}_{[4]}) &=
\begin{bmatrix}
\text{Paris}: 94\% \\
\text{London}: 4\% \\
\text{Berlin}: 2\% \\
\vdots
\end{bmatrix}
\end{aligned}
$$

Since the token with the highest probability (94%) is Paris, it becomes our next token.
