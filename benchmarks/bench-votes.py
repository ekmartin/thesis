from os import environ
from subprocess import check_output


MAX_FACTOR = int(environ.get('MAX_FACTOR', 1))
BASE_ARTICLES = 100000
BASE_VOTES = 100000
REPEAT = 3


def get_stats(output):
    string = str(output, 'utf8')
    initial = None
    total = None
    for line in string.split('\n'):
        if 'Initial Recovery Time' in line:
            initial = float(line.split(' ')[-1])
        elif 'Total Recovery Time' in line:
            total = float(line.split(' ')[-1])

    return initial, total


def run_command(command):
    return check_output(command, shell=True)


def run_bench(command):
    initial = 0
    total = 0
    for i in range(REPEAT):
        i, t = get_stats(run_command(command))
        print('%s: (%s, %s)' % (command, i, t))
        initial += i
        total += t

    return initial / REPEAT, total / REPEAT


def main():
    try:
        run_command('rm *-snapshot_id; rm *-log-*.json; rm *.bin')
    except:
        pass

    results = []

    for i in range(0, MAX_FACTOR + 1):
        votes = BASE_VOTES * 2 ** i
        command = 'cargo run --release --bin vote-recovery -- --quiet --articles=%s --votes=%s' % (BASE_ARTICLES, votes)
        logs = run_bench(command)
        snapshots = run_bench('%s --snapshot' % command)
        result = {
            'articles': BASE_ARTICLES,
            'votes': votes,
            'factor': i,
            'logs': logs,
            'snapshots': snapshots
        }

        print(result)
        results.append(result)

    print(results)


main()
