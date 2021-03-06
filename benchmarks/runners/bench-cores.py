import json
from os import environ
from subprocess import check_output


MAX_PUTTERS = int(environ.get('MAX_TIMEOUT', 15))
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

    for putters in range(1, MAX_PUTTERS + 1):
        for t in (0, 10):
            timeout = '--snapshot-timeout=%s' % t if t else ''
            command = 'cargo run --bin vote --release -- --quiet --avg --mixers=%s --runtime=60 %s write' % (putters, timeout)
            s = 0.0
            for i in range(RUNS):
                writes = get_stats(run_command(command))
                s += writes
                print('Writes for %s: %s' % (t, writes))

            result = {
                'timeout': t,
                'writes': s / RUNS,
            }

            print(result)
            results.append(result)

    print(json.dumps(results))


main()
