import { createClient } from "@/lib/supabase/client";

/** Redimensiona (lado máximo) e recodifica como JPEG no navegador. */
export async function comprimirImagem(file: File, maxLado = 1500, quality = 0.8): Promise<Blob> {
  const dataUrl = await new Promise<string>((res, rej) => {
    const r = new FileReader();
    r.onload = () => res(r.result as string);
    r.onerror = () => rej(new Error("Falha ao ler o arquivo."));
    r.readAsDataURL(file);
  });

  const img = await new Promise<HTMLImageElement>((res, rej) => {
    const i = new Image();
    i.onload = () => res(i);
    i.onerror = () => rej(new Error("Falha ao carregar a imagem."));
    i.src = dataUrl;
  });

  let { width, height } = img;
  if (width > maxLado || height > maxLado) {
    if (width >= height) {
      height = Math.round((height * maxLado) / width);
      width = maxLado;
    } else {
      width = Math.round((width * maxLado) / height);
      height = maxLado;
    }
  }

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas indisponível.");
  ctx.drawImage(img, 0, 0, width, height);

  return await new Promise<Blob>((res, rej) =>
    canvas.toBlob((b) => (b ? res(b) : rej(new Error("Falha ao compactar a imagem."))), "image/jpeg", quality)
  );
}

/** Compacta, envia ao bucket `relatorios` e devolve a URL pública. */
export async function uploadFoto(file: File): Promise<string> {
  const blob = await comprimirImagem(file);
  const sb = createClient();
  const nome = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}.jpg`;
  const { error } = await sb.storage.from("relatorios").upload(nome, blob, {
    contentType: "image/jpeg",
    upsert: false,
  });
  if (error) throw error;
  const { data } = sb.storage.from("relatorios").getPublicUrl(nome);
  return data.publicUrl;
}
