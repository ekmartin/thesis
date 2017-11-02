# Abstract

# Introduction

# Background
## Soup
Which problems are Soup solving? How are they doing it?
Maybe talk about some of the existing research that Soup is based on.
Briefly talk about overall results. What trade-offs are they doing to achieve
these results?

## Rust
Brief introduction to the language. Why does it work well for Soup (or systems
programming in general).

## Recovery
General recovery mechanisms that are used in databases. Logging, ARIES etc.
Talk about how Soup does logging with its group commit protocol, how recovery is
structured. If not mentioned earlier, talk about transactions in general in
Soup.

Could also have a segment here about how the logging recovery implementation
itself in Soup.

# Snapshotting
(this could possibly be under background as well?)
Talk about how snapshotting in Soup is similar to snapshotting in a distributed
system (messages that move along a graph at different paces, no global clock).
Talk about different ways of doing snapshotting (Chandy/Lamport etc.)
What goals do we have, and what trade-offs are we willing to make? What is the
outcome we're looking for.

## Implementation
How snapshotting ended up being implemented.

# Results
Does snapshotting make the system slower (possibly, if it has to block
messages). Does the throughput go down, or just the latency?
How does snapshotting compare to log only recovery (the base case)?

If possible, how does recovery speed in Soup compare to other database systems?

# Conclusion
Does the result work well, or does it need a different approach? How will this
work for future versions of Soup? (This might belong in another segment).
