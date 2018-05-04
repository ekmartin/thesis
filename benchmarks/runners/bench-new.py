import sys
import json
from subprocess import check_output
from collections import defaultdict


REPEAT = 3


def get_stats(output):
    stats = {}
    string = str(output, 'utf8')
    lines = string.split('\n')
    stats['ops'] = {'total': float(lines[0].split(' ')[-1])}
    for line in lines[2:]:
        if not line.strip():
            continue

        name, percentile, sojourn, remote, _ = line.split('\t')
        stats['%s_%s' % (name, percentile)] = {
            'sojourn': float(sojourn),
            'remote': float(remote),
        }

    output_stats(stats)
    return stats


def run_command(command):
    return check_output(command, shell=True)


def run_bench(command):
    total = defaultdict(lambda: defaultdict(float))
    for i in range(REPEAT):
        stats = get_stats(run_command(command))
        for (key, values) in stats.items():
            for (bench, value) in values.items():
                total[key][bench] += value

    for (key, values) in total.items():
        for bench in values.keys():
            total[key][bench] /= REPEAT

    return total


def output_stats(stats):
    percentiles = [50, 95, 99, 100]
    print('total ops/s:', stats['ops']['total'])
    print('{0:<8} {1:<8} {2:<8} {3:<8}'.format('op', 'pct', 'sojourn', 'remote'))
    for percentile in percentiles:
        for method in ['write', 'read']:
            values = stats['%s_%s' % (method, percentile)]
            print(
                '{0:<8} {1:<8} {2:<8} {3:<8}'.format(
                    method,
                    percentile,
                    int(values['sojourn']),
                    int(values['remote']),
                )
            )


def main():
    try:
        run_command('rm *-snapshot_id; rm *-log-*.json; rm *.bin; rm *.db; rm *.db-journal')
    except:
        pass

    command = 'cargo run --release --manifest-path benchmarks/Cargo.toml --bin vote -- %s' % ' '.join(sys.argv[1:])
    stats = run_bench(command)
    print('\n\n#######\nfinal stats:')
    output_stats(stats)


main()
