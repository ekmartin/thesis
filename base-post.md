# Write performance
## Replacing Soup's log with SQlite's write-ahead log
I had a theory that the performance gains from a possibly more optimized
write-ahead log in SQlite could offset the reduced performance from having to
persist data in SQlite. This would mean fsyncing every merged packet to SQlite,
and only sending ACKs to clients after that has completed. 

While some initial results from mixed-load benchmarks indicated that this might
be plausible, proper write-only benchmarks quickly showed that this was far from
true. No matter the optimizations, I was never able to push the `vote` throughput to
anything higher than ~45k ops/s on a single shard. In comparison, a pure write
benchmark with Soup's log easily handles half a million ops/s.

### Checkpointing
Using default settings SQlite moves data from the WAL to the database after the
WAL reaches a threshold of a 1000 pages. This inflicts a latency hit on the
commit that causes the threshold to be reached, which in `vote` sometimes
amounted to up to *300ms* after the database started gaining a decent amount of
rows. 

The SQlite docs explain the trade-off between read performance and how often
checkpoints are taken. Since reads have to look up data in both the WAL and the main
database, a larger WAL results in slower reads. From measuring insert and commit
latencies in `vote` this seems to be the case for writes too, and this might
be the reason the earlier mixed-load benchmarks performed much better: the
write-load was never high enough to grow neither the WAL or the main database to
a significant size.

#### Checkpointing after ACKs
We know we have to checkpoint the WAL at some point, but we definitely don't
have to do it before responding to clients. This meant disabling SQlite's
automatic checkpoints, and instead manually checkpointing after a certain row
limit was reached. 

This helped somewhat, and increased the throughput from a
measly 25k ops/s to at least 42k ops/s. It doesn't really solve the problem
though: checkpoints are still synchronous, and they still halt the processing at
that domain for a significant period. The time it takes to create a checkpoint
grows gradually with the database size: initially a couple of milliseconds,
but up to hundreds towards the end of `vote`. The latency does depend on how
often a checkpoint is taken, however even with checkpoints every 10k rows, the
later checkpoints ended up taking at least a 100ms. As a comparison, the time it
takes to persist a merged packet of ~400 rows to SQlite starts out at less than
a millisecond and grows to around 10ms.

#### Checkpointing in a separate thread
The SQlite docs mention the possibility of doing manual checkpoints in a
separate thread. The
[`sqlite3_wal_checkpoint`](https://www.sqlite.org/c3ref/wal_checkpoint_v2.html)
method comes in a few flavors, but whereas the `PASSIVE` mode might seem
promising, as it doesn't lock the database - this only helps if the write
throughput is low enough to allow "breaks" between writes where these
checkpoints might happen. If that's not the case the checkpoint calls will just
be no-ops, and the WAL will continue to grow. 

The other modes would instead block write processing, which would basically be
the same as having automatic checkpoints on (since we only write from one thread
per database).

## Without fsyncing to SQlite
So, back to the original idea: writing to Soup's log first, and then only
persisting data to SQlite after sending ACKs to clients. This means we can relax
the durability guarantees of SQlite somehow. The benchmarks here use the
following:

[`synchronous = OFF`](https://www.sqlite.org/pragma.html#pragma_synchronous) - never wait for SQlite to fsync data before returning
[`journal_mode = OFF`](https://www.sqlite.org/pragma.html#pragma_journal_mode) - don't keep a journal at all, effectively disabling atomic
commit/rollback

This is not very optimal in SQlite's case, as a poorly timed failure could cause
the database to go corrupt. `journal_mode = WAL` would probably be better in
that regard, and with `synchronous = NORMAL` it would only fsync prior to
checkpoints happening. However, the more relaxed guarantees are probably closer
to what we ultimately want to achieve with a persistent index structure when
we're syncing the log before ACKing every write (as long as we can make it work
with recovery). It's also a more useful comparison point: if this is still too
slow, then obviously, the stricter guarantees are not going to work either.

### Results
Unfortunately, while the results are better than in the previous section, it is
still really slow. With a single shard it i


TODO:
tried compiling sqlite with single thread mode (no mutex code), and removing
some extra features we don't need
tried bigger page size

