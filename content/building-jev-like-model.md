---
title: Building a Decision Model 
date: 2026-11-03T21:51:32+05:30
tags: [ai engg]
---

> A live demo of this project is available [here](https://jbjev.himanshu.co/)

## What even is a decision model
With the (not so) recent release of
[**Jev**](https://typesafe.ai/blog/introducing-system-one-models-and-jev), a
new class of models called *decision models* emerged, unlike traditional LLMs,
these do not generate text, but rather answer objective questions, Jev can answer three types of questions:

- **Choice**: Given a query and a few options/choices, it assigns a score to each of the choices.
- **Noul (boolean)**: The answer can either be a yes or a no.
- **Score**: Assigns a score in the range of 0-1.

## Architecture
While Jev's actual architecture is unkown, since [**TypeSafe
AI**](https://typesafe.ai) has not made any info regarding Jev's internals
public, I decided to build my own version using similar open-source
implementations such as
[**OpenJev**](https://github.com/zhangcy122/OpenJev/tree/main).

**OpenJev** uses a *Qwen3.5-4B* under the hood but repurposed as a
cross-encoder, given a state and a list of options, it assigns a score to each
of the options. 

```tikz
\begin{tikzpicture}[
  box/.style={draw, thick, rounded corners=2pt, align=center, inner sep=4pt},
  inp/.style={box, draw=black!60},
  mdl/.style={box, draw=blue!65!black},
  hd/.style={box, draw=violet!65!black},
  arr/.style={->, thick, draw=black!70}
]
  \node[inp, text width=3.0cm, minimum height=10mm] (prem) at (0,1.15)
    {\textbf{premise}\\[1pt]{\scriptsize state = the resume}};
  \node[inp, text width=3.0cm, minimum height=10mm] (hyp) at (0,-1.05)
    {\textbf{hypothesis}\\[1pt]{\scriptsize one option + rubric}};

  \node[box, draw=black!40, text width=3.3cm, minimum height=30mm] (seq) at (4.7,0.05)
    {one sequence\\[1pt]{\scriptsize premise \,[SEP]\, hypothesis}};
  \draw[arr] (prem.east) -- (seq.west |- prem.east);
  \draw[arr] (hyp.east)  -- (seq.west |- hyp.east);

  \node[mdl, text width=3.1cm, minimum height=22mm] (model) at (9.3,0.05)
    {\textbf{Qwen3.5-4B}\\[1pt]{\scriptsize cross-encoder}\\[1pt]{\scriptsize causal mask off}};
  \draw[arr] (seq.east) -- (model.west);

  \node[hd, text width=2.4cm, minimum height=22mm] (head) at (13.1,0.05)
    {3-way head\\[1pt]{\scriptsize 3 logits}};
  \draw[arr] (model.east) -- (head.west);

  \draw[arr] (head.south) -- (13.1,-1.75);
  \node[font=\scriptsize, anchor=west] at (13.1,-1.95) {softmax};

  \node[font=\scriptsize, anchor=east] at (12.6,-2.55) {entailment};
  \draw[very thick, draw=green!55!black, fill=green!18] (12.7,-2.70) rectangle ++(3.0,0.28);
  \node[font=\scriptsize, anchor=west] at (15.8,-2.55) {$0.81$};

  \node[font=\scriptsize, anchor=east] at (12.6,-3.15) {contradiction};
  \draw[very thick, draw=red!60!black, fill=red!18] (12.7,-3.30) rectangle ++(0.15,0.28);
  \node[font=\scriptsize, anchor=west] at (15.8,-3.15) {$0.04$};

  \node[font=\scriptsize, anchor=east] at (12.6,-3.75) {neutral};
  \draw[very thick, draw=orange!75!black, fill=orange!18] (12.7,-3.90) rectangle ++(0.55,0.28);
  \node[font=\scriptsize, anchor=west] at (15.8,-3.75) {$0.15$};

  \node[font=\scriptsize, anchor=west] at (0,-3.75)
    {one forward pass \emph{per option}; the argmax is the decision};
\end{tikzpicture}
```

A request to OpenJev is made up of 2 parts, a premise/evidence and a hypothesis, a possible question/option.

It's output head is modified to return three numbers:

- **Entailment**: The hypothesis follows the premise.
- **Contradiction**: The hypothesis cannot be true given the premise.
- **Neutral**: The premise is not enough to decisively conclude the Hypothesis.

For a score question, this output head outputs these 3 numbers once for each of the hypotheses.

My implementation, although a little different (i can't afford a GPU :( )
essentially builds upon the same idea and uses a DistilBERT instead of Qwen3.5

```tikz
\begin{tikzpicture}[
  box/.style={draw, thick, rounded corners=2pt, align=center, inner sep=4pt},
  inp/.style={box, draw=black!60},
  mdl/.style={box, draw=blue!65!black},
  hd/.style={box, draw=violet!65!black},
  cal/.style={box, draw=orange!75!black},
  res/.style={box, draw=green!55!black},
  side/.style={box, draw=black!35},
  arr/.style={->, thick, draw=black!70}
]
  \node[inp, text width=3.2cm, minimum height=9mm] (resume) at (0,1.15) {\textbf{resume}};
  \node[inp, text width=3.2cm, minimum height=9mm] (jd) at (0,-1.05) {\textbf{job description}};

  \node[box, draw=black!40, text width=2.9cm, minimum height=30mm] (seq) at (4.0,0.05)
    {one sequence\\[1pt]{\scriptsize resume \,[SEP]\, job}};
  \draw[arr] (resume.east) -- (seq.west |- resume.east);
  \draw[arr] (jd.east) -- (seq.west |- jd.east);

  \node[mdl, text width=3.0cm, minimum height=22mm] (enc) at (8.4,0.05)
    {\textbf{DistilBERT 66M}\\[1pt]{\scriptsize 6 layers}\\[1pt]{\scriptsize bottom 2 frozen}};
  \draw[arr] (seq.east) -- (enc.west);

  \node[hd, text width=2.5cm, minimum height=22mm] (cls) at (12.4,0.05)
    {\textbf{CLS} vector\\[1pt]{\scriptsize 768 numbers}};
  \draw[arr] (enc.east) -- (cls.west);

  \node[hd, text width=3.1cm, minimum height=11mm] (sc) at (12.4,-2.75)
    {score head\\[1pt]{\scriptsize 768, 256, 1, sigmoid}};
  \draw[arr] (cls.south) -- (sc.north);

  \node[side, dashed, text width=2.3cm, minimum height=11mm] (vc) at (16.4,-2.75)
    {verdict head\\[1pt]{\scriptsize trained, unused}};
  \draw[arr, dashed, draw=black!45] (cls.east) -| (vc.north);

  \node[cal, text width=2.8cm, minimum height=11mm] (iso) at (8.4,-2.75)
    {calibration table\\[1pt]{\scriptsize 69 knots, held out}};
  \draw[arr] (sc.west) -- (iso.east);

  \node[cal, text width=2.6cm, minimum height=11mm] (thr) at (4.5,-2.75)
    {thresholds\\[1pt]{\scriptsize 0.36 / 0.68 / 0.50}};
  \draw[arr] (iso.west) -- (thr.east);

  \node[res, text width=2.5cm, minimum height=11mm] (result) at (1.0,-2.75)
    {\textbf{0.46}\\[1pt]{\scriptsize verdict 1, apply 0}};
  \draw[arr] (thr.west) -- (result.east);

  \node[font=\scriptsize, anchor=west] at (1.0,-3.95)
    {one pass, one number; calibration and thresholds live outside the network};
\end{tikzpicture}
```

I stuff the premise and the hypothesis into one single query using the following
template:

```txt
Premise: <resume>
Hypothesis: this candidate matches the job: <job>
Answer: score
```

It outputs a single number (the **score**) instead of 3 values like OpenJev.
The other values can be computed as a function of the score.

The rubric for deciding the score includes:

- Skill Coverage
- Domain Fit
- Seniority Fit
- Project Evidence
- Degree Fit
- Location Fit

The model usually tends to be overly optimistic and often outputted a score
higher than the actual expected score as per the distilled data, to fix this, I
made use of **calibration tables**, small lookup tables that map my model's
overly optimistic scores to corrected scores.  

| raw score | corrected |
|---|---|
| 0.19 | 0.11 | looked like a weak match, really a bad one |
| 0.46 | 0.41 | looked like a partial match, really a weak partial |
| 0.62 | 0.55 | looked like a strong partial, really a middling one |
| 0.88 | 0.86 | strong, and it knew it |

Based on this newly computed corrected score, the model decides the final verdict.


## Building a Resume-JD Matcher
As I'm writing this, I'm currently looking for a job, so what better use for a
model than to help me decide if a job matches my resume

### Getting data
The first step to building a model would be gathering data, I needed a ton of training samples in the format `(resume, jd, verdict)`


To get said data, I put my [OpenCode Go](https://opencode.ai/go) subscription to good use and used (near)-frontier open models such as DeepSeek-v4.1 Flash, GLM 5.3 Flash, Muse Spark 1.3 etc. to generate 3,000 samples.

I also had some JDs from Internshala and Naukri that I scraped for a previous project ([**shhh**](https://github.com/matchmyresume))

A sample looks like this:
```json
{
  "text": "resume: Flutter, Dart, Firebase | B.Tech CSE 2024, one Flutter clone project, no production app | Ahmedabad\n[SEP]\njob: Mobile Engineer @ Zepto Bengaluru | Flutter, Dart, REST APIs. 2+ yrs.",
  "verdict": 1,
  "apply": 0,
  "score": 0.46
}
```

The only field we're concerned with is the `score`, all the remaining fields are functions of the score.

### Training

Since OpenJev's Qwen3.5-4B was too much for my VPS to run, I tried with smaller models, one notable model was [LFM3-1.7B](https://huggingface.co/LiquidAI/LFM3-1.7B) which was great except it took 7s to generate a response, a bit too long for my liking. I finally settled with DistilBERT-66M.

I fine-tuned ~28M of the 66M parameters and ended up with the following 

- 41 ms per resume/job pair
- 270 MB of RAM
- same accuracy as the 1.7B

However this was only the result on evaluating it on the synthetic generated
pairs, when I ran it against real job listings from Naukri and Internshala
where the JD is much larger and the actual keywords are stuffed somewhere in
the middle, the accuracy fell drastically, I then retrained the model using
more scraped job listings and achieved an accuracy of 82%

### The calibration bug
When I later added the real scraped job listings to the dataset, I forgot to
re-generate the calibration tables, which meant the range of my calibration
tables was extremely limited (0.29 to 0.67). When the actual training data's
scores ran from 0.07 to 0.92.

This meant that even for a very strong match (say 0.92), when that score was
looked up in the calibration table, it returned the highest number it had (0.67),
seemingly reducing the model's accuracy by half.

While benchmarking the model's performance, the metrics I was looking at were:

- MAE
- Spearman

MAE is concerned with the magnitude of difference between the true and
predicted values while Spearman checks the orders, during this bug, the MAE
shot up while the Spearman score remained the same.
