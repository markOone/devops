from flask import Flask, request, jsonify
import psycopg2
import json

app = Flask(__name__)

CONFIG_PATH = '/etc/mywebapp/config.json'


def get_db_connection():
    try:
        with open(CONFIG_PATH, 'r') as f:
            config = json.load(f)
        conn = psycopg2.connect(
            dbname=config['dbname'],
            user=config['user'],
            password=config['password'],
            host=config['host']
        )
        return conn
    except Exception as e:
        app.logger.error(f"Database connection error: {e}")
        return None


@app.route('/health/alive', methods=['GET'])
def alive():
    return "OK", 200


@app.route('/health/ready', methods=['GET'])
def ready():
    conn = get_db_connection()
    if conn:
        conn.close()
        return "OK", 200
    return "Database connection failed", 500


@app.route('/', methods=['GET'])
def index():
    html = """
    <h1>Task Tracker API</h1>
    <ul>
        <li>GET /health/alive</li>
        <li>GET /health/ready</li>
        <li>GET /tasks</li>
        <li>POST /tasks</li>
        <li>POST /tasks/&lt;id&gt;/done</li>
    </ul>
    """
    return html, 200


@app.route('/tasks', methods=['GET', 'POST'])
def handle_tasks():
    conn = get_db_connection()
    if not conn:
        return "Internal Server Error", 500
    cur = conn.cursor()

    if request.method == 'POST':
        title = request.form.get(
            'title') if request.form else request.json.get('title')
        cur.execute("INSERT INTO tasks (title) VALUES (%s);", (title,))
        conn.commit()
        cur.close()
        conn.close()
        return "Task created", 201

    if request.method == 'GET':
        cur.execute(
            "SELECT id, title, status, created_at FROM tasks ORDER BY id ASC;")
        tasks = cur.fetchall()
        cur.close()
        conn.close()

        accept_header = request.headers.get('Accept', '')

        if 'text/html' in accept_header:
            html = "<table border='1'><tr><th>ID</th><th>Title</th>" \
                   "<th>Status</th><th>Created At</th></tr>"
            for t in tasks:
                html += f"<tr><td>{t[0]}</td><td>{t[1]}</td>" \
                        f"<td>{t[2]}</td><td>{t[3]}</td></tr>"
            html += "</table>"
            return html, 200

        result = [{"id": t[0], "title": t[1], "status": t[2],
                   "created_at": t[3]} for t in tasks]
        return jsonify(result), 200


@app.route('/tasks/<int:task_id>/done', methods=['POST'])
def mark_done(task_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("UPDATE tasks SET status = 'done' WHERE id = %s;", (task_id,))
    conn.commit()
    cur.close()
    conn.close()
    return "Task marked as done", 200


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=3000)
