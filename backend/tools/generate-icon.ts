import "@vibecodeapp/proxy";
const form = new FormData();
form.append("model", "gpt-image-2.6-flare");
form.append("prompt", "Square iOS app icon. Close-up of this exact cheerful kid in the green dinosaur onesie hood (head and shoulders, big laughing face, googly eye on the hood) centered, on a bright glossy rainbow sunburst background with sparkles. Bold cartoon sticker style, thick outlines. Fill the whole square edge to edge, no rounded corners, no text, no border.");
form.append("image", new Blob([await Bun.file("/tmp/gen/kid_kid_dino.png").arrayBuffer()], { type: "image/png" }), "ref.png");
form.append("size", "1024x1024"); form.append("quality", "high"); form.append("background", "opaque"); form.append("output_format", "png");
const res = await fetch("https://api.openai.com/v1/images/edits", { method: "POST", headers: { Authorization: `Bearer ${process.env.OPENAI_API_KEY}` }, body: form });
const j: any = await res.json();
await Bun.write("/tmp/gen/icon.png", Buffer.from(j.data[0].b64_json, "base64")); console.log("ok");
