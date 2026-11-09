"""Prepare an ignored Flutter define file from the local demo .env."""
import json
from pathlib import Path

directory = Path(__file__).resolve().parent
env_path = directory / '.env'
if not env_path.is_file():
    raise SystemExit('Créez tool/.env avec GROQ_API_KEY avant de continuer.')

key = None
for line in env_path.read_text(encoding='utf-8-sig').splitlines():
    name, separator, value = line.strip().partition('=')
    if separator and name.strip() == 'GROQ_API_KEY':
        key = value.strip().strip('"').strip("'")
        break
if not key:
    raise SystemExit('GROQ_API_KEY est absent ou vide dans tool/.env.')

target = directory / 'groq_demo_config.json'
target.write_text(json.dumps({'GROQ_API_KEY': key}), encoding='utf-8')
print('Configuration locale créée. Ne partagez ni ce fichier ni la version compilée.')
