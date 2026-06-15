import { redirect } from "next/navigation";

// A lista virou a Home. Mantém a rota antiga funcionando.
export default function RelatoriosIndex() {
  redirect("/admin/home");
}
