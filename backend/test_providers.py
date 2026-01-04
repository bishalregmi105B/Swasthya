#!/usr/bin/env python3
"""
G4F Provider & Model Tester - Fetches working providers from GitHub and tests them
Includes both text and vision model testing
"""

import signal
import sys
import os
import base64
import urllib.request

# URL to fetch working providers list
WORKING_PROVIDERS_URL = "https://raw.githubusercontent.com/maruf009sultan/g4f-working/refs/heads/main/working/working_results.txt"

# Demo image URL for testing vision models (a simple medical image)
DEMO_IMAGE_URL = "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Human_heart_diagram.svg/400px-Human_heart_diagram.svg.png"

def timeout_handler(signum, frame):
    raise TimeoutError("Timeout")

def fetch_working_providers():
    """Fetch working providers from GitHub"""
    text_providers = []
    vision_providers = []
    image_providers = []
    
    try:
        print(f"📥 Fetching working providers from:\n   {WORKING_PROVIDERS_URL}\n")
        with urllib.request.urlopen(WORKING_PROVIDERS_URL, timeout=10) as response:
            content = response.read().decode('utf-8')
        
        for line in content.strip().split('\n'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            parts = line.split('|')
            if len(parts) >= 3:
                provider = parts[0].strip()
                model = parts[1].strip()
                model_type = parts[2].strip().lower()
                
                if model_type == 'text':
                    text_providers.append((provider, model))
                elif model_type == 'vision':
                    vision_providers.append((provider, model))
                elif model_type == 'image':
                    image_providers.append((provider, model))
        
        print(f"✅ Found {len(text_providers)} text, {len(vision_providers)} vision, {len(image_providers)} image providers\n")
        
    except Exception as e:
        print(f"❌ Failed to fetch providers: {e}")
        print("⚠️ Using fallback hardcoded list\n")
        
        # Fallback list
        text_providers = [
            ("CohereForAI_C4AI_Command", "command-a-03-2025"),
            ("CohereForAI_C4AI_Command", "command-r-plus-08-2024"),
            ("ApiAirforce", "deepseek-v3.2:free"),
            ("BAAI_Ling", "ling-flash-2.0"),
        ]
    
    return text_providers, vision_providers, image_providers

def get_demo_image_base64():
    """Download demo image and convert to base64"""
    try:
        with urllib.request.urlopen(DEMO_IMAGE_URL, timeout=10) as response:
            image_data = response.read()
        return base64.b64encode(image_data).decode('utf-8')
    except Exception as e:
        print(f"Failed to download demo image: {e}")
        return None

def test_single(provider_name, model):
    """Test a single provider+model with timeout"""
    try:
        from g4f.client import Client
        import g4f
        
        provider = getattr(g4f.Provider, provider_name, None)
        if not provider:
            return "NO_PROVIDER"
        
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(10)  # 10 second timeout
        
        client = Client(provider=provider)
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Say OK"}],
        )
        
        signal.alarm(0)
        result = response.choices[0].message.content
        if result and len(result.strip()) > 0:
            return result[:30]
        return "EMPTY"
        
    except TimeoutError:
        signal.alarm(0)
        return "TIMEOUT"
    except Exception as e:
        signal.alarm(0)
        err = str(e)[:50]
        return f"ERR: {err}"

def test_vision(provider_name, model, image_base64=None, image_url=None):
    """Test a vision model with an image"""
    try:
        from g4f.client import Client
        import g4f
        
        provider = getattr(g4f.Provider, provider_name, None)
        if not provider:
            return "NO_PROVIDER"
        
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(15)  # 15 second timeout for vision
        
        client = Client(provider=provider)
        
        # Build message with image
        if image_base64:
            messages = [{
                "role": "user",
                "content": [
                    {"type": "text", "text": "What is shown in this image? Describe briefly."},
                    {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{image_base64}"}}
                ]
            }]
        elif image_url:
            messages = [{
                "role": "user",
                "content": [
                    {"type": "text", "text": "What is shown in this image? Describe briefly."},
                    {"type": "image_url", "image_url": {"url": image_url}}
                ]
            }]
        else:
            return "NO_IMAGE"
        
        response = client.chat.completions.create(
            model=model,
            messages=messages,
        )
        
        signal.alarm(0)
        result = response.choices[0].message.content
        if result and len(result.strip()) > 0:
            return result[:50]
        return "EMPTY"
        
    except TimeoutError:
        signal.alarm(0)
        return "TIMEOUT"
    except Exception as e:
        signal.alarm(0)
        err = str(e)[:50]
        return f"ERR: {err}"

def test_text_providers(providers_to_test):
    """Test text providers"""
    print("=" * 70)
    print("TESTING G4F TEXT PROVIDERS & MODELS")
    print("=" * 70)
    
    working_text = []
    
    if not providers_to_test:
        print("⚠️ No text providers to test")
        return working_text
    
    total = len(providers_to_test)
    for i, (prov, model) in enumerate(providers_to_test):
        print(f"[{i+1}/{total}] {prov} + {model}...", end=" ", flush=True)
        
        result = test_single(prov, model)
        
        if result == "NO_PROVIDER":
            print("⚠️ Provider not found")
        elif result == "TIMEOUT":
            print("⏱️ Timeout")
        elif result == "EMPTY":
            print("❌ Empty response")
        elif result.startswith("ERR:"):
            print(f"❌ {result}")
        else:
            print(f"✅ {result}")
            working_text.append((prov, model))
    
    return working_text

def test_vision_providers(providers_to_test, image_base64, image_url):
    """Test vision providers"""
    print("\n" + "=" * 70)
    print("TESTING G4F VISION PROVIDERS & MODELS")
    print("=" * 70)
    print(f"Using demo image: {image_url}")
    print()
    
    working_vision = []
    
    if not providers_to_test:
        print("⚠️ No vision providers to test")
        return working_vision
    
    total = len(providers_to_test)
    for i, (prov, model) in enumerate(providers_to_test):
        print(f"[{i+1}/{total}] {prov} + {model}...", end=" ", flush=True)
        
        # Try with URL first, then base64
        result = test_vision(prov, model, image_url=image_url)
        
        if result.startswith("ERR") or result == "TIMEOUT":
            # Try with base64 if URL failed
            result = test_vision(prov, model, image_base64=image_base64)
        
        if result == "NO_PROVIDER":
            print("⚠️ Provider not found")
        elif result == "TIMEOUT":
            print("⏱️ Timeout")
        elif result == "EMPTY":
            print("❌ Empty response")
        elif result.startswith("ERR:"):
            print(f"❌ {result}")
        else:
            print(f"✅ {result}")
            working_vision.append((prov, model))
    
    return working_vision

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Test G4F providers and models')
    parser.add_argument('--text-only', action='store_true', help='Test only text models')
    parser.add_argument('--vision-only', action='store_true', help='Test only vision models')
    parser.add_argument('--image', type=str, help='Path to local image for vision testing')
    parser.add_argument('--url', type=str, help='Custom URL to fetch providers from')
    args = parser.parse_args()
    
    # Fetch working providers from URL
    global WORKING_PROVIDERS_URL
    if args.url:
        WORKING_PROVIDERS_URL = args.url
    
    text_providers, vision_providers, image_providers = fetch_working_providers()
    
    working_text = []
    working_vision = []
    
    # Test text providers
    if not args.vision_only:
        working_text = test_text_providers(text_providers)
    
    # Test vision providers
    if not args.text_only and vision_providers:
        print("\n📷 Preparing vision test...")
        
        # Get image for testing
        image_base64 = None
        image_url = DEMO_IMAGE_URL
        
        if args.image:
            if os.path.exists(args.image):
                with open(args.image, 'rb') as f:
                    image_base64 = base64.b64encode(f.read()).decode('utf-8')
                image_url = None
                print(f"Using local image: {args.image}")
            else:
                print(f"⚠️ Image not found: {args.image}")
        else:
            print("Downloading demo image...")
            image_base64 = get_demo_image_base64()
        
        if image_base64 or image_url:
            working_vision = test_vision_providers(vision_providers, image_base64, image_url)
        else:
            print("❌ No image available for vision testing")
    
    # Summary
    print("\n" + "=" * 70)
    print("✅ WORKING PROVIDER + MODEL COMBINATIONS")
    print("=" * 70)
    
    if working_text:
        print("\n📝 TEXT MODELS:")
        for prov, model in working_text:
            print(f"  {prov} | {model}")
        print(f"  Total: {len(working_text)}")
    
    if working_vision:
        print("\n👁️ VISION MODELS:")
        for prov, model in working_vision:
            print(f"  {prov} | {model}")
        print(f"  Total: {len(working_vision)}")
    
    # Recommended .env settings
    if working_text or working_vision:
        print("\n" + "=" * 70)
        print("RECOMMENDED .ENV SETTINGS")
        print("=" * 70)
        
        if working_text:
            providers = list(set([p for p, m in working_text]))
            models = [m for p, m in working_text]
            
            print(f"\n# Primary text provider")
            print(f"AI_DEFAULT_PROVIDER={providers[0]}")
            print(f"AI_CHAT_MODEL={models[0]}")
            
            if len(models) > 1:
                print(f"AI_CHAT_MODEL_FALLBACKS={','.join(models[1:4])}")
        
        if working_vision:
            vision_providers = list(set([p for p, m in working_vision]))
            vision_models = [m for p, m in working_vision]
            
            print(f"\n# Vision provider")
            print(f"AI_VISION_PROVIDER={vision_providers[0]}")
            print(f"AI_VISION_MODEL={vision_models[0]}")
            
            if len(vision_models) > 1:
                print(f"AI_VISION_MODEL_FALLBACKS={','.join(vision_models[1:3])}")

if __name__ == "__main__":
    main()
