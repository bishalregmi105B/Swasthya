from g4f.client import Client
from g4f.Provider import PollinationsAI

# No API key required
client = Client(provider=PollinationsAI)
images = [
    [open("screen.png", "rb").read(), "screen.png"],
    # [open("another.jpg", "rb").read(), "another.jpeg"],
]
response = client.chat.completions.create(
    model="openai",
    messages=[
        {"role": "user", "content": "What is in this image? Explain his full details"}
    ],
    images=images, # Removed image input for debugging

)

print(response.choices[0].message.content)