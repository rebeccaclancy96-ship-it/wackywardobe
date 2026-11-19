import "@vibecodeapp/proxy";
import { z } from "zod";
import { resolve } from "node:path";
const env = z.object({ OPENAI_API_KEY: z.string().min(1) }).parse(process.env);
const form = new FormData();
for (const name of ["kid_girl_dino", "kid_boy_shark", "pet_puppy_dino"]) {
  const file = Bun.file(resolve(`../ios/vibecodedapp/Assets.xcassets/${name}.imageset/${name}.png`));
  form.append("image[]", file, `${name}.png`);
}
form.append("model", "gpt-image-2.6-flare");
form.append("size", "2304x1024");
form.append("quality", "high");
form.append("background", "opaque");
form.append("output_format", "png");
form.append("prompt", "Create a polished landscape promotional header for the actual children's dress-up game Wacky Wardrobe. Use the supplied game's characters faithfully: smiling girl in green dinosaur onesie, boy in shark costume, little golden puppy. Bright sunny sky-blue, a sweeping rainbow, soft rounded clouds, little sparkles, playful premium illustrated game art. Composition: left 55% has huge highly legible white rounded bubble lettering with a deep cobalt outline, exact title WACKY WARDROBE on two lines, and below smaller exact text Dress up. Make friends. Play! Right 45% features the supplied character friends waving together with full bodies and a puppy; ground them on a little green grassy island. Clear generous margins. Joyful and age appropriate, no purchase prompts, no urgency, no ratings, no Apple logo, no device frame. Do not add any other words. This is promotional key art, not a screenshot of game UI.");
const response = await fetch("https://api.openai.com/v1/images/edits", { method: "POST", headers: { Authorization: `Bearer ${env.OPENAI_API_KEY}` }, body: form });
if (!response.ok) throw new Error(`Header generation ${response.status}: ${(await response.text()).slice(0, 500)}`);
const result = await response.json() as { data: { b64_json: string }[] };
const bytes = Buffer.from(result.data[0]!.b64_json, "base64");
await Bun.write(resolve("../ios/app-store/promo-20261118/header.png"), bytes);
console.log("Created promotional header", bytes.length, "bytes; estimated generation cost $0.10-$0.20.");
