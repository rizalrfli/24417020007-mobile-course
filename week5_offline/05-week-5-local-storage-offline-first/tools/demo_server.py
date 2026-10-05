"""Server praktikum single-device: HTTP ACK setelah transaksi SQLite selesai."""
import argparse
import json
import sqlite3
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


def instant(value):
    parsed = datetime.fromisoformat(value.replace('Z', '+00:00'))
    if parsed.tzinfo is None:
        raise ValueError('updated_at wajib memiliki zona waktu')
    return parsed


def resolve_conflict(local, remote):
    return remote if instant(remote['updated_at']) > instant(local['updated_at']) else local


def create_handler(db_path):
    class Handler(BaseHTTPRequestHandler):
        def reply(self, status, payload):
            body = json.dumps(payload).encode()
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if self.path != '/notes':
                return self.reply(404, {'error': 'not found'})
            with sqlite3.connect(db_path) as db:
                records = db.execute('SELECT payload FROM notes ORDER BY id').fetchall()
            self.reply(200, [json.loads(row[0]) for row in records])

        def do_PUT(self):
            try:
                note_id = int(self.path.removeprefix('/notes/'))
                payload = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0))))
                if payload['id'] != note_id or not isinstance(payload['title'], str) or not isinstance(payload['body'], str) or payload['deleted'] not in (0, 1):
                    raise ValueError('invalid note')
                instant(payload['updated_at'])
            except (ValueError, KeyError, TypeError):
                return self.reply(400, {'error': 'invalid note'})
            with sqlite3.connect(db_path) as db:
                row = db.execute('SELECT payload FROM notes WHERE id = ?', (note_id,)).fetchone()
                accepted = resolve_conflict(payload, json.loads(row[0])) if row else payload
                accepted['dirty'] = 0
                db.execute('INSERT OR REPLACE INTO notes VALUES (?, ?)', (note_id, json.dumps(accepted)))
            self.reply(200, accepted)
    return Handler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8080)
    parser.add_argument('--db', default='build/demo-server.sqlite')
    args = parser.parse_args()
    Path(args.db).parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(args.db) as db:
        db.execute('CREATE TABLE IF NOT EXISTS notes(id INTEGER PRIMARY KEY, payload TEXT NOT NULL)')
    print(f'Demo server listening on port {args.port}', flush=True)
    HTTPServer(('0.0.0.0', args.port), create_handler(args.db)).serve_forever()


if __name__ == '__main__':
    main()
