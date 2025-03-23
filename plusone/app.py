from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

app = FastAPI()

@app.get("/plusone/{number}", response_class=PlainTextResponse)
async def plus_one(number: int):
    return str(number + 1)
