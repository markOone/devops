import psycopg2
import json

CONFIG_PATH = '/etc/mywebapp/config.json'

def migrate():
    try:
        with open(CONFIG_PATH, 'r') as f:
            config = json.load(f)
            
        conn = psycopg2.connect(
            dbname=config['dbname'],
            user=config['user'],
            password=config['password'],
            host=config['host']
        )
        cur = conn.cursor()

        cur.execute('''
            CREATE TABLE IF NOT EXISTS tasks (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                status VARCHAR(50) DEFAULT 'todo',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        ''')

        conn.commit()
        cur.close()
        conn.close()
        print("Database migration completed successfully.")
    except Exception as e:
        print(f"Migration failed: {e}")

if __name__ == '__main__':
    migrate()