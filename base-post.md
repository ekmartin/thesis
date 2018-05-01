# Write performance
Here's an update regarding the raw write performance of the methods I've tried so far in making the Soup bases persistent. For reference, here's how Soup performs with and without a durable log without any changes:

## Replacing Soup's log with SQlite's write-ahead log
I had a theory that the performance gains from a possibly more optimized write-ahead log in SQlite could offset the reduced performance from having to persist data in SQlite. This would mean fsyncing every merged packet to SQlite, and only sending ACKs to clients after that has completed. 

While some initial results from mixed-load benchmarks indicated that this might be plausible, proper write-only benchmarks quickly showed that this was far from true. No matter the optimizations, I was never able to push the `vote` throughput to anything higher than ~45k ops/s on a single shard. In comparison, a pure write benchmark with Soup's log easily handles half a million ops/s.

Part of this is the indices' fault, as SQlite maintains indices on each write, even when using a WAL. This shows up quite clearly in flame graphs (zoom in on `worker1`):

* [Without indices](https://ekmartin.com/flame_graphs/wal.svg):
* [With indices](https://ekmartin.com/flame_graphs/wal_no_indies.svg):

This performs decently, but is still slower than regular Soup. Regardless, we need those indices. 

### Checkpointing

Another issue was the checkpoints SQlite was doing to move data from the WAL to the main database. By default this happens after the WAL reaches a threshold of a 1000 pages. This inflicts a latency hit on the commit that causes the threshold to be reached, which in `vote` sometimes amounted to up to *300ms* after the database started gaining a decent amount of rows. 

The SQlite docs explain the trade-off between read performance and how often checkpoints are taken. Since reads have to look up data in both the WAL and the main database, a larger WAL results in slower reads. From measuring insert and commit latencies in `vote` this seems to be the case for writes too, and this might be the reason the earlier mixed-load benchmarks performed much better: the write-load was never high enough to grow neither the WAL nor the main database to a significant size.

#### Checkpointing after ACKs

We know we have to checkpoint the WAL at some point, but we definitely don't have to do it before responding to clients. This meant disabling SQlite's automatic checkpoints, and instead manually checkpointing after a certain row limit was reached. 

This helped somewhat, and increased the throughput from a measly 25k ops/s to at least 42k ops/s. It doesn't really solve the problem though: checkpoints are still synchronous, and they still halt the processing at that domain for a significant period. The time it takes to create a checkpoint grows gradually with the database size: initially a couple of milliseconds, but up to hundreds towards the end of `vote`. The latency does depend on how often a checkpoint is taken, however even with checkpoints every 10k rows, the later checkpoints ended up taking at least a 100ms. As a comparison, the time it takes to persist a merged packet of ~400 rows to SQlite starts out at less than a millisecond and grows to around 10ms.

#### Checkpointing in a separate thread

The SQlite docs mention the possibility of doing manual checkpoints in a separate thread. The [`sqlite3_wal_checkpoint`](https://www.sqlite.org/c3ref/wal_checkpoint_v2.html) method comes in a few flavors, but whereas the `PASSIVE` mode might seem promising, as it doesn't lock the database - this only helps if the write throughput is low enough to allow "breaks" between writes where these checkpoints might happen. If that's not the case the checkpoint calls will just be no-ops, and the WAL will continue to grow. 

The other modes would instead block write processing, which would basically be the same as having automatic checkpoints on (since we only write from one thread per database).

## Without fsyncing to SQlite

So, back to the original idea: writing to Soup's log first, and then only persisting data to SQlite after sending ACKs to clients. This means we can relax the durability guarantees of SQlite somehow. The benchmarks here use the following:

[`synchronous = OFF`](https://www.sqlite.org/pragma.html#pragma_synchronous) - never wait for SQlite to fsync data before returning
[`journal_mode = OFF`](https://www.sqlite.org/pragma.html#pragma_journal_mode) - don't keep a journal at all, effectively disabling atomic
commit/rollback

This is not very optimal in SQlite's case, as a poorly timed failure could cause the database to go corrupt. `journal_mode = WAL` would probably be better in that regard, and with `synchronous = NORMAL` it would only fsync prior to checkpoints happening. However, the more relaxed guarantees are probably closer to what we ultimately want to achieve with a persistent index structure when we're syncing the log before ACKing every write (as long as we can make it work with recovery). It's also a more useful comparison point: if this is still too slow, then the stricter guarantees are not going to work either.

### Results

Unfortunately, while the results are better than in the previous section, it is
still really slow. With a single shard the throughput never pushes past 100k
ops/s, with quickly growing latencies.

With 4 shards the throughput climbs to about 300k ops/s, albeit still with poor
latencies.

### Batching

Since it seemed like transaction commits were taking a significant amount of time, I thought that perhaps batching up a larger amount of rows into each transaction would be an improvement. This proved to be wrong, as it seems like commit time scales somewhat linearly past a specific amount of rows, which in hindsight makes sense. Inserting 10k rows takes ~100ms (+ 5ms to commit), while 100k rows takes about 1000ms (+ 50ms to commit).

This means that the only thing it really helps with is the 50th percentile remote latency, for those few inserts that are lucky enough not to go past the batch limit. This doesn't really help throughput at all though, as the batches still happen on the regular domain path (in fact, the throughput goes down slightly). 

Code: https://github.com/mit-pdos/distributary/compare/master...ekmartin:base_indices_batched

### SQlite Conclusion

The fact that SQlite works quite well out of the box without a lot of tuning is
definitely one of its strengths. Regardless, there's a few knobs to turn
both at runtime and compile time.

I experimented with a few of the recommended compile options [here](https://www.sqlite.org/compile.html), such as completely removing the mutex code and disabling unnecessary extra features. Although I didn't get much of an impact out of this, I'm sure there are options that could've improved the situation a little. Regardless, I don't think that's where the main problem lies, and at this point I suspect that no matter what, keeping the necessary indices up to date on the main path with SQlite is going to be too slow.

Does this mean that directly maintaining something like B-tree indices for each base would be insufficient as well? Possibly. SQlite definitely has a lot of overhead we don't really need, but in the end, the bulk of the time is spent maintaining its B-trees.

## RocksDB

As an experiment, I thought I'd see how something like RocksDB fared in terms of raw write performance. RocksDB normally works by persisting writes to a WAL, while holding data in a memtable structure, which later on gets flushed to disk in the form of SSTables. We already have a WAL though, so instead of writing to a WAL again, we'll just write to memtables and have RocksDB's background threads eventually flush the data to disk. Not a very fair comparison to SQlite, which would have to do all the writing on the main materialization path, but still useful as a benchmarking point.

Whereas SQlite's defaults are quite okay, RocksDB potentially requires a lot of tuning, which I haven't gotten around to yet. The initial results are decent though, maintaining a throughput well above 500k ops/s:

The question then however, is the read performance. I'll post an update once I have a decently tuned benchmark up and running, but I fear that it would be worse than SQlite's (which uses B-trees), simply from the fact that it uses LSM-trees as its data structure.

## Tailing the Soup log

This was what @ms705 proposed when we initially discussed persistent base indices:

If we're not going to write to disk on the main materialization path, it might be better to do the background flushing ourselves, instead of relying on RocksDB to do the same. We could do so by assigning each log to a persistence worker, which would then read all the new log entries inserted, either directly from the file itself, or from a buffer across the threads, and persist everything to SQlite.

As in the SQlite batching implementation, reads would have to first refer to SQlite, and then a regular `MemoryState` cache - in case any relevant rows were inserted after the last flush.

If my assumptions regarding RocksDB read performance turn out to be correct, I think this could potentially be a better solution. I'll try implementing it in the next few days, and post an update after diong so.
