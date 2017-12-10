from os import environ
from subprocess import check_output


MAX_FACTOR = int(environ.get('MAX_FACTOR', 1))
BASE_ARTICLES = 10000
BASE_VOTES = 100000


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


def main():
    try:
        run_command('rm *-snapshot_id; rm *-log-*.json; rm *.bin')
    except:
        pass

    results = []

    for i in range(0, MAX_FACTOR + 1):
        articles = BASE_ARTICLES * 2 ** i
        votes = BASE_VOTES * 2 ** i
        command = 'cargo run --release --bin vote-recovery -- --quiet --articles=%s --votes=%s' % (articles, votes)
        logs = get_stats(run_command(command))
        snapshots = get_stats(run_command('%s --snapshot' % command))
        result = {
            'articles': articles,
            'votes': votes,
            'factor': i,
            'logs': logs,
            'snapshots': snapshots
        }

        print(result)
        results.append(result)

    print(results)


main()
