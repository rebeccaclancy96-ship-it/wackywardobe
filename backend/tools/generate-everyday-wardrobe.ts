import "@vibecodeapp/proxy";
import { existsSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";
import { z } from "zod";

// One-off static project artwork only. No routes, catalogs, or Swift are changed.
const { OPENAI_API_KEY } = z.object({ OPENAI_API_KEY: z.string().min(1) }).parse(process.env);
const assets = resolve(import.meta.dir, "../../ios/vibecodedapp/Assets.xcassets");
const style = "Match the reference's exact bold kid-friendly cartoon sticker style, thick dark outlines, glossy saturated colors, gentle fabric sparkle, cheerful expression. Single full-body character centered, facing viewer, all feet and hair/ears visible, generous transparent padding, nothing cropped. Genuine transparent alpha background, no backdrop, no floor shadow, no lettering, no extra objects.";
const clothes = {
  casual: "a colorful striped short-sleeve tee, blue jeans and sneakers",
  overalls: "a sunny yellow short-sleeve tee under blue denim overalls, and sneakers",
  pajamas: "a matching lavender pajama top and lavender pajama pants covered with small pale yellow stars, and cozy matching slippers. No hat, no hood, no head covering",
  rainbow: "a bright rainbow-striped hoodie with its hood DOWN behind the neck, coordinating jogger pants and sneakers. No head covering; the entire hairstyle must be exposed",
};
const hair = {
  boy: "short messy brown hair, warm tan skin",
  girl: "golden-blonde pigtails, warm tan skin",
  kid: "fluffy curly dark bob haircut, deep brown skin",
};
type Job = { name: string; ref: string; prompt: string; size: string };
const jobs: Job[] = [];
for (const [type, identity] of Object.entries(hair)) {
  for (const [outfit, description] of Object.entries(clothes)) {
    jobs.push({
      name: `kid_${type}_${outfit}`,
      ref: `kid_${type}_dino`,
      prompt: `Edit the supplied reference, keeping the EXACT same child: identical face, facial features, expression, skin color, proportions, pose and illustration style. Preserve ${identity}. Replace ONLY the entire dinosaur costume with ${description}. Remove every dinosaur element including hood, tail, claws and spikes. Show the child's natural hair fully, keeping the same hair identity and color as the reference. Keep arms happily outstretched and both feet visible. ${style}`,
      size: "1024x1536",
    });
  }
}
for (const pet of ["puppy", "kitty", "bunny", "piggy"]) {
  for (const outfit of ["pajamas", "rainbow"]) {
    const description = outfit === "pajamas"
      ? "a tiny lavender pajama outfit decorated with pale yellow stars, fitted naturally to this animal's body and legs"
      : "a tiny rainbow-striped hoodie with the hood DOWN behind the neck, fitted naturally to this animal's body";
    jobs.push({
      name: `pet_${pet}_${outfit}`,
      ref: `pet_${pet}_plain`,
      prompt: `Edit this exact reference pet. Keep EXACTLY the same animal identity, face, fur/skin color, markings, eyes, ears, tail, proportions, cheerful expression, front-facing seated pose and art style. Change only the clothing: dress the pet in ${description}. Head, fur tuft, entire ears and paws stay visible and unchanged, no hat or raised hood. No human features or human limbs. ${style}`,
      size: "1024x1024",
    });
  }
}

let requests = 0;
const successes: string[] = [];
const failures: string[] = [];
async function generate(job: Job) {
  const directory = `${assets}/${job.name}.imageset`;
  const image = `${directory}/${job.name}.png`;
  if (existsSync(image)) { console.log("SKIP", job.name); return; }
  try {
    const form = new FormData();
    form.append("model", "gpt-image-2.6-sunburst");
    form.append("prompt", job.prompt);
    form.append("image", new Blob([await Bun.file(`${assets}/${job.ref}.imageset/${job.ref}.png`).arrayBuffer()], { type: "image/png" }), `${job.ref}.png`);
    form.append("size", job.size);
    form.append("quality", "medium");
    form.append("background", "transparent");
    form.append("output_format", "png");
    requests++;
    const response = await fetch("https://api.openai.com/v1/images/edits", {
      method: "POST", headers: { Authorization: `Bearer ${OPENAI_API_KEY}` }, body: form,
      signal: AbortSignal.timeout(240_000),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}: ${(await response.text()).slice(0, 400)}`);
    const result = await response.json() as { data?: { b64_json?: string }[]; usage?: unknown };
    const encoded = result.data?.[0]?.b64_json;
    if (!encoded) throw new Error("Response has no image");
    mkdirSync(directory, { recursive: true });
    await Bun.write(image, Buffer.from(encoded, "base64"));
    await Bun.write(`${directory}/Contents.json`, JSON.stringify({ images: [{ idiom: "universal", filename: `${job.name}.png` }], info: { author: "xcode", version: 1 } }) + "\n");
    successes.push(job.name);
    console.log("OK", job.name, "usage", JSON.stringify(result.usage ?? {}));
  } catch (error) {
    failures.push(job.name);
    console.error("FAILED", job.name, String(error));
  }
}
// No automatic paid retries: keep the requested batch within its small budget.
const queue = [...jobs];
await Promise.all(Array.from({ length: 4 }, async () => {
  while (queue.length) await generate(queue.shift()!);
}));
console.log(JSON.stringify({ requests, successes, failures, approximateCreditsUSD: requests * 0.08 }));
if (failures.length) process.exitCode = 1;
