"use client";
import { createContext, useContext, useState } from "react";
import type { Report } from "@/types";
import { SEED_REPORTS } from "@/data/seed";

interface Ctx {
  reports: Report[];      // ativos (não arquivados)
  arquivados: Report[];
  add: (r: Omit<Report, "id">) => Report;
  update: (id: string, patch: Partial<Omit<Report, "id">>) => void;
  archive: (id: string) => void;
  unarchive: (id: string) => void;
  get: (id: string) => Report | undefined;
}

const ReportsContext = createContext<Ctx | null>(null);

export function ReportsProvider({ children }: { children: React.ReactNode }) {
  const [all, setAll] = useState<Report[]>(SEED_REPORTS);

  const add: Ctx["add"] = (r) => {
    const nr: Report = { ...r, id: String(Date.now()), arquivado: false };
    setAll((prev) => [nr, ...prev]);
    return nr;
  };
  const update: Ctx["update"] = (id, patch) =>
    setAll((prev) => prev.map((r) => (r.id === id ? { ...r, ...patch } : r)));
  const archive: Ctx["archive"] = (id) => update(id, { arquivado: true });
  const unarchive: Ctx["unarchive"] = (id) => update(id, { arquivado: false });
  const get: Ctx["get"] = (id) => all.find((r) => r.id === id);

  const reports = all.filter((r) => !r.arquivado);
  const arquivados = all.filter((r) => r.arquivado);

  return (
    <ReportsContext.Provider value={{ reports, arquivados, add, update, archive, unarchive, get }}>
      {children}
    </ReportsContext.Provider>
  );
}

export function useReports() {
  const ctx = useContext(ReportsContext);
  if (!ctx) throw new Error("useReports precisa estar dentro de <ReportsProvider>");
  return ctx;
}
