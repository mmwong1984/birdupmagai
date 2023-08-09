from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict
from playwright.sync_api import Playwright, sync_playwright, expect
from playwright.async_api import async_playwright as Playwright
import asyncio
import time
import uvicorn


app = FastAPI()

class Message(BaseModel):
    role: str
    content: str

class ChatCompletion(BaseModel):
    model: str
    messages: List[Message]
    allow_fallback: bool

async def run(playwright: Playwright, message: str) -> str:
    browser = await playwright.chromium.launch(headless=True)
    context = await browser.new_context(permissions=['clipboard-read', 'clipboard-write'])
    page = await context.new_page()
    await page.goto("https://app.myshell.ai/chat")
    await page.get_by_role("button", name="GPT 4").click()
    await page.get_by_placeholder("Write a Message").click()
    await page.get_by_placeholder("Write a Message").fill(message)
    await page.get_by_label("send").nth(1).click()
    await asyncio.sleep(10)
    message_locator = page.locator("li:nth-child(2) > div > div > div").first
    await message_locator.click(button="right")
    await asyncio.sleep(1)
    await page.get_by_role("button", name="Copy Message").click()

    copied_text = await page.evaluate("""
        navigator.clipboard.readText().then(function(text) {
            return text;
        })
    """)
    await context.close()
    await browser.close()
    return copied_text

@app.post("/v1/chat/completions")
async def get_chat_completion(chat_completion: ChatCompletion):
    user_messages = [message.content for message in chat_completion.messages if message.role == 'user']
    responses = []
    async with Playwright() as playwright:
        for message in user_messages:
            response = await run(playwright, message)
            responses.append(response)
    return {"completions": responses}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
