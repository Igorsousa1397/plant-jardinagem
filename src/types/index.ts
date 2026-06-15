export type Status = "Finalizado" | "Em andamento" | "Agendado" | "Atrasado";

export interface Report {
  id: string;
  condo: string;
  data: string;          // exibição dd/mm/aaaa (no banco, guarde ISO)
  duracao: string;
  status: Status;
  servicos: string[];
  equipamentos: string[];
  epi: string[];
  observacoes: string;
  proximaVisita: string;
  fotosAntes: string[];  // URLs (Supabase Storage) ou dataURL no protótipo
  fotosDepois: string[];
  arquivado?: boolean;
}

export interface Cliente {
  id: string;
  nome: string;          // condomínio
  sindico?: string;
  telefone?: string;     // formato exibição; só dígitos pra wa.me
}

export type Papel = "admin" | "funcionario";
