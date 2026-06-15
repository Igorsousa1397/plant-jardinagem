"use client";
import { createContext, useCallback, useContext, useEffect, useState } from "react";
import type { Report } from "@/types";
import * as api from "@/lib/relatorios";

interface Ctx {
  reports: Report[];      // ativos
  arquivados: Report[];
  loading: boolean;
  error: string | null;
  add: (r: Omit<Report, "id">) => Promise<Report>;
  update: (id: string, patch: Omit<Report, "id">) => Promise<void>;
  archive: (id: string) => Promise<void>;
  unarchive: (id: string) => Promise<void>;
  get: (id: string) => Report | undefined;
  refresh: () => Promise<void>;
}

const ReportsContext = createContext<Ctx | null>(null);

export function ReportsProvider({ children }: { children: React.ReactNode }) {
  const [all, setAll] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      setAll(await api.listRelatorios());
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erro ao carregar relatórios.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const add: Ctx["add"] = async (r) => {
    const novo = await api.createRelatorio(r);
    setAll((prev) => [novo, ...prev]);
    return novo;
  };
  const update: Ctx["update"] = async (id, patch) => {
    await api.updateRelatorio(id, patch);
    setAll((prev) => prev.map((x) => (x.id === id ? { ...x, ...patch, id } : x)));
  };
  const archive: Ctx["archive"] = async (id) => {
    await api.setArquivado(id, true);
    setAll((prev) => prev.map((x) => (x.id === id ? { ...x, arquivado: true } : x)));
  };
  const unarchive: Ctx["unarchive"] = async (id) => {
    await api.setArquivado(id, false);
    setAll((prev) => prev.map((x) => (x.id === id ? { ...x, arquivado: false } : x)));
  };
  const get: Ctx["get"] = (id) => all.find((x) => x.id === id);

  const reports = all.filter((x) => !x.arquivado);
  const arquivados = all.filter((x) => x.arquivado);

  return (
    <ReportsContext.Provider
      value={{ reports, arquivados, loading, error, add, update, archive, unarchive, get, refresh }}
    >
      {children}
    </ReportsContext.Provider>
  );
}

export function useReports() {
  const ctx = useContext(ReportsContext);
  if (!ctx) throw new Error("useReports precisa estar dentro de <ReportsProvider>");
  return ctx;
}
