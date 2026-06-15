import { redirect } from "next/navigation";
import { getPapel } from "@/lib/supabase/profile";

export default async function Home() {
  const papel = await getPapel();
  if (!papel) redirect("/login");
  redirect(papel === "admin" ? "/admin/home" : "/campo/ponto");
}
