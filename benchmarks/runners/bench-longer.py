import json
from os import environ
from subprocess import check_output


MAX_RUNTIME = int(environ.get('MAX_RUNTIME', 360))
RUNS = 3


def get_stats(output):
    string = str(output, 'utf8')
    for line in string.split('\n'):
        if 'cumavg MIX:' in line:
            return float(line.split(' ')[-1])


def run_command(command):
    try:
        check_output('rm *-snapshot_id; rm *-log-*.json; rm *.bin', shell=True)
    except:
        pass

    return check_output(command, shell=True)


def main():

    results = []

    for runtime in range(60, MAX_RUNTIME + 20, 20):
        for t in [0, 15]:
            timeout = '--snapshot-timeout=%s' % t if t else ''
            command = 'cargo run --bin vote --release -- --quiet --avg --mixers=1 --runtime=%s %s write' % (runtime, timeout)
            s = 0.0
            for i in range(RUNS):
                writes = get_stats(run_command(command))
                s += writes
                print('(%s seconds): Writes for %s: %s' % (runtime, t, writes), flush=True)

            result = {
                'timeout': t,
                'runtime': runtime,
                'writes': s / RUNS,
            }

            print(result, flush=True)
            results.append(result)

    print(json.dumps(results))


main()
