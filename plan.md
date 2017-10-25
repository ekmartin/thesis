# Plan
## Background
### Soup
* Why
* Brief results (it's fast!)
* How
* CAP

### Rust
What is Rust, why is it useful, how did it come to be.

## Recovery
How is recovery traditionally handled in database systems?
Aries, write ahead logging.
How is it handled in Soup?
Group commit.
Why is linear recovery slow, why is snapshotting hard?

## Snapshotting
Snapshotting in regular database systems
Snapshotting in distributed systems

## Implementation
Snapshotting in Soup

## Results
Compare linear recovery to snapshot based recovery. Maybe compare it to recovery
in other systems, e.g. like in the write behind logging paper?

## Conclusion
Hopefully that snapshotting is awesome!

## References
Cache hierarchy paper from FB
Some of the phloem references

