import "@vibecodeapp/proxy";
import { existsSync } from "fs";

const OUT = "/tmp/gen";
const KEY = process.env.OPENAI_API_KEY!;
const STYLE =
  "Bold kid-friendly cartoon sticker illustration, thick dark outlines, glossy bright saturated colors, subtle sparkly texture on fabric, cheerful expression, same art style as the reference image. Full body, centered, facing the viewer, standing happily with arms slightly out, feet visible, nothing cropped. Fully transparent background, no text, no sign, no shadow on the ground.";

async function edit(name: string, refs: string[], prompt: string, size: string) {
  const path = `${OUT}/${name}.png`;
  if (existsSync(path)) return;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const form = new FormData();
      form.append("model", "gpt-image-2.6-flare");
      form.append("prompt", prompt);
      for (const r of refs) form.append(refs.length > 1 ? "image[]" : "image", new Blob([await Bun.file(`${OUT}/${r}.png`).arrayBuffer()], { type: "image/png" }), `${r}.png`);
      form.append("size", size);
      form.append("quality", "medium");
      form.append("background", "transparent");
      form.append("output_format", "png");
      const res = await fetch("https://api.openai.com/v1/images/edits", { method: "POST", headers: { Authorization: `Bearer ${KEY}` }, body: form });
      const json: any = await res.json();
      const b64 = json?.data?.[0]?.b64_json;
      if (!b64) throw new Error(JSON.stringify(json).slice(0, 300));
      await Bun.write(path, Buffer.from(b64, "base64"));
      console.log("OK", name);
      return;
    } catch (e) {
      console.log("ERR", name, String(e));
    }
  }
}

async function pool<T>(items: T[], n: number, fn: (t: T) => Promise<void>) {
  const q = [...items];
  await Promise.all(Array.from({ length: n }, async () => { while (q.length) await fn(q.shift()!); }));
}

const kids: Record<string, string> = {
  boy: "a cheerful little boy (about 6 years old) with short messy brown hair and warm tan skin",
  girl: "a cheerful little girl (about 6 years old) with golden-blonde pigtails peeking out and warm tan skin",
  kid: "a cheerful little kid (about 6 years old) with a fluffy curly dark bob haircut and deep brown skin, gender-neutral look",
};
const costumes: Record<string, string> = {
  dino: "a green sparkly dinosaur onesie with the dino-head hood around the face (big teeth around the hood opening, one googly eye on top), yellow belly, orange spikes and a tail, exactly like the reference",
  shark: "a blue shark onesie with the shark-mouth hood (white soft teeth) around the face, a fin on top, white belly and a shark tail",
  unicorn: "a white and pastel rainbow unicorn onesie with a golden sparkly horn on the hood, rainbow mane and rainbow tail",
  banana: "a giant yellow banana costume covering the body with the face peeking out of the peel, a little brown stem on top",
  taco: "a giant taco costume with crunchy yellow shell, lettuce, tomato and cheese, face peeking out the top",
  astronaut: "a puffy white and orange astronaut space suit with mission patches and a clear bubble helmet",
  chicken: "a fluffy white chicken costume with a red comb on the hood, an orange beak cap, little wings and orange chicken feet",
  pickle: "a bumpy green pickle costume with a friendly pickle face hood, arms and legs out",
};

const pets: Record<string, string> = {
  puppy: "a tiny fluffy golden puppy with floppy ears",
  kitty: "a tiny chubby orange tabby kitten",
  bunny: "a tiny fluffy white bunny with pink inner ears",
  piggy: "a tiny round pink piglet",
};
const petOutfits: Record<string, string> = {
  plain: "",
  dino: "wearing a tiny green dinosaur hoodie with orange spikes and a little tail",
  bee: "wearing a tiny yellow and black bumblebee costume with little wings and antennae",
  strawberry: "wearing a tiny red strawberry hat with green leaves",
  hero: "wearing a tiny red superhero cape and blue eye mask",
};
const PET_STYLE = "Bold kid-friendly cartoon sticker illustration, thick dark outlines, glossy bright saturated colors, huge sparkly cute eyes, same art style as the reference image. Full body, centered, sitting and facing the viewer, nothing cropped. Fully transparent background, no text, no people, no shadow.";

const phase = process.argv[2] ?? "all";

if (phase === "all" || phase === "base") {
  await pool(Object.entries(kids), 3, ([k, d]) =>
    edit(`kid_${k}_dino`, ["ref"], `Redraw the character as ${d}, wearing ${costumes.dino}. ${STYLE}`, "1024x1536"));
  await pool(Object.entries(pets), 4, ([p, d]) =>
    edit(`pet_${p}_plain`, ["ref"], `Using only the art style of the reference (not the child), draw ${d}. ${PET_STYLE}`, "1024x1024"));
}
if (phase === "all" || phase === "rest") {
  const jobs: [string, string[], string, string][] = [];
  for (const [k, d] of Object.entries(kids))
    for (const [c, cd] of Object.entries(costumes)) {
      if (c === "dino") continue;
      jobs.push([`kid_${k}_${c}`, [`kid_${k}_dino`], `Keep the exact same child (same face, hair, skin tone, proportions, pose and art style) as the reference, but change the outfit so they are wearing ${cd} instead of the dinosaur onesie. ${STYLE}`, "1024x1536"]);
    }
  for (const [p, d] of Object.entries(pets))
    for (const [o, od] of Object.entries(petOutfits)) {
      if (o === "plain") continue;
      jobs.push([`pet_${p}_${o}`, [`pet_${p}_plain`], `Keep the exact same animal (${d}), same pose and art style as the reference, now ${od}. ${PET_STYLE}`, "1024x1024"]);
    }
  await pool(jobs, 6, ([n, r, pr, s]) => edit(n, r, pr, s));
}
console.log("DONE", phase);
