import "@vibecodeapp/proxy";
import { existsSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";
import { z } from "zod";

// One-off, user-requested static app artwork; never used for runtime uploads.
const { OPENAI_API_KEY } = z.object({ OPENAI_API_KEY: z.string().min(1) }).parse(process.env);
const assets = resolve(import.meta.dir, "../../ios/vibecodedapp/Assets.xcassets");
const style = "Match the reference's bold kid-friendly cartoon sticker illustration, thick dark outlines, glossy bright saturated colors and huge sparkly friendly eyes. One tiny adorable baby animal, full body centered, seated in a front three-quarter pose looking at viewer, every hoof/foot, head, tail and shell visible, generous transparent padding, nothing cropped. Genuine transparent alpha cutout: no background color, no glow backdrop, no floor, no ground shadow, no text, no people, no extra objects.";
const pets = {
  unicorn: "a tiny adorable pearly white baby unicorn, pastel rainbow mane and tail, one golden spiral horn on its forehead, four little sparkle hooves, huge friendly eyes. Clearly an equine baby unicorn with a short cute muzzle, not a kitten; no cat whiskers or tabby markings",
  turtle: "a tiny adorable mint green baby turtle with a rounded turquoise shell decorated with golden speckles, pale mint belly, four short turtle feet, tiny turtle tail and huge friendly eyes. Clearly a baby turtle, no fur, no cat ears, no whiskers; show its distinctive golden-speckled turquoise shell prominently at the side in the front three-quarter sitting pose",
};
const outfits = {
  pajamas: "tiny lavender pajamas decorated with pale yellow stars, naturally fitted around its body and legs; no head covering",
  rainbow: "a tiny bright rainbow-striped hoodie with the hood DOWN behind the neck; no head covering",
  strawberry: "a tiny red strawberry hat with small yellow seeds and green leaves, face completely exposed",
  bee: "a tiny yellow-and-black striped bumblebee costume with little translucent wings and a small antenna headband, face completely exposed",
  dino: "a tiny green dinosaur hoodie with soft orange spikes and a little costume tail, hood framing rather than hiding the face",
  hero: "a tiny red superhero cape and a blue eye mask, with the large friendly eyes fully visible through its openings; no letters or logo",
};
type Pet = keyof typeof pets;
type Job = { name: string; reference: string; prompt: string };
const phase = z.enum(["base", "outfits", "all"]).parse(process.argv[2] ?? "all");
let requests = 0;
const successes: string[] = [];
const failures: string[] = [];
async function generate(job: Job) {
  const directory = `${assets}/${job.name}.imageset`;
  const destination = `${directory}/${job.name}.png`;
  if (existsSync(destination) && existsSync(`${directory}/Contents.json`)) {
    console.log("SKIP", job.name);
    return;
  }
  try {
    const reference = Bun.file(`${assets}/${job.reference}.imageset/${job.reference}.png`);
    if (!await reference.exists()) throw new Error(`Missing reference ${job.reference}`);
    const form = new FormData();
    form.append("model", "gpt-image-2.6-flare");
    form.append("prompt", job.prompt);
    form.append("image", new Blob([await reference.arrayBuffer()], { type: "image/png" }), `${job.reference}.png`);
    form.append("size", "1024x1024");
    form.append("quality", "high");
    form.append("background", "transparent");
    form.append("output_format", "png");
    requests++;
    const response = await fetch("https://api.openai.com/v1/images/edits", {
      method: "POST", headers: { Authorization: `Bearer ${OPENAI_API_KEY}` }, body: form,
      signal: AbortSignal.timeout(240_000),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}: ${(await response.text()).slice(0, 400)}`);
    const result = z.object({ data: z.array(z.object({ b64_json: z.string().min(1) })).min(1), usage: z.unknown().optional() }).parse(await response.json());
    const png = Buffer.from(result.data[0]!.b64_json, "base64");
    if (png.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a") throw new Error("Response is not PNG");
    if (png.readUInt32BE(16) !== 1024 || png.readUInt32BE(20) !== 1024) throw new Error("Unexpected PNG dimensions");
    mkdirSync(directory, { recursive: true });
    await Bun.write(destination, png);
    await Bun.write(`${directory}/Contents.json`, JSON.stringify({ images: [{ idiom: "universal", filename: `${job.name}.png` }], info: { author: "xcode", version: 1 } }) + "\n");
    successes.push(job.name);
    console.log("OK", job.name, "usage", JSON.stringify(result.usage ?? {}));
  } catch (error) {
    failures.push(job.name);
    console.error("FAILED", job.name, String(error));
  }
}
async function pool(jobs: Job[], concurrency: number) {
  const queue = [...jobs];
  await Promise.all(Array.from({ length: concurrency }, async () => {
    while (queue.length) await generate(queue.shift()!);
  }));
}
if (phase === "base" || phase === "all") {
  await pool((Object.keys(pets) as Pet[]).map(pet => ({
    name: `pet_${pet}_plain`, reference: "pet_kitty_plain",
    prompt: `Use the supplied kitty image ONLY as an illustration art-style reference. Replace the kitten entirely with ${pets[pet]}. No clothes or accessories. ${style}`,
  })), 2);
}
if (phase === "outfits" || phase === "all") {
  const jobs: Job[] = [];
  for (const pet of Object.keys(pets) as Pet[]) {
    for (const [outfit, description] of Object.entries(outfits)) {
      jobs.push({
        name: `pet_${pet}_${outfit}`, reference: `pet_${pet}_plain`,
        prompt: `Edit the exact reference animal, keeping IDENTICAL face, species, colors, anatomy, proportions, expression, eyes, pose and art style. This pet is ${pets[pet]}. Change ONLY clothing: dress it in ${description}. ${pet === "unicorn" ? "The original single golden horn must remain visible, projecting naturally through a small opening in any headwear. Preserve its pastel rainbow mane and tail and four equine hooves. Do not add a second horn, shell, or cat features." : "Preserve the same visible golden-speckled turquoise shell, mint green skin, turtle feet and turtle head. Clothing fits around the shell without concealing or replacing it. It remains a TURTLE even in dinosaur clothing; do not replace its shell with spikes or change species."} No human hands or limbs. ${style}`,
      });
    }
  }
  await pool(jobs, 3);
}
console.log(JSON.stringify({ phase, requests, successes, failures, estimatedCreditsUSD: Number((requests * 0.08).toFixed(2)) }));
if (failures.length) process.exitCode = 1;
