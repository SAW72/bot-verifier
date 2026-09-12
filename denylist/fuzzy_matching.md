# Fuzzy Matching

Catches near-identical dangerous bots.

## Method
Store behavioral signatures: response patterns across the scenario library.
Compare new bot's signature to denylist using similarity threshold (e.g. 0.92).
If above threshold, flag as same threat family.

## Why
A bad actor can change one weight. They cannot easily change the behavioral fingerprint without changing the training.
