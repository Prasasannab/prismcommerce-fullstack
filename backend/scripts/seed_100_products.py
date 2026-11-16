#!/usr/bin/env python3
import json
import uuid
import datetime
import subprocess

# Categories to ensure
CATEGORIES = [
    {
        "id": "3f646ab3-5876-4d82-97a6-8bb229d87c98",
        "name": "Audio",
        "slug": "audio",
        "description": "High-fidelity headphones, earbuds, DACs, and studio audio gear.",
        "image": "https://images.unsplash.com/photo-1546435770-a3e426bf472b"
    },
    {
        "id": "d494f66c-76b6-404b-a064-ac58fb38ca9b",
        "name": "Laptops",
        "slug": "laptops",
        "description": "High-performance laptops, workstations, and ultraportable notebooks.",
        "image": "https://images.unsplash.com/photo-1517336714731-489689fd1ca8"
    },
    {
        "id": "d56df8c8-4dd5-47f0-a205-733a8940e41c",
        "name": "Wearables",
        "slug": "wearables",
        "description": "Smartwatches, fitness bands, smart rings, and connected health trackers.",
        "image": "https://images.unsplash.com/photo-1523275335684-37898b6baf30"
    },
    {
        "id": str(uuid.uuid5(uuid.NAMESPACE_DNS, "phones-tablets.prismcommerce.com")),
        "name": "Phones & Tablets",
        "slug": "phones-tablets",
        "description": "Flagship 5G smartphones, creator tablets, and foldable mobile devices.",
        "image": "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9"
    },
    {
        "id": str(uuid.uuid5(uuid.NAMESPACE_DNS, "gaming-vr.prismcommerce.com")),
        "name": "Gaming & VR",
        "slug": "gaming-vr",
        "description": "Next-gen VR headsets, mechanical keyboards, gaming mice, and streaming controllers.",
        "image": "https://images.unsplash.com/photo-1550745165-9bc0b252726f"
    },
    {
        "id": str(uuid.uuid5(uuid.NAMESPACE_DNS, "accessories.prismcommerce.com")),
        "name": "Accessories & Gear",
        "slug": "accessories",
        "description": "GaN chargers, magnetic power banks, Thunderbolt docks, and EDC tech pouches.",
        "image": "https://images.unsplash.com/photo-1588872657578-7efd1f1555ed"
    }
]

# High-resolution Unsplash tech images pool
IMAGES_POOL = {
    "audio": [
        "https://images.unsplash.com/photo-1590658268037-6bf12165a8df",
        "https://images.unsplash.com/photo-1546435770-a3e426bf472b",
        "https://images.unsplash.com/photo-1505740420928-5e560c06d30e",
        "https://images.unsplash.com/photo-1484704849700-f032a568e944",
        "https://images.unsplash.com/photo-1598331668826-20cecc596b86",
        "https://images.unsplash.com/photo-1572536147248-ac59a8abfa4b",
        "https://images.unsplash.com/photo-1545454675-3531b543be5d",
        "https://images.unsplash.com/photo-1524678606370-a47ad25cb82a"
    ],
    "laptops": [
        "https://images.unsplash.com/photo-1517336714731-489689fd1ca8",
        "https://images.unsplash.com/photo-1496181133206-80ce9b88a853",
        "https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2",
        "https://images.unsplash.com/photo-1588872657578-7efd1f1555ed",
        "https://images.unsplash.com/photo-1531297484001-80022131f5a1",
        "https://images.unsplash.com/photo-1541807084-5c52b6b3adef"
    ],
    "wearables": [
        "https://images.unsplash.com/photo-1523275335684-37898b6baf30",
        "https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1",
        "https://images.unsplash.com/photo-1544117519-31a4b719223d",
        "https://images.unsplash.com/photo-1579586337278-3befd40fd17a",
        "https://images.unsplash.com/photo-1510017803434-a899398421b3"
    ],
    "phones": [
        "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9",
        "https://images.unsplash.com/photo-1592899677977-9c10ca588bbd",
        "https://images.unsplash.com/photo-1565849904461-04a58ad377e0",
        "https://images.unsplash.com/photo-1580910051074-3eb694886505",
        "https://images.unsplash.com/photo-1585060544812-6b45742d762f"
    ],
    "gaming": [
        "https://images.unsplash.com/photo-1550745165-9bc0b252726f",
        "https://images.unsplash.com/photo-1612287233204-6338b556b5bc",
        "https://images.unsplash.com/photo-1542751371-adc38448a05e",
        "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f",
        "https://images.unsplash.com/photo-1587202372775-e229f172b9d7"
    ],
    "accessories": [
        "https://images.unsplash.com/photo-1622445262464-84b1a0e6052e",
        "https://images.unsplash.com/photo-1583863788434-e58a36330cf0",
        "https://images.unsplash.com/photo-1586953208448-b95a79798f07",
        "https://images.unsplash.com/photo-1527864550417-7fd91fc51a46",
        "https://images.unsplash.com/photo-1546868871-7041f2a55e12"
    ]
}

# 100 detailed product specs
RAW_PRODUCTS = [
    # --- AUDIO (20 items) ---
    ("Horizon ANC Headphones", "audio", "Precision studio wireless over-ear headphones with custom 45mm dynamic drivers and 48hr battery.", 349.00, [("Space Gray", "Over-Ear", 0, 45), ("Matte Black", "Over-Ear", 0, 35)]),
    ("Quantum Pro Earbuds", "audio", "Audiophile true-wireless earbuds with dual balanced armature drivers and transparency mode.", 229.00, [("Obsidian", "Standard", 0, 60), ("Pure White", "Standard", 0, 50)]),
    ("Pulse SoundStage Mini", "audio", "Compact 360-degree wireless Bluetooth speaker with IP67 waterproof aluminum enclosure.", 129.00, [("Charcoal", "Portable", 0, 80), ("Forest Green", "Portable", 0, 40)]),
    ("EchoFit Sport Earbuds", "audio", "Ergonomic secure-fit athletic earbuds featuring biometric heart-rate tracking and sweatproofing.", 179.00, [("Volt Yellow", "Sport", 0, 55), ("Midnight Navy", "Sport", 0, 65)]),
    ("Aura Ambient Soundbar", "audio", "Dolby Atmos 5.1.2 home theater soundbar with wireless down-firing subwoofer.", 599.00, [("Titanium Black", "Standard", 0, 25)]),
    ("Master Reference Studio Monitor", "audio", "Pair of professional 6.5-inch active studio monitors for mastering and acoustic production.", 749.00, [("Walnut Finish", "Pair", 0, 20), ("Matte Black", "Pair", 0, 30)]),
    ("SonicAir Ultra Buds", "audio", "Featherweight 3.8g earbuds with dual beamforming microphones and lossless 24-bit audio.", 189.00, [("Cloud White", "Standard", 0, 70), ("Graphite", "Standard", 0, 50)]),
    ("RetroSound 1974 Over-Ear", "audio", "Vintage-inspired open-back planar magnetic headphones with real mahogany wood cups.", 499.00, [("Mahogany", "Open-Back", 0, 18)]),
    ("VocalStream USB Microphone", "audio", "Studio-grade condenser mic with multi-pattern polar pickup, integrated pop filter, and zero-latency monitoring.", 159.00, [("Midnight Black", "Desktop", 0, 75)]),
    ("CarbonPulse Wireless Duo", "audio", "Dual-pack of synchronized magnetic wireless speakers for immersive true stereo pairing.", 199.00, [("Space Gray", "Duo Pack", 0, 40)]),
    ("WaveSub Subwoofer 10", "audio", "Powered 300W high-excursion home theater subwoofer with deep 22Hz frequency response.", 449.00, [("Gloss Black", "10-inch", 0, 15)]),
    ("Nomad ANC Travel Headphones", "audio", "Ultra-foldable noise-cancelling headphones featuring aircraft adapter and memory foam cushions.", 279.00, [("Sandstone", "Travel", 0, 50), ("Matte Black", "Travel", 0, 60)]),
    ("Pulse Mini Clip Speaker", "audio", "Pocket-sized Bluetooth 5.3 speaker with integrated carabiner clip and 12-hour playback.", 49.00, [("Coral Red", "Mini", 0, 95), ("Cyan Blue", "Mini", 0, 85)]),
    ("StudioDAC Pro Converter", "audio", "High-resolution desktop DAC and headphone amplifier capable of decoding 384kHz/32-bit audio.", 329.00, [("Anodized Silver", "Desktop", 0, 30)]),
    ("BassCannon Wireless Boombox", "audio", "Heavy-duty outdoor party speaker with 80W output, dynamic RGB ring lighting, and dual woofers.", 289.00, [("Rugged Black", "Standard", 0, 35)]),
    ("PodAir Open-Ear Sport", "audio", "Bone-conduction sports headset keeping your ears unobstructed for outdoor runner safety.", 139.00, [("Slate Gray", "Open-Ear", 0, 65)]),
    ("AcousticLine Desktop Speakers", "audio", "Premium 2.0 desktop stereo speakers with woven Kevlar woofers and silk dome tweeters.", 249.00, [("Bamboo", "2.0 Pair", 0, 40), ("Matte White", "2.0 Pair", 0, 35)]),
    ("LavPro Wireless Lavalier Mic", "audio", "Dual-channel wireless lapel mic kit with 200m range and onboard recording for creators.", 219.00, [("Black", "Duo Kit", 0, 45)]),
    ("Pulse ANC Shield", "audio", "Industrial-grade active noise ear defenders with Bluetooth audio streaming for workshops.", 169.00, [("High-Viz Yellow", "Standard", 0, 30)]),
    ("Symphony Pro In-Ear Monitors", "audio", "Triple-driver hybrid IEMs with detachable silver-plated braided MMCX cable.", 299.00, [("Clear Crystal", "MMCX", 0, 25)]),

    # --- LAPTOPS & COMPUTING (20 items) ---
    ("PrismBook Air 13", "laptops", "Ultra-thin 13.3-inch fanless notebook with Retina display and all-day 18hr battery.", 1099.00, [("Midnight", "256GB / 16GB", 0, 35), ("Starlight", "512GB / 16GB", 200, 25)]),
    ("Titan RTX 4080 Beast", "laptops", "17.3-inch 240Hz QHD gaming laptop powered by RTX 4080 and liquid metal cooling.", 2799.00, [("Abyssal Black", "1TB / 32GB", 0, 15), ("Abyssal Black", "2TB / 64GB", 400, 10)]),
    ("AeroBlade Slim 14", "laptops", "Magnesium-alloy 14-inch OLED developer laptop weighing only 1.1kg.", 1499.00, [("Space Silver", "512GB / 16GB", 0, 40), ("Space Silver", "1TB / 32GB", 250, 20)]),
    ("VisionBook Pro 15", "laptops", "Creator laptop with factory-calibrated 4K OLED touch panel and dedicated stylus pen.", 1899.00, [("Slate Gray", "1TB / 32GB", 0, 20)]),
    ("CodeCraft DevStation 16", "laptops", "Linux-certified developer workstation with mechanical keyboard and swappable memory modules.", 1699.00, [("Matte Black", "1TB / 32GB", 0, 30), ("Matte Black", "2TB / 64GB", 350, 15)]),
    ("Horizon Flip 2-in-1", "laptops", "360-degree convertible touchscreen laptop with active pen support and 3K resolution.", 1249.00, [("Aluminum Gray", "512GB / 16GB", 0, 25)]),
    ("PrismView 32 4K OLED Monitor", "laptops", "32-inch 4K OLED creator monitor with 99% DCI-P3 color gamut and 90W USB-C hub.", 1199.00, [("Minimalist Silver", "32-inch", 0, 18)]),
    ("UltraCurve 38 Ultrawide Monitor", "laptops", "38-inch curved 144Hz IPS display with 21:9 aspect ratio and built-in KVM switch.", 1049.00, [("Dark Titanium", "38-inch", 0, 14)]),
    ("Apex Mechanical Keyboard 75", "laptops", "Hot-swappable wireless mechanical keyboard with gasket mount and PBT doubleshot keycaps.", 169.00, [("Retro Gray", "Linear Red", 0, 50), ("Retro Gray", "Tactile Brown", 0, 45)]),
    ("Pulse Ergonomic Mouse", "laptops", "Vertical ergonomic wireless mouse engineered to eliminate wrist strain with thumb scroll.", 89.00, [("Graphite", "Wireless", 0, 70), ("Off-White", "Wireless", 0, 50)]),
    ("CyberKeys Low-Profile TKL", "laptops", "Ultra-slim aircraft-grade aluminum mechanical keyboard with per-key RGB backlighting.", 149.00, [("Space Gray", "Clicky White", 0, 40)]),
    ("Studio Trackball Pro", "laptops", "Precision optical trackball with customizable dual-angle tilt wedge and 8 programmable buttons.", 119.00, [("Matte Black", "Standard", 0, 35)]),
    ("MiniStation Compact PC", "laptops", "Small form-factor desktop computer packed with 14-core processor and dual 2.5G LAN ports.", 899.00, [("Space Silver", "512GB / 32GB", 0, 25)]),
    ("PrismHub Thunderbolt 4 Dock", "laptops", "14-in-1 aluminum docking station supporting dual 4K 120Hz displays and 96W charging.", 279.00, [("Anodized Gray", "14-in-1", 0, 45)]),
    ("AeroStand Laptop Riser", "laptops", "CNC-machined folding aluminum laptop stand with dual silent cooling fans.", 69.00, [("Space Gray", "Foldable", 0, 80), ("Silver", "Foldable", 0, 70)]),
    ("VisionCam 4K Pro Webcam", "laptops", "4K 60fps streaming webcam with Sony STARVIS sensor, autofocus, and dual stereo mics.", 199.00, [("Black Aluminum", "4K HDR", 0, 55)]),
    ("ScreenBar Halo Light", "laptops", "Monitor-mounted smart desk lamp with auto-dimming ambient sensor and wireless controller.", 149.00, [("Gunmetal", "Wireless Dial", 0, 60)]),
    ("DeskMat XL Vegan Leather", "laptops", "Water-resistant premium desk pad with micro-textured surface and anti-fray stitched edges.", 45.00, [("Caramel Brown", "90x40cm", 0, 120), ("Midnight Black", "90x40cm", 0, 110)]),
    ("Titan Dual Arm Monitor Mount", "laptops", "Heavy-duty gas-spring dual monitor arm holding screens up to 34 inches.", 139.00, [("Matte Black", "Dual Desk Clamp", 0, 40)]),
    ("Apex Portable Monitor 15", "laptops", "15.6-inch 1080p OLED portable monitor with folding magnetic kickstand case.", 299.00, [("Carbon Fiber", "15.6-inch", 0, 35)]),

    # --- WEARABLES (15 items) ---
    ("Prism Watch Ultra", "wearables", "Aerospace titanium smartwatch with sapphire crystal face, dual-frequency GPS, and 100m dive rating.", 799.00, [("Natural Titanium", "49mm Trail Loop", 0, 30), ("Natural Titanium", "49mm Ocean Band", 0, 25)]),
    ("Apex Chrono Elite", "wearables", "Ceramic luxury smartwatch with always-on AMOLED display and 14-day battery life.", 499.00, [("Obsidian Ceramic", "46mm Leather", 0, 35), ("Silver Steel", "46mm Link", 50, 20)]),
    ("Pulse Active S", "wearables", "Lightweight GPS running watch with VO2 max tracking, training readiness scores, and music storage.", 299.00, [("Slate Black", "42mm Silicone", 0, 60), ("Sunset Coral", "42mm Silicone", 0, 45)]),
    ("Horizon Ring Titanium Gen 2", "wearables", "Discreet biometric smart ring tracking sleep stages, skin temperature, and recovery scores.", 299.00, [("Matte Black", "Size 10", 0, 30), ("Stealth Gray", "Size 11", 0, 25), ("Gold", "Size 9", 50, 15)]),
    ("AeroFit Fitness Band", "wearables", "Slim water-resistant activity tracker with curved AMOLED screen and stress monitoring.", 99.00, [("Midnight Black", "Standard", 0, 85), ("Powder Pink", "Standard", 0, 60)]),
    ("Prism Vision Audio Shades", "wearables", "Polarized sunglasses with built-in open-ear directional audio speakers and voice control.", 199.00, [("Classic Wayfarer", "Polarized", 0, 45)]),
    ("Titan Diver 500M Smart", "wearables", "Extreme diving computer watch with integrated depth gauge, ascent alarm, and compass.", 899.00, [("Deep Blue", "Titanium 50mm", 0, 15)]),
    ("Pulse Band Kids Edition", "wearables", "Durable interactive kids smartwatch with parental GPS geofencing and SOS call button.", 119.00, [("Electric Blue", "Kids Fit", 0, 40), ("Neon Lime", "Kids Fit", 0, 35)]),
    ("Horizon BioSleep Headband", "wearables", "Smart EEG sleep headband generating adaptive binaural soundscapes to deepen restorative sleep.", 349.00, [("Cool Gray", "Adjustable", 0, 20)]),
    ("Chrono Milanese Band", "wearables", "Woven stainless steel magnetic mesh replacement band for Prism Watch series.", 59.00, [("Silver Mesh", "22mm", 0, 75), ("Black Mesh", "22mm", 0, 70)]),
    ("Rugged Armor Watch Case", "wearables", "Shock-absorbent bumper case with tempered glass screen protector for smartwatches.", 29.00, [("Tactical Olive", "49mm", 0, 100), ("Matte Black", "49mm", 0, 110)]),
    ("Sport Silicone Band 3-Pack", "wearables", "Breathable perforated silicone sport bands in three stylish complementary colors.", 39.00, [("Trio Pack", "20mm", 0, 80)]),
    ("Leather Link Luxury Strap", "wearables", "Handcrafted French calfskin leather band with flexible concealed magnetic closure.", 89.00, [("Saddle Brown", "Universal", 0, 40), ("Midnight Black", "Universal", 0, 35)]),
    ("Smart Jump Rope Digital", "wearables", "Weighted jump rope with magnetic hall sensors syncing rotation count and calorie burn to app.", 49.00, [("Matte Gray", "Standard", 0, 60)]),
    ("PostureGuard Biometric Clip", "wearables", "Discreet collar clip gently vibrating when slouching to reinforce ergonomic spinal alignment.", 79.00, [("White Frost", "Clip", 0, 50)]),

    # --- PHONES & TABLETS (15 items) ---
    ("PrismPhone Pro 16", "phones-tablets", "Flagship smartphone featuring Grade 5 titanium frame, periscope 10x telephoto, and AI silicon.", 1199.00, [("Natural Titanium", "256GB", 0, 40), ("Space Black", "512GB", 200, 30)]),
    ("PrismPhone Ultra Fold", "phones-tablets", "Next-gen inward folding phone opening into an 8-inch 120Hz flexible AMOLED tablet.", 1799.00, [("Phantom Black", "512GB", 0, 20)]),
    ("Apex 5G Compact", "phones-tablets", "One-handed 5.9-inch flagship smartphone with dual cameras, IP68 water resistance, and stereo speakers.", 699.00, [("Starlight Silver", "128GB", 0, 50), ("Midnight", "256GB", 80, 40)]),
    ("Horizon Nova 12", "phones-tablets", "Value champion smartphone with 108MP camera, 5000mAh battery, and 67W rapid charging.", 449.00, [("Aurora Green", "128GB", 0, 70), ("Glacier Blue", "256GB", 50, 60)]),
    ("PrismPad Pro 12.9", "phones-tablets", "12.9-inch Liquid Retina XDR tablet with M-series silicon and Thunderbolt expansion.", 1099.00, [("Space Gray", "128GB Wi-Fi", 0, 35), ("Space Gray", "256GB Cellular", 250, 25)]),
    ("PrismPad Mini 8.3", "phones-tablets", "Compact 8.3-inch powerhouse tablet perfect for digital pilots, note-takers, and e-reading.", 599.00, [("Starlight", "64GB", 0, 45), ("Space Gray", "256GB", 150, 30)]),
    ("Horizon PaperInk Color E-Reader", "phones-tablets", "10.3-inch color E-Ink digital notepad with stylus pen and glare-free sunlight reading.", 479.00, [("Canvas White", "64GB with Pen", 0, 30)]),
    ("Magnetic Floating Keyboard Case", "phones-tablets", "Cantilever floating arm keyboard case with built-in glass trackpad and backlit keys.", 299.00, [("Space Black", "12.9-inch", 0, 40)]),
    ("Stylus Pen Pro Active", "phones-tablets", "Pixel-perfect drawing stylus with tilt sensitivity, palm rejection, and wireless charging.", 99.00, [("Matte White", "Standard", 0, 80)]),
    ("Foldable MagSafe Stand", "phones-tablets", "Dual-hinge aluminum desktop stand with integrated 15W Qi2 wireless charger.", 69.00, [("Silver Aluminum", "Adjustable", 0, 75)]),
    ("ArmorDrop Tough Phone Case", "phones-tablets", "Mil-spec 16ft drop protection case with reinforced corners and kickstand ring.", 39.00, [("Carbon Kevlar", "Pro Edition", 0, 110)]),
    ("PaperFeel Screen Protector 2-Pack", "phones-tablets", "Matte screen protector providing realistic paper friction for sketching and writing.", 25.00, [("Matte Texture", "12.9-inch", 0, 90)]),
    ("Car Mount MagSafe Air Vent", "phones-tablets", "Ultra-strong neodymium magnetic car air-vent mount with 360-degree ball joint.", 35.00, [("Matte Black", "Universal", 0, 85)]),
    ("Leather Folio Wallet Case", "phones-tablets", "Full-grain leather flip wallet case with RFID-blocking card slots.", 59.00, [("Cognac Tan", "Universal", 0, 65)]),
    ("USB-C Fast Charger 65W Duo", "phones-tablets", "Compact dual-port GaN fast wall charger with foldable prongs.", 45.00, [("Alpine White", "Dual USB-C", 0, 120)]),

    # --- GAMING & VR (15 items) ---
    ("Apex Deck OLED Handheld", "gaming-vr", "7.4-inch 90Hz OLED PC gaming handheld with custom AMD APU and ergonomic controls.", 649.00, [("Matte Black", "512GB NVMe", 0, 25), ("Matte Black", "1TB Anti-Glare", 100, 20)]),
    ("Prism Horizon VR Headset", "gaming-vr", "All-in-one wireless VR/MR headset with 4K per-eye micro-OLED panels and passthrough.", 999.00, [("Arctic White", "256GB", 0, 18), ("Arctic White", "512GB", 150, 15)]),
    ("CyberStrike Wireless Gamepad", "gaming-vr", "Hall-effect joystick wireless pro controller with mechanical microswitch buttons.", 89.00, [("Cyber Purple", "Multi-Platform", 0, 60), ("Stealth Black", "Multi-Platform", 0, 70)]),
    ("Titan Esports Gaming Mouse", "gaming-vr", "Ultra-lightweight 49g wireless gaming mouse with 32,000 DPI optical sensor and 8K polling.", 129.00, [("Chalk White", "Wireless", 0, 50), ("Matte Black", "Wireless", 0, 55)]),
    ("HyperGlide Glass Mousepad", "gaming-vr", "Tempered aluminosilicate glass gaming mouse pad offering zero-resistance gliding.", 79.00, [("Frosted Obsidian", "490x420mm", 0, 45)]),
    ("RetroPulse Micro Arcade", "gaming-vr", "Mini tabletop arcade cabinet preloaded with 300 licensed retro arcade classics.", 149.00, [("Classic Cabinet", "Standard", 0, 30)]),
    ("Apex Flight Stick Pro", "gaming-vr", "Realistic flight simulation throttle and stick with 33 programmable buttons.", 249.00, [("Steel Gray", "HOTAS Kit", 0, 20)]),
    ("Racing Wheel Force Feedback", "gaming-vr", "Direct-drive racing wheel and load-cell pedal set for sim racing enthusiasts.", 599.00, [("Brushed Metal", "Wheel + Pedals", 0, 15)]),
    ("StreamDeck Control Pad", "gaming-vr", "15 customizable LCD keys to trigger streaming scenes, audio cues, and shortcuts.", 149.00, [("Matte Black", "15-Key", 0, 60)]),
    ("Aura RGB Light Tower Pair", "gaming-vr", "Dual smart ambient light bars syncing colors dynamically to your gaming display.", 119.00, [("Black Base", "2-Pack", 0, 40)]),
    ("Custom PBT Keycaps Synthwave", "gaming-vr", "Cherry-profile doubleshot PBT keycap set featuring retro neon synthwave styling.", 49.00, [("Synthwave Neon", "134 Keys", 0, 80)]),
    ("Artisan Wrist Rest Walnut", "gaming-vr", "Hand-polished solid walnut wooden wrist rest for 75% and TKL mechanical keyboards.", 39.00, [("Solid Walnut", "Compact 75%", 0, 65)]),
    ("VR Prescription Lens Inserts", "gaming-vr", "Magnetic anti-blue light prescription lens attachments for VR headsets.", 59.00, [("Magnetic Mount", "Pair", 0, 40)]),
    ("Coiled Aviator Keyboard Cable", "gaming-vr", "Double-sleeved paracord coiled USB-C cable with quick-release metal aviator connector.", 29.00, [("Midnight Blue", "USB-C", 0, 90)]),
    ("NoiseDampening Mic Shield", "gaming-vr", "Curved multi-layer acoustic foam isolation reflection shield for broadcast microphones.", 49.00, [("High-Density Foam", "Desk Clamp", 0, 50)]),

    # --- ACCESSORIES & GEAR (15 items) ---
    ("GaN 140W Ultra Fast Charger", "accessories", "Multi-port 140W GaN charger capable of fast-charging a 16-inch laptop and two phones simultaneously.", 89.00, [("Matte Black", "3x USB-C / 1x USB-A", 0, 90)]),
    ("MagSafe Battery Pack 10000", "accessories", "Slim wireless magnetic power bank with integrated folding zinc alloy kickstand.", 59.00, [("Graphite", "10,000mAh", 0, 110), ("Alpine White", "10,000mAh", 0, 80)]),
    ("Nomad Tech Backpack 24L", "accessories", "Weatherproof Cordura travel backpack with dedicated padded laptop compartment and luggage pass-through.", 189.00, [("Charcoal Black", "24 Liters", 0, 35)]),
    ("Apex Hardcase EDC Pouch", "accessories", "Semi-rigid water-resistant electronics organizer pouch with elastic cable loops.", 39.00, [("Storm Gray", "Medium", 0, 120)]),
    ("Thunderbolt 4 Braided Cable", "accessories", "Certified 40Gbps high-speed data and 240W power delivery braided 2-meter cable.", 39.00, [("Braided Black", "2 Meters", 0, 150)]),
    ("MagSafe 3-in-1 Charging Tree", "accessories", "Weighted floating metal stand simultaneously charging phone, watch, and wireless earbuds.", 129.00, [("Space Silver", "3-in-1", 0, 55)]),
    ("SolarPower Camp Hub 25000", "accessories", "Rugged outdoor power bank with fold-out high-efficiency monocrystalline solar panels.", 99.00, [("Adventure Orange", "25,000mAh", 0, 45)]),
    ("Prism Air Tag Finder 4-Pack", "accessories", "Precision ultra-wideband Bluetooth item trackers with replaceable 1-year battery.", 89.00, [("White Gloss", "4-Pack", 0, 100)]),
    ("Titanium EDC Multi-Tool Pen", "accessories", "Machined Grade 5 titanium bolt-action ballpoint pen with tungsten glass breaker.", 69.00, [("Raw Titanium", "Fine Point", 0, 60)]),
    ("Minimalist Laptop Sleeve 14", "accessories", "Ultra-thin magnetic closure felt and vegan leather sleeve with soft microfiber interior.", 45.00, [("Heather Charcoal", "14-inch", 0, 85)]),
    ("Screen Cleaning Kit Pro", "accessories", "Alcohol-free antimicrobial screen mist with washable oversized microfiber polishing cloth.", 19.00, [("Mist Spray", "150ml", 0, 200)]),
    ("Cable Management Magnetic Clips", "accessories", "Pack of 6 weighted silicone magnetic desktop cable collars keeping wires tidy.", 22.00, [("Slate Black", "6-Pack", 0, 160)]),
    ("USB-C to HDMI 8K Adapter", "accessories", "Aluminum adapter supporting 8K 60Hz and 4K 144Hz video output with HDR.", 35.00, [("Space Gray", "Braided", 0, 95)]),
    ("Passport & Tech Travel Wallet", "accessories", "RFID-blocking zippered travel organizer holding passport, SIM cards, cards, and phone.", 49.00, [("Vintage Black", "Full Grain", 0, 50)]),
    ("Desk Cup Holder with Headphone Hook", "accessories", "Under-desk clamp dual-purpose aluminum drink holder and headphone hanger.", 29.00, [("Black Aluminum", "Desk Clamp", 0, 80)])
]

def generate_sql():
    sql_lines = []
    
    # 1. Upsert Categories
    for cat in CATEGORIES:
        cid = cat['id']
        name = cat['name'].replace("'", "''")
        slug = cat['slug']
        desc = cat['description'].replace("'", "''")
        img = cat['image']
        now = "NOW()"
        
        sql = f"""
        INSERT INTO "Categories" ("Id", "Name", "Slug", "Description", "ImageUrl", "CreatedAt")
        VALUES ('{cid}', '{name}', '{slug}', '{desc}', '{img}', {now})
        ON CONFLICT ("Slug") DO UPDATE SET "Name" = EXCLUDED."Name", "Description" = EXCLUDED."Description", "ImageUrl" = EXCLUDED."ImageUrl";
        """
        sql_lines.append(sql.strip())

    # Build category slug to ID mapping
    cat_id_map = {c['slug']: c['id'] for c in CATEGORIES}

    # 2. Insert Products, Variants, Inventory
    count = 0
    for name, cat_slug, desc, base_price, variants in RAW_PRODUCTS:
        count += 1
        cid = cat_id_map[cat_slug]
        pid = str(uuid.uuid5(uuid.NAMESPACE_DNS, f"product.{name.lower()}"))
        slug = name.lower().replace(" ", "-").replace("&", "and").replace("/", "-").replace("'", "")
        desc_escaped = desc.replace("'", "''")
        name_escaped = name.replace("'", "''")
        
        # Pick images from pool
        img_cat = cat_slug if cat_slug in IMAGES_POOL else "accessories"
        if "phone" in cat_slug: img_cat = "phones"
        pool = IMAGES_POOL.get(img_cat, IMAGES_POOL["accessories"])
        img1 = pool[(count - 1) % len(pool)]
        img2 = pool[count % len(pool)]
        imgs_sql = f"ARRAY['{img1}', '{img2}']::text[]"

        prod_sql = f"""
        INSERT INTO "Products" ("Id", "CategoryId", "Name", "Slug", "Description", "BasePrice", "IsActive", "ImageUrls", "CreatedAt")
        VALUES ('{pid}', '{cid}', '{name_escaped}', '{slug}', '{desc_escaped}', {base_price:.2f}, true, {imgs_sql}, NOW())
        ON CONFLICT ("Slug") DO UPDATE SET "BasePrice" = EXCLUDED."BasePrice", "Description" = EXCLUDED."Description", "ImageUrls" = EXCLUDED."ImageUrls";
        """
        sql_lines.append(prod_sql.strip())

        # Insert Variants and Inventory
        v_idx = 0
        for color, size, price_adj, stock in variants:
            v_idx += 1
            vid = str(uuid.uuid5(uuid.NAMESPACE_DNS, f"variant.{pid}.{v_idx}"))
            sku = f"PRD-{cat_slug[:3].upper()}-{count:03d}-{v_idx:02d}"
            title = f"{color} / {size}" if color and size else (color or size or "Standard")
            title_escaped = title.replace("'", "''")
            color_escaped = color.replace("'", "''") if color else None
            size_escaped = size.replace("'", "''") if size else None
            color_val = f"'{color_escaped}'" if color_escaped else "NULL"
            size_val = f"'{size_escaped}'" if size_escaped else "NULL"

            var_sql = f"""
            INSERT INTO "ProductVariants" ("Id", "ProductId", "Sku", "Title", "Color", "Size", "PriceAdjustment", "CreatedAt")
            VALUES ('{vid}', '{pid}', '{sku}', '{title_escaped}', {color_val}, {size_val}, {price_adj:.2f}, NOW())
            ON CONFLICT ("Sku") DO UPDATE SET "Title" = EXCLUDED."Title", "PriceAdjustment" = EXCLUDED."PriceAdjustment";
            """
            sql_lines.append(var_sql.strip())

            invid = str(uuid.uuid5(uuid.NAMESPACE_DNS, f"inv.{vid}"))
            inv_sql = f"""
            INSERT INTO "InventoryRecords" ("Id", "ProductVariantId", "StockQuantity", "ReservedQuantity", "RowVersion", "CreatedAt")
            VALUES ('{invid}', '{vid}', {stock}, 0, 1, NOW())
            ON CONFLICT ("ProductVariantId") DO UPDATE SET "StockQuantity" = EXCLUDED."StockQuantity";
            """
            sql_lines.append(inv_sql.strip())

    return "\n".join(sql_lines), count

if __name__ == "__main__":
    sql_script, count = generate_sql()
    with open("/tmp/seed_100_products.sql", "w") as f:
        f.write(sql_script)
    print(f"Generated SQL for {count} products in /tmp/seed_100_products.sql")
