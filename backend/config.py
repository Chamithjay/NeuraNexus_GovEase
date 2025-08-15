import os
from dotenv import load_dotenv

# Find the path to the .env file inside backend/
env_path = os.path.join(os.path.dirname(__file__), ".env")
print(f"Loading env from: {env_path}")  # Debug line

# Load the environment variables
load_dotenv(dotenv_path=env_path)

# Read the variables
MONGO_URI = os.getenv("MONGO_URI")
DB_NAME = os.getenv("DB_NAME")

print(f"MONGO_URI from .env: {MONGO_URI}")  # Debug line
print(f"DB_NAME from .env: {DB_NAME}")      # Debug line

if not MONGO_URI or not DB_NAME:
    raise ValueError("MONGO_URI and DB_NAME must be set in environment variables")
