import { ReportsProvider } from "@/components/relatorios/store";
import { BottomNav } from "@/components/ui/BottomNav";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <ReportsProvider>
      <div className="mx-auto min-h-screen max-w-md bg-papel">
        {children}
        <BottomNav />
      </div>
    </ReportsProvider>
  );
}
