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

### !!! Read the fast-checkpoint-sigmod16 paper

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

## Plan
* Write a little bit more about Rust, provide an example for move semantics.
* Positive and negative updates
* Checktable stuff
* Sharding
* ACID (cite or describe)
* Formalize snapshot requirement
* Describe snapshot protocol in soup in pseudo code
  - Clarify that we're building up a snapshot protocol in steps
* More figures:
  - Group commit protocol
  - Which nodes are materialized (under 3.2 Snapshotting)

New stuff to write:
* Write about the snapshotting implementation (Snapshotting and Logging in Soup).
We've written an overview, this section should rather go into the details of how
it works in Soup.
  - Difference between local and remote Soup.
  - Exactly which packets are sent, what happens when they're received?
    - How is a snapshot initiated?
    - How is a snapshot packet forwarded through the graph?
    - What happens when a node receives two snapshot packets?
    - What happens when a node receives two recovery packets?
  - How is a snapshot taken and restored? bincode
  - Snapshot ID in log entries (ignore on recovery)

* Results:
  - Improvement in recovery time. Compare recovery time for a vote runtime of
    120s, with varying snapshot timeouts? Also against baseline of no
    snapshotting.
  - Graph for write throughput with different snapshot timeouts.
  - Graph with CPU starved (one core maybe?)

* Improvement Options:
  - Persisting snapshots to distributed remote storage, avoiding coordination
    messages from domains to controllers.
  - Completely asynchronous snapshots.

* Conclusion:
Snapshots are good, and a needed supplement to logging for in-memory databases.
Using snapshotting algorithms primarily made for distributed systems works, but
it would be interesting to look at completely asynchronous and local snapshots.
Throughput reduction not that bad.
