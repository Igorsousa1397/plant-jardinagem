import type { Report, Cliente } from "@/types";

export const SEED_REPORTS: Report[] = [
  {
    id: "1",
    condo: "Alameda das Palmeiras",
    data: "08/09/2025",
    duracao: "5 horas",
    status: "Finalizado",
    servicos: ["Corte e Poda", "Remoção de Folhas / Galhos", "Paisagismo", "Limpeza Geral do Jardim"],
    equipamentos: ["Roçadeira", "Soprador", "Rastelo"],
    epi: ["Luvas", "Botas", "Óculos de Proteção"],
    observacoes:
      "Colocação de pedras brancas na caixa de palmeiras. Reforçar a rega, principalmente nas gramas recém-colocadas.",
    proximaVisita: "22/09/2025",
    fotosAntes: [],
    fotosDepois: [],
    arquivado: false,
  },
  {
    id: "2",
    condo: "San Denis",
    data: "21/07/2025",
    duracao: "4 horas",
    status: "Agendado",
    servicos: ["Corte de grama", "Poda de arbustos"],
    equipamentos: ["Roçadeira"],
    epi: ["Luvas", "Botas"],
    observacoes: "",
    proximaVisita: "04/08/2025",
    fotosAntes: [],
    fotosDepois: [],
    arquivado: false,
  },
];

// Clientes (extraídos das referências da proposta). Trocar por Supabase.
export const SEED_CLIENTES: Cliente[] = [
  { id: "c1", nome: "Alameda das Palmeiras" },
  { id: "c2", nome: "San Denis" },
  { id: "c3", nome: "Quinta do Moinho", sindico: "Hélio Vidilino", telefone: "(11) 94037-7744" },
  { id: "c4", nome: "Quinta do Loureiro", sindico: "Tiago Mello", telefone: "(11) 96149-8089" },
  { id: "c5", nome: "dos Girassóis", sindico: "Thiago Maiellaro", telefone: "(11) 99694-4188" },
];
