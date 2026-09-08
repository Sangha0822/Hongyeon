import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

load_dotenv()
engine = create_async_engine(os.environ["DATABASE_URL"])
async_session = async_sessionmaker(engine, expire_on_commit=False)
