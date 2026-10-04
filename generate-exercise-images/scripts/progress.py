#!/usr/bin/env python3
"""Local non-secret run recorder; remote evidence and publication require MCP."""
import argparse
import copy
import datetime as dt
import fcntl
import json
import os
from pathlib import Path
import re
import sys
import tempfile

STATES = set('queued resolved colorful_reserved colorful_saved colorful_validated pencil_reserved pencil_saved pair_validated awaiting_review approved uploading uploaded db_committed completed needs_clarification rejected failed generation_unknown conflict'.split())
STYLE_STATES = set('pending reserved saved validated rejected approved uploaded unknown failed'.split())

def now():
    return dt.datetime.now(dt.timezone.utc).isoformat()

def require(condition, message):
    if not condition:
        raise ValueError(message)

def atomic(path, text):
    fd, tmp = tempfile.mkstemp(prefix='.checkpoint-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)

def cell(value):
    return str(value).replace('|', '\\|').replace('\n', ' ').replace('\r', ' ')

def render(state):
    counts = {}
    for item in state['exercises']:
        counts[item['status']] = counts.get(item['status'], 0) + 1
    lines = ['# Exercise image progress', '',
             f"Run: {cell(state['run_id'])}",
             f"Collection: {cell(state['collection_id'])}",
             f"State revision: {state['state_revision']}",
             f"Review every pair: {state['review_every_pair']}",
             f"Updated (UTC): {state['updated_at']}", '',
             ', '.join(f'{key}: {value}' for key, value in sorted(counts.items())), '',
             '| Exercise | Status | Colorful | Pencil | Next action |',
             '| --- | --- | --- | --- | --- |']
    for item in state['exercises']:
        values = [item['name'], item['status'], item['styles']['colorful']['status'],
                  item['styles']['pencil']['status'], item.get('next_action', '')]
        lines.append('| ' + ' | '.join(cell(value) for value in values) + ' |')
    lines += ['', '## Recent events', '']
    lines.extend(f"- {event['at']}: {cell(event['exercise_id'])} → {event['status']}"
                 for event in state['events'][-30:])
    return '\n'.join(lines) + '\n'

def initialize(data):
    required = {'run_id','collection_id','input_sha256','profile_sha256','review_every_pair','exercises'}
    require(set(data) == required, 'Use only documented initialization fields; no credentials.')
    for name in ('run_id','collection_id'):
        require(isinstance(data[name], str) and re.fullmatch(r'[A-Za-z0-9_-]{1,128}', data[name]), 'Invalid stable run/collection identifier.')
    for name in ('input_sha256','profile_sha256'):
        require(isinstance(data[name], str) and re.fullmatch(r'[a-f0-9]{64}', data[name]), 'Expected SHA-256 digest.')
    require(type(data['review_every_pair']) is bool, 'Review policy must be an explicit boolean.')
    require(isinstance(data['exercises'], list) and data['exercises'], 'Exercise list is empty.')
    seen = set()
    items = []
    for entry in data['exercises']:
        require(isinstance(entry, dict) and set(entry) == {'id','name'}, 'Exercise requires only id and name.')
        require(isinstance(entry['id'], str) and re.fullmatch(r'[A-Za-z0-9_-]{1,128}', entry['id']), 'Invalid exercise identifier.')
        require(entry['id'] not in seen, 'Duplicate exercise identifier.')
        require(isinstance(entry['name'], str) and 0 < len(entry['name'].strip()) <= 500, 'Invalid exercise name.')
        seen.add(entry['id'])
        items.append({**entry, 'status':'queued', 'styles':{style:{'status':'pending','generation_calls':0} for style in ('colorful','pencil')}, 'next_action':'Resolve clinical variant/reference'})
    return {**data, 'exercises':items, 'state_revision':0, 'updated_at':now(), 'events':[]}

def update(state, data):
    require(set(data) <= {'expected_revision','exercise_id','status','styles','next_action'}, 'Unknown update field; no credentials.')
    require(type(data.get('expected_revision')) is int and data['expected_revision'] == state['state_revision'], 'State revision conflict; reload run.json.')
    require(data.get('status') in STATES, 'Unknown item status.')
    updated = copy.deepcopy(state)
    item = next((entry for entry in updated['exercises'] if entry['id'] == data.get('exercise_id')), None)
    require(item is not None, 'Unknown exercise identifier.')
    require(item['status'] != 'completed' or data['status'] == 'completed', 'Do not reopen a completed revision.')
    styles = data.get('styles', {})
    require(isinstance(styles, dict) and set(styles) <= {'colorful','pencil'}, 'Unknown style.')
    for style, change in styles.items():
        require(isinstance(change, dict) and set(change) <= {'status','generation_calls'}, 'Unknown style field.')
        merged = {**item['styles'][style], **change}
        require(merged['status'] in STYLE_STATES, 'Unknown style status.')
        count = merged['generation_calls']
        require(type(count) is int and count in (0,1), 'Exactly one generation dispatch maximum per style/revision.')
        require(count >= item['styles'][style]['generation_calls'], 'Cannot reset a generation reservation.')
        require(merged['status'] == 'pending' or count == 1, 'Reserve the style before recording its result.')
        item['styles'][style] = merged
    if data['status'] in {'uploaded','db_committed','completed'}:
        require(all(value['status'] == 'uploaded' for value in item['styles'].values()), 'Both image slots must be uploaded.')
    if 'next_action' in data:
        require(isinstance(data['next_action'], str) and len(data['next_action']) <= 1000, 'Invalid next action.')
        item['next_action'] = data['next_action']
    item['status'] = data['status']
    updated['state_revision'] += 1
    updated['updated_at'] = now()
    updated['events'].append({'at':updated['updated_at'],'exercise_id':item['id'],'status':item['status']})
    return updated

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run_directory', type=Path)
    parser.add_argument('action', choices=('init','update','render'))
    args = parser.parse_args()
    args.run_directory.mkdir(parents=True, exist_ok=True)
    path = args.run_directory / 'run.json'
    with (args.run_directory / '.progress.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if args.action == 'init':
            require(not path.exists(), 'Run already exists; restore or update it.')
            state = initialize(json.load(sys.stdin))
        else:
            require(path.exists(), 'Restore run.json from durable storage first.')
            state = json.loads(path.read_text(encoding='utf-8'))
            if args.action == 'update':
                state = update(state, json.load(sys.stdin))
        if args.action != 'render':
            atomic(path, json.dumps(state, ensure_ascii=False, indent=2) + '\n')
        atomic(args.run_directory / 'progress.md', render(state))
        print(json.dumps({'state_revision':state['state_revision'],'exercise_count':len(state['exercises'])}))

if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, KeyError, TypeError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
