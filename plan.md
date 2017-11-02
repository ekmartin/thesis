# Plan
## Background
### Soup
* Why
* Brief results (it's fast!)
* How
* CAP

### Rust
What is Rust, why is it useful, how did it come to be.

## Recovery How is recovery traditionally handled in database systems?
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

## Notes
### Chandy/Lamport
Send a marker when a snapshot should be taken. Node takes a snapshot, then
forwards the marker. In the paper nodes also send their snapshots to each other,
but this wouldn't necessarily be a requirement in Soup.

## Snapshot Papers
* Lightweight Asynchronous Snapshots for Distributed Dataflows
* K. M. Chandy and L. Lamport. Distributed snapshots: determining global states of
distributed systems.
* B. He, M. Yang, Z. Guo, R. Chen, B. Su, W. Lin, and L. Zhou. Comet: batched
  stream processing for data intensive distributed computing.
* A. D. Kshemkalyani, M. Raynal, and M. Singhal. An introduction to snapshot
  algorithms in distributed com-
  puting.
* T. H. Lai and T. H. Yang. On distributed snapshots. Information Processing
  Letters, 25(3):
