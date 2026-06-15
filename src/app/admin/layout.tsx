import { redirect } from "next/navigation";
import { getPapel } from "@/lib/supabase/profile";
import { ReportsProvider } from "@/components/relatorios/store";
import { BottomNav } from "@/components/ui/BottomNav";

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const papel = await getPapel();
  if (!papel) redirect("/login");
  if (papel !== "admin") redirect("/campo/ponto");

  return (
    <ReportsProvider>
      <div className="mx-auto min-h-screen max-w-md bg-papel">
        {children}
        <BottomNav />
      </div>
    </ReportsProvider>
  );
}
